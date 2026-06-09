import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> clearDatabaseExceptUser() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;

  const keepUserId = 'XelDzMXLNiR9CrNsTBEUdAF6csm2';

  // --- USERS: Alle außer keepUserId löschen ---
  final usersSnap = await firestore.collection('users').get();
  for (final doc in usersSnap.docs) {
    if (doc.id != keepUserId) {
      await firestore.collection('users').doc(doc.id).delete();
      debugPrint('❌ User gelöscht: ${doc.id}');
    }
  }

  // --- TEAMS löschen ---
  final teamsSnap = await firestore.collection('teams').get();
  for (final doc in teamsSnap.docs) {
    await firestore.collection('teams').doc(doc.id).delete();
    debugPrint('❌ Team gelöscht: ${doc.id}');
  }

  // --- MATCHES löschen ---
  final matchesSnap = await firestore.collection('matches').get();
  for (final doc in matchesSnap.docs) {
    await firestore.collection('matches').doc(doc.id).delete();
    debugPrint('❌ Match gelöscht: ${doc.id}');
  }

  // --- TIPS löschen ---
  final tipsSnap = await firestore.collection('tips').get();
  for (final doc in tipsSnap.docs) {
    await firestore.collection('tips').doc(doc.id).delete();
    debugPrint('❌ Tipp gelöscht: ${doc.id}');
  }

  debugPrint('✅ Datenbank aufgeräumt, User $keepUserId behalten.');
}
