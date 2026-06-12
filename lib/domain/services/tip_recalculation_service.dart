import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/domain/usecases/recalculate_match_tips_usecase.dart';

/// Service der auf Match-Änderungen horcht und automatisch Punkte neuberechnet.
class TipRecalculationService {
  final MatchRepository matchRepository;
  final RecalculateMatchTipsUseCase recalculateMatchTipsUseCase;
  final FirebaseFirestore firebaseFirestore;

  final Map<String, CustomMatch> _lastMatchesById = {};
  final Map<String, CustomMatch> _pendingMatchesById = {};

  StreamSubscription? _matchesSubscription;
  Timer? _debounceTimer;

  bool _isListening = false;
  bool _isProcessing = false;
  bool _hasInitialSnapshot = false;

  final String _instanceId = DateTime.now().millisecondsSinceEpoch.toString();

  static const _debounceDuration = Duration(milliseconds: 500);
  static const _lockDuration = Duration(seconds: 90);

  TipRecalculationService({
    required this.matchRepository,
    required this.recalculateMatchTipsUseCase,
    required this.firebaseFirestore,
  });

  DocumentReference<Map<String, dynamic>> get _lockRef =>
      firebaseFirestore.collection('system_locks').doc('ranking_recalculation');

  void startListening() {
    if (_isListening) {
      debugPrint(
        '⚠️ TipRecalculationService $_instanceId läuft bereits - startListening ignoriert',
      );
      return;
    }

    _isListening = true;

    debugPrint(
      '🎯 TipRecalculationService $_instanceId gestartet - Höre auf Match-Änderungen...',
    );

    _matchesSubscription = matchRepository.watchAllMatches().listen(
      (failureOrMatches) async {
        await failureOrMatches.fold(
          (failure) async {
            debugPrint('❌ Fehler beim Überwachen von Matches: $failure');
          },
          (matches) async {
            final matchesWithResults =
                matches.where((match) => match.hasResult).toList();

            if (!_hasInitialSnapshot) {
              for (final match in matchesWithResults) {
                _lastMatchesById[match.id] = match;
              }

              _hasInitialSnapshot = true;

              debugPrint(
                '📌 Service $_instanceId: Initialer Match-Snapshot gecached '
                '(${matchesWithResults.length} Matches mit Ergebnis) - keine Recalculation',
              );

              return;
            }

            for (final match in matchesWithResults) {
              final lastMatch = _lastMatchesById[match.id];

              final hasScoreChanged = lastMatch != null &&
                  (lastMatch.homeScore != match.homeScore ||
                      lastMatch.guestScore != match.guestScore);

              _lastMatchesById[match.id] = match;

              if (hasScoreChanged) {
                _pendingMatchesById[match.id] = match;
              }
            }

            if (_pendingMatchesById.isNotEmpty) {
              _scheduleProcessing();
            }
          },
        );
      },
      onError: (error) {
        debugPrint('❌ Stream-Fehler in TipRecalculationService: $error');
      },
    );
  }

  void _scheduleProcessing() {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(_debounceDuration, () async {
      if (_isProcessing) {
        debugPrint(
          '⏳ Service $_instanceId: Recalculation läuft bereits - neuer Durchlauf wird danach geplant',
        );
        return;
      }

      if (_pendingMatchesById.isEmpty) {
        return;
      }

      _isProcessing = true;

      final matchesToProcess = _pendingMatchesById.values.toList();
      _pendingMatchesById.clear();

      final hasLock = await _tryAcquireLock();

      if (!hasLock) {
        debugPrint(
          '🔒 Service $_instanceId: Recalculation übersprungen - anderer Client rechnet bereits',
        );

        _isProcessing = false;
        return;
      }

      try {
        debugPrint(
          '🔄 Service $_instanceId verarbeitet ${matchesToProcess.length} Matches mit Ergebnis-Änderung...',
        );

        for (final match in matchesToProcess) {
          await _recalculateForMatch(match);
        }

        debugPrint(
          '🏁 Service $_instanceId startet updateAllUserRankings',
        );

        await recalculateMatchTipsUseCase.updateAllUserRankings();
      } finally {
        await _releaseLock();

        _isProcessing = false;

        if (_pendingMatchesById.isNotEmpty) {
          _scheduleProcessing();
        }
      }
    });
  }

  Future<bool> _tryAcquireLock() async {
    try {
      final now = DateTime.now();
      final lockedUntil = now.add(_lockDuration);

      return await firebaseFirestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(_lockRef);
        final data = snapshot.data();

        final existingLockedUntil = data?['lockedUntil'];

        if (existingLockedUntil is Timestamp) {
          final existingDate = existingLockedUntil.toDate();

          if (existingDate.isAfter(now)) {
            debugPrint(
              '🔒 Service $_instanceId: Lock ist belegt bis $existingDate von ${data?['ownerId']}',
            );
            return false;
          }
        }

        transaction.set(
          _lockRef,
          {
            'ownerId': _instanceId,
            'lockedUntil': Timestamp.fromDate(lockedUntil),
            'startedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        debugPrint(
          '🔓 Service $_instanceId: Lock erhalten bis $lockedUntil',
        );

        return true;
      });
    } catch (e) {
      debugPrint('❌ Service $_instanceId: Lock konnte nicht geholt werden: $e');
      return false;
    }
  }

  Future<void> _releaseLock() async {
    try {
      final snapshot = await _lockRef.get();
      final data = snapshot.data();

      if (data?['ownerId'] != _instanceId) {
        debugPrint(
          '⚠️ Service $_instanceId: Lock wird nicht freigegeben, weil Owner abweicht',
        );
        return;
      }

      await _lockRef.set(
        {
          'lockedUntil': Timestamp.fromDate(DateTime.now()),
          'finishedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint('🔓 Service $_instanceId: Lock freigegeben');
    } catch (e) {
      debugPrint(
          '❌ Service $_instanceId: Lock konnte nicht freigegeben werden: $e');
    }
  }

  Future<void> _recalculateForMatch(CustomMatch match) async {
    final result = await recalculateMatchTipsUseCase(match: match);

    result.fold(
      (failure) {
        debugPrint('❌ Fehler bei Neuberechnung für ${match.id}: $failure');
      },
      (_) {},
    );
  }

  Future<void> dispose() async {
    _debounceTimer?.cancel();
    await _matchesSubscription?.cancel();

    _matchesSubscription = null;
    _isListening = false;
    _isProcessing = false;
    _hasInitialSnapshot = false;

    _lastMatchesById.clear();
    _pendingMatchesById.clear();
  }
}
