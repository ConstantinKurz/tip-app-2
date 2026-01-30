import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/domain/usecases/recalculate_match_tips_usecase.dart';

/// Service der auf Match-Änderungen horcht und automatisch Punkte neuberechnet
class TipRecalculationService {
  final MatchRepository matchRepository;
  final RecalculateMatchTipsUseCase recalculateMatchTipsUseCase;

  TipRecalculationService({
    required this.matchRepository,
    required this.recalculateMatchTipsUseCase,
  });

  /// Startet den Listener für Match-Änderungen
  /// Horcht auf watchAllMatches() Stream und reagiert auf neue Ergebnisse
  void startListening() {
    print(
        '🎯 TipRecalculationService gestartet - Höre auf Match-Änderungen...');

    matchRepository.watchAllMatches().listen(
      (failureOrMatches) {
        failureOrMatches.fold(
          (failure) {
            print('❌ Fehler beim Überwachen von Matches: $failure');
          },
          (matches) async {
            // Filtere nur Matches mit neuen Ergebnissen
            final matchesWithResults =
                matches.where((m) => m.hasResult).toList();

            if (matchesWithResults.isNotEmpty) {
              print(
                  '🔄 ${matchesWithResults.length} Matches mit Ergebnissen gefunden');

              // Neuberechne Punkte für jedes Match mit Ergebnis
              for (final match in matchesWithResults) {
                await _recalculateForMatch(match);
              }
            }
          },
        );
      },
      onError: (e) {
        print('❌ Stream-Fehler in TipRecalculationService: $e');
      },
    );
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
