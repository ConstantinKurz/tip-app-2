// ignore_for_file: public_member_api_docs

import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import '../entities/match_day_statistics.dart';
import '../entities/match_phase.dart';
import '../repositories/tip_repository.dart';
import '../repositories/match_repository.dart';

/// UseCase zur Validierung der Joker-Nutzung basierend auf matchDay
class ValidateJokerUsageUseCase {
  final TipRepository tipRepository;
  final MatchRepository matchRepository;
  
  ValidateJokerUsageUseCase({
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
    final maxJokers = phase.maxJokers;
    
    final jokersResult = await tipRepository.getJokersUsedInMatchDay(
      userId: userId,
      matchDay: matchDay,
    );

    final tippedGamesResult = await tipRepository.getTippedGamesInMatchDay(
      userId: userId,
      matchDay: matchDay,
    );

    // Hole Gesamtanzahl der Spiele im Spieltag
    final allMatchesResult = await matchRepository.getAllMatches();
    final totalGamesInMatchDay = allMatchesResult.fold(
      (_) => 0,
      (matches) => matches.where((m) => m.matchDay == matchDay).length,
    );

    return tippedGamesResult.fold(
      (failure) => left(failure),
      (tippedGames) => jokersResult.fold(
        (failure)  {
          return left(failure);
        },
        (usedJokers) => right(MatchDayStatistics(
          matchDay: matchDay,
          tippedGames: tippedGames,
          totalGames: totalGamesInMatchDay,
          jokersUsed: usedJokers,
          jokersAvailable: maxJokers,
        )),
      ),
    );
  }
}
