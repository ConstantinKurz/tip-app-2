import 'package:dartz/dartz.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';

abstract class AuthRepository {
  Future<Either<AuthFailure, Unit>> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? username,
    bool admin = false,
  });

  Future<Either<AuthFailure, Unit>> signInWithEmailAndPassword(
      {required String email, required String password});

  Future<void> signOut();

  Future<Either<AuthFailure, Unit>> updateUser({required AppUser user});

  Future<Option<AppUser>> getSignedInUser();

  Stream<Either<AuthFailure, List<AppUser>>> watchAllUsers();

  Future<Either<AuthFailure, Unit>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail({
    required String email,
  });

  /// Resets the users stream (clears cached BehaviorSubject)
  /// Call this before retry to get fresh data from Firestore
  void resetUsersStream();

  /// Updates the current user's own email in Firebase Authentication
  /// Sends a verification email to the new address
  Future<Either<AuthFailure, Unit>> updateOwnEmail({
    required String newEmail,
    required String currentPassword,
  });
}
