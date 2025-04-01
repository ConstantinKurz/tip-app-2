import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/team_failures.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/repositories/team_repository.dart';
import 'package:flutter_web/infrastructure/models/team_model.dart';


class TeamRepositoryImpl implements TeamRepository {

  final CollectionReference teamsCollection =
      FirebaseFirestore.instance.collection('teams');

  @override
  Future<Either<TeamFailure, Unit>> create(Team team) async {
    try {
      final teamModel = TeamModel.fromDomain(team);
      await teamsCollection.doc(teamModel.id).set(teamModel.toMap());

      return right(unit);
    } on FirebaseException catch (e) {
      if (e.code.contains("PERMISSION_DENIED")) {
        return left(InsufficientPermisssons());
      } else {
        return left(UnexpectedFailure());
      }
    }
  }

  @override
  Future<Either<TeamFailure, Unit>> delete(Team todo) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<Either<TeamFailure, Unit>> update(Team todo) {
    // TODO: implement update
    throw UnimplementedError();
  }

  @override
  Future<Either<TeamFailure,List<Team>>> getAll() async {
    try {
      QuerySnapshot snapshot = await teamsCollection.get();
      List<Team> teams = snapshot.docs.map((doc) => TeamModel.fromFirestore(doc).toDomain()).toList();
      return right(teams);
    } catch (e) {
      return left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<TeamFailure, Team>> get(String teamId) async {
    try {
      final teamDoc = await teamsCollection.doc(teamId).get();

      if (!teamDoc.exists) {
        return left(NotFoundFailure());
      }

      final team = TeamModel.fromFirestore(teamDoc).toDomain();
      return right(team);
    } on FirebaseException catch (e) {
      if (e.code.contains("PERMISSION_DENIED")) {
        return left(InsufficientPermisssons());
      } else {
        return left(UnexpectedFailure());
      }
    } catch (e) {
      return left(UnexpectedFailure());
    }
  }

  // @override
  // Future<Either<TeamFailure, List<Team>>> watchAll() async {
  //   try {
  //     QuerySnapshot snapshot = await teamsCollection.get();
  //     List<Team> teams =
  //         snapshot.docs.map((doc) => TeamModel.fromFirestore(doc).toDomain()).toList();
  //     return right(teams);
  //   } catch (e) {
  //     return left(UnexpectedFailure());
  //   }
  // }

    @override
  Stream<Either<TeamFailure, List<Team>>> watchAllTeams() async* {

    // Extract documents from the querySnapshot
    yield* teamsCollection
        .snapshots()
        // right side listen on todos
        .map((snapshot) =>
          right<TeamFailure, List<Team>>(snapshot.docs
            .map((doc) => TeamModel.fromFirestore(doc).toDomain())
            .toList()))
        // left side handle error
        .handleError((e) {
          print(e);
      if (e is FirebaseException) {
        if (e.code.contains('permission-denied') ||
            e.code.contains("PERMISSION_DENIED")) {
          return left(InsufficientPermisssons());
        } else {
          return left(UnexpectedFailure());
        }
      } else {
        return left(UnexpectedFailure());
      }
    });
  }
  
  @override
  Future<Either<TeamFailure, List<Team>>> getAllTeams() {
    // TODO: implement getAllTeams
    throw UnimplementedError();
  }
}