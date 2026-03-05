import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/exception_mapping.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/core/utils/firestore_logger.dart';
import 'package:flutter_web/domain/entities/match_phase.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/infrastructure/models/tip_model.dart';
import 'package:rxdart/rxdart.dart';

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
    print('🎯 [TipRepository] watchUserTips STREAM STARTED for user: $userId');
    FirestoreLogger.logRead('tips', 'watchUserTips (STREAM)', docId: userId);
    
    int eventCount = 0;
    
    yield* tipsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        // .throttleTime(const Duration(milliseconds: 300), trailing: true)
        .map<Either<TipFailure, List<Tip>>>((snapshot) {
      eventCount++;
      FirestoreLogger.logRead('tips', 'watchUserTips (EVENT #$eventCount)', docId: '$userId [${snapshot.docs.length} docs]');
      print('📥 [TipRepository] watchUserTips EVENT #$eventCount: ${snapshot.docs.length} tips for $userId');
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
  Stream<Either<TipFailure, List<Tip>>> watchTipsForMatch(String matchId) async* {
    yield* tipsCollection
        .where('matchId', isEqualTo: matchId)
        .snapshots()
        .map<Either<TipFailure, List<Tip>>>((snapshot) {
      try {
        final matchTips = snapshot.docs
            .map((doc) => TipModel.fromFirestore(doc).toDomain())
            .toList();
        return right<TipFailure, List<Tip>>(matchTips);
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
    print('🎯 [TipRepository] watchAll STREAM STARTED');
    FirestoreLogger.logRead('tips', 'watchAll (STREAM)');
    
    int eventCount = 0;
    
    yield* tipsCollection
        .snapshots()
        // .throttleTime(const Duration(milliseconds: 300), trailing: true)
        .map<Either<TipFailure, Map<String, List<Tip>>>>((snapshot) {
      eventCount++;
      FirestoreLogger.logRead('tips', 'watchAll (EVENT #$eventCount)', docId: '[${snapshot.docs.length} docs]');
      print('📥 [TipRepository] watchAll EVENT #$eventCount: ${snapshot.docs.length} tips total');
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
    FirestoreLogger.logRead('tips', 'getJokersUsedInMatchDay', docId: 'user=$userId, matchDay=$matchDay');
    print('🃏 [TipRepository] getJokersUsedInMatchDay: user=$userId, matchDay=$matchDay');
    
    try {
      // ✅ Bestimme die Phase und alle zugehörigen matchDays
      final phase = MatchPhase.fromMatchDay(matchDay);
      final matchDaysInPhase = phase.getMatchDaysForPhase();

      // Hole alle Tips des Users mit Joker
      final querySnapshot = await tipsCollection
          .where('userId', isEqualTo: userId)
          .where('joker', isEqualTo: true)
          .get();

      //Sammle alle matchIds und lade in einem Batch
      final matchIds = <String>[];
      for (final doc in querySnapshot.docs) {
        final tipData = doc.data() as Map<String, dynamic>;
        final tipMatchId = tipData['matchId'] as String?;
        if (tipMatchId != null) {
          matchIds.add(tipMatchId);
        }
      }

      if (matchIds.isEmpty) {
        return right(0);
      }

      // ✅ Lade alle Matches in Batches (Firestore limit: 10 per whereIn)
      final matchDayMap = await _loadMatchDaysForMatchIds(matchIds);

      // Zähle Joker in ALLEN matchDays dieser Phase
      int jokerCount = 0;
      for (final matchId in matchIds) {
        final docMatchDay = matchDayMap[matchId];
        if (docMatchDay != null && matchDaysInPhase.contains(docMatchDay)) {
          jokerCount++;
        }
      }

      return right(jokerCount);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  /// ✅ Hilfsmethode: Lädt matchDays für mehrere matchIds in Batches
  Future<Map<String, int>> _loadMatchDaysForMatchIds(List<String> matchIds) async {
    final result = <String, int>{};
    
    // Firestore erlaubt max 10 Elemente pro whereIn Query
    for (var i = 0; i < matchIds.length; i += 10) {
      final batch = matchIds.sublist(i, i + 10 > matchIds.length ? matchIds.length : i + 10);
      
      final querySnapshot = await firebaseFirestore
          .collection('matches')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      
      for (final doc in querySnapshot.docs) {
        final matchData = doc.data();
        final docMatchDay = matchData['matchDay'] as int?;
        if (docMatchDay != null) {
          result[doc.id] = docMatchDay;
        }
      }
    }
    
    return result;
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
    FirestoreLogger.logRead('tips', 'getTippedGamesInMatchDay', docId: 'user=$userId, matchDay=$matchDay');
    print('🎮 [TipRepository] getTippedGamesInMatchDay: user=$userId, matchDay=$matchDay');
    
    try {
      // First, get all tips for the user that are not null on at least one field.
      // Firestore does not allow multiple inequality filters.
      final querySnapshot = await tipsCollection
          .where('userId', isEqualTo: userId)
          .where('tipHome', isNull: false)
          .get();

      // ✅ OPTIMIERT: Sammle alle matchIds und filtere bei gültigen Tips
      final matchIdsWithValidTips = <String>[];
      for (final doc in querySnapshot.docs) {
        final tipData = doc.data() as Map<String, dynamic>;

        // Perform the second part of the check on the client side.
        if (tipData['tipGuest'] == null) {
          continue;
        }

        final tipMatchId = tipData['matchId'] as String?;
        if (tipMatchId != null) {
          matchIdsWithValidTips.add(tipMatchId);
        }
      }

      if (matchIdsWithValidTips.isEmpty) {
        return right(0);
      }

      // ✅ Lade alle Matches in Batches
      final matchDayMap = await _loadMatchDaysForMatchIds(matchIdsWithValidTips);

      // Zähle nur Tips für den angegebenen matchDay
      int tippedGamesCount = 0;
      for (final matchId in matchIdsWithValidTips) {
        final docMatchDay = matchDayMap[matchId];
        if (docMatchDay == matchDay) {
          tippedGamesCount++;
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

  @override
  Future<Either<TipFailure, int>> getJokersUsedInMatchDays({
    required String userId,
    required List<int> matchDays,
  }) async {
    try {
      final querySnapshot = await tipsCollection
          .where('userId', isEqualTo: userId)
          .where('joker', isEqualTo: true)
          .get();

      // ✅ OPTIMIERT: Sammle alle matchIds
      final matchIds = <String>[];
      for (final doc in querySnapshot.docs) {
        final tipData = doc.data() as Map<String, dynamic>;
        final tipMatchId = tipData['matchId'] as String?;
        if (tipMatchId != null) {
          matchIds.add(tipMatchId);
        }
      }

      if (matchIds.isEmpty) {
        return right(0);
      }

      // ✅ Lade alle Matches in Batches
      final matchDayMap = await _loadMatchDaysForMatchIds(matchIds);

      // Zähle wenn matchDay in der Liste ist
      int jokerCount = 0;
      for (final matchId in matchIds) {
        final docMatchDay = matchDayMap[matchId];
        if (docMatchDay != null && matchDays.contains(docMatchDay)) {
          jokerCount++;
        }
      }

      return right(jokerCount);
    } catch (e) {
      return left(UnexpectedFailure(message: e.toString()));
    }
  }
}
