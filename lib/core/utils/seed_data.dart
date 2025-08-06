import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> seedTestData() async {
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  // --- Teams ---
  final teamsData = [
    {
      'id': 'ARG',
      'champion': false,
      'flag_code': 'AR',
      'name': 'ArgentinienTestTest',
      'win_points': 10,
    },
    {
      'id': 'FRA',
      'champion': false,
      'flag_code': 'FR',
      'name': 'Frankreich',
      'win_points': 8,
    },
    {
      'id': 'GER',
      'champion': true,
      'flag_code': 'DE',
      'name': 'Deutschland',
      'win_points': 15,
    },
    {
      'id': 'BRA',
      'champion': false,
      'flag_code': 'BR',
      'name': 'Brasilien',
      'win_points': 7,
    },
  ];

  for (var team in teamsData) {
    await firestore.collection('teams').doc(team['id'].toString()).set(team);
  }

  // --- Users ---
  final usersData = [
    {
      'id': 'k74zYhXQSnVoTvrMDb9lKTl2g542',
      'champion_id': 'SPA',
      'email': 'constantin1test.kurz@aol.com',
      'jokerSum': 0,
      'rank': 2,
      'score': 0,
      'sixer': 1,
    },
    {
      'id': 'user2_test_id',
      'champion_id': 'GER',
      'email': 'another.user@example.com',
      'jokerSum': 1,
      'rank': 1,
      'score': 15,
      'sixer': 0,
    },
  ];

  for (var user in usersData) {
    await firestore.collection('users').doc(user['id'].toString()).set(user);
  }

  // --- Tips ---
  final tipsData = [
    {
      'userId': 'k74zYhXQSnVoTvrMDb9lKTl2g542',
      'matchId': 'ARGvsFRA_6',
      'joker': true,
      'points': null,
      'tipDate': Timestamp.fromDate(DateTime(2025, 7, 26, 14, 11, 32)),
      'tipGuest': 2,
      'tipHome': 1,
    },
    {
      'userId': 'user2_test_id',
      'matchId': 'GERvsBRA_7',
      'joker': false,
      'points': 3,
      'tipDate': Timestamp.fromDate(DateTime(2025, 8, 5, 10, 0, 0)),
      'tipGuest': 1,
      'tipHome': 2,
    },
  ];

  for (var tip in tipsData) {
    final tipId = '${tip['userId']}_${tip['matchId']}';
    await firestore.collection('tips').doc(tipId).set(tip);
  }

  print('✅ Testdaten erfolgreich hinzugefügt!');
}
