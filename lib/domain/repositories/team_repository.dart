import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/team_failures.dart';
import 'package:flutter_web/domain/entities/team.dart';


abstract class TeamRepository {
  Future<Either<TeamFailure, List<Team>>> getAll();

  Future<Either<TeamFailure, Unit>> createTeam(Team todo);

  Future<Either<TeamFailure, Unit>> updateTeam(Team todo);

  Future<Either<TeamFailure, Unit>> deleteTeamById(String id);

  Future<Either<TeamFailure, Team>> getById(String teamId);

  Stream<Either<TeamFailure, List<Team>>> watchAllTeams();
}