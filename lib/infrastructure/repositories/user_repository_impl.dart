import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/core/utils/firestore_logger.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/domain/repositories/user_repository.dart';
import 'package:flutter_web/infrastructure/models/user_model.dart';

class UserRepositoryImpl extends UserRepository {
  final FirebaseFirestore firebaseFirestore;

  UserRepositoryImpl({required this.firebaseFirestore});

  static const String _collectionPath = 'users';

  @override
  Future<Either<TipFailure, AppUser>> getUserById(String userId) async {
    try {
      FirestoreLogger.logRead('users', 'getUserById', docId: userId);
      debugPrint('📥 [UserRepository] getUserById: $userId');
      final doc =
          await firebaseFirestore.collection(_collectionPath).doc(userId).get();

      if (!doc.exists) {
        return left(ServerFailure(message: 'User not found'));
      }

      final userModel = UserModel.fromJson(doc.data() as Map<String, dynamic>);
      return right(userModel.toDomain());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<TipFailure, List<AppUser>>> getAllUsers() async {
    try {
      FirestoreLogger.logRead('users', 'getAllUsers');
      debugPrint('📥 [UserRepository] getAllUsers called');
      final snapshot =
          await firebaseFirestore.collection(_collectionPath).get();
      FirestoreLogger.logRead('users', 'getAllUsers (RESULT)',
          docId: '[${snapshot.docs.length} docs]');
      debugPrint(
          '✅ [UserRepository] getAllUsers: ${snapshot.docs.length} users');
      final users = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()).toDomain())
          .toList();
      return right(users);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<TipFailure, Unit>> updateUser(AppUser user) async {
    try {
      final userModel = UserModel.fromDomain(user);
      await firebaseFirestore
          .collection(_collectionPath)
          .doc(user.id)
          .update(userModel.toJson());
      return right(unit);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  /// ✅ NEU: Batch-Update für mehrere User in EINEM Firestore-Write
  /// Firestore Batches unterstützen max 500 Operationen pro Batch
  @override
  Future<Either<TipFailure, Unit>> batchUpdateUsers(List<AppUser> users) async {
    if (users.isEmpty) return right(unit);

    try {
      debugPrint(
          '📦 [UserRepository] Batch-Update für ${users.length} User gestartet');

      // Firestore Batches sind auf 500 Operationen begrenzt
      const batchSize = 500;

      for (var i = 0; i < users.length; i += batchSize) {
        final batch = firebaseFirestore.batch();
        final end =
            (i + batchSize < users.length) ? i + batchSize : users.length;

        for (var j = i; j < end; j++) {
          final user = users[j];
          final userModel = UserModel.fromDomain(user);
          final docRef =
              firebaseFirestore.collection(_collectionPath).doc(user.id);
          batch.update(docRef, userModel.toJson());
        }

        await batch.commit();
        debugPrint(
            '✅ [UserRepository] Batch ${(i ~/ batchSize) + 1} committed (${end - i} User)');
      }

      debugPrint(
          '✅ [UserRepository] Batch-Update abgeschlossen: ${users.length} User');
      return right(unit);
    } catch (e) {
      debugPrint('❌ [UserRepository] Batch-Update Fehler: $e');
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<TipFailure, AppUser>> watchUserById(String userId) {
    debugPrint('🎯 [UserRepository] watchUserById STREAM STARTED for: $userId');
    FirestoreLogger.logRead('users', 'watchUserById (STREAM)', docId: userId);

    int eventCount = 0;

    return firebaseFirestore
        .collection(_collectionPath)
        .doc(userId)
        .snapshots()
        .map<Either<TipFailure, AppUser>>((snapshot) {
      eventCount++;
      FirestoreLogger.logRead('users', 'watchUserById (EVENT #$eventCount)',
          docId: userId);
      debugPrint(
          '📥 [UserRepository] watchUserById EVENT #$eventCount: $userId');
      if (!snapshot.exists) {
        return left(ServerFailure(message: 'User not found'));
      }
      final userModel =
          UserModel.fromJson(snapshot.data() as Map<String, dynamic>);
      return right(userModel.toDomain());
    });
  }
}
