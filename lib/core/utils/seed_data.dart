 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';

Future<void> seedTestData() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  final random = Random();

  // --- Teams (immer überschreiben) ---
  final teamsData = [
    {'id': 'ARG', 'champion': false, 'flag_code': 'AR', 'name': 'Argentinien', 'win_points': 10},
    {'id': 'FRA', 'champion': false, 'flag_code': 'FR', 'name': 'Frankreich', 'win_points': 8},
    {'id': 'GER', 'champion': true,  'flag_code': 'DE', 'name': 'Deutschland', 'win_points': 15},
    {'id': 'BRA', 'champion': false, 'flag_code': 'BR', 'name': 'Brasilien', 'win_points': 7},
    {'id': 'SPA', 'champion': false, 'flag_code': 'ES', 'name': 'Spanien', 'win_points': 12},
    {'id': 'ITA', 'champion': false, 'flag_code': 'IT', 'name': 'Italien', 'win_points': 9},
    {'id': 'ENG', 'champion': false, 'flag_code': 'GB', 'name': 'England', 'win_points': 11},
    {'id': 'NED', 'champion': false, 'flag_code': 'NL', 'name': 'Niederlande', 'win_points': 6},
  ];
  for (var team in teamsData) {
    final teamId = team['id']?.toString() ?? '';
    if (teamId.isEmpty) continue;
    await firestore.collection('teams').doc(teamId).set(team);
  }

  // --- Spieler (nur hinzufügen, falls nicht vorhanden) ---
  final List<Map<String, dynamic>> usersData = List.generate(20, (i) {
    return {
      'id': 'user_${i + 1}',
      'champion_id': teamsData[random.nextInt(teamsData.length)]['id'],
      'email': 'user${i + 1}@example.com',
      'jokerSum': random.nextInt(3),
      'rank': i + 1,
      'score': random.nextInt(50),
      'sixer': random.nextInt(3),
    };
  });

  for (var user in usersData) {
    final userId = user['id']?.toString() ?? '';
    if (userId.isEmpty) continue;
    final docRef = firestore.collection('users').doc(userId);
    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set(user);
    }
  }

  // --- Matches (immer neu schreiben) ---
  final matchesData = <Map<String, dynamic>>[];
  int matchCounter = 1;
  outerLoop:
  for (int i = 0; i < teamsData.length; i++) {
    for (int j = i + 1; j < teamsData.length; j++) {
      matchesData.add({
        'id': 'MATCH_$matchCounter',
        'homeTeamId': teamsData[i]['id'],
        'guestTeamId': teamsData[j]['id'],
        'matchDate': Timestamp.fromDate(DateTime(2025, 9, (matchCounter % 28) + 1)),
        'matchDay': matchCounter,
        'homeScore': null,
        'guestScore': null,
      });
      matchCounter++;
      if (matchesData.length >= 20) break outerLoop;
    }
  }
  for (var match in matchesData) {
    final matchId = match['id']?.toString() ?? '';
    if (matchId.isEmpty) continue;
    await firestore.collection('matches').doc(matchId).set(match);
  }

  // --- Tipps (immer neu setzen) ---
  for (var match in matchesData) {
    final matchId = match['id']?.toString() ?? '';
    if (matchId.isEmpty) continue;

    for (var user in usersData) {
      final userId = user['id']?.toString() ?? '';
      if (userId.isEmpty) continue;

      await firestore.collection('tips').doc('${userId}_$matchId').set({
        'userId': userId,
        'matchId': matchId,
        'joker': random.nextBool(),
        'points': null,
        'tipDate': Timestamp.now(),
        'tipGuest': random.nextInt(5),
        'tipHome': random.nextInt(5),
      });
    }

    // Leerer Tipp
    await firestore.collection('tips').doc('EMPTYTIP_$matchId').set({
      'userId': 'empty_user',
      'matchId': matchId,
      'joker': false,
      'points': null,
      'tipDate': Timestamp.now(),
      'tipGuest': null,
      'tipHome': null,
    });
  }

  print('✅ Teams & Matches überschrieben, Spieler nur ergänzt, Tipps neu gesetzt!');
}
