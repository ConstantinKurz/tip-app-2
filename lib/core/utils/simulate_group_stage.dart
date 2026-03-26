import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/usecases/recalculate_match_tips_usecase.dart';
import 'package:flutter_web/injections.dart';
import 'dart:math';

/// Simuliert NUR die Gruppenphase (matchDay 1-3)
Future<void> simulateGroupStageResults() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();

  print('🏆 Starte Gruppenphase Simulation (matchDay 1-3)...\n');

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

  // Filtere nur Gruppenphase Matches (matchDay 1-3)
  final groupStageMatches = matches.where((m) => m.matchDay <= 3).toList();

  // Hole alle User IDs
  final usersSnap = await firestore.collection('users').get();
  final userIds = usersSnap.docs.map((doc) => doc.id).toList();

  // Hole alle Teams für win_points
  final teamsSnap = await firestore.collection('teams').get();
  final teams = {for (var doc in teamsSnap.docs) doc.id: doc.data()};

  print('📊 Gefunden: ${groupStageMatches.length} Matches, ${userIds.length} User\n');

  // ===== SCHRITT 1: Erst alle Tipps erstellen =====
  print('📝 Erstelle Tipps für alle User...\n');
  await _createGroupStageTips(
    firestore,
    groupStageMatches,
    userIds,
    random,
    tipRepository,
  );

  // ===== SCHRITT 2: Dann Ergebnisse simulieren =====
  print('\n⚽ Simuliere Ergebnisse...\n');
  int processedMatches = 0;

  for (final match in groupStageMatches) {
    // Überspringe Matches die bereits Ergebnisse haben
    if (match.hasResult) {
      print('⏭️  ${match.id} hat bereits Ergebnis');
      continue;
    }

    // Überspringe TBD-Matches
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

  print('\n✅ $processedMatches Matches der Gruppenphase simuliert');
  print('🏆 Simulation der Gruppenphase abgeschlossen!');
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

/// Erstellt Tipps für Gruppenphase mit korrektem Joker-Limit (3 pro Phase)
Future<void> _createGroupStageTips(
  FirebaseFirestore firestore,
  List<CustomMatch> matches,
  List<String> userIds,
  Random random,
  TipRepository tipRepository,
) async {
  int totalTips = 0;
  int skippedTips = 0;

  for (final userId in userIds) {
    // ✅ Joker-Budget für GESAMTE Gruppenphase: 3 Joker für matchDay 1-3
    int jokerBudget = 3;
    final userStrategy = random.nextInt(4);

    // Zähle bereits verwendete Joker in Gruppenphase
    final existingJokersSnap = await firestore
        .collection('tips')
        .where('userId', isEqualTo: userId)
        .where('joker', isEqualTo: true)
        .get();

    for (final doc in existingJokersSnap.docs) {
      final tipMatchId = doc.data()['matchId'] as String?;
      if (tipMatchId != null) {
        // Prüfe ob dieser Tipp zu einem Gruppenphase-Match gehört
        final isGroupStageMatch = matches.any((m) => m.id == tipMatchId);
        if (isGroupStageMatch) {
          jokerBudget--;
        }
      }
    }

    print('👤 User $userId: $jokerBudget Joker verfügbar');

    for (final match in matches) {
      final tipId = '${userId}_${match.id}';

      // Prüfe ob Tipp bereits existiert
      final existingTip = await firestore.collection('tips').doc(tipId).get();
      if (existingTip.exists) {
        skippedTips++;
        continue;
      }

      // Generiere realistischen Tipp
      final tipData = _generateRealisticTip(
        userStrategy,
        random,
        jokerBudget > 0,
      );

      if (tipData['joker'] as bool) {
        jokerBudget--;
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

/// Generiert realistische Tipps basierend auf User-Strategie
Map<String, dynamic> _generateRealisticTip(
  int strategy,
  Random random,
  bool canUseJoker,
) {
  int tipHome, tipGuest;
  bool joker = false;

  switch (strategy) {
    case 0: // Favoriten-Tipper
      tipHome = random.nextInt(3) + 1;
      tipGuest = random.nextInt(2);
      if (canUseJoker && random.nextDouble() < 0.10) {
        joker = true;
      }
      break;
    case 1: // Aggressive Tipper
      tipHome = random.nextInt(4);
      tipGuest = random.nextInt(4);
      if (canUseJoker && random.nextDouble() < 0.15) {
        joker = true;
      }
      break;
    case 2: // Conservative Tipper
      tipHome = 1;
      tipGuest = 1;
      joker = false;
      break;
    case 3: // Random Guesser
      tipHome = random.nextInt(5);
      tipGuest = random.nextInt(5);
      if (canUseJoker && random.nextDouble() < 0.12) {
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
