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

    // ✅ NEU: Für Vorrunde (matchDay 1-3) aggregierte Statistik über alle Spieltage
    final bool isGroupStage = phase == MatchPhase.groupStage;
    final matchDaysForTips = isGroupStage ? [1, 2, 3] : [matchDay];
    
    // Tipped Games: Für Vorrunde über alle 3 Spieltage, sonst nur einzelner matchDay
    final Either<TipFailure, int> tippedGamesResult;
    if (isGroupStage) {
      tippedGamesResult = await tipRepository.getTippedGamesInMatchDays(
        userId: userId,
        matchDays: matchDaysForTips,
      );
    } else {
      tippedGamesResult = await tipRepository.getTippedGamesInMatchDay(
        userId: userId,
        matchDay: matchDay,
      );
    }

    // ✅ NEU: Für Vorrunde ist totalGames = maxTips (20), sonst tatsächliche Spielanzahl
    int totalGamesForPhase;
    if (isGroupStage && phase.maxTips != null) {
      totalGamesForPhase = phase.maxTips!;
    } else {
      final allMatchesResult = await matchRepository.getAllMatches();
      totalGamesForPhase = allMatchesResult.fold(
        (_) => 0,
        (matches) => matches.where((m) => m.matchDay == matchDay).length,
      );
    }

    return tippedGamesResult.fold(
      (failure) => left(failure),
      (tippedGames) => jokersResult.fold(
        (failure) {
          return left(failure);
        },
        (usedJokers) => right(MatchDayStatistics(
          matchDay: matchDay,
          tippedGames: tippedGames,         // ← Für Vorrunde: über alle 3 Spieltage
          totalGames: totalGamesForPhase,   // ← Für Vorrunde: maxTips (20)
          jokersUsed: usedJokers,
          jokersAvailable: maxJokers,
        )),
      ),
    );
  }
}
