import 'package:dartz/dartz.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';

abstract class AuthRepository {
  Future<Either<AuthFailure, Unit>> registerWithEmailAndPassword(
      {required String email, required String password});

  Future<Either<AuthFailure, Unit>> signInWithEmailAndPassword(
      {required String email, required String password});

  Future<void> signOut();

  Future<Option<AppUser>> getSignedInUser();

  Stream<Either<AuthFailure, List<AppUser>>> watchAllUsers();
}
