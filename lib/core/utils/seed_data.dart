import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';

Future<void> seedTestDataTwentyUsers() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final random = Random();

  // --- 1. Test-User-Konfiguration (20 User) ---
  final testUsers = List.generate(20, (i) {
    final num = i + 1;
    return {
      'email': 'user$num@test.com',
      'password': '123456',
      'name': 'User $num',
      'champion_id': _championPool[i % _championPool.length]['id'],
    };
  });

  final userIds = <String>[];

  // --- 2. User in Auth & Firestore anlegen ---
  for (final u in testUsers) {
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: u['email'] as String,
        password: u['password'] as String,
      );

      print('✅ Auth-User erstellt: ${u['email']}');
      userIds.add(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final existingUser = await auth.signInWithEmailAndPassword(
          email: u['email'] as String,
          password: u['password'] as String,
        );
        userIds.add(existingUser.user!.uid);
        print('ℹ️ User existiert schon: ${u['email']}');
      } else {
        rethrow;
      }
    }
  }

  // --- 3. Firestore-User-Dokumente setzen ---
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

  // --- 4. Teams anlegen ---
  for (var team in _championPool) {
    await firestore.collection('teams').doc(team['id']! as String?).set(team);
  }

  // --- 5. Matches generieren (jede Team-Kombi einmal) ---
  final matchesData = <Map<String, dynamic>>[];
  int matchCounter = 1;
  for (int i = 0; i < _championPool.length; i++) {
    for (int j = i + 1; j < _championPool.length; j++) {
      matchesData.add({
        'id': '${_championPool[i]['id']}vs${_championPool[j]['id']}_$matchCounter',
        'homeTeamId': _championPool[i]['id'],
        'guestTeamId': _championPool[j]['id'],
        'matchDate': Timestamp.fromDate(
            DateTime.now().add(Duration(days: matchCounter))),
        'matchDay': matchCounter,
        'homeScore': null,
        'guestScore': null,
      });
      matchCounter++;
    }
  }

  for (var match in matchesData) {
    await firestore.collection('matches').doc(match['id']!).set(match);
  }

  // --- 6. Tipps für jeden User & jedes Match ---
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

  print(
      '✅ 20 User, ${_championPool.length} Teams, ${matchesData.length} Spiele und Tipps angelegt.');
}

// --- Pool an Teams (mindestens 8–10 für viele Matches) ---
final _championPool = [
  {
    'id': 'ARG',
    'champion': false,
    'flag_code': 'AR',
    'name': 'Argentinien',
    'win_points': 10
  },
  {
    'id': 'BRA',
    'champion': false,
    'flag_code': 'BR',
    'name': 'Brasilien',
    'win_points': 7
  },
  {
    'id': 'GER',
    'champion': true,
    'flag_code': 'DE',
    'name': 'Deutschland',
    'win_points': 15
  },
  {
    'id': 'ESP',
    'champion': false,
    'flag_code': 'ES',
    'name': 'Spanien',
    'win_points': 12
  },
  {
    'id': 'FRA',
    'champion': false,
    'flag_code': 'FR',
    'name': 'Frankreich',
    'win_points': 8
  },
  {
    'id': 'ITA',
    'champion': false,
    'flag_code': 'IT',
    'name': 'Italien',
    'win_points': 9
  },
  {
    'id': 'NED',
    'champion': false,
    'flag_code': 'NL',
    'name': 'Niederlande',
    'win_points': 6
  },
  {
    'id': 'ENG',
    'champion': false,
    'flag_code': 'GB',
    'name': 'England',
    'win_points': 11
  },
  {
    'id': 'POR',
    'champion': false,
    'flag_code': 'PT',
    'name': 'Portugal',
    'win_points': 10
  },
  {
    'id': 'BEL',
    'champion': false,
    'flag_code': 'BE',
    'name': 'Belgien',
    'win_points': 8
  },
];
