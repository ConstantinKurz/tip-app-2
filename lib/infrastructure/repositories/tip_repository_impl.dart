import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/exception_mapping.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
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

    CollectionReference get usersCollection => firebaseFirestore.collection('users');

    CollectionReference get tipsCollection => firebaseFirestore.collection('tips');

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
}
