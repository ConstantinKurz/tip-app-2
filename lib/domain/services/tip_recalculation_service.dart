import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/domain/usecases/recalculate_match_tips_usecase.dart';

/// Service der auf Match-Änderungen horcht und automatisch Punkte neuberechnet
class TipRecalculationService {
  final MatchRepository matchRepository;
  final RecalculateMatchTipsUseCase recalculateMatchTipsUseCase;

  // Map zum Speichern des letzten Match-Status
  final Map<String, CustomMatch> _lastMatchesById = {};

  // ✅ Debounce Timer für Batch-Updates
  Timer? _debounceTimer;
  final List<CustomMatch> _pendingMatches = [];
  static const _debounceDuration = Duration(milliseconds: 500);

  // ✅ Stream Subscription für Cancel bei Neustart
  StreamSubscription? _matchStreamSub;
  bool _isListening = false;

  TipRecalculationService({
    required this.matchRepository,
    required this.recalculateMatchTipsUseCase,
  });

  /// Startet den Listener für Match-Änderungen
  /// Horcht auf watchAllMatches() Stream und reagiert auf neue Ergebnisse
  void startListening() {
    // ✅ Verhindere mehrfaches Starten
    if (_isListening) {
      debugPrint('⏭️ TipRecalculationService bereits aktiv - überspringe');
      return;
    }
    _isListening = true;

    debugPrint(
        '🎯 TipRecalculationService gestartet - Höre auf Match-Änderungen...');

    _matchStreamSub?.cancel();
    _matchStreamSub = matchRepository.watchAllMatches().listen(
      (failureOrMatches) async {
        await failureOrMatches.fold(
          (failure) async {
            debugPrint('❌ Fehler beim Überwachen von Matches: $failure');
          },
          (matches) async {
            final matchesWithResults =
                matches.where((m) => m.hasResult).toList();

            // Filter: Nur Matches mit Ergebnis-Änderung
            final changedMatches = <CustomMatch>[];
            for (final match in matchesWithResults) {
              final lastMatch = _lastMatchesById[match.id];
              if (lastMatch == null ||
                  lastMatch.homeScore != match.homeScore ||
                  lastMatch.guestScore != match.guestScore) {
                changedMatches.add(match);
              }
              // Update Map mit aktuellem Match
              _lastMatchesById[match.id] = match;
            }

            if (changedMatches.isNotEmpty) {
              // ✅ Sammle Änderungen und debounce
              _pendingMatches.addAll(changedMatches);
              _scheduleProcessing();
            }
          },
        );
      },
      onError: (e) {
        debugPrint('❌ Stream-Fehler in TipRecalculationService: $e');
      },
    );
  }

  /// ✅ Debounced Verarbeitung der Matches
  void _scheduleProcessing() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () async {
      if (_pendingMatches.isEmpty) return;

      // Kopiere und leere die Liste
      final matchesToProcess = List<CustomMatch>.from(_pendingMatches);
      _pendingMatches.clear();

      debugPrint(
          '🔄 ${matchesToProcess.length} Matches mit Ergebnis-Änderung werden verarbeitet...');

      // ✅ Update Punkte für alle Matches OHNE User-Score-Update (sammelt betroffene User)
      for (final match in matchesToProcess) {
        await _recalculateForMatch(match);
      }

      // ✅ EINMAL am Ende: User-Scores für alle betroffenen User aktualisieren
      await recalculateMatchTipsUseCase.updatePendingUserScores();

      // ✅ Ranking nur EINMAL nach allen Updates!
      await recalculateMatchTipsUseCase.updateAllUserRankings();
    });
  }

  /// Neuberechnet Punkte für ein einzelnes Match (ohne User-Score-Update)
  Future<void> _recalculateForMatch(CustomMatch match) async {
    // ✅ skipUserScoreUpdate: true - User-Scores werden am Ende gesammelt aktualisiert
    final result = await recalculateMatchTipsUseCase(
      match: match,
      skipUserScoreUpdate: true,
    );

    result.fold(
      (failure) {
        debugPrint('❌ Fehler bei Neuberechnung für ${match.id}: $failure');
      },
      (_) {},
    );
  }
}
