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
      {required String email,
      required String password,
      String? username}) async {
    try {
      await firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      // Use provided username if available, otherwise generate a random one
      final faker = Faker();
      final String finalUsername = username ?? faker.internet.userName();

      // Create user document in Firestore
      final userModel = UserModel.empty(finalUsername, email);

      await usersCollection.doc(finalUsername).set(userModel.toMap());

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
  Future<void> signOut() async {
    firebaseAuth.signOut();
  }

  @override
  Future<Option<AppUser>> getSignedInUser() async {
    final user = firebaseAuth.currentUser;
    print("Signed in user  $user");
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
  Future<Either<AuthFailure, Unit>> updateUser({required AppUser user}) async {
    try {
      // Firestore-Dokument aktualisieren
      final userModel = UserModel.fromDomain(user);
      await usersCollection.doc(user.username).update(userModel.toMap());

      return right(unit);
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code.contains('permission-denied') ||
            e.code.contains("PERMISSION_DENIED")) {
          return left(InsufficientPermisssons());
        } else {
          return left(UnexpectedFailure());
        }
      } else {
        (print("Update User: Outer catch error: $e"));
        return left(UnexpectedFailure());
      }
    }
  }

  @override
  Stream<Either<AuthFailure, List<AppUser>>> watchAllUsers() async* {
    try {
      print("watchAllUsers: Stream started");
      try {
        final snapshots = usersCollection.snapshots();
        print("watchAllUsers: snapshots() called, stream obtained"); 
        yield* snapshots.map((snapshot) {
          print("watchAllUsers: Snapshot received");
          print(
              "watchAllUsers: Number of documents: ${snapshot.docs.length}"); 

          for (var doc in snapshot.docs) {
            print("watchAllUsers: Document data: ${doc.data()}");
          }

          final users = snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc).toDomain())
              .toList();
          print("watchAllUsers: Users list: $users");
          return right<AuthFailure, List<AppUser>>(users);
        }).handleError((e) {
          print("watchAllUsers: Error occurred: $e");
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
        print("watchAllUsers: Outer catch error: $e");
        yield left(UnexpectedFailure());
      }
    } catch (e) {
      print("Initial exception caught" + e.toString());
      yield Left(UnexpectedFailure());
    }
  }
}
