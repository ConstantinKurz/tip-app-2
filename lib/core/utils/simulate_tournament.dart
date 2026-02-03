import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/injections.dart';
import 'dart:math';

/// Würfelt Ergebnisse für ALLE Matches aus und erstellt Tipps
/// Nutzt die bestehenden Repositories und Services
Future<void> simulateTournamentResults() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  final random = Random();

  print('🎲 Starte Ergebnis-Simulation...\n');

  // Hole Repositories aus Service Locator
  final matchRepository = sl<MatchRepository>();
  final tipRepository = sl<TipRepository>();

  // Hole alle Matches
  final matchesResult = await matchRepository.getAllMatches();
  final matches = await matchesResult.fold(
    (failure) {
      print('❌ Fehler beim Laden der Matches: $failure');
      return <CustomMatch>[];
    },
    (matches) => matches,
  );

  // Hole alle User IDs
  final usersSnap = await firestore.collection('users').get();
  final userIds = usersSnap.docs.map((doc) => doc.id).toList();

  // Hole alle Teams für win_points
  final teamsSnap = await firestore.collection('teams').get();
  final teams = {
    for (var doc in teamsSnap.docs) doc.id: doc.data()
  };

  int processedMatches = 0;

  print('📊 Simuliere ${matches.length} Matches...\n');

  // Simuliere ALLE Matches (Gruppenphase + K.O.)
  for (final match in matches) {
    // Überspringe Matches die bereits Ergebnisse haben
    if (match.hasResult) {
      print('⏭️  ${match.id} hat bereits Ergebnis');
      continue;
    }

    // Überspringe TBD-Matches (K.O.-Phase noch nicht festgelegt)
    if (match.homeTeamId == 'TBD' || match.guestTeamId == 'TBD') {
      print('⏭️  ${match.id} wartet auf Team-Festlegung');
      continue;
    }

    final homeTeam = teams[match.homeTeamId];
    final guestTeam = teams[match.guestTeamId];

    if (homeTeam == null || guestTeam == null) {
      print('⚠️  Teams nicht gefunden für ${match.id}');
      continue;
    }

    // Simuliere Ergebnis basierend auf Team-Stärke
    final result = _calculateMatchResult(
      homeTeam['win_points'] as int,
      guestTeam['win_points'] as int,
      random,
    );

    // ✅ Nutze das bestehende Repository für Update
    final updatedMatch = match.copyWith(
      homeScore: result['home'],
      guestScore: result['guest'],
    );

    await matchRepository.updateMatch(updatedMatch);

    print('⚽ ${match.id}: ${result['home']} - ${result['guest']}');
    processedMatches++;
  }

  print('\n✅ $processedMatches Matches simuliert');

  // Erstelle Tipps für alle User (falls noch nicht vorhanden)
  await _createRealisticTips(firestore, matches, userIds, random, tipRepository);

  print('\n🏆 Simulation abgeschlossen!');
  print('ℹ️  Die Punkte werden automatisch durch den TipRecalculationService berechnet');
}

/// Berechnet Match-Ergebnis basierend auf Team-Stärke
Map<String, int> _calculateMatchResult(
  int homePower,
  int guestPower,
  Random random,
) {
  final powerDiff = homePower - guestPower;
  final homeWinChance = 0.5 + (powerDiff / 100);

  final homeGoals = random.nextInt(4) + (homeWinChance > 0.6 ? 1 : 0);
  final guestGoals = random.nextInt(4) + (homeWinChance < 0.4 ? 1 : 0);

  return {'home': homeGoals, 'guest': guestGoals};
}

/// Erstellt realistische Tipps für alle User (ohne Punkte)
Future<void> _createRealisticTips(
  FirebaseFirestore firestore,
  List<CustomMatch> matches,
  List<String> userIds,
  Random random,
  TipRepository tipRepository,
) async {
  int totalTips = 0;

  for (final userId in userIds) {
    // ✅ Joker-Budget PRO PHASE (nicht pro matchDay!)
    final jokerBudgetsPerPhase = {
      'groupStage': 3,      // Vorrunde: 3 Joker für matchDays 1-3 zusammen
      'roundOf16': 4,       // 16tel: 4 Joker
      'quarterFinal': 2,    // Achtel: 2 Joker
      'semiFinal': 1,       // Viertel: 1 Joker
      'finalStage': 2,      // Halbfinale + Finale: 2 Joker für matchDays 7-8 zusammen
    };

    for (final match in matches) {
      final matchDay = match.matchDay;

      // Prüfe ob Tipp bereits existiert
      final existingTip = await firestore
          .collection('tips')
          .doc('${userId}_${match.id}')
          .get();

      if (existingTip.exists) {
        continue; // Tipp existiert bereits
      }

      // ✅ Bestimme Phase basierend auf matchDay
      String phase;
      if (matchDay <= 3) {
        phase = 'groupStage';
      } else if (matchDay == 4) {
        phase = 'roundOf16';
      } else if (matchDay == 5) {
        phase = 'quarterFinal';
      } else if (matchDay == 6) {
        phase = 'semiFinal';
      } else {
        phase = 'finalStage'; // matchDay 7 und 8
      }

      // Generiere Tipp
      final canUseJoker = (jokerBudgetsPerPhase[phase] ?? 0) > 0;
      final useJoker = canUseJoker && random.nextDouble() < 0.15; // 15% Chance

      if (useJoker) {
        jokerBudgetsPerPhase[phase] = (jokerBudgetsPerPhase[phase] ?? 1) - 1;
      }

      final tip = Tip(
        id: '${userId}_${match.id}',
        userId: userId,
        matchId: match.id,
        tipHome: random.nextInt(4), // 0-3 Tore
        tipGuest: random.nextInt(4),
        joker: useJoker,
        points: null, // ✅ Wird automatisch vom Service berechnet
        tipDate: DateTime.now(),
      );

      // ✅ Nutze das bestehende Repository
      await tipRepository.create(tip);

      totalTips++;
    }
  }

  print('✅ $totalTips Tipps erstellt');
  print('📊 Joker-Verteilung:');
  print('   - Vorrunde (1-3): max 3 Joker gesamt');
  print('   - 16tel (4): max 4 Joker');
  print('   - Achtel (5): max 2 Joker');
  print('   - Viertel (6): max 1 Joker');
  print('   - Halbfinale + Finale (7-8): max 2 Joker gesamt');
}