import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';

Future<void> seedTestDataSingleUser() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  final random = Random();

  const userId = 'k74zYhXQSnVoTvrMDb9lKTl2g542';

  // --- 2 Teams setzen ---
  final teamsData = [
    {'id': 'ARG', 'champion': false, 'flag_code': 'AR', 'name': 'Argentinien', 'win_points': 10},
    {'id': 'BRA', 'champion': false, 'flag_code': 'BR', 'name': 'Brasilien', 'win_points': 7},
  ];
  for (var team in teamsData) {
    await firestore.collection('teams').doc(team['id']! as String?).set(team);
  }

  // --- 1 Match zwischen den beiden Teams ---
  final matchId = 'ARGvsBRA_1';
  final matchData = {
    'id': matchId,
    'homeTeamId': teamsData[0]['id'],
    'guestTeamId': teamsData[1]['id'],
    'matchDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
    'matchDay': 1,
    'homeScore': null,
    'guestScore': null,
  };
  await firestore.collection('matches').doc(matchId).set(matchData);

  // --- Tipp für deinen User ---
  final tipId = '${userId}_$matchId';
  final tipData = {
    'id': tipId,
    'userId': userId,
    'matchId': matchId,
    'joker': random.nextBool(),
    'points': null,
    'tipDate': Timestamp.now(),
    'tipGuest': random.nextInt(5),
    'tipHome': random.nextInt(5),
  };
  await firestore.collection('tips').doc(tipId).set(tipData);

  // --- Leerer Tipp ---
  final emptyTipId = 'EMPTYTIP_$matchId';
  await firestore.collection('tips').doc(emptyTipId).set({
    'id': emptyTipId,
    'userId': 'empty_user',
    'matchId': matchId,
    'joker': false,
    'points': null,
    'tipDate': Timestamp.now(),
    'tipGuest': null,
    'tipHome': null,
  });

  print('✅ 2 Teams, 1 Match & 1 Tipp für $userId erstellt.');
}
