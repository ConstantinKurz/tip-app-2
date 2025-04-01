import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/match_failures.dart'; // Adjust import path as per your project structure
import 'package:flutter_web/domain/entities/match.dart'; // Adjust import path as per your project structure

abstract class MatchRepository {
  Stream<Either<MatchFailure, List<CustomMatch>>> watchAllMatches();

  Future<Either<MatchFailure, Unit>> createMatch(CustomMatch match);

  Future<Either<MatchFailure, Unit>> updateMatch(CustomMatch match);

  Future<Either<MatchFailure, Unit>> deleteMatch(CustomMatch match);

  Future<Either<MatchFailure, List<CustomMatch>>> getAllMatches();
}
