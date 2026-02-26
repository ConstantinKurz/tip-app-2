// ignore_for_file: public_member_api_docs

import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import '../entities/match_day_statistics.dart';
import '../entities/match_phase.dart';
import '../repositories/tip_repository.dart';
import '../repositories/match_repository.dart';

/// UseCase zur Validierung der Joker-Nutzung basierend auf matchDay
class ValidateJokerUsageUpdateStatUseCase {
  final TipRepository tipRepository;
  final MatchRepository matchRepository;
  
  ValidateJokerUsageUpdateStatUseCase({
    required this.tipRepository,
    required this.matchRepository,
  });

  /// Prüft ob Benutzer noch Joker in diesem matchDay verfügbar hat
  /// Nutzt matchDay um die Phase und deren Limits zu bestimmen
  Future<Either<TipFailure, MatchDayStatistics>> call({
    required String userId,
    required int matchDay,
  }) async {
    final phase = MatchPhase.fromMatchDay(matchDay);
    
    // ✅ Für Joker: Nutze Phase-Logik (7+8 zusammen für Halbfinale/Finale)
    final matchDaysForJokers = phase.getMatchDaysForJokerPhase();
    
    // ✅ Spezialfall: Halbfinale + Finale teilen sich 2 Joker
    int maxJokers;
    if (matchDay == 7 || matchDay == 8) {
      maxJokers = 2; // Beide zusammen haben 2 Joker
    } else {
      maxJokers = phase.maxJokers;
    }

    // ✅ Joker: Zähle für die ganze Phase (7+8 zusammen)
    final jokersResult = await tipRepository.getJokersUsedInMatchDay(
      userId: userId,
      matchDay: matchDay,
    );

    // ✅ Tipped Games: Zähle NUR für diesen einzelnen matchDay
    final tippedGamesResult = await tipRepository.getTippedGamesInMatchDay(
      userId: userId,
      matchDay: matchDay, // ← Nur dieser matchDay!
    );

    // Hole Gesamtanzahl der Spiele im EINZELNEN Spieltag
    final allMatchesResult = await matchRepository.getAllMatches();
    final totalGamesInMatchDay = allMatchesResult.fold(
      (_) => 0,
      (matches) => matches.where((m) => m.matchDay == matchDay).length,
    );

    return tippedGamesResult.fold(
      (failure) => left(failure),
      (tippedGames) => jokersResult.fold(
        (failure) {
          return left(failure);
        },
        (usedJokers) => right(MatchDayStatistics(
          matchDay: matchDay,
          tippedGames: tippedGames,        // ← Nur für DIESEN matchDay
          totalGames: totalGamesInMatchDay, // ← Nur für DIESEN matchDay
          jokersUsed: usedJokers,          // ← Für die ganze Phase (7+8)
          jokersAvailable: maxJokers,      // ← Phase-Limit
        )),
      ),
    );
  }
}
