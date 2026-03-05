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
      print('📥 [UserRepository] getUserById: $userId');
      final doc = await firebaseFirestore.collection(_collectionPath).doc(userId).get();
      
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
      print('📥 [UserRepository] getAllUsers called');
      final snapshot = await firebaseFirestore.collection(_collectionPath).get();
      FirestoreLogger.logRead('users', 'getAllUsers (RESULT)', docId: '[${snapshot.docs.length} docs]');
      print('✅ [UserRepository] getAllUsers: ${snapshot.docs.length} users');
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

  @override
  Stream<Either<TipFailure, AppUser>> watchUserById(String userId) {
    print('🎯 [UserRepository] watchUserById STREAM STARTED for: $userId');
    FirestoreLogger.logRead('users', 'watchUserById (STREAM)', docId: userId);
    
    int eventCount = 0;
    
    return firebaseFirestore
        .collection(_collectionPath)
        .doc(userId)
        .snapshots()
        .map<Either<TipFailure, AppUser>>((snapshot) {
      eventCount++;
      FirestoreLogger.logRead('users', 'watchUserById (EVENT #$eventCount)', docId: userId);
      print('📥 [UserRepository] watchUserById EVENT #$eventCount: $userId');
      if (!snapshot.exists) {
        return left(ServerFailure(message: 'User not found'));
      }
      final userModel = UserModel.fromJson(snapshot.data() as Map<String, dynamic>);
      return right(userModel.toDomain());
    });
  }
}
