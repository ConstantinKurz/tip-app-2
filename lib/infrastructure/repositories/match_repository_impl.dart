import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/exception_mapping.dart';
import 'package:flutter_web/core/failures/match_failures.dart';
import 'package:flutter_web/core/utils/firestore_logger.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/infrastructure/models/match_model.dart';

class MatchRepositoryImpl implements MatchRepository {
  final FirebaseFirestore firebaseFirestore;
  MatchRepositoryImpl({required this.firebaseFirestore});

  CollectionReference get matchesCollection => firebaseFirestore.collection('matches');

  @override
  Stream<Either<MatchFailure, List<CustomMatch>>> watchAllMatches() async* {
    print('🎯 [MatchRepository] watchAllMatches STREAM STARTED');
    FirestoreLogger.logRead('matches', 'watchAllMatches (STREAM)');
    
    int eventCount = 0;
    
    yield* matchesCollection.orderBy('matchDate').snapshots().map<Either<MatchFailure, List<CustomMatch>>>((snapshot) {
      eventCount++;
      FirestoreLogger.logRead('matches', 'watchAllMatches (EVENT #$eventCount)', docId: '[${snapshot.docs.length} docs]');
      print('📥 [MatchRepository] watchAllMatches EVENT #$eventCount: ${snapshot.docs.length} matches');
      try {
        final matches = snapshot.docs
            .map((doc) => MatchModel.fromFirestore(doc).toDomain())
            .toList();

        return right<MatchFailure, List<CustomMatch>>(matches);
      } catch (e) {
        return left<MatchFailure, List<CustomMatch>>(
          mapFirebaseError<MatchFailure>(
            e,
            insufficientPermissions: InsufficientPermisssons(),
            unexpected: UnexpectedFailure(),
            notFound: NotFoundFailure(),
          ),
        );
      }
    }).handleError((e) {
      return left<MatchFailure, List<CustomMatch>>(
        mapFirebaseError<MatchFailure>(
          e,
          insufficientPermissions: InsufficientPermisssons(),
          unexpected: UnexpectedFailure(),
          notFound: NotFoundFailure(),
        ),
      );
    });
  }

  @override
  Future<Either<MatchFailure, Unit>> createMatch(CustomMatch match) async {
    try {
      final matchModel = MatchModel.fromDomain(match);
      await matchesCollection.doc(matchModel.id).set(matchModel.toMap());
      return right(unit);
    } catch (e) {
      return left(mapFirebaseError<MatchFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedFailure(),
        notFound: NotFoundFailure(),
      ));
    }
  }

  @override
  Future<Either<MatchFailure, Unit>> deleteMatchById(String matchId) async {
    try {
      await matchesCollection.doc(matchId).delete();
      return right(unit);
    } catch (e) {
      return left(mapFirebaseError<MatchFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedFailure(),
        notFound: NotFoundFailure(),
      ));
    }
  }

  @override
  Future<Either<MatchFailure, List<CustomMatch>>> getAllMatches() async {
    try {
      FirestoreLogger.logRead('matches', 'getAllMatches');
      print('📥 [MatchRepository] getAllMatches called');
      final snapshot = await matchesCollection.get();
      FirestoreLogger.logRead('matches', 'getAllMatches (RESULT)', docId: '[${snapshot.docs.length} docs]');
      print('✅ [MatchRepository] getAllMatches: ${snapshot.docs.length} matches');
      final matches = snapshot.docs
          .map((doc) => MatchModel.fromFirestore(doc).toDomain())
          .toList();
      return right(matches);
    } catch (e) {
      return left(mapFirebaseError<MatchFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedFailure(),
        notFound: NotFoundFailure(),
      ));
    }
  }

  @override
  Future<Either<MatchFailure, Unit>> updateMatch(CustomMatch match) async {
    try {
      final matchModel = MatchModel.fromDomain(match);
      print('Matchday wird an Firestore gesendet: ${matchModel.toMap()}');
      await matchesCollection.doc(matchModel.id).update(matchModel.toMap());
      return right(unit);
    } catch (e) {
      return left(mapFirebaseError<MatchFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedFailure(),
        notFound: NotFoundFailure(),
      ));
    }
  }

  @override
  Future<Either<MatchFailure, CustomMatch>> getMatchById(String matchId) async {
    try {
      FirestoreLogger.logRead('matches', 'getMatchById', docId: matchId);
      print('📥 [MatchRepository] getMatchById: $matchId');
      final doc = await matchesCollection.doc(matchId).get();
      if (doc.exists) {
        return right(MatchModel.fromFirestore(doc).toDomain());
      } else {
        return left(NotFoundFailure());
      }
    } catch (e) {
      return left(mapFirebaseError<MatchFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedFailure(),
        notFound: NotFoundFailure(),
      ));
    }
  }
}
