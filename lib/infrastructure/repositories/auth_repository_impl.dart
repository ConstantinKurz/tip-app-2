import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:faker/faker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/infrastructure/models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth firebaseAuth;

  AuthRepositoryImpl({required this.firebaseAuth});

  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  @override
  Future<Either<AuthFailure, Unit>> registerWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      final authResult = await firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      final userId = authResult.user!.uid;

      final faker = Faker();
      String username = faker.internet.userName();
      // Create user document in Firestore
      final userModel = UserModel.empty(userId, username, email);

      await usersCollection.doc(userId).set(userModel.toMap());

      return right(unit);
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        return left(EmailAlreadyInUseFailure());
      }
      return left(ServerFailure());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      await firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      return right(unit);
    } on FirebaseAuthException catch (e) {
      if (e.code == "wrong-password" ||
          e.code == "user-not-found" ||
          e.code == "invalid-credential") {
        return left(InvalidEmailAndPasswordCombinationFailure());
      }
      return left(ServerFailure());
    }
  }

  @override
  Future<void> signOut() => Future.wait([
        firebaseAuth.signOut(),
      ]);

  @override
  Future<Option<AppUser>> getSignedInUser() async {
    final user = firebaseAuth.currentUser;

    if (user == null) {
      return none();
    } else {
      final userDoc = await usersCollection.doc(user.uid).get();
      if (userDoc.exists) {
        final userModel = UserModel.fromFirestore(userDoc);
        return some(userModel.toDomain());
      } else {
        return none();
      }
    }
  }

  @override
  Stream<Either<AuthFailure, List<AppUser>>> watchAllUsers() async* {
    yield* usersCollection
        .snapshots()
        .map((snapshot) => right<AuthFailure, List<AppUser>>(snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc).toDomain())
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
}
