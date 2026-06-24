import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:faker/faker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/core/failures/exception_mapping.dart';
import 'package:flutter_web/core/utils/firestore_logger.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:flutter_web/infrastructure/models/user_model.dart';
import 'package:rxdart/rxdart.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;

  // ✅ BehaviorSubject - cached letzten Wert für späte Listener
  BehaviorSubject<Either<AuthFailure, List<AppUser>>>? _usersSubject;
  StreamSubscription? _usersSub;
  int _streamEventCount = 0;

  AuthRepositoryImpl(
      {required this.firebaseAuth, required this.firebaseFirestore});

  CollectionReference get usersCollection =>
      firebaseFirestore.collection('users');

  @override
  Future<Either<AuthFailure, Unit>> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? username,
    bool admin = false,
  }) async {
    try {
      // Firebase Auth User erstellen
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Firebase Auth UID als Document-ID verwenden
      final authUid = userCredential.user!.uid;

      // Benutzername: übergeben oder zufällig generieren
      final faker = Faker();
      final String finalUsername = username ?? faker.internet.userName();

      final userModel = UserModel(
        id: authUid, // Firebase Auth UID als ID
        championId: 'TBD',
        name: finalUsername,
        email: email,
        rank: 0,
        score: 0,
        jokerSum: 0,
        sixer: 0,
        admin: admin,
      );

      // Speichere mit Firebase Auth UID als Document-ID
      await usersCollection.doc(authUid).set(userModel.toMap());

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
        notFound: UserNotFoundFailure(
            message: "Benutzer mit dieser E-Mail wurde nicht gefunden"),
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
        notFound: UserNotFoundFailure(
            message: "Benutzer mit dieser E-Mail wurde nicht gefunden"),
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
      FirestoreLogger.logRead('users', 'getSignedInUser', docId: user.uid);
      debugPrint('📥 [AuthRepository] getSignedInUser: ${user.uid}');
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
        notFound: UserNotFoundFailure(
            message: "Benutzer mit dieser E-Mail wurde nicht gefunden"),
      ));
    }
  }

  @override
  Stream<Either<AuthFailure, List<AppUser>>> watchAllUsers() {
    // ✅ BehaviorSubject - cached letzten Wert, späte Listener bekommen sofort Daten
    if (_usersSubject != null) {
      debugPrint(
          '♻️ [AuthRepository] watchAllUsers - Returning existing BehaviorSubject stream');
      return _usersSubject!.stream;
    }

    debugPrint('🎯 [AuthRepository] watchAllUsers STREAM STARTED (SINGLETON)');
    FirestoreLogger.logRead('users', 'watchAllUsers (STREAM)');

    _usersSubject = BehaviorSubject<Either<AuthFailure, List<AppUser>>>();

    _usersSub = usersCollection.snapshots().listen(
      (snapshot) {
        _streamEventCount++;
        FirestoreLogger.logRead(
            'users', 'watchAllUsers (EVENT #$_streamEventCount)',
            docId: '[${snapshot.docs.length} docs]');
        debugPrint(
            '📥 [AuthRepository] watchAllUsers EVENT #$_streamEventCount: ${snapshot.docs.length} users');
        try {
          final users = snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc).toDomain())
              .toList();
          _usersSubject!.add(right<AuthFailure, List<AppUser>>(users));
        } catch (e) {
          _usersSubject!.add(left<AuthFailure, List<AppUser>>(
            mapFirebaseError<AuthFailure>(
              e,
              insufficientPermissions: InsufficientPermisssons(),
              unexpected: UnexpectedAuthFailure(),
              notFound: UserNotFoundFailure(
                  message: "Benutzer mit dieser E-Mail wurde nicht gefunden"),
            ),
          ));
        }
      },
      onError: (e) {
        _usersSubject!.add(left<AuthFailure, List<AppUser>>(
          mapFirebaseError<AuthFailure>(
            e,
            insufficientPermissions: InsufficientPermisssons(),
            unexpected: UnexpectedAuthFailure(),
            notFound: UserNotFoundFailure(
                message: "Benutzer mit dieser E-Mail wurde nicht gefunden"),
          ),
        ));
      },
    );

    return _usersSubject!.stream;
  }

  @override
  Future<Either<AuthFailure, Unit>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        return left(UserNotFoundFailure(
            message: "Benutzer mit dieser E-Mail wurde nicht gefunden"));
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
        return left(
            InvalidCredential(message: "Ungültiges aktuelles Passwort"));
      }
      return left(ServerFailure());
    } catch (e) {
      return left(mapFirebaseError<AuthFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedAuthFailure(),
        notFound: UserNotFoundFailure(
            message: "Benutzer mit dieser E-Mail wurde nicht gefunden"),
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
        return left(UserNotFoundFailure(
            message: "Benutzer mit dieser E-Mail wurde nicht gefunden"));
      } else if (e.code == "invalid-email") {
        return left(
            InvalidEmailFailure(message: "Die angegebene E-Mail ist ungültig"));
      }
      return left(ServerFailure());
    } catch (e) {
      return left(mapFirebaseError<AuthFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedAuthFailure(),
        notFound: UserNotFoundFailure(
            message: "Benutzer mit dieser E-Mail wurde nicht gefunden"),
      ));
    }
  }

  Future<Either<AuthFailure, List<AppUser>>> getAllUsers() async {
    try {
      FirestoreLogger.logRead('users', 'getAllUsers');
      debugPrint('📥 [AuthRepository] getAllUsers called');
      final snapshot = await usersCollection.get();
      FirestoreLogger.logRead('users', 'getAllUsers (RESULT)',
          docId: '[${snapshot.docs.length} docs]');
      debugPrint(
          '✅ [AuthRepository] getAllUsers: ${snapshot.docs.length} users');
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc).toDomain())
          .toList();
      return right(users);
    } catch (e) {
      return left(mapFirebaseError<AuthFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedAuthFailure(),
        notFound: UserNotFoundFailure(
            message: "Benutzer konnten nicht geladen werden"),
      ));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> updateOwnEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        return left(UserNotFoundFailure(message: "Kein Benutzer eingeloggt"));
      }

      debugPrint('📧 [AuthRepository] Updating own email...');
      debugPrint('   Current email: ${user.email}');
      debugPrint('   New email: $newEmail');

      // Re-authenticate with current password first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      debugPrint('✅ [AuthRepository] Re-authentication successful');

      // Send verification email to new address and update
      await user.verifyBeforeUpdateEmail(newEmail);
      debugPrint('✅ [AuthRepository] Verification email sent to $newEmail');

      // Update Firestore with new email
      await usersCollection.doc(user.uid).update({'email': newEmail});
      debugPrint('✅ [AuthRepository] Firestore email updated');

      return right(unit);
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthRepository] FirebaseAuthException: ${e.code}');
      if (e.code == "wrong-password" || e.code == "invalid-credential") {
        return left(InvalidCredential(message: "Falsches Passwort"));
      } else if (e.code == "email-already-in-use") {
        return left(EmailAlreadyInUseFailure());
      } else if (e.code == "invalid-email") {
        return left(InvalidEmailFailure(message: "Ungültige E-Mail-Adresse"));
      } else if (e.code == "requires-recent-login") {
        return left(InsufficientPermisssons());
      }
      return left(ServerFailure());
    } catch (e) {
      debugPrint('❌ [AuthRepository] Unexpected error: $e');
      return left(mapFirebaseError<AuthFailure>(
        e,
        insufficientPermissions: InsufficientPermisssons(),
        unexpected: UnexpectedAuthFailure(),
        notFound: UserNotFoundFailure(message: "Benutzer nicht gefunden"),
      ));
    }
  }
}
