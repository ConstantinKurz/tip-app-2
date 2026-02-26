import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/tip.dart';

abstract class TipRepository {
  Stream<Either<TipFailure, Map<String, List<Tip>>>> watchAll();

  Stream<Either<TipFailure, List<Tip>>> watchUserTips(String userID);

  /// ✅ NEU: Stream für Community-Tips eines einzelnen Matches
  Stream<Either<TipFailure, List<Tip>>> watchTipsForMatch(String matchId);

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
  
  /// ✅ NEU: Gibt die Anzahl verwendeter Joker in mehreren matchDays zurück
  Future<Either<TipFailure, int>> getJokersUsedInMatchDays({
    required String userId,
    required List<int> matchDays,
  });
  
  /// Validiert ob Joker noch verfügbar ist
  Future<Either<TipFailure, bool>> canUseJokerInMatchDay({
    required String userId,
    required int matchDay,
  });
  
  /// Gibt die Anzahl der getippten Spiele an einem Spieltag zurück
  Future<Either<TipFailure, int>> getTippedGamesInMatchDay({
    required String userId,
    required int matchDay,
  });
}