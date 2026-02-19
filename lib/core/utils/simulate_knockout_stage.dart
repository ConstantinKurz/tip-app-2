import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/match_phase.dart';
import 'package:flutter_web/domain/usecases/recalculate_match_tips_usecase.dart';
import 'package:flutter_web/injections.dart';
import 'dart:math';

/// Simuliert NUR die K.O.-Phase (matchDay 4-8)
Future<void> simulateKnockoutStageResults() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();

  print('🏆 Starte K.O.-Phase Simulation (matchDay 4-8)...\n');

  // Hole Repositories aus Service Locator
  final matchRepository = sl<MatchRepository>();
  final tipRepository = sl<TipRepository>();
  final recalculateUseCase = sl<RecalculateMatchTipsUseCase>();

  // Hole alle Matches
  final matchesResult = await matchRepository.getAllMatches();
  final matches = matchesResult.fold(
    (failure) {
      print('❌ Fehler beim Laden der Matches: $failure');
      return <CustomMatch>[];
    },
    (matches) => matches,
  );

  // Filtere nur K.O.-Phase Matches (matchDay 4-8)
  final knockoutStageMatches = matches.where((m) => m.matchDay >= 4).toList();

  // Hole alle User IDs
  final usersSnap = await firestore.collection('users').get();
  final userIds = usersSnap.docs.map((doc) => doc.id).toList();

  // Hole alle Teams für win_points
  final teamsSnap = await firestore.collection('teams').get();
  final teams = {for (var doc in teamsSnap.docs) doc.id: doc.data()};

  print('📊 Gefunden: ${knockoutStageMatches.length} Matches, ${userIds.length} User\n');

  // ===== SCHRITT 1: Erst alle Tipps erstellen =====
  print('📝 Erstelle Tipps für alle User...\n');
  await _createKnockoutStageTips(
    firestore,
    knockoutStageMatches,
    userIds,
    random,
    tipRepository,
  );

  // ===== SCHRITT 2: Dann Ergebnisse simulieren =====
  print('\n⚽ Simuliere Ergebnisse...\n');
  int processedMatches = 0;

  for (final match in knockoutStageMatches) {
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
      homeTeam['win_points'] as int? ?? 20,
      guestTeam['win_points'] as int? ?? 20,
      random,
    );

    // Update Match mit Ergebnis
    final updatedMatch = match.copyWith(
      homeScore: result['home'],
      guestScore: result['guest'],
    );

    await matchRepository.updateMatch(updatedMatch);
    print('⚽ ${match.id}: ${result['home']} - ${result['guest']}');
    processedMatches++;

    // ===== SCHRITT 3: Punkte für dieses Match berechnen =====
    try {
      await recalculateUseCase(match: updatedMatch);
      print('   ✅ Punkte neuberechnet');
    } catch (e) {
      print('   ❌ Fehler bei Neuberechnung: $e');
    }
  }

  print('\n✅ $processedMatches Matches der K.O.-Phase simuliert');
  print('🏆 Simulation der K.O.-Phase abgeschlossen!');
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

/// Erstellt Tipps für K.O.-Phase mit korrekten Joker-Limits pro Phase
Future<void> _createKnockoutStageTips(
  FirebaseFirestore firestore,
  List<CustomMatch> matches,
  List<String> userIds,
  Random random,
  TipRepository tipRepository,
) async {
  int totalTips = 0;
  int skippedTips = 0;

  // Joker-Limits pro Phase
  const jokerLimits = {
    MatchPhase.roundOf16: 4,    // 16tel: 4 Joker
    MatchPhase.quarterFinal: 2, // Achtel: 2 Joker
    MatchPhase.semiFinal: 1,    // Viertel: 1 Joker
    MatchPhase.finalStage: 2,   // Halbfinale + Finale: 2 Joker zusammen
  };

  for (final userId in userIds) {
    // ✅ Joker-Budget pro Phase initialisieren
    final jokerBudgets = Map<MatchPhase, int>.from(jokerLimits);

    // Zähle bereits verwendete Joker pro Phase
    final existingJokersSnap = await firestore
        .collection('tips')
        .where('userId', isEqualTo: userId)
        .where('joker', isEqualTo: true)
        .get();

    for (final doc in existingJokersSnap.docs) {
      final tipMatchId = doc.data()['matchId'] as String?;
      if (tipMatchId != null) {
        // Finde das Match zu diesem Tipp
        final tipMatch = matches.cast<CustomMatch?>().firstWhere(
          (m) => m?.id == tipMatchId,
          orElse: () => null,
        );
        if (tipMatch != null) {
          final phase = MatchPhase.fromMatchDay(tipMatch.matchDay);
          jokerBudgets[phase] = (jokerBudgets[phase] ?? 1) - 1;
        }
      }
    }

    print('👤 User $userId: Joker-Budget: $jokerBudgets');

    final userStrategy = random.nextInt(4);

    for (final match in matches) {
      final tipId = '${userId}_${match.id}';

      // Prüfe ob Tipp bereits existiert
      final existingTip = await firestore.collection('tips').doc(tipId).get();
      if (existingTip.exists) {
        skippedTips++;
        continue;
      }

      // Bestimme Phase und Joker-Budget
      final phase = MatchPhase.fromMatchDay(match.matchDay);
      final canUseJoker = (jokerBudgets[phase] ?? 0) > 0;

      // Generiere realistischen Tipp
      final tipData = _generateKnockoutTip(
        userStrategy,
        random,
        canUseJoker,
        match.matchDay,
      );

      if (tipData['joker'] as bool) {
        jokerBudgets[phase] = (jokerBudgets[phase] ?? 1) - 1;
      }

      // Erstelle Tip OHNE Punkte
      final tip = Tip(
        id: tipId,
        userId: userId,
        matchId: match.id,
        tipDate: DateTime.now(),
        tipHome: tipData['tipHome'] as int,
        tipGuest: tipData['tipGuest'] as int,
        joker: tipData['joker'] as bool,
        points: null,
      );

      await tipRepository.create(tip);
      totalTips++;
    }
  }

  print('✅ $totalTips Tipps erstellt, $skippedTips übersprungen');
}

/// Generiert Tipps für K.O.-Phase mit erhöhter Joker-Chance
Map<String, dynamic> _generateKnockoutTip(
  int strategy,
  Random random,
  bool canUseJoker,
  int matchDay,
) {
  int tipHome, tipGuest;
  bool joker = false;

  // K.O.-Phase: Höhere Joker-Chancen in späteren Runden
  final baseJokerChance = matchDay == 4
      ? 0.25 // 16tel
      : matchDay == 5
          ? 0.30 // Achtel
          : matchDay == 6
              ? 0.40 // Viertel
              : 0.50; // Halbfinale/Finale

  switch (strategy) {
    case 0: // Favoriten-Tipper
      tipHome = random.nextInt(2) + 1;
      tipGuest = random.nextInt(2);
      if (canUseJoker && random.nextDouble() < baseJokerChance) {
        joker = true;
      }
      break;
    case 1: // Aggressive Tipper
      tipHome = random.nextInt(4);
      tipGuest = random.nextInt(4);
      if (canUseJoker && random.nextDouble() < baseJokerChance + 0.15) {
        joker = true;
      }
      break;
    case 2: // Conservative Tipper
      tipHome = 1;
      tipGuest = 0;
      // Spart Joker für späte Phase
      if (canUseJoker && matchDay >= 6 && random.nextDouble() < 0.50) {
        joker = true;
      }
      break;
    case 3: // Random Guesser
      tipHome = random.nextInt(5);
      tipGuest = random.nextInt(5);
      if (canUseJoker && random.nextDouble() < baseJokerChance - 0.05) {
        joker = true;
      }
      break;
    default:
      tipHome = 1;
      tipGuest = 0;
  }

  return {
    'tipHome': tipHome,
    'tipGuest': tipGuest,
    'joker': joker,
  };
}
