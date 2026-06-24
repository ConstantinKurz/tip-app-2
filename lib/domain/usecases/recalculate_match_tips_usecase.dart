import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/user.dart'; // AppUser

import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/domain/repositories/team_repository.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/repositories/user_repository.dart';
import 'package:flutter_web/domain/usecases/tip_calculator_usecase.dart';

class RecalculateMatchTipsUseCase {
  final TipRepository tipRepository;
  final UserRepository userRepository;
  final MatchRepository matchRepository;
  final TeamRepository teamRepository;

  // ✅ Cache für Finale-Match und Champion-Team (werden nur einmal geladen)
  CustomMatch? _cachedFinalMatch;
  Team? _cachedChampionTeam;
  String? _cachedChampionId;
  List<CustomMatch>? _cachedAllMatches;

  // ✅ NEU: User-Cache für Batch-Operationen (vermeidet 1000+ getUserById Aufrufe)
  Map<String, dynamic>? _cachedUsersById;

  // ✅ NEU: Sammelt betroffene User über mehrere Match-Aufrufe hinweg
  final Set<String> _pendingAffectedUsers = {};

  RecalculateMatchTipsUseCase({
    required this.tipRepository,
    required this.userRepository,
    required this.matchRepository,
    required this.teamRepository,
  });

  /// Lädt alle benötigten Daten einmal und cached sie
  Future<void> _loadSharedData() async {
    if (_cachedAllMatches != null && _cachedUsersById != null) {
      return; // Bereits geladen
    }

    // ✅ Lade alle User EINMAL (statt 1000+ einzelne getUserById Aufrufe)
    if (_cachedUsersById == null) {
      final allUsersResult = await userRepository.getAllUsers();
      allUsersResult.fold(
        (failure) {
          debugPrint('❌ Fehler beim Laden aller User: $failure');
          _cachedUsersById = {};
        },
        (users) {
          _cachedUsersById = {for (var user in users) user.id: user};
          debugPrint(
              '📦 [RecalculateMatchTipsUseCase] ${users.length} User gecached (1 Read statt ${users.length * 104} Reads)');
        },
      );
    }

    if (_cachedAllMatches != null) return;

    final allMatchesResult = await matchRepository.getAllMatches();
    await allMatchesResult.fold(
      (failure) async {
        debugPrint('❌ Fehler beim Laden aller Matches: $failure');
      },
      (allMatches) async {
        _cachedAllMatches = allMatches;

        // Finde das Finale-Match: das ZEITLICH LETZTE Spiel mit matchDay 8
        // (nicht das Spiel um Platz 3, das früher stattfindet)
        final matchDay8Matches = allMatches
            .where((m) => m.matchDay == 8 && m.hasResult)
            .toList()
          ..sort((a, b) => b.matchDate.compareTo(a.matchDate));

        _cachedFinalMatch =
            matchDay8Matches.isNotEmpty ? matchDay8Matches.first : null;

        if (_cachedFinalMatch != null) {
          final homeScore = _cachedFinalMatch!.homeScore ?? 0;
          final guestScore = _cachedFinalMatch!.guestScore ?? 0;

          // Champion ermitteln: Bei Unentschieden (Elfmeterschießen) nutze team.champion Flag
          if (homeScore > guestScore) {
            _cachedChampionId = _cachedFinalMatch!.homeTeamId;
          } else if (homeScore < guestScore) {
            _cachedChampionId = _cachedFinalMatch!.guestTeamId;
          } else {
            // Unentschieden → Champion aus team.champion Flag ermitteln
            final allTeamsResult = await teamRepository.getAll();
            allTeamsResult.fold(
              (failure) {
                debugPrint(
                    '❌ Fehler beim Laden der Teams für Champion-Ermittlung: $failure');
              },
              (teams) {
                final champion = teams.cast<Team?>().firstWhere(
                      (t) => t != null && t.champion,
                      orElse: () => null,
                    );
                if (champion != null) {
                  _cachedChampionId = champion.id;
                  _cachedChampionTeam = champion;
                  debugPrint(
                      '🏆 Champion bei Unentschieden aus Flag ermittelt: ${champion.name}');
                } else {
                  debugPrint(
                      '⚠️ Finale unentschieden, aber kein Team als Champion markiert!');
                }
              },
            );
          }

          // Lade Champion-Team einmal (falls nicht bereits durch Unentschieden-Logik geladen)
          if (_cachedChampionId != null && _cachedChampionTeam == null) {
            final championTeamResult =
                await teamRepository.getById(_cachedChampionId!);
            championTeamResult.fold(
              (failure) {},
              (team) {
                _cachedChampionTeam = team;
              },
            );
          }
        }
      },
    );
  }

  /// Löscht den Cache (z.B. nach einem Batch-Update)
  void clearCache() {
    _cachedFinalMatch = null;
    _cachedChampionTeam = null;
    _cachedChampionId = null;
    _cachedAllMatches = null;
    _cachedUsersById = null;
    _pendingAffectedUsers.clear();
  }

  /// Berechnet Punkte für alle Tips eines Matches neu
  /// [skipUserScoreUpdate]: Wenn true, werden User-Scores nicht aktualisiert (für Batch-Verarbeitung)
  Future<Either<TipFailure, Unit>> call({
    required CustomMatch match,
    bool skipUserScoreUpdate = false,
  }) async {
    if (!match.hasResult) {
      return right(unit); // Nichts zu berechnen
    }

    try {
      // ✅ Lade shared data einmal (cached)
      await _loadSharedData();

      // Hole alle Tips für dieses Match
      final allTips = await tipRepository.getTipsForMatch(match.id);
      final affectedUsers = <String>{};

      await allTips.fold(
        (failure) async {
          throw Exception('Tips konnten nicht geladen werden');
        },
        (tips) async {
          // Berechne Punkte für alle Tips neu
          for (final tip in tips) {
            affectedUsers.add(tip.userId);

            // Berechne Punkte neu mit TipCalculator
            int newPoints = TipCalculator.calculatePoints(
              tipHome: tip.tipHome ?? 0,
              tipGuest: tip.tipGuest ?? 0,
              actualHome: match.homeScore ?? 0,
              actualGuest: match.guestScore ?? 0,
              hasJoker: tip.joker,
              phase: match.phase,
            );

            // 🏆 FINALE: Champion-Bonus nur für das ECHTE Finale (zeitlich letztes Spiel)
            // Nicht für das Spiel um Platz 3 (auch matchDay 8, aber früher)
            if (_cachedFinalMatch != null &&
                match.id == _cachedFinalMatch!.id &&
                _cachedChampionId != null &&
                _cachedChampionTeam != null) {
              // ✅ OPTIMIERT: Nutze gecachten User statt getUserById
              final cachedUser = _cachedUsersById?[tip.userId] as AppUser?;
              if (cachedUser != null &&
                  cachedUser.championId == _cachedChampionId) {
                newPoints += _cachedChampionTeam!.winPoints;
                debugPrint(
                    '🏆 [Finale] Champion-Bonus für ${cachedUser.name}: +${_cachedChampionTeam!.winPoints} → Total: $newPoints');
              }
            }

            // Speichere Punkte, wenn unterschiedlich
            if (tip.points != newPoints) {
              await tipRepository.updatePoints(
                tipId: tip.id,
                points: newPoints,
              );
            }
          }
        },
      );

      // ✅ Sammle betroffene User für späteres Batch-Update
      _pendingAffectedUsers.addAll(affectedUsers);

      // ✅ Aktualisiere Score nur wenn nicht übersprungen (für Batch-Verarbeitung)
      if (!skipUserScoreUpdate) {
        await _updateUserScores(affectedUsers);
      }

      return right(unit);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  /// ✅ NEU: Aktualisiert User-Scores für alle gesammelten betroffenen User
  /// Wird nach der Verarbeitung aller Matches aufgerufen
  Future<void> updatePendingUserScores() async {
    if (_pendingAffectedUsers.isEmpty) return;

    debugPrint(
        '📦 Aktualisiere Scores für ${_pendingAffectedUsers.length} betroffene User...');
    await _updateUserScores(_pendingAffectedUsers);
    _pendingAffectedUsers.clear();
  }

  /// Berechnet Statistiken für User neu - OPTIMIERT mit Batch-Update
  Future<void> _updateUserScores(Set<String> userIds) async {
    if (userIds.isEmpty) return;

    // ✅ Sammle alle User-Updates für Batch-Operation
    final usersToUpdate = <AppUser>[];

    for (final userId in userIds) {
      try {
        final userTipsResult = await tipRepository.getTipsByUserId(userId);

        userTipsResult.fold(
          (failure) {
            debugPrint('❌ Fehler beim Laden der Tips für $userId: $failure');
          },
          (tips) {
            int totalScore = 0;
            int jokersUsed = 0;
            int perfectPredictions = 0;

            for (final tip in tips) {
              totalScore += tip.points ?? 0;

              // ✅ Zähle nur VERBRAUCHTE Joker (auf vergangene Spiele gesetzt)
              if (tip.joker && tip.matchId != null) {
                // Hole Match aus Cache und prüfe ob es bereits ein Ergebnis hat
                final match = _cachedAllMatches?.firstWhere(
                  (m) => m.id == tip.matchId,
                  orElse: () => CustomMatch.empty(),
                );
                // Nur Joker zählen, die auf Spiele mit Ergebnis gesetzt wurden
                if (match != null && match.id.isNotEmpty && match.hasResult) {
                  jokersUsed++;
                }
              }

              if ((tip.points ?? 0) == 6 && !tip.joker) {
                perfectPredictions++;
              }
            }

            // ✅ OPTIMIERT: Nutze gecachten User statt getUserById
            final cachedUser = _cachedUsersById?[userId] as AppUser?;
            if (cachedUser != null && cachedUser.id.isNotEmpty) {
              // Update User mit neuen Scores
              final updatedUser = cachedUser.copyWith(
                score: totalScore,
                jokerSum: jokersUsed,
                sixer: perfectPredictions,
              );

              // ✅ Zur Batch-Liste hinzufügen statt einzeln speichern
              usersToUpdate.add(updatedUser);

              // ✅ Cache aktualisieren für nachfolgende Lookups
              _cachedUsersById![userId] = updatedUser;
            } else {
              debugPrint('⚠️ User $userId nicht im Cache gefunden');
            }
          },
        );
      } catch (e) {
        debugPrint('❌ Fehler beim Berechnen der Scores für $userId: $e');
      }
    }

    // ✅ BATCH-UPDATE: Alle User in EINEM Firestore-Write
    if (usersToUpdate.isNotEmpty) {
      await userRepository.batchUpdateUsers(usersToUpdate);
      debugPrint(
          '📦 ${usersToUpdate.length} User-Scores per Batch aktualisiert');
    }
  }

  /// Aktualisiert Rankings für alle User mit Tiebreaker-Logik - OPTIMIERT
  Future<void> updateAllUserRankings() async {
    try {
      // ✅ Verwende gecachte User statt erneut zu laden
      List<AppUser> users;
      if (_cachedUsersById != null && _cachedUsersById!.isNotEmpty) {
        users = _cachedUsersById!.values.cast<AppUser>().toList();
        debugPrint('📦 [Ranking] Verwende ${users.length} gecachte User');
      } else {
        // Fallback: Lade User falls Cache leer
        final allUsersResult = await userRepository.getAllUsers();
        final result = allUsersResult.fold(
          (failure) {
            debugPrint(
                '❌ Fehler beim Laden aller User für Ranking-Update: $failure');
            return <AppUser>[];
          },
          (loadedUsers) => loadedUsers,
        );
        users = result;
      }

      if (users.isEmpty) return;

      // Sortiere mit komplexer Tiebreaker-Logik
      final sortedUsers = List.from(users)
        ..sort((a, b) {
          // 1. Nach Punkten (höher = besser)
          final scoreComparison = b.score.compareTo(a.score);
          if (scoreComparison != 0) return scoreComparison;

          // 2. Bei gleichen Punkten: Mehr Sechser = besser
          final sixersComparison = b.sixer.compareTo(a.sixer);
          if (sixersComparison != 0) return sixersComparison;

          // 3. Bei gleichen 6ern: Weniger Joker = besser
          final jokerComparison = a.jokerSum.compareTo(b.jokerSum);
          if (jokerComparison != 0) return jokerComparison;

          // 4. Letzter Tiebreaker: Alphabetisch nach Namen
          return a.name.compareTo(b.name);
        });

      // ✅ Sammle nur User mit geändertem Rang
      final usersToUpdate = <AppUser>[];
      for (int i = 0; i < sortedUsers.length; i++) {
        final user = sortedUsers[i];
        final newRank = i + 1;

        if (user.rank != newRank) {
          usersToUpdate.add(user.copyWith(rank: newRank));
        }
      }

      // ✅ BATCH-UPDATE: Alle User in EINEM Firestore-Write (statt 43 einzelne)
      if (usersToUpdate.isNotEmpty) {
        await userRepository.batchUpdateUsers(usersToUpdate);
      }

      debugPrint(
          '✅ Rankings für ${usersToUpdate.length}/${sortedUsers.length} User aktualisiert (1 Batch)');

      // ✅ Cache leeren nach Ranking-Update
      clearCache();
    } catch (e) {
      debugPrint('❌ Fehler beim Ranking-Update: $e');
    }
  }

  /// ✅ NEU: Berechnet ALLE User-Statistiken neu (jokerSum, score, sixer)
  /// UND korrigiert Tipp-Punkte für Spiele ohne Ergebnis!
  Future<Either<TipFailure, Unit>> recalculateAllUserStatistics() async {
    try {
      debugPrint('🔄 Starte Neuberechnung aller User-Statistiken...');

      // ✅ Lade shared data einmal (cached)
      await _loadSharedData();

      // Hole alle User
      final allUsersResult = await userRepository.getAllUsers();

      return await allUsersResult.fold(
        (failure) async {
          debugPrint('❌ Fehler beim Laden aller User: $failure');
          return left(failure);
        },
        (allUsers) async {
          int correctedTipsCount = 0;
          // ✅ Sammle alle User-Updates für Batch-Operation
          final usersToUpdate = <AppUser>[];

          for (final user in allUsers) {
            try {
              final userTipsResult =
                  await tipRepository.getTipsByUserId(user.id);

              userTipsResult.fold(
                (failure) {
                  debugPrint(
                      '❌ Fehler beim Laden der Tips für ${user.name}: $failure');
                },
                (tips) {
                  int totalScore = 0;
                  int jokersUsed = 0;
                  int perfectPredictions = 0;

                  for (final tip in tips) {
                    // ✅ Hole das Match für diesen Tipp
                    final match = _cachedAllMatches?.firstWhere(
                      (m) => m.id == tip.matchId,
                      orElse: () => CustomMatch.empty(),
                    );

                    final matchHasResult =
                        match != null && match.id.isNotEmpty && match.hasResult;

                    // ✅ KORREKTUR: Wenn Match KEIN Ergebnis hat, aber Tipp hat Punkte → Reset!
                    if (!matchHasResult &&
                        tip.points != null &&
                        tip.points != 0) {
                      // Note: tipRepository.updatePoints wird separat behandelt (kein Batch für Tips)
                      tipRepository.updatePoints(tipId: tip.id, points: 0);
                      correctedTipsCount++;
                      debugPrint(
                          '🔧 Tipp ${tip.id} korrigiert: Punkte auf 0 gesetzt (Match ohne Ergebnis)');
                      // Punkte nicht zum Score addieren
                    }
                    // ✅ Wenn Match Ergebnis hat, Punkte neu berechnen
                    else if (matchHasResult) {
                      final newPoints = TipCalculator.calculatePoints(
                        tipHome: tip.tipHome ?? 0,
                        tipGuest: tip.tipGuest ?? 0,
                        actualHome: match.homeScore ?? 0,
                        actualGuest: match.guestScore ?? 0,
                        hasJoker: tip.joker,
                        phase: match.phase,
                      );

                      // Update Punkte wenn unterschiedlich
                      if (tip.points != newPoints) {
                        tipRepository.updatePoints(
                            tipId: tip.id, points: newPoints);
                        correctedTipsCount++;
                        debugPrint(
                            '🔧 Tipp ${tip.id} korrigiert: ${tip.points} → $newPoints');
                      }

                      totalScore += newPoints;

                      // Zähle Sechser (ohne Joker)
                      if (newPoints == 6 && !tip.joker) {
                        perfectPredictions++;
                      }

                      // Zähle verbrauchte Joker
                      if (tip.joker) {
                        jokersUsed++;
                      }
                    }
                  }

                  // ✅ Zur Batch-Liste hinzufügen, wenn Werte unterschiedlich sind
                  if (user.score != totalScore ||
                      user.jokerSum != jokersUsed ||
                      user.sixer != perfectPredictions) {
                    final updatedUser = user.copyWith(
                      score: totalScore,
                      jokerSum: jokersUsed,
                      sixer: perfectPredictions,
                    );
                    usersToUpdate.add(updatedUser);
                    debugPrint(
                        '✅ ${user.name}: Score=$totalScore, Joker=$jokersUsed, Sixer=$perfectPredictions');
                  }
                },
              );
            } catch (e) {
              debugPrint('❌ Fehler bei User ${user.name}: $e');
            }
          }

          // ✅ BATCH-UPDATE: Alle User in EINEM Firestore-Write
          if (usersToUpdate.isNotEmpty) {
            await userRepository.batchUpdateUsers(usersToUpdate);
          }

          debugPrint(
              '✅ Neuberechnung abgeschlossen: ${usersToUpdate.length} User aktualisiert (1 Batch), $correctedTipsCount Tipps korrigiert');

          // ✅ Cache leeren nach Neuberechnung
          clearCache();

          return right(unit);
        },
      );
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }
}
