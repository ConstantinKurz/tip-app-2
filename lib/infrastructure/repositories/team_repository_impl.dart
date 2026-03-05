import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/exception_mapping.dart';
import 'package:flutter_web/core/failures/team_failures.dart';
import 'package:flutter_web/core/utils/firestore_logger.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/repositories/team_repository.dart';
import 'package:flutter_web/infrastructure/models/team_model.dart';

class TeamRepositoryImpl implements TeamRepository {
  final FirebaseFirestore firebaseFirestore;
  TeamRepositoryImpl({required this.firebaseFirestore});

  CollectionReference get teamsCollection => firebaseFirestore.collection('teams');

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
      FirestoreLogger.logRead('teams', 'getAll');
      print('📥 [TeamRepository] getAll called');
      final snapshot = await teamsCollection.get();
      FirestoreLogger.logRead('teams', 'getAll (RESULT)', docId: '[${snapshot.docs.length} docs]');
      print('✅ [TeamRepository] getAll: ${snapshot.docs.length} teams');
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
      FirestoreLogger.logRead('teams', 'getById', docId: teamId);
      print('📥 [TeamRepository] getById: $teamId');
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
    print('🎯 [TeamRepository] watchAllTeams STREAM STARTED');
    FirestoreLogger.logRead('teams', 'watchAllTeams (STREAM)');
    
    int eventCount = 0;
    
    yield* teamsCollection.snapshots()
        .map<Either<TeamFailure, List<Team>>>((snapshot) {
      eventCount++;
      FirestoreLogger.logRead('teams', 'watchAllTeams (EVENT #$eventCount)', docId: '[${snapshot.docs.length} docs]');
      print('📥 [TeamRepository] watchAllTeams EVENT #$eventCount: ${snapshot.docs.length} teams');
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
