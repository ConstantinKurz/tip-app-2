import 'package:cloud_firestore/cloud_firestore.dart';

T mapFirebaseError<T>(
  Object e, {
  required T insufficientPermissions,
  required T unexpected,
  T? notFound,
}) {
  if (e is FirebaseException) {
    final code = e.code.toLowerCase();

    if (code.contains('permission-denied')) {
      return insufficientPermissions;
    }
    if (notFound != null && code.contains('not-found')) {
      return notFound;
    }
    return unexpected;
  }
  return unexpected;
}
