import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/exception_mapping.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/match_phase.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/infrastructure/models/tip_model.dart';

class TipRepositoryImpl implements TipRepository {
  final FirebaseFirestore firebaseFirestore;
  final AuthRepository authRepository;
  TipRepositoryImpl({
    required this.firebaseFirestore,
    required this.authRepository,
  });

  CollectionReference get usersCollection =>
      firebaseFirestore.collection('users');

  CollectionReference get tipsCollection =>
      firebaseFirestore.collection('tips');

  @override
  Future<Either<TipFailure, Unit>> create(Tip tip) async {
    try {
      final tipModel = TipModel.fromDomain(tip);
      await tipsCollection.doc(tipModel.id).set(tipModel.toMap());
      return right(unit);
    } catch (e) {
      return left(mapFirebaseError<TipFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedFailure(),
        notFound: NotFoundFailure(),
      ));
    }
  }

  @override
  Stream<Either<TipFailure, List<Tip>>> watchUserTips(String userId) async* {
    yield* tipsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map<Either<TipFailure, List<Tip>>>((snapshot) {
      try {
        final userTips = snapshot.docs
            .map((doc) => TipModel.fromFirestore(doc).toDomain())
            .toList();
        return right<TipFailure, List<Tip>>(userTips);
      } catch (e) {
        return left<TipFailure, List<Tip>>(
          mapFirebaseError<TipFailure>(
            e,
            insufficientPermissions: InsufficientPermisssons(),
            unexpected: UnexpectedFailure(),
            notFound: NotFoundFailure(),
          ),
        );
      }
    }).handleError((e) {
      return left<TipFailure, List<Tip>>(
        mapFirebaseError<TipFailure>(
          e,
          insufficientPermissions: InsufficientPermisssons(),
          unexpected: UnexpectedFailure(),
          notFound: NotFoundFailure(),
        ),
      );
    });
  }

  @override
  Stream<Either<TipFailure, Map<String, List<Tip>>>> watchAll() async* {
    yield* tipsCollection
        .snapshots()
        .map<Either<TipFailure, Map<String, List<Tip>>>>((snapshot) {
      try {
        final userTipsMap = <String, List<Tip>>{};
        for (var doc in snapshot.docs) {
          final tip = TipModel.fromFirestore(doc).toDomain();
          final userId = tip.userId.toString();
          userTipsMap.putIfAbsent(userId, () => []);
          userTipsMap[userId]!.add(tip);
        }
        return right<TipFailure, Map<String, List<Tip>>>(userTipsMap);
      } catch (e) {
        return left<TipFailure, Map<String, List<Tip>>>(
          mapFirebaseError<TipFailure>(
            e,
            insufficientPermissions: InsufficientPermisssons(),
            unexpected: UnexpectedFailure(),
            notFound: NotFoundFailure(),
          ),
        );
      }
    }).handleError((e) {
      return left<TipFailure, Map<String, List<Tip>>>(
        mapFirebaseError<TipFailure>(
          e,
          insufficientPermissions: InsufficientPermisssons(),
          unexpected: UnexpectedFailure(),
          notFound: NotFoundFailure(),
        ),
      );
    });
  }

  @override
  Future<Either<TipFailure, int>> getJokersUsedInMatchDay({
    required String userId,
    required int matchDay,
  }) async {
    try {
      // ✅ Bestimme die Phase und alle zugehörigen matchDays
      final phase = MatchPhase.fromMatchDay(matchDay);
      final matchDaysInPhase = phase.getMatchDaysForPhase();

      // Hole alle Tips des Users mit Joker
      final querySnapshot = await tipsCollection
          .where('userId', isEqualTo: userId)
          .where('joker', isEqualTo: true)
          .get();

      // Zähle Joker in ALLEN matchDays dieser Phase
      int jokerCount = 0;
      for (final doc in querySnapshot.docs) {
        final tipData = doc.data() as Map<String, dynamic>;
        final tipMatchId = tipData['matchId'] as String?;

        if (tipMatchId != null) {
          final matchDoc = await firebaseFirestore
              .collection('matches')
              .doc(tipMatchId)
              .get();

          if (matchDoc.exists) {
            final matchData = matchDoc.data() as Map<String, dynamic>;
            final docMatchDay = matchData['matchDay'] as int?;

            // ✅ Prüfe ob matchDay in dieser Phase ist
            if (docMatchDay != null && matchDaysInPhase.contains(docMatchDay)) {
              jokerCount++;
            }
          }
        }
      }

      return right(jokerCount);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<TipFailure, bool>> canUseJokerInMatchDay({
    required String userId,
    required int matchDay,
  }) async {
    final phase = MatchPhase.fromMatchDay(matchDay);
    final maxJokersForMatchDay = phase.maxJokers;

    final result = await getJokersUsedInMatchDay(
      userId: userId,
      matchDay: matchDay,
    );

    return result.fold(
      (failure) => left(failure),
      (usedJokers) => right(usedJokers < maxJokersForMatchDay),
    );
  }

  @override
  Future<Either<TipFailure, List<Tip>>> getTipsForMatch(String matchId) async {
    try {
      final querySnapshot = await tipsCollection
          .where('matchId', isEqualTo: matchId)
          .get();

      final tips = querySnapshot.docs
          .map((doc) => TipModel.fromFirestore(doc).toDomain())
          .toList();

      return right(tips);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<TipFailure, List<Tip>>> getTipsByUserId(String userId) async {
    try {
      final querySnapshot = await tipsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final tips = querySnapshot.docs
          .map((doc) => TipModel.fromFirestore(doc).toDomain())
          .toList();

      return right(tips);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<TipFailure, Unit>> updatePoints({
    required String tipId,
    required int points,
  }) async {
    try {
      await tipsCollection.doc(tipId).update({'points': points});
      return right(unit);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<TipFailure, int>> getTippedGamesInMatchDay({
    required String userId,
    required int matchDay,
  }) async {
    try {
      // First, get all tips for the user that are not null on at least one field.
      // Firestore does not allow multiple inequality filters.
      final querySnapshot = await tipsCollection
          .where('userId', isEqualTo: userId)
          .where('tipHome', isNull: false)
          .get();

      int tippedGamesCount = 0;
      // Iterate through the tips and check the matchDay for each one
      for (final doc in querySnapshot.docs) {
        final tipData = doc.data() as Map<String, dynamic>;

        // Perform the second part of the check on the client side.
        if (tipData['tipGuest'] == null) {
          continue;
        }

        final tipMatchId = tipData['matchId'] as String?;

        if (tipMatchId != null) {
          final matchDoc = await firebaseFirestore
              .collection('matches')
              .doc(tipMatchId)
              .get();

          if (matchDoc.exists) {
            final matchData = matchDoc.data() as Map<String, dynamic>;
            final docMatchDay = matchData['matchDay'] as int?;

            if (docMatchDay == matchDay) {
              tippedGamesCount++;
            }
          }
        }
      }
      return right(tippedGamesCount);
    } on FirebaseException catch (e) {
      if (e.code.contains('permission-denied')) {
        return left(InsufficientPermisssons());
      } else {
        return left(UnexpectedFailure());
      }
    } catch (e) {
      return left(UnexpectedFailure(message: e.toString()));
    }
  }
}
