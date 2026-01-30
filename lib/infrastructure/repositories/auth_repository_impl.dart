import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:faker/faker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/core/failures/exception_mapping.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:flutter_web/infrastructure/models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;

  AuthRepositoryImpl({required this.firebaseAuth, required this.firebaseFirestore});

  CollectionReference get usersCollection => firebaseFirestore.collection('users');

  @override
  Future<Either<AuthFailure, Unit>> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      await firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Benutzername: übergeben oder zufällig generieren
      final faker = Faker();
      final String finalUsername = username ?? faker.internet.userName();

      final userModel = UserModel.empty(finalUsername, email);
      await usersCollection.doc(finalUsername).set(userModel.toMap());

      return right(unit);
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        return left(EmailAlreadyInUseFailure());
      }
      return left(ServerFailure());
    } catch (e) {
      return left(mapFirebaseError<AuthFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: ServerFailure(),
        notFound: UserNotFoundFailure(message: "Benutzer mit dieser E-Mail wurde nicht gefunden"),
      ));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
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
    } catch (e) {
      return left(mapFirebaseError<AuthFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: ServerFailure(),
        notFound: UserNotFoundFailure(message: "Benutzer mit dieser E-Mail wurde nicht gefunden"),
      ));
    }
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<Option<AppUser>> getSignedInUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      return none();
    } else {
      final userDoc = await usersCollection.doc(user.uid).get();
      if (userDoc.exists) {
        return some(UserModel.fromFirestore(userDoc).toDomain());
      } else {
        return none();
      }
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> updateUser({required AppUser user}) async {
    try {
      final userModel = UserModel.fromDomain(user);
      await usersCollection.doc(user.id).update(userModel.toMap());
      return right(unit);
    } catch (e) {
      return left(mapFirebaseError<AuthFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedAuthFailure(),
        notFound: UserNotFoundFailure(message: "Benutzer mit dieser E-Mail wurde nicht gefunden"),
      ));
    }
  }

  @override
  Stream<Either<AuthFailure, List<AppUser>>> watchAllUsers() async* {
    yield* usersCollection.orderBy('rank').snapshots()
        .map<Either<AuthFailure, List<AppUser>>>((snapshot) {
      try {
        final users = snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc).toDomain())
            .toList();
        return right<AuthFailure, List<AppUser>>(users);
      } catch (e) {
        return left<AuthFailure, List<AppUser>>(
          mapFirebaseError<AuthFailure>(
            e,
            insufficientPermissions: InsufficientPermisssons(),
            unexpected: UnexpectedAuthFailure(),
            notFound: UserNotFoundFailure(message: "Benutzer mit dieser E-Mail wurde nicht gefunden"),
          ),
        );
      }
    }).handleError((e) {
      return left<AuthFailure, List<AppUser>>(
        mapFirebaseError<AuthFailure>(
          e,
          insufficientPermissions: InsufficientPermisssons(),
          unexpected: UnexpectedAuthFailure(),
          notFound: UserNotFoundFailure(message: "Benutzer mit dieser E-Mail wurde nicht gefunden"),
        ),
      );
    });
  }

  @override
  Future<Either<AuthFailure, Unit>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        return left(UserNotFoundFailure(message: "Benutzer mit dieser E-Mail wurde nicht gefunden"));
      }

      // Re-authentifizierung mit dem aktuellen Passwort
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      
      // Neues Passwort setzen
      await user.updatePassword(newPassword);
      
      return right(unit);
    } on FirebaseAuthException catch (e) {
      if (e.code == "wrong-password") {
        return left(InvalidEmailAndPasswordCombinationFailure());
      } else if (e.code == "weak-password") {
        return left(ServerFailure());
      } else if (e.code == "requires-recent-login") {
        return left(InsufficientPermisssons());
      } else if (e.code == "invalid-credential") {
        return left(InvalidCredential(message: "Ungültiges aktuelles Passwort"));
      }
      return left(ServerFailure());
    } catch (e) {
      return left(mapFirebaseError<AuthFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedAuthFailure(),
        notFound: UserNotFoundFailure(message: "Benutzer mit dieser E-Mail wurde nicht gefunden"),
      ));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return right(unit);
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        return left(UserNotFoundFailure(message: "Benutzer mit dieser E-Mail wurde nicht gefunden"));
      } else if (e.code == "invalid-email") {
        return left(InvalidEmailFailure(message: "Die angegebene E-Mail ist ungültig"));
      }
      return left(ServerFailure());
    } catch (e) {
      return left(mapFirebaseError<AuthFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedAuthFailure(),
        notFound: UserNotFoundFailure(message: "Benutzer mit dieser E-Mail wurde nicht gefunden"),
      ));
    }
  }

  @override
  Future<Either<AuthFailure, List<AppUser>>> getAllUsers() async {
    try {
      final snapshot = await usersCollection.get();
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc).toDomain())
          .toList();
      return right(users);
    } catch (e) {
      return left(mapFirebaseError<AuthFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedAuthFailure(),
        notFound: UserNotFoundFailure(message: "Benutzer konnten nicht geladen werden"),
      ));
    }
  }
}
