import 'package:cloud_firestore/cloud_firestore.dart';

extension DocumentReferenceExt on DocumentReference {
  CollectionReference<Map<String, dynamic>> get teamCollection =>
      collection("team");
}
