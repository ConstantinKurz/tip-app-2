import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';

Future<void> seedTestDataThreeUsers() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final random = Random();

  // --- Test-User-Konfiguration ---
  final testUsers = [
    {'email': 'user1@test.com', 'password': '123456', 'name': 'User One', 'champion_id': 'ARG'},
    {'email': 'user2@test.com', 'password': '123456', 'name': 'User Two', 'champion_id': 'BRA'},
    {'email': 'user3@test.com', 'password': '123456', 'name': 'User Three', 'champion_id': 'GER'},
  ];

  final userIds = <String>[];

  // --- 1. User in Auth & Firestore anlegen ---
  for (final u in testUsers) {
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: u['email']!,
        password: u['password']!,
      );
      print('✅ Auth-User erstellt: ${u['email']}');
      userIds.add(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final existingUser = await auth.signInWithEmailAndPassword(
          email: u['email']!,
          password: u['password']!,
        );
        userIds.add(existingUser.user!.uid);
        print('ℹ️ User existiert schon: ${u['email']}');
      } else {
        rethrow;
      }
    }
  }

  // --- 2. Firestore-User-Dokumente anlegen ---
  for (var i = 0; i < userIds.length; i++) {
    final uid = userIds[i];
    final u = testUsers[i];
    await firestore.collection('users').doc(uid).set({
      'id': uid,
      'champion_id': u['champion_id'],
      'email': u['email'],
      'name': u['name'],
      'rank': i + 1,
      'score': 0,
      'jokerSum': 0,
      'mixer': 0,
    });
  }

  // --- 3. Zwei Teams ---
  final teamsData = [
    {'id': 'ARG', 'champion': false, 'flag_code': 'AR', 'name': 'Argentinien', 'win_points': 10},
    {'id': 'BRA', 'champion': false, 'flag_code': 'BR', 'name': 'Brasilien', 'win_points': 7},
  ];
  for (var team in teamsData) {
    await firestore.collection('teams').doc(team['id']! as String?).set(team);
  }

  // --- 4. Zwei Matches ---
  final matchesData = [
    {
      'id': 'ARGvsBRA_1',
      'homeTeamId': 'ARG',
      'guestTeamId': 'BRA',
      'matchDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
      'matchDay': 1,
      'homeScore': null,
      'guestScore': null,
    },
    {
      'id': 'BRAvsARG_2',
      'homeTeamId': 'BRA',
      'guestTeamId': 'ARG',
      'matchDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
      'matchDay': 2,
      'homeScore': null,
      'guestScore': null,
    },
  ];
  for (var match in matchesData) {
    await firestore.collection('matches').doc(match['id']! as String?).set(match);
  }

  // --- 5. Tipps für jeden User & jedes Match ---
  for (var match in matchesData) {
    final matchId = match['id']!;
    for (var uid in userIds) {
      final tipId = '${uid}_$matchId';
      await firestore.collection('tips').doc(tipId).set({
        'id': tipId,
        'userId': uid,
        'matchId': matchId,
        'joker': random.nextBool(),
        'points': null,
        'tipDate': Timestamp.now(),
        'tipGuest': random.nextInt(5),
        'tipHome': random.nextInt(5),
      });
    }
  }

  print('✅ 3 User, 2 Spiele, je ein Tipp pro Match/User angelegt');
}
