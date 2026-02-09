import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';

Future<void> seedRealisticWMSimulation() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final random = Random();

  print('🏆 Starte realistische WM 2026 Simulation...\n');

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
      'score': 0, // Wird später berechnet
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

  // Jeder Spieltag hat 8 Spiele (2 pro Gruppe parallel)
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
          'homeScore': null, // Wird später gesetzt
          'guestScore': null,
        };

        allMatches.add(matchData);
      }
    }
  }

  // ===== 5. K.O.-PHASE SIMULIEREN =====
  final groupWinners = _simulateGroupStage(groups, random);
  final koMatches = _generateKOMatches(groupWinners);

  for (var i = 0; i < koMatches.length; i++) {
    final match = koMatches[i];
    final matchDay = 4 + (i ~/ 8); // matchDay 4-8 für K.O.

    allMatches.add({
      'id': 'wm_match_ko_$i',
      'homeTeamId': match['home'],
      'guestTeamId': match['guest'],
      'matchDay': matchDay,
      'matchDate': Timestamp.fromDate(
          DateTime.now().add(Duration(days: 3 + i ~/ 4))),
      'homeScore': null,
      'guestScore': null,
    });
  }

  // ===== 6. ERGEBNISSE SIMULIEREN =====
  for (var match in allMatches) {
    final homeTeam = _wmTeams.firstWhere((t) => t['id'] == match['homeTeamId']);
    final guestTeam = _wmTeams.firstWhere((t) => t['id'] == match['guestTeamId']);

    final result = _simulateMatch(
      homeTeam['win_points'] as int,
      guestTeam['win_points'] as int,
      random,
    );

    match['homeScore'] = result['home'];
    match['guestScore'] = result['guest'];
  }

  // Speichere alle Matches mit id-Feld
  for (var match in allMatches) {
    await firestore.collection('matches').doc(match['id']).set({
      ...match,
      'id': match['id'], // ✅ Speichere id auch als Feld!
    });
  }

  print('\n✅ ${allMatches.length} Matches erstellt');

  // ===== 7. TIPPS ERSTELLEN MIT REALISTISCHEN MUSTERN & JOKER-LIMITS =====
  int totalTips = 0;
  
  for (final userId in userIds) {
    // Initialisiere Joker-Budgets pro User und Phase
    final jokerBudgets = {
      'group': 5, // Vorrunde: 5 Joker für 20 Spiele
      'round16': 4, // 16tel: 4 Joker für 16 Spiele
      'round8': 2, // 8tel: 2 Joker für 8 Spiele
      'quarter': 1, // 4tel: 1 Joker für 4 Spiele
      'semi': 2, // Halbfinale+: 2 Joker für 3 Spiele
    };

    final userStrategy = random.nextInt(4); // Verschiedene Strategien

    for (final match in allMatches) {
      final tipId = '${userId}_${match['id']}';
      final matchDay = match['matchDay'] as int;

      // Nur vergangene Matches haben echte Tipps
      if (match['homeScore'] != null) {
        final phase = _getPhase(matchDay);
        final jokerBudget = jokerBudgets[phase]!;

        final tip = _generateRealisticTip(
          userId,
          match,
          userStrategy,
          random,
          jokerBudget > 0, // Kann Joker setzen, wenn Budget vorhanden
        );

        // Subtrahiere Joker vom Budget wenn verwendet
        if (tip['joker'] as bool) {
          jokerBudgets[phase] = jokerBudgets[phase]! - 1;
        }

        // Berechne Punkte
        final points = _calculatePoints(
          tip['tipHome'] as int,
          tip['tipGuest'] as int,
          match['homeScore'] as int,
          match['guestScore'] as int,
          tip['joker'] as bool,
          matchDay,
        );

        await firestore.collection('tips').doc(tipId).set({
          'id': tipId,
          'userId': userId,
          'matchId': match['id'],
          'tipHome': tip['tipHome'],
          'tipGuest': tip['tipGuest'],
          'joker': tip['joker'],
          'points': points,
          'tipDate': Timestamp.now(),
        });

        totalTips++;
      }
    }
  }

  print('✅ $totalTips Tipps erstellt');
  print('\n🏆 WM 2026 Simulation erfolgreich abgeschlossen!');
}

// ===== HILFSFUNKTIONEN =====

/// Gibt die Phase basierend auf matchDay zurück
String _getPhase(int matchDay) {
  if (matchDay <= 3) return 'group'; // Vorrunde
  if (matchDay == 4) return 'round16'; // 16tel
  if (matchDay == 5) return 'round8'; // 8tel
  if (matchDay == 6) return 'quarter'; // 4tel
  return 'semi'; // Halbfinale & Finale
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

    // Erzeuge alle Match-Paarungen in dieser Gruppe
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

/// Simuliert Gruppenphase und gibt Gewinner zurück
List<String> _simulateGroupStage(
  List<List<Map<String, String>>> groups,
  Random random,
) {
  final winners = <String>[];

  for (final group in groups) {
    final standings = <String, int>{};

    for (final match in group) {
      final home = match['home']!;
      final guest = match['guest']!;
      standings[home] ??= 0;
      standings[guest] ??= 0;

      // Simuliere Match
      final homeTeam = _wmTeams.firstWhere((t) => t['id'] == home);
      final guestTeam = _wmTeams.firstWhere((t) => t['id'] == guest);
      final result = _simulateMatch(
        homeTeam['win_points'] as int,
        guestTeam['win_points'] as int,
        random,
      );

      if (result['home']! > result['guest']!) {
        standings[home] = standings[home]! + 3;
      } else if (result['home']! < result['guest']!) {
        standings[guest] = standings[guest]! + 3;
      } else {
        standings[home] = standings[home]! + 1;
        standings[guest] = standings[guest]! + 1;
      }
    }

    // Top 2 aus Gruppe kommen weiter
    final sorted = standings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    winners.add(sorted[0].key);
    winners.add(sorted[1].key);
  }

  return winners;
}

/// Generiert K.O.-Phasen-Matches
List<Map<String, String>> _generateKOMatches(List<String> winners) {
  final koMatches = <Map<String, String>>[];

  // 16tel-Finale: 1 vs 16, 2 vs 15, etc.
  for (int i = 0; i < 8; i++) {
    koMatches.add({
      'home': winners[i],
      'guest': winners[15 - i],
    });
  }

  return koMatches;
}

/// Simuliert ein Match basierend auf Team-Stärke
Map<String, int> _simulateMatch(int homePower, int guestPower, Random random) {
  final powerDiff = homePower - guestPower;
  final homeWinChance = 0.5 + (powerDiff / 100);

  final homeGoals = random.nextInt(4) + (homeWinChance > 0.6 ? 1 : 0);
  final guestGoals = random.nextInt(4) + (homeWinChance < 0.4 ? 1 : 0);

  return {'home': homeGoals, 'guest': guestGoals};
}

/// Generiert realistische Tipps basierend auf User-Strategie
Map<String, dynamic> _generateRealisticTip(
  String userId,
  Map<String, dynamic> match,
  int strategy,
  Random random,
  bool canUseJoker,
) {
  final homeTeamId = match['homeTeamId'] as String;
  final guestTeamId = match['guestTeamId'] as String;
  final homeTeam = _wmTeams.firstWhere((t) => t['id'] == homeTeamId);
  final guestTeam = _wmTeams.firstWhere((t) => t['id'] == guestTeamId);
  final matchDay = match['matchDay'] as int;

  int tipHome, tipGuest;
  bool joker = false;

  switch (strategy) {
    case 0: // Favoriten-Tipper
      tipHome = (homeTeam['win_points'] as int) > (guestTeam['win_points'] as int)
          ? random.nextInt(2) + 1
          : 0;
      tipGuest = (guestTeam['win_points'] as int) > (homeTeam['win_points'] as int)
          ? random.nextInt(2) + 1
          : 0;
      // Joker eher in K.O.-Phase
      if (canUseJoker && matchDay >= 5) {
        joker = random.nextDouble() < 0.25; // 25% in K.O.-Phase
      } else if (canUseJoker) {
        joker = random.nextDouble() < 0.08; // 8% in Vorrunde
      }
      break;
    case 1: // Aggressive Tipper (riskante Joker)
      tipHome = random.nextInt(3);
      tipGuest = random.nextInt(3);
      if (canUseJoker) {
        joker = random.nextDouble() < _getJokerProbability(matchDay, true);
      }
      break;
    case 2: // Conservative Tipper
      tipHome = 1;
      tipGuest = 1;
      if (canUseJoker && matchDay >= 6) {
        joker = random.nextDouble() < 0.30; // Spart Joker für späte Phase
      }
      break;
    case 3: // Random Guesser
      tipHome = random.nextInt(4);
      tipGuest = random.nextInt(4);
      if (canUseJoker) {
        joker = random.nextDouble() < 0.10;
      }
      break;
    default:
      tipHome = 0;
      tipGuest = 0;
  }

  return {
    'tipHome': tipHome,
    'tipGuest': tipGuest,
    'joker': joker,
  };
}

/// Gibt die Wahrscheinlichkeit für Joker-Einsatz pro Phase zurück
double _getJokerProbability(int matchDay, bool aggressive) {
  if (matchDay <= 3) return aggressive ? 0.12 : 0.05; // Vorrunde: 5 Joker auf 20 Spiele
  if (matchDay == 4) return aggressive ? 0.25 : 0.15; // 16tel: 4 Joker auf 16 Spiele
  if (matchDay == 5) return aggressive ? 0.40 : 0.25; // 8tel: 2 Joker auf 8 Spiele
  if (matchDay == 6) return aggressive ? 0.50 : 0.40; // 4tel: 1 Joker auf 4 Spiele
  return aggressive ? 0.60 : 0.50; // Halbfinale+: 2 Joker auf 3 Spiele
}

/// Berechnet Punkte nach deinen Regeln mit Phase-Multiplikatoren
int _calculatePoints(
  int tipHome,
  int tipGuest,
  int actualHome,
  int actualGuest,
  bool joker,
  int matchDay,
) {
  int basePoints = 0;

  // Basis-Punkte
  if (tipHome == actualHome && tipGuest == actualGuest) {
    basePoints = 6;
  } else if ((tipHome - tipGuest) == (actualHome - actualGuest)) {
    basePoints = 5;
  } else if ((tipHome > tipGuest && actualHome > actualGuest) ||
      (tipHome < tipGuest && actualHome < actualGuest) ||
      (tipHome == tipGuest && actualHome == actualGuest)) {
    basePoints = 1;
  }

  // Phase-Multiplikator
  final multiplier = _getPhaseMultiplier(matchDay);
  final multipliedPoints = basePoints * multiplier;

  // Joker verdoppelt
  return joker ? multipliedPoints * 2 : multipliedPoints;
}

/// Gibt den Multiplikator basierend auf der Phase zurück
int _getPhaseMultiplier(int matchDay) {
  if (matchDay <= 3) return 1; // Vorrunde
  if (matchDay == 4) return 1; // 16tel
  if (matchDay == 5) return 2; // 8tel
  if (matchDay == 6) return 3; // 4tel
  return 3; // Halbfinale & Finale
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
