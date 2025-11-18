import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/match_failures.dart';
import 'package:flutter_web/domain/entities/match.dart';

abstract class MatchRepository {
  Stream<Either<MatchFailure, List<CustomMatch>>> watchAllMatches();

  Future<Either<MatchFailure, Unit>> createMatch(CustomMatch match);

  Future<Either<MatchFailure, Unit>> updateMatch(CustomMatch match);

  Future<Either<MatchFailure, Unit>> deleteMatchById(String matchId);

  Future<Either<MatchFailure, List<CustomMatch>>> getAllMatches();

  Future<Either<MatchFailure, CustomMatch>> getMatchById(String matchId);
}
