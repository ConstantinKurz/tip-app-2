import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/tip.dart';

abstract class TipRepository {
  Stream<Either<TipFailure, Map<String, List<Tip>>>> watchAll();

  Stream<Either<TipFailure, List<Tip>>> watchUserTips(String userID);

  Future<Either<TipFailure, Unit>> create(Tip tip);
  
  /// Gibt alle Tips für ein bestimmtes Match zurück
  Future<Either<TipFailure, List<Tip>>> getTipsForMatch(String matchId);
  
  /// Gibt alle Tips eines Users zurück
  Future<Either<TipFailure, List<Tip>>> getTipsByUserId(String userId);
  
  /// Aktualisiert die Punkte eines Tips
  Future<Either<TipFailure, Unit>> updatePoints({
    required String tipId,
    required int points,
  });
  
  /// Gibt die Anzahl verwendeter Joker in einem matchDay zurück
  Future<Either<TipFailure, int>> getJokersUsedInMatchDay({
    required String userId,
    required int matchDay,
  });
  
  /// Validiert ob Joker noch verfügbar ist
  Future<Either<TipFailure, bool>> canUseJokerInMatchDay({
    required String userId,
    required int matchDay,
  });
}