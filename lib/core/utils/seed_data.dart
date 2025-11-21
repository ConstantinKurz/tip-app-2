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
      'score': random.nextInt(50) + 10, // Zufällige Punkte zwischen 10-60
      'jokerSum': random.nextInt(20),
      'mixer': random.nextInt(10),
    });
  }

  // --- 4. Teams anlegen ---
  for (var team in _championPool) {
    await firestore.collection('teams').doc(team['id']! as String?).set(team);
  }

  // --- 5. Mix aus vergangenen, aktuellen und zukünftigen Matches ---
  final now = DateTime.now();
  final matchesData = <Map<String, dynamic>>[];
  int matchCounter = 1;
  
  // Erste 15 Matches in der Vergangenheit (mit Ergebnissen)
  for (int i = 0; i < _championPool.length && matchCounter <= 15; i++) {
    for (int j = i + 1; j < _championPool.length && matchCounter <= 15; j++) {
      matchesData.add({
        'id': '${_championPool[i]['id']}vs${_championPool[j]['id']}_$matchCounter',
        'homeTeamId': _championPool[i]['id'],
        'guestTeamId': _championPool[j]['id'],
        'kickOff': Timestamp.fromDate(
            now.subtract(Duration(days: 20 - matchCounter))),
        'matchDay': random.nextInt(7),
        'homeScore': random.nextInt(4),
        'guestScore': random.nextInt(4),
      });
      matchCounter++;
    }
  }
  
  // Ein aktuelles Spiel (vor 30 Min gestartet, noch kein Ergebnis)
  if (matchCounter <= _championPool.length * (_championPool.length - 1) ~/ 2) {
    final homeIndex = random.nextInt(_championPool.length);
    var guestIndex = random.nextInt(_championPool.length);
    while (guestIndex == homeIndex) {
      guestIndex = random.nextInt(_championPool.length);
    }
    
    matchesData.add({
      'id': '${_championPool[homeIndex]['id']}vs${_championPool[guestIndex]['id']}_CURRENT',
      'homeTeamId': _championPool[homeIndex]['id'],
      'guestTeamId': _championPool[guestIndex]['id'],
      'kickOff': Timestamp.fromDate(now.subtract(const Duration(minutes: 30))),
      'matchDay': 6,
      'homeScore': null,
      'guestScore': null,
    });
    matchCounter++;
  }
  
  // Restliche Matches in der Zukunft
  final remainingPairs = <List<int>>[];
  for (int i = 0; i < _championPool.length; i++) {
    for (int j = i + 1; j < _championPool.length; j++) {
      final existingMatch = matchesData.any((m) => 
        (m['homeTeamId'] == _championPool[i]['id'] && m['guestTeamId'] == _championPool[j]['id']) ||
        (m['homeTeamId'] == _championPool[j]['id'] && m['guestTeamId'] == _championPool[i]['id'])
      );
      if (!existingMatch) {
        remainingPairs.add([i, j]);
      }
    }
  }
  
  remainingPairs.shuffle();
  for (int k = 0; k < remainingPairs.length; k++) {
    final pair = remainingPairs[k];
    matchesData.add({
      'id': '${_championPool[pair[0]]['id']}vs${_championPool[pair[1]]['id']}_$matchCounter',
      'homeTeamId': _championPool[pair[0]]['id'],
      'guestTeamId': _championPool[pair[1]]['id'],
      'matchDate': Timestamp.fromDate(
          now.add(Duration(hours: 2 + k * 6))),
      'matchDay': 7 + (k ~/ 5),
      'homeScore': null,
      'guestScore': null,
    });
    matchCounter++;
  }

  for (var match in matchesData) {
    await firestore.collection('matches').doc(match['id']!).set(match);
  }

  // --- 6. Tipps für jeden User & jedes Match ---
  for (var match in matchesData) {
    final matchId = match['id']!;
    final hasResult = match['homeScore'] != null;
    
    for (var uid in userIds) {
      final tipId = '${uid}_$matchId';
      final tipData = {
        'id': tipId,
        'userId': uid,
        'matchId': matchId,
        'joker': random.nextBool() && random.nextDouble() < 0.05, // 5% Chance auf Joker
        'points': hasResult ? random.nextInt(6) + 1 : null, // Punkte nur für vergangene Spiele
        'tipDate': hasResult 
            ? Timestamp.fromDate((match['kickOff'] as Timestamp).toDate().subtract(Duration(hours: 1)))
            : Timestamp.now(),
        'tipGuest': random.nextInt(4),
        'tipHome': random.nextInt(4),
      };
      await firestore.collection('tips').doc(tipId).set(tipData);
    }
  }

  print('✅ 20 User, ${_championPool.length} Teams, ${matchesData.length} Spiele und Tipps angelegt.');
  print('📊 Vergangene Spiele: ${matchesData.where((m) => m['homeScore'] != null).length}');
  print('🎯 Aktuelles Spiel: 1 (vor 30 Min gestartet)');
  print('🔮 Zukünftige Spiele: ${matchesData.where((m) => m['homeScore'] == null && m['id'] != matchesData.firstWhere((m) => m['id'].toString().contains('CURRENT'))['id']).length}');
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
