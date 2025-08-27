import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/exception_mapping.dart';
import 'package:flutter_web/core/failures/team_failures.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/repositories/team_repository.dart';
import 'package:flutter_web/infrastructure/models/team_model.dart';

class TeamRepositoryImpl implements TeamRepository {
  final CollectionReference teamsCollection =
      FirebaseFirestore.instance.collection('teams');

  @override
  Future<Either<TeamFailure, Unit>> createTeam(Team team) async {
    try {
      final teamModel = TeamModel.fromDomain(team);
      await teamsCollection.doc(teamModel.id).set(teamModel.toMap());
      return right(unit);
    } catch (e) {
      return left(mapFirebaseError<TeamFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedFailure(),
        notFound: NotFoundFailure(),
      ));
    }
  }

  @override
  Future<Either<TeamFailure, Unit>> deleteTeamById(String id) async {
    try {
      await teamsCollection.doc(id).delete();
      return right(unit);
    } catch (e) {
      return left(mapFirebaseError<TeamFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedFailure(),
        notFound: NotFoundFailure(),
      ));
    }
  }

  @override
  Future<Either<TeamFailure, Unit>> updateTeam(Team team) async {
    try {
      final teamModel = TeamModel.fromDomain(team);
      await teamsCollection.doc(teamModel.id).update(teamModel.toMap());
      return right(unit);
    } catch (e) {
      return left(mapFirebaseError<TeamFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedFailure(),
        notFound: NotFoundFailure(),
      ));
    }
  }

  @override
  Future<Either<TeamFailure, List<Team>>> getAll() async {
    try {
      final snapshot = await teamsCollection.get();
      final teams = snapshot.docs
          .map((doc) => TeamModel.fromFirestore(doc).toDomain())
          .toList();
      return right(teams);
    } catch (e) {
      return left(mapFirebaseError<TeamFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedFailure(),
        notFound: NotFoundFailure(),
      ));
    }
  }

  @override
  Future<Either<TeamFailure, Team>> getById(String teamId) async {
    try {
      final doc = await teamsCollection.doc(teamId).get();
      if (!doc.exists) {
        return left(NotFoundFailure());
      }
      return right(TeamModel.fromFirestore(doc).toDomain());
    } catch (e) {
      return left(mapFirebaseError<TeamFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedFailure(),
        notFound: NotFoundFailure(),
      ));
    }
  }

  @override
  Stream<Either<TeamFailure, List<Team>>> watchAllTeams() async* {
    yield* teamsCollection.snapshots()
        .map<Either<TeamFailure, List<Team>>>((snapshot) {
      try {
        final teams = snapshot.docs
            .map((doc) => TeamModel.fromFirestore(doc).toDomain())
            .toList();
        return right<TeamFailure, List<Team>>(teams);
      } catch (e) {
        return left<TeamFailure, List<Team>>(
          mapFirebaseError<TeamFailure>(
            e,
            insufficientPermissions: InsufficientPermisssons(),
            unexpected: UnexpectedFailure(),
            notFound: NotFoundFailure(),
          ),
        );
      }
    }).handleError((e) {
      return left<TeamFailure, List<Team>>(
        mapFirebaseError<TeamFailure>(
          e,
          insufficientPermissions: InsufficientPermisssons(),
          unexpected: UnexpectedFailure(),
          notFound: NotFoundFailure(),
        ),
      );
    });
  }
}
