import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/user.dart';

abstract class UserRepository {
  /// Gibt einen User anhand seiner ID zurück
  Future<Either<TipFailure, AppUser>> getUserById(String userId);

  /// Gibt alle User zurück
  Future<Either<TipFailure, List<AppUser>>> getAllUsers();

  /// Aktualisiert einen User
  Future<Either<TipFailure, Unit>> updateUser(AppUser user);

  /// ✅ NEU: Batch-Update für mehrere User in EINEM Firestore-Write
  /// Reduziert 300+ Events auf 1 Event
  Future<Either<TipFailure, Unit>> batchUpdateUsers(List<AppUser> users);

  /// Beobachtet einen User anhand seiner ID
  Stream<Either<TipFailure, AppUser>> watchUserById(String userId);
}
