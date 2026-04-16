import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/domain/repositories/team_repository.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/match_phase.dart';
import 'package:flutter_web/domain/usecases/recalculate_match_tips_usecase.dart';
import 'package:flutter_web/injections.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

/// Simuliert die Gruppenphase (matchDay 1-3) mit echten DB-Daten
/// Erstellt User (falls keine vorhanden), Tips für alle User und simuliert Match-Ergebnisse
Future<void> simulateGroupStageFromDB() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();

  print('🏆 Starte Gruppenphase Simulation (matchDay 1-3) mit DB-Daten...\n');

  final matchRepository = sl<MatchRepository>();
  final tipRepository = sl<TipRepository>();
  final recalculateUseCase = sl<RecalculateMatchTipsUseCase>();

  // Hole alle Matches aus DB
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

  // Hole alle Teams für win_points und Champion-Auswahl
  final teamsSnap = await firestore.collection('teams').get();
  final teams = {for (var doc in teamsSnap.docs) doc.id: doc.data()};
  final teamIds = teams.keys.toList();

  if (groupStageMatches.isEmpty) {
    print('⚠️  Keine Gruppenphase-Matches gefunden!');
    return;
  }

  if (teamIds.isEmpty) {
    print('⚠️  Keine Teams gefunden! Bitte erst Teams anlegen.');
    return;
  }

  // ===== SCHRITT 0: User erstellen falls zu wenige vorhanden =====
  var usersSnap = await firestore.collection('users').get();
  var userIds = usersSnap.docs.map((doc) => doc.id).toList();

  // Erstelle simulierte User wenn weniger als 5 existieren
  if (userIds.length < 5) {
    print('👥 Nur ${userIds.length} User gefunden - erstelle weitere simulierte User...\n');
    final newUserIds = await _createSimulatedUsers(
      firestore, 
      teamIds, 
      random,
      userCount: 10 - userIds.length, // Fülle auf 10 User auf
    );
    userIds.addAll(newUserIds);
  }

  print('📊 Gefunden: ${groupStageMatches.length} Gruppenphase-Matches, ${teams.length} Teams, ${userIds.length} User\n');

  // ===== SCHRITT 1: Tipps erstellen =====
  print('📝 Erstelle Tipps für alle User...\n');
  await _createGroupStageTips(
    firestore,
    groupStageMatches,
    userIds,
    random,
    tipRepository,
  );

  // ===== SCHRITT 2: Ergebnisse simulieren =====
  print('\n⚽ Simuliere Ergebnisse...\n');
  int processedMatches = 0;
  int skippedMatches = 0;

  print('📋 Prüfe ${groupStageMatches.length} Matches...');

  for (final match in groupStageMatches) {
    print('   Prüfe Match: ${match.id} (hasResult: ${match.hasResult}, home: ${match.homeTeamId}, guest: ${match.guestTeamId})');
    
    // Überspringe Matches die bereits Ergebnisse haben
    if (match.hasResult) {
      print('⏭️  ${match.id} hat bereits Ergebnis: ${match.homeScore}-${match.guestScore}');
      skippedMatches++;
      continue;
    }

    // Überspringe TBD-Matches
    if (match.homeTeamId == 'TBD' || match.guestTeamId == 'TBD') {
      print('⏭️  ${match.id} wartet auf Team-Festlegung');
      skippedMatches++;
      continue;
    }

    final homeTeam = teams[match.homeTeamId];
    final guestTeam = teams[match.guestTeamId];

    if (homeTeam == null || guestTeam == null) {
      print('⚠️  Teams nicht gefunden für ${match.id} (home: ${match.homeTeamId}, guest: ${match.guestTeamId})');
      print('   Verfügbare Team-IDs: ${teams.keys.toList()}');
      skippedMatches++;
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
    print('⚽ ${match.id}: ${homeTeam['name']} ${result['home']} - ${result['guest']} ${guestTeam['name']}');
    processedMatches++;

    // Punkte für dieses Match berechnen
    try {
      await recalculateUseCase(match: updatedMatch);
      print('   ✅ Punkte neuberechnet');
    } catch (e) {
      print('   ❌ Fehler bei Neuberechnung: $e');
    }
  }

  print('\n✅ $processedMatches Matches simuliert, $skippedMatches übersprungen');
  print('🏆 Gruppenphase Simulation abgeschlossen!');
}

/// Simuliert die K.O.-Phase (matchDay 4-8) mit echten DB-Daten
/// Erstellt Tips und bestimmt nach dem Finale den Champion
Future<void> simulateKnockoutStageFromDB() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();

  print('🏆 Starte K.O.-Phase Simulation (matchDay 4-8) mit DB-Daten...\n');

  final matchRepository = sl<MatchRepository>();
  final teamRepository = sl<TeamRepository>();
  final tipRepository = sl<TipRepository>();
  final recalculateUseCase = sl<RecalculateMatchTipsUseCase>();

  // Hole alle Matches aus DB
  var matchesResult = await matchRepository.getAllMatches();
  var matches = matchesResult.fold(
    (failure) {
      print('❌ Fehler beim Laden der Matches: $failure');
      return <CustomMatch>[];
    },
    (matches) => matches,
  );

  // Filtere nur K.O.-Phase Matches (matchDay 4-8), sortiert nach matchDay
  var knockoutMatches = matches.where((m) => m.matchDay >= 4).toList()
    ..sort((a, b) => a.matchDay.compareTo(b.matchDay));

  // Hole alle User und deren Champion-IDs
  final usersSnap = await firestore.collection('users').get();
  final userIds = usersSnap.docs.map((doc) => doc.id).toList();
  
  // Debug: Zeige was in der DB steht
  print('🔍 Debug - User Champion-IDs aus DB:');
  for (final doc in usersSnap.docs) {
    final data = doc.data();
    final champId = data['champion_id'];
    final userName = data['name'] ?? doc.id;
    print('   👤 $userName → Champion: "$champId"');
  }

  final userChampionIds = usersSnap.docs
      .map((doc) => doc.data()['champion_id'] as String?)
      .where((id) => id != null && id.isNotEmpty && id != 'TBD')
      .cast<String>()
      .toSet();

  // Hole alle Teams
  final teamsSnap = await firestore.collection('teams').get();
  final teams = {for (var doc in teamsSnap.docs) doc.id: doc.data()};
  final teamIds = teams.keys.toList();

  print('📊 Gefunden: ${knockoutMatches.length} K.O.-Matches, ${teams.length} Teams, ${userIds.length} User');
  print('🎯 User-Champions (unique): $userChampionIds\n');

  if (knockoutMatches.isEmpty) {
    print('⚠️  Keine K.O.-Matches gefunden!');
    return;
  }

  // ===== SCHRITT 0: Teams für TBD-Matches zuweisen =====
  final hasTbdMatches = knockoutMatches.any(
    (m) => m.homeTeamId == 'TBD' || m.guestTeamId == 'TBD'
  );
  
  if (hasTbdMatches) {
    print('🔄 Weise Teams für K.O.-Matches zu...\n');
    await _assignKnockoutTeams(
      knockoutMatches,
      teamIds,
      userChampionIds,
      matchRepository,
      random,
    );
    
    // Matches neu laden nach Team-Zuweisung
    matchesResult = await matchRepository.getAllMatches();
    matches = matchesResult.fold(
      (failure) => <CustomMatch>[],
      (matches) => matches,
    );
    knockoutMatches = matches.where((m) => m.matchDay >= 4).toList()
      ..sort((a, b) => a.matchDay.compareTo(b.matchDay));
    print('');
  }

  // ===== SCHRITT 1: Tipps erstellen =====
  print('📝 Erstelle Tipps für alle User...\n');
  await _createKnockoutStageTips(
    firestore,
    knockoutMatches,
    userIds,
    random,
    tipRepository,
  );

  // ===== SCHRITT 2: Ergebnisse simulieren =====
  print('\n⚽ Simuliere Ergebnisse...\n');
  int processedMatches = 0;
  int skippedMatches = 0;
  CustomMatch? finaleMatch;

  for (final match in knockoutMatches) {
    // Überspringe Matches die bereits Ergebnisse haben
    if (match.hasResult) {
      print('⏭️  ${match.id} (Tag ${match.matchDay}) hat bereits Ergebnis: ${match.homeScore}-${match.guestScore}');
      skippedMatches++;
      
      // Speichere Finale für Champion-Bestimmung
      if (match.matchDay == 8) {
        finaleMatch = match;
      }
      continue;
    }

    // Überspringe TBD-Matches (sollte nach _assignKnockoutTeams nicht mehr vorkommen)
    if (match.homeTeamId == 'TBD' || match.guestTeamId == 'TBD') {
      print('⏭️  ${match.id} (Tag ${match.matchDay}) wartet auf Team-Festlegung');
      skippedMatches++;
      continue;
    }

    final homeTeam = teams[match.homeTeamId];
    final guestTeam = teams[match.guestTeamId];

    if (homeTeam == null || guestTeam == null) {
      print('⚠️  Teams nicht gefunden für ${match.id} (home: ${match.homeTeamId}, guest: ${match.guestTeamId})');
      skippedMatches++;
      continue;
    }

    // Simuliere Ergebnis
    Map<String, int> result;
    
    // FINALE: User-Champion gewinnt garantiert!
    if (match.matchDay == 8) {
      result = _calculateFinaleResult(match, userChampionIds, random);
      print('🏆 FINALE: User-Champion gewinnt!');
    } else {
      // Normale K.O.-Runde: Kein Unentschieden möglich
      result = _calculateKnockoutResult(
        homeTeam['win_points'] as int? ?? 20,
        guestTeam['win_points'] as int? ?? 20,
        random,
      );
    }

    // Update Match mit Ergebnis
    final updatedMatch = match.copyWith(
      homeScore: result['home'],
      guestScore: result['guest'],
    );

    await matchRepository.updateMatch(updatedMatch);
    print('⚽ ${match.id} (Tag ${match.matchDay}): ${homeTeam['name']} ${result['home']} - ${result['guest']} ${guestTeam['name']}');
    processedMatches++;

    // Punkte für dieses Match berechnen
    try {
      await recalculateUseCase(match: updatedMatch);
      print('   ✅ Punkte neuberechnet');
    } catch (e) {
      print('   ❌ Fehler bei Neuberechnung: $e');
    }

    // Speichere Finale für Champion-Bestimmung
    if (match.matchDay == 8) {
      finaleMatch = updatedMatch;
    }
  }

  print('\n✅ $processedMatches Matches simuliert, $skippedMatches übersprungen');

  // ===== CHAMPION BESTIMMEN =====
  if (finaleMatch != null && finaleMatch.hasResult) {
    await _determineChampion(finaleMatch, teams, teamRepository);
  } else {
    print('\n⚠️  Finale noch nicht gespielt - kein Champion bestimmt');
  }

  print('🏆 K.O.-Phase Simulation abgeschlossen!');
}

// ==================== HELPER FUNCTIONS ====================

/// Berechnet Match-Ergebnis basierend auf Team-Stärke (Gruppenphase)
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

/// Berechnet Match-Ergebnis für K.O.-Phase (kein Unentschieden)
Map<String, int> _calculateKnockoutResult(
  int homePower,
  int guestPower,
  Random random,
) {
  final powerDiff = homePower - guestPower;
  final homeWinChance = 0.5 + (powerDiff / 100);

  var homeGoals = random.nextInt(4) + (homeWinChance > 0.6 ? 1 : 0);
  var guestGoals = random.nextInt(4) + (homeWinChance < 0.4 ? 1 : 0);

  // K.O.-Phase: Bei Unentschieden einen zufälligen Sieger bestimmen
  while (homeGoals == guestGoals) {
    if (random.nextDouble() < homeWinChance) {
      homeGoals++;
    } else {
      guestGoals++;
    }
  }

  return {'home': homeGoals, 'guest': guestGoals};
}

/// Weist zufällige Teams den K.O.-Matches zu
/// Stellt sicher dass mindestens ein User-Champion im Finale ist
Future<void> _assignKnockoutTeams(
  List<CustomMatch> knockoutMatches,
  List<String> teamIds,
  Set<String> userChampionIds,
  MatchRepository matchRepository,
  Random random,
) async {
  if (teamIds.isEmpty) {
    print('⚠️  Keine Teams verfügbar für Zuweisung!');
    return;
  }

  // Validiere: Nur User-Champions die auch als Team existieren
  final validUserChampions = userChampionIds.where((id) => teamIds.contains(id)).toSet();
  
  print('   📋 Alle Team-IDs: $teamIds');
  print('   📋 User-Champion-IDs (roh): $userChampionIds');
  print('   📋 Valide User-Champions: $validUserChampions');

  // Wähle einen User-Champion der garantiert ins Finale kommt
  String guaranteedChampion;
  if (validUserChampions.isNotEmpty) {
    guaranteedChampion = validUserChampions.elementAt(random.nextInt(validUserChampions.length));
    print('🎯 Garantierter Finalist (User-Champion): $guaranteedChampion');
  } else {
    guaranteedChampion = teamIds[random.nextInt(teamIds.length)];
    print('⚠️  Kein valider User-Champion gefunden! Nutze zufälliges Team: $guaranteedChampion');
  }

  // Gruppiere Matches nach matchDay
  final matchesByDay = <int, List<CustomMatch>>{};
  for (final match in knockoutMatches) {
    matchesByDay.putIfAbsent(match.matchDay, () => []).add(match);
  }

  // Weise Teams pro Runde zu
  for (final day in matchesByDay.keys.toList()..sort()) {
    final dayMatches = matchesByDay[day]!;
    final shuffledTeams = List<String>.from(teamIds)..shuffle(random);
    var teamIndex = 0;

    for (final match in dayMatches) {
      // Überspringe bereits zugewiesene Matches
      if (match.homeTeamId != 'TBD' && match.guestTeamId != 'TBD') {
        continue;
      }

      String homeTeamId;
      String guestTeamId;

      // FINALE (Tag 8): Garantiere User-Champion als Teilnehmer
      if (day == 8) {
        homeTeamId = guaranteedChampion;
        // Wähle anderen Team für Gegner
        guestTeamId = shuffledTeams.firstWhere(
          (id) => id != guaranteedChampion,
          orElse: () => shuffledTeams[0],
        );
        print('   🏆 Finale: $homeTeamId vs $guestTeamId (Champion garantiert)');
      } else {
        // Normale Runde: Zufällige Teams
        homeTeamId = shuffledTeams[teamIndex % shuffledTeams.length];
        teamIndex++;
        guestTeamId = shuffledTeams[teamIndex % shuffledTeams.length];
        teamIndex++;
      }

      final updatedMatch = match.copyWith(
        homeTeamId: homeTeamId,
        guestTeamId: guestTeamId,
      );

      await matchRepository.updateMatch(updatedMatch);
      print('   ✅ Tag $day: ${match.id} → $homeTeamId vs $guestTeamId');
    }
  }
}

/// Berechnet Finale-Ergebnis: User-Champion gewinnt garantiert
Map<String, int> _calculateFinaleResult(
  CustomMatch finaleMatch,
  Set<String> userChampionIds,
  Random random,
) {
  final isHomeChampion = userChampionIds.contains(finaleMatch.homeTeamId);
  final isGuestChampion = userChampionIds.contains(finaleMatch.guestTeamId);

  // Bestimme wer gewinnen soll
  bool homeWins;
  if (isHomeChampion && !isGuestChampion) {
    homeWins = true;
  } else if (isGuestChampion && !isHomeChampion) {
    homeWins = false;
  } else {
    // Beide oder keiner ist Champion → Home gewinnt (einer davon ist garantiert Champion)
    homeWins = true;
  }

  // Generiere Ergebnis wo Gewinner mehr Tore hat
  final winnerGoals = random.nextInt(3) + 1; // 1-3 Tore
  final loserGoals = random.nextInt(winnerGoals); // 0 bis (winner-1)

  if (homeWins) {
    return {'home': winnerGoals, 'guest': loserGoals};
  } else {
    return {'home': loserGoals, 'guest': winnerGoals};
  }
}

/// Erstellt Tipps für Gruppenphase mit Joker-Limit (3 pro Phase)
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
    // Joker-Budget für GESAMTE Gruppenphase: 3 Joker für matchDay 1-3
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
        final isGroupStageMatch = matches.any((m) => m.id == tipMatchId);
        if (isGroupStageMatch) {
          jokerBudget--;
        }
      }
    }

    print('👤 User $userId: $jokerBudget Joker verfügbar');

    int tipsCreatedForUser = 0;
    const maxTipsPerUser = 20; // Nur 20 Tips pro User in Gruppenphase

    for (final match in matches) {
      // Überspringe wenn 20 Tips bereits erstellt
      if (tipsCreatedForUser >= maxTipsPerUser) {
        print('   ℹ️  Max $maxTipsPerUser Tips für diesen User erreicht');
        break;
      }

      // Überspringe TBD-Matches
      if (match.homeTeamId == 'TBD' || match.guestTeamId == 'TBD') {
        continue;
      }

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
      tipsCreatedForUser++;
    }
  }

  print('✅ $totalTips Tipps erstellt, $skippedTips übersprungen');
}

/// Erstellt Tipps für K.O.-Phase mit Joker-Limits pro Phase
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
    MatchPhase.roundOf16: 4,
    MatchPhase.quarterFinal: 2,
    MatchPhase.semiFinal: 1,
    MatchPhase.finalStage: 2,
  };

  for (final userId in userIds) {
    final jokerBudgets = Map<MatchPhase, int>.from(jokerLimits);
    final userStrategy = random.nextInt(4);

    // Zähle bereits verwendete Joker pro Phase
    final existingJokersSnap = await firestore
        .collection('tips')
        .where('userId', isEqualTo: userId)
        .where('joker', isEqualTo: true)
        .get();

    for (final doc in existingJokersSnap.docs) {
      final tipMatchId = doc.data()['matchId'] as String?;
      if (tipMatchId != null) {
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

    for (final match in matches) {
      // Überspringe TBD-Matches
      if (match.homeTeamId == 'TBD' || match.guestTeamId == 'TBD') {
        continue;
      }

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

      // Generiere Tipp
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
      ? 0.25
      : matchDay == 5
          ? 0.30
          : matchDay == 6
              ? 0.40
              : 0.50;

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

/// Bestimmt den Champion nach dem Finale
Future<void> _determineChampion(
  CustomMatch finaleMatch,
  Map<String, Map<String, dynamic>> teams,
  TeamRepository teamRepository,
) async {
  print('\n🏆 Bestimme Champion...');

  final homeScore = finaleMatch.homeScore ?? 0;
  final guestScore = finaleMatch.guestScore ?? 0;

  String championId;
  if (homeScore > guestScore) {
    championId = finaleMatch.homeTeamId;
  } else {
    championId = finaleMatch.guestTeamId;
  }

  final championData = teams[championId];
  if (championData == null) {
    print('❌ Champion-Team nicht gefunden: $championId');
    return;
  }

  print('🥇 Champion: ${championData['name']} (ID: $championId)');

  // Erstelle Team-Objekt und setze champion = true
  final championTeam = Team(
    id: championId,
    name: championData['name'] as String? ?? '',
    flagCode: championData['flag_code'] as String? ?? '',
    winPoints: championData['win_points'] as int? ?? 20,
    champion: true,
  );

  final result = await teamRepository.updateTeam(championTeam);
  result.fold(
    (failure) => print('❌ Fehler beim Setzen des Champions: $failure'),
    (_) => print('✅ ${championData['name']} als Champion in DB gesetzt!'),
  );
}

/// Erstellt simulierte User in Firestore (ohne Firebase Auth)
/// Gibt Liste der erstellten User-IDs zurück
Future<List<String>> _createSimulatedUsers(
  FirebaseFirestore firestore,
  List<String> teamIds,
  Random random, {
  int userCount = 10,
}) async {
  final uuid = const Uuid();
  final userIds = <String>[];
  
  // Deutsche Vornamen für realistischere Namen
  final firstNames = [
    'Max', 'Paul', 'Leon', 'Felix', 'Jonas', 'Lukas', 'Tim', 'Tom', 'Jan', 'Nico',
    'Anna', 'Lena', 'Marie', 'Sophie', 'Laura', 'Lisa', 'Julia', 'Sarah', 'Emma', 'Mia',
  ];
  
  final lastNames = [
    'Müller', 'Schmidt', 'Schneider', 'Fischer', 'Weber', 'Meyer', 'Wagner', 'Becker',
    'Schulz', 'Hoffmann', 'Koch', 'Richter', 'Klein', 'Wolf', 'Schröder', 'Neumann',
  ];

  print('👥 Erstelle $userCount simulierte User...\n');

  for (int i = 0; i < userCount; i++) {
    final id = uuid.v4();
    final firstName = firstNames[random.nextInt(firstNames.length)];
    final lastName = lastNames[random.nextInt(lastNames.length)];
    final name = '$firstName $lastName';
    final email = '${firstName.toLowerCase()}.${lastName.toLowerCase()}${i + 1}@test.com';
    
    // Zufälliger Champion aus verfügbaren Teams
    final championId = teamIds[random.nextInt(teamIds.length)];

    await firestore.collection('users').doc(id).set({
      'id': id,
      'champion_id': championId,
      'email': email,
      'name': name,
      'rank': i + 1,
      'score': 0,
      'jokerSum': 0,
      'sixer': 0,
      'admin': false,
    });

    userIds.add(id);
    print('✅ User erstellt: $name (Champion: $championId)');
  }

  print('\n✅ $userCount User erfolgreich erstellt!\n');
  return userIds;
}

/// Erstellt Test-Matches für die Simulation
/// - 1 Match aus der Vergangenheit (mit Ergebnis) → darf nicht geändert werden
/// - 1 Match ohne Ergebnis → soll simuliert werden
Future<void> createTestMatches() async {
  final firestore = FirebaseFirestore.instance;
  final matchRepository = sl<MatchRepository>();
  
  print('📋 Erstelle Test-Matches...\n');

  // Hole Teams
  final teamsSnap = await firestore.collection('teams').get();
  final teamsList = teamsSnap.docs.map((doc) => doc.data()).toList();
  
  if (teamsList.length < 2) {
    print('❌ Mindestens 2 Teams erforderlich!');
    return;
  }

  final team1 = teamsList[0];
  final team2 = teamsList[1];
  
  final team1Id = team1['id'] as String? ?? '';
  final team2Id = team2['id'] as String? ?? '';
  final team1Name = team1['name'] as String? ?? 'Team 1';
  final team2Name = team2['name'] as String? ?? 'Team 2';

  // Match 1: Vergangenheit mit Ergebnis (darf nicht geändert werden)
  final pastMatch = CustomMatch(
    id: 'test_past_${DateTime.now().millisecondsSinceEpoch}',
    homeTeamId: team1Id,
    guestTeamId: team2Id,
    matchDate: DateTime.now().subtract(const Duration(days: 5)),
    matchDay: 1,
    homeScore: 2,
    guestScore: 1,
  );

  await matchRepository.createMatch(pastMatch);
  print('✅ Test-Match aus Vergangenheit erstellt:');
  print('   → $team1Name 2 - 1 $team2Name');
  print('   → Hat bereits Ergebnis → sollte NICHT aktualisiert werden\n');

  // Match 2: Heute ohne Ergebnis (soll simuliert werden)
  final futureMatch = CustomMatch(
    id: 'test_future_${DateTime.now().millisecondsSinceEpoch}',
    homeTeamId: team2Id,
    guestTeamId: team1Id,
    matchDate: DateTime.now(),
    matchDay: 2,
    homeScore: null,
    guestScore: null,
  );

  await matchRepository.updateMatch(futureMatch);
  print('✅ Test-Match ohne Ergebnis erstellt:');
  print('   → $team2Name vs $team1Name');
  print('   → Kein Ergebnis → sollte simuliert werden\n');

  print('🏆 Test-Matches erfolgreich erstellt!');
}
