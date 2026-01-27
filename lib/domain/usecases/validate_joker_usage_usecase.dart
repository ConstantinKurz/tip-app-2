// ignore_for_file: public_member_api_docs

import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import '../entities/match_phase.dart';
import '../repositories/tip_repository.dart';

/// UseCase zur Validierung der Joker-Nutzung basierend auf matchDay
class ValidateJokerUsageUseCase {
  final TipRepository tipRepository;
  
  ValidateJokerUsageUseCase(this.tipRepository);

  /// Prüft ob Benutzer noch Joker in diesem matchDay verfügbar hat
  /// Nutzt matchDay um die Phase und deren Limits zu bestimmen
  Future<Either<TipFailure, JokerValidationResult>> call({
    required String userId,
    required int matchDay,
  }) async {
    final phase = MatchPhase.fromMatchDay(matchDay);
    final maxJokers = phase.maxJokers;
    
    final result = await tipRepository.getJokersUsedInMatchDay(
      userId: userId,
      matchDay: matchDay,
    );

    return result.fold(
      (failure) => left(failure),
      (usedJokers) => right(JokerValidationResult(
        isAvailable: usedJokers < maxJokers,
        used: usedJokers,
        total: maxJokers,
        matchDay: matchDay,
      )),
    );
  }
}

class JokerValidationResult {
  final bool isAvailable;
  final int used;
  final int total;
  final int matchDay;
  
  JokerValidationResult({
    required this.isAvailable,
    required this.used,
    required this.total,
    required this.matchDay,
  });
}
