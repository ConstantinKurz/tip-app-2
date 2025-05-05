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
  Future<void> signOut() => Future.wait([
        firebaseAuth.signOut(),
      ]);

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
  Stream<Either<AuthFailure, List<AppUser>>> watchAllUsers() async* {
    try {
      print("===============watchAllUsers()====================");
      try {
        final snapshots = usersCollection.snapshots();
        snapshots.listen((value) => print("Value received:" + value.toString()),
            onError: (error) => print("Stream error" + error.toString()));

        print("watchAllUsers: snapshots() called, stream obtained"); // Add this
      } catch (e) {
        print("watchAllUsers: Outer catch error: $e"); // Catch any outer errors
        yield left(UnexpectedFailure()); // Make sure to yield an error
      }
    } catch (e) {
      print("Initial exception caught" + e.toString());

      yield Left(UnexpectedFailure());
    }
    try {
      print("watchAllUsers: Stream started");
      try {
        final snapshots = usersCollection.snapshots();
        print("watchAllUsers: snapshots() called, stream obtained"); // Add this
        yield* snapshots.map((snapshot) {
          print("watchAllUsers: Snapshot received"); // Debugging
          print(
              "watchAllUsers: Number of documents: ${snapshot.docs.length}"); // Debugging

          for (var doc in snapshot.docs) {
            print("watchAllUsers: Document data: ${doc.data()}"); // Debugging
          }

          final users = snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc).toDomain())
              .toList();
          print("watchAllUsers: Users list: $users"); // Debugging
          return right<AuthFailure, List<AppUser>>(users);
        }).handleError((e) {
          print("watchAllUsers: Error occurred: $e"); // Debugging
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
        print("watchAllUsers: Outer catch error: $e"); // Catch any outer errors
        yield left(UnexpectedFailure()); // Make sure to yield an error
      }
    } catch (e) {
      print("Initial exception caught" + e.toString());
      yield Left(UnexpectedFailure());
    }
  }
}
