// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
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

  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  final CollectionReference tipsCollection =
      FirebaseFirestore.instance.collection("tips");

  @override
  Future<Either<TipFailure, Unit>> create(Tip tip) async {
    try {
      final tipModel = TipModel.fromDomain(tip);

      await tipsCollection.doc(tipModel.id).set(tipModel.toMap());
      return right(unit);
    } catch (e) {
      return left(UnexpectedFailure());
    }
  }

  @override
  Stream<Either<TipFailure, List<Tip>>> watchUserTips(String userId) async* {
    try {
      yield* tipsCollection.where('userId', isEqualTo: userId).snapshots().map(
        (snapshot) {
          final userTips = snapshot.docs.map((doc) {
            return TipModel.fromFirestore(doc).toDomain();
          }).toList();
          return right<TipFailure, List<Tip>>(userTips);
        },
      ).handleError((e) {
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
    } catch (e) {
      yield left(UnexpectedFailure());
    }
  }

  @override
  Stream<Either<TipFailure, Map<String, List<Tip>>>> watchAll() async* {
    try {
      yield* tipsCollection.snapshots().map(
        (snapshot) {
          final userTipsMap = <String, List<Tip>>{};
          for (var doc in snapshot.docs) {
            final tip = TipModel.fromFirestore(doc).toDomain();
            final userId = tip.userId.toString();
            if (!userTipsMap.containsKey(userId)) {
              userTipsMap[userId] = [];
            }
            userTipsMap[userId]!.add(tip);
          }
          return right<TipFailure, Map<String, List<Tip>>>(userTipsMap);
        },
      ).handleError((e) {
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
    } catch (e) {
      yield left(UnexpectedFailure());
    }
  }
}
