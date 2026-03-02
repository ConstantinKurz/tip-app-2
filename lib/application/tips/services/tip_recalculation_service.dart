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

  TipRecalculationService({
    required this.matchRepository,
    required this.recalculateMatchTipsUseCase,
  });

  /// Startet den Listener für Match-Änderungen
  /// Horcht auf watchAllMatches() Stream und reagiert auf neue Ergebnisse
  void startListening() {
    print('🎯 TipRecalculationService gestartet - Höre auf Match-Änderungen...');

    matchRepository.watchAllMatches().listen(
      (failureOrMatches) async {
        await failureOrMatches.fold(
          (failure) async {
            print('❌ Fehler beim Überwachen von Matches: $failure');
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
        print('❌ Stream-Fehler in TipRecalculationService: $e');
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

      print('🔄 ${matchesToProcess.length} Matches mit Ergebnis-Änderung werden verarbeitet...');
      // Update Punkte für Matches
      for (final match in matchesToProcess) {
        await _recalculateForMatch(match);
      }
      // Dann rufe ranking update auf.
      // ✅ Ranking nur EINMAL nach allen Updates!
      await recalculateMatchTipsUseCase.updateAllUserRankings();
    });
  }

  /// Neuberechnet Punkte für ein einzelnes Match
  Future<void> _recalculateForMatch(CustomMatch match) async {
    final result = await recalculateMatchTipsUseCase(match: match);

    result.fold(
      (failure) {
        print('❌ Fehler bei Neuberechnung für ${match.id}: $failure');
      },
      (_) {},
    );
  }
}
