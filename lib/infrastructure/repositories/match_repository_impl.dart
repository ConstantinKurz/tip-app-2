import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/exception_mapping.dart';
import 'package:flutter_web/core/failures/match_failures.dart';
import 'package:flutter_web/core/utils/firestore_logger.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/infrastructure/models/match_model.dart';
import 'package:rxdart/rxdart.dart';

class MatchRepositoryImpl implements MatchRepository {
  final FirebaseFirestore firebaseFirestore;

  // ✅ BehaviorSubject - cached letzten Wert für späte Listener
  BehaviorSubject<Either<MatchFailure, List<CustomMatch>>>? _matchesSubject;
  StreamSubscription? _matchesSub;
  int _streamEventCount = 0;

  MatchRepositoryImpl({required this.firebaseFirestore});

  CollectionReference get matchesCollection =>
      firebaseFirestore.collection('matches');

  @override
  Stream<Either<MatchFailure, List<CustomMatch>>> watchAllMatches() {
    // ✅ BehaviorSubject - cached letzten Wert, späte Listener bekommen sofort Daten
    if (_matchesSubject != null) {
      debugPrint(
          '♻️ [MatchRepository] watchAllMatches - Returning existing BehaviorSubject stream');
      return _matchesSubject!.stream;
    }

    debugPrint(
        '🎯 [MatchRepository] watchAllMatches STREAM STARTED (SINGLETON)');
    FirestoreLogger.logRead('matches', 'watchAllMatches (STREAM)');

    _matchesSubject =
        BehaviorSubject<Either<MatchFailure, List<CustomMatch>>>();

    _matchesSub = matchesCollection.orderBy('matchDate').snapshots().listen(
      (snapshot) {
        _streamEventCount++;
        FirestoreLogger.logRead(
            'matches', 'watchAllMatches (EVENT #$_streamEventCount)',
            docId: '[${snapshot.docs.length} docs]');
        debugPrint(
            '📥 [MatchRepository] watchAllMatches EVENT #$_streamEventCount: ${snapshot.docs.length} matches');
        try {
          final matches = snapshot.docs
              .map((doc) => MatchModel.fromFirestore(doc).toDomain())
              .toList();
          _matchesSubject!.add(right<MatchFailure, List<CustomMatch>>(matches));
        } catch (e) {
          // ✅ FIX: Bei InsufficientPermissions NICHT den Fehler cachen
          final error = mapFirebaseError<MatchFailure>(
            e,
            insufficientPermissions: InsufficientPermisssons(),
            unexpected: UnexpectedFailure(),
            notFound: NotFoundFailure(),
          );
          if (error is InsufficientPermisssons) {
            debugPrint('⏳ [MatchRepository] InsufficientPermissions in snapshot - waiting for auth token...');
            return; // Nicht emittieren, einfach warten
          }
          _matchesSubject!.add(left<MatchFailure, List<CustomMatch>>(error));
        }
      },
      onError: (e) {
        // ✅ FIX: Bei InsufficientPermissions NICHT den Fehler cachen
        final error = mapFirebaseError<MatchFailure>(
          e,
          insufficientPermissions: InsufficientPermisssons(),
          unexpected: UnexpectedFailure(),
          notFound: NotFoundFailure(),
        );
        if (error is InsufficientPermisssons) {
          debugPrint('⏳ [MatchRepository] InsufficientPermissions onError - waiting for auth token...');
          return; // Nicht emittieren, einfach warten
        }
        _matchesSubject!.add(left<MatchFailure, List<CustomMatch>>(error));
      },
    );

    return _matchesSubject!.stream;
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
      debugPrint('📥 [MatchRepository] getAllMatches called');
      final snapshot = await matchesCollection.get();
      FirestoreLogger.logRead('matches', 'getAllMatches (RESULT)',
          docId: '[${snapshot.docs.length} docs]');
      debugPrint(
          '✅ [MatchRepository] getAllMatches: ${snapshot.docs.length} matches');
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
      debugPrint('Matchday wird an Firestore gesendet: ${matchModel.toMap()}');
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
      debugPrint('📥 [MatchRepository] getMatchById: $matchId');
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
