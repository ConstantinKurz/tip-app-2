import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Erstellt Teams, User und Matches - OHNE Ergebnisse
Future<void> setupTournament() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  print('🏆 Starte Turnier-Setup...\n');

  // ===== 1. USER ERSTELLEN =====
  final testUsers = List.generate(20, (i) {
    final num = i + 1;
    return {
      'email': 'user$num@test.com',
      'password': '123456',
      'name': 'User $num',
      'champion_id': _wmTeams[i % _wmTeams.length]['id'],
    };
  });

  final userIds = <String>[];

  for (final u in testUsers) {
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: u['email'] as String,
        password: u['password'] as String,
      );
      userIds.add(cred.user!.uid);
      print('✅ User erstellt: ${u['email']}');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final existing = await auth.signInWithEmailAndPassword(
          email: u['email'] as String,
          password: u['password'] as String,
        );
        userIds.add(existing.user!.uid);
        print('ℹ️ User existiert: ${u['email']}');
      }
    }
  }

  // ===== 2. USER-DOKUMENTE IN FIRESTORE =====
  for (var i = 0; i < userIds.length; i++) {
    await firestore.collection('users').doc(userIds[i]).set({
      'id': userIds[i],
      'champion_id': testUsers[i]['champion_id'],
      'email': testUsers[i]['email'],
      'name': testUsers[i]['name'],
      'rank': i + 1,
      'score': 0,
      'jokerSum': 0,
      'sixer': 0,
      'admin': false,
    });
  }

  // ===== 3. TEAMS =====
  for (var team in _wmTeams) {
    await firestore.collection('teams').doc(team['id']! as String).set(team);
  }

  // ===== 4. GRUPPENPHASE MATCHES (matchDay 1-3) =====
  final groups = _createGroups();
  final allMatches = <Map<String, dynamic>>[];
  int matchId = 0;

  for (var matchDay = 1; matchDay <= 3; matchDay++) {
    for (var groupMatches in groups) {
      if (groupMatches.length >= matchDay) {
        final match = groupMatches[matchDay - 1];

        final matchData = {
          'id': 'wm_match_${matchId++}',
          'homeTeamId': match['home'],
          'guestTeamId': match['guest'],
          'matchDay': matchDay,
          'matchDate': Timestamp.fromDate(
              DateTime.now().add(Duration(days: matchDay - 1, hours: 20))),
          'homeScore': null,
          'guestScore': null,
        };

        allMatches.add(matchData);
      }
    }
  }

  // ===== 5. K.O.-PHASE VORBEREITEN (ohne Ergebnisse) =====
  // Erstelle Platzhalter für K.O.-Matches
  for (int round = 4; round <= 8; round++) {
    int matchesInRound = 16; // 16tel
    if (round == 5) matchesInRound = 8; // Achtel
    if (round == 6) matchesInRound = 4; // Viertel
    if (round == 7) matchesInRound = 2; // Halbfinale
    if (round == 8) matchesInRound = 1; // Finale

    for (int i = 0; i < matchesInRound; i++) {
      allMatches.add({
        'id': 'wm_match_ko_${round}_$i',
        'homeTeamId': 'TBD', // Wird später bestimmt
        'guestTeamId': 'TBD',
        'matchDay': round,
        'matchDate': Timestamp.fromDate(
            DateTime.now().add(Duration(days: round + 2))),
        'homeScore': null,
        'guestScore': null,
      });
    }
  }

  // Speichere alle Matches
  for (var match in allMatches) {
    await firestore.collection('matches').doc(match['id']).set(match);
  }

  print('\n✅ ${allMatches.length} Matches erstellt');
  print('✅ Setup abgeschlossen - bereit für Tipps!');
}

/// Erstellt Gruppen mit Match-Paarungen
List<List<Map<String, String>>> _createGroups() {
  const groups = 8;
  const teamsPerGroup = 4;
  final groupList = <List<Map<String, String>>>[];

  var teamIndex = 0;
  for (int g = 0; g < groups; g++) {
    final groupTeams = <String>[];
    for (int t = 0; t < teamsPerGroup; t++) {
      groupTeams.add(_wmTeams[teamIndex++ % _wmTeams.length]['id'] as String);
    }

    final groupMatches = <Map<String, String>>[];
    for (int i = 0; i < groupTeams.length; i++) {
      for (int j = i + 1; j < groupTeams.length; j++) {
        groupMatches.add({
          'home': groupTeams[i],
          'guest': groupTeams[j],
        });
      }
    }

    groupList.add(groupMatches);
  }

  return groupList;
}

// ===== WM TEAMS =====
final _wmTeams = [
  {'id': 'ARG', 'name': 'Argentinien', 'flag_code': 'AR', 'win_points': 30, 'champion': false},
  {'id': 'BRA', 'name': 'Brasilien', 'flag_code': 'BR', 'win_points': 30, 'champion': false},
  {'id': 'GER', 'name': 'Deutschland', 'flag_code': 'DE', 'win_points': 30, 'champion': true},
  {'id': 'FRA', 'name': 'Frankreich', 'flag_code': 'FR', 'win_points': 30, 'champion': false},
  {'id': 'ESP', 'name': 'Spanien', 'flag_code': 'ES', 'win_points': 30, 'champion': false},
  {'id': 'ENG', 'name': 'England', 'flag_code': 'GB', 'win_points': 20, 'champion': false},
  {'id': 'NED', 'name': 'Niederlande', 'flag_code': 'NL', 'win_points': 20, 'champion': false},
  {'id': 'BEL', 'name': 'Belgien', 'flag_code': 'BE', 'win_points': 30, 'champion': false},
  {'id': 'ITA', 'name': 'Italien', 'flag_code': 'IT', 'win_points': 30, 'champion': false},
  {'id': 'USA', 'name': 'USA', 'flag_code': 'US', 'win_points': 20, 'champion': false},
  {'id': 'MEX', 'name': 'Mexiko', 'flag_code': 'MX', 'win_points': 30, 'champion': false},
  {'id': 'JPN', 'name': 'Japan', 'flag_code': 'JP', 'win_points': 30, 'champion': false},
  {'id': 'KOR', 'name': 'Südkorea', 'flag_code': 'KR', 'win_points': 30, 'champion': false},
  {'id': 'AUS', 'name': 'Australien', 'flag_code': 'AU', 'win_points': 20, 'champion': false},
  {'id': 'CAN', 'name': 'Kanada', 'flag_code': 'CA', 'win_points': 20, 'champion': false},
  {'id': 'SWE', 'name': 'Schweden', 'flag_code': 'SE', 'win_points': 20, 'champion': false},
];