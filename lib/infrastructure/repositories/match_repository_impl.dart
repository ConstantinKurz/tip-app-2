import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/match_failures.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/infrastructure/models/match_model.dart';

class MatchRepositoryImpl implements MatchRepository {
  final CollectionReference matchesCollection =
      FirebaseFirestore.instance.collection('matches');

  @override
  Stream<Either<MatchFailure, List<CustomMatch>>> watchAllMatches() async* {
    // Extract documents from the querySnapshot
    yield* matchesCollection
        .snapshots()
        // right side listen on todos
        .map((snapshot) => right<MatchFailure, List<CustomMatch>>(snapshot.docs
            .map((doc) => MatchModel.fromFirestore(doc).toDomain())
            .toList()))
        // left side handle error
        .handleError((e) {
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
  Future<Either<MatchFailure, Unit>> createMatch(CustomMatch match) async {
    try {
      final matchModel = MatchModel.fromDomain(match);
      await matchesCollection.doc(matchModel.id).set(matchModel.toMap());

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
  Future<Either<MatchFailure, Unit>> deleteMatchById(String matchId) async {
    try {
      await matchesCollection.doc(matchId).delete();
      return right(unit);
    } catch (e) {
      return left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<MatchFailure, List<CustomMatch>>> getAllMatches() async {
    try {
      QuerySnapshot snapshot = await matchesCollection.get();
      List<CustomMatch> matches = snapshot.docs
          .map((doc) => MatchModel.fromFirestore(doc).toDomain())
          .toList();
      return right(matches);
    } catch (e) {
      return left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<MatchFailure, Unit>> updateMatch(CustomMatch match) async {
    try {
      final matchModel = MatchModel.fromDomain(match);
      print('Matchday wird an Firestore gesendet: ${matchModel.toMap()}');
      await matchesCollection.doc(matchModel.id).update(matchModel.toMap());
      return right(unit);
    } on FirebaseException catch (e) {
      if (e.code.contains("PERMISSION_DENIED")) {
        return left(InsufficientPermisssons());
      } else {
        return left(UnexpectedFailure());
      }
    }
  }

  // @override
  // Future<Either<MatchFailure, Unit>> createMatch(CustomMatch match) async {
  //   try {
  //     final matchModel = MatchModel.fromDomain(match);
  //     await matchesCollection.doc(matchModel.id).set(matchModel.toMap());

  //     return right(unit);
  //   } on FirebaseException catch (e) {
  //     if (e.code.contains("PERMISSION_DENIED")) {
  //       return left(InsufficientPermisssons());
  //     } else {
  //       return left(UnexpectedFailure());
  //     }
  //   }
  // }

  @override
  Future<Either<MatchFailure, CustomMatch>> getMatchById(String matchId) async {
    try {
      DocumentSnapshot doc = await matchesCollection.doc(matchId).get();
      if (doc.exists) {
        CustomMatch match = MatchModel.fromFirestore(doc).toDomain();
        return right(match);
      } else {
        return left(NotFoundFailure());
      }
    } catch (e) {
      return left(UnexpectedFailure());
    }
  }
}
