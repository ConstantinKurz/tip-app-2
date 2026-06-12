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
  final Set<String> _dirtyUserIds = {};

  RecalculateMatchTipsUseCase({
    required this.tipRepository,
    required this.userRepository,
    required this.matchRepository,
    required this.teamRepository,
  });

  /// Lädt alle benötigten Daten einmal und cached sie
  Future<void> _loadSharedData() async {
    if (_cachedAllMatches != null && _cachedUsersById != null)
      return; // Bereits geladen

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
    _dirtyUserIds.clear();
  }

  /// Berechnet Punkte für alle Tips eines Matches neu
  /// und aktualisiert User-Scores
  Future<Either<TipFailure, Unit>> call({
    required CustomMatch match,
  }) async {
    if (!match.hasResult) {
      return right(unit); // Nichts zu berechnen
    }

    try {
      // ✅ Lade shared data einmal (cached)
      await _loadSharedData();
      final allTips = await tipRepository.getTipsForMatch(match.id);
      final affectedUsers = <String>{};
      final pointsToUpdate = <String, int>{};

      await allTips.fold(
        (failure) async {
          throw Exception('Tips konnten nicht geladen werden');
        },
        (tips) async {
          for (final tip in tips) {
            affectedUsers.add(tip.userId);

            int newPoints = TipCalculator.calculatePoints(
              tipHome: tip.tipHome ?? 0,
              tipGuest: tip.tipGuest ?? 0,
              actualHome: match.homeScore ?? 0,
              actualGuest: match.guestScore ?? 0,
              hasJoker: tip.joker,
              phase: match.phase,
            );

            if (_cachedFinalMatch != null &&
                match.id == _cachedFinalMatch!.id &&
                _cachedChampionId != null &&
                _cachedChampionTeam != null) {
              final cachedUser = _cachedUsersById?[tip.userId] as AppUser?;

              if (cachedUser != null &&
                  cachedUser.championId == _cachedChampionId) {
                newPoints += _cachedChampionTeam!.winPoints;

                debugPrint(
                  '🏆 [Finale] Champion-Bonus für ${cachedUser.name}: '
                  '+${_cachedChampionTeam!.winPoints} → Total: $newPoints',
                );
              }
            }

            if (tip.points != newPoints) {
              pointsToUpdate[tip.id] = newPoints;
            }
          }
        },
      );

      if (pointsToUpdate.isNotEmpty) {
        final updateResult = await tipRepository.updatePointsBatch(
          pointsByTipId: pointsToUpdate,
        );

        updateResult.fold(
          (failure) {
            throw Exception(
                'Tipp-Punkte konnten nicht batchweise aktualisiert werden');
          },
          (_) {
            debugPrint(
              '✅ ${pointsToUpdate.length} Tipp-Punkte batchweise aktualisiert',
            );
          },
        );
      }

      // ✅ Aktualisiere Score für alle betroffenen User (mit gecachten Daten)
      await _updateUserScores(affectedUsers);

      return right(unit);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  Future<void> _updateUserScores(Set<String> userIds) async {
    if (userIds.isEmpty) return;

    for (final userId in userIds) {
      try {
        final userTipsResult = await tipRepository.getTipsByUserId(userId);

        await userTipsResult.fold(
          (failure) async {
            debugPrint('❌ Fehler beim Laden der Tips für $userId: $failure');
          },
          (tips) async {
            int totalScore = 0;
            int jokersUsed = 0;
            int perfectPredictions = 0;

            for (final tip in tips) {
              totalScore += tip.points ?? 0;

              if (tip.joker && tip.matchId != null) {
                final match = _cachedAllMatches?.firstWhere(
                  (m) => m.id == tip.matchId,
                  orElse: () => CustomMatch.empty(),
                );

                if (match != null && match.id.isNotEmpty && match.hasResult) {
                  jokersUsed++;
                }
              }

              if ((tip.points ?? 0) == 6 && !tip.joker) {
                perfectPredictions++;
              }
            }

            final cachedUser = _cachedUsersById?[userId] as AppUser?;

            if (cachedUser != null && cachedUser.id.isNotEmpty) {
              final updatedUser = cachedUser.copyWith(
                score: totalScore,
                jokerSum: jokersUsed,
                sixer: perfectPredictions,
              );

              final hasChanged = cachedUser.score != updatedUser.score ||
                  cachedUser.jokerSum != updatedUser.jokerSum ||
                  cachedUser.sixer != updatedUser.sixer;

              if (hasChanged) {
                // ✅ Nur Cache aktualisieren, noch NICHT Firestore schreiben.
                _cachedUsersById![userId] = updatedUser;
                _dirtyUserIds.add(userId);
              }
            } else {
              debugPrint('⚠️ User $userId nicht im Cache gefunden');
            }
          },
        );
      } catch (e) {
        debugPrint('❌ Fehler beim Berechnen der Scores für $userId: $e');
      }
    }

    if (_dirtyUserIds.isNotEmpty) {
      debugPrint(
        '✅ Scores für ${_dirtyUserIds.length}/${userIds.length} User im Cache aktualisiert',
      );
    }
  }

  /// Aktualisiert Rankings für alle User mit olympischer Ranking-Logik.
  ///
  /// Olympisches Ranking bedeutet:
  /// - User mit identischen Ranking-Werten erhalten denselben Rang.
  /// - Der nächste Rang überspringt entsprechend die belegten Plätze.
  ///
  /// Beispiel:
  /// - Platz 1: User A
  /// - Platz 1: User B
  /// - Platz 3: User C
  ///
  /// Sortier- und Gleichstandslogik:
  /// 1. Mehr Punkte = besser
  /// 2. Mehr Sechser = besser
  /// 3. Weniger Joker = besser
  /// 4. Gleicher Name wird NICHT als Tiebreaker für gleiche Ränge verwendet.
  ///    Name dient nur zur stabilen Anzeige innerhalb gleicher Gruppen.
  Future<void> updateAllUserRankings() async {
    try {
      final cachedUsers = _cachedUsersById?.values.cast<AppUser>().toList();

      if (cachedUsers != null && cachedUsers.isNotEmpty) {
        await _updateRankingsForUsers(cachedUsers);
        clearCache();
        return;
      }

      final allUsersResult = await userRepository.getAllUsers();

      await allUsersResult.fold(
        (failure) async {
          debugPrint(
            '❌ Fehler beim Laden aller User für Ranking-Update: $failure',
          );
        },
        (users) async {
          await _updateRankingsForUsers(users);
        },
      );

      clearCache();
    } catch (e) {
      debugPrint('❌ Fehler beim Ranking-Update: $e');
    }
  }

  Future<void> _updateRankingsForUsers(List<AppUser> users) async {
    final sortedUsers = List<AppUser>.from(users)
      ..sort((a, b) {
        final scoreComparison = b.score.compareTo(a.score);
        if (scoreComparison != 0) return scoreComparison;

        final sixersComparison = b.sixer.compareTo(a.sixer);
        if (sixersComparison != 0) return sixersComparison;

        final jokerComparison = a.jokerSum.compareTo(b.jokerSum);
        if (jokerComparison != 0) return jokerComparison;

        return a.name.compareTo(b.name);
      });

    final usersToUpdate = <AppUser>[];

    int currentRank = 0;
    AppUser? previousUser;

    for (int i = 0; i < sortedUsers.length; i++) {
      final user = sortedUsers[i];
      final position = i + 1;

      final isSameRankAsPrevious = previousUser != null &&
          user.score == previousUser.score &&
          user.sixer == previousUser.sixer &&
          user.jokerSum == previousUser.jokerSum;

      if (!isSameRankAsPrevious) {
        currentRank = position;
      }

      previousUser = user;

      final rankChanged = user.rank != currentRank;
      final scoreChanged = _dirtyUserIds.contains(user.id);

      if (rankChanged || scoreChanged) {
        usersToUpdate.add(
          user.copyWith(rank: currentRank),
        );
      }
    }

    debugPrint(
      '📦 Users to update: ${usersToUpdate.length}/${sortedUsers.length}',
    );

    if (usersToUpdate.isNotEmpty) {
      await userRepository.updateUsersBatch(usersToUpdate);
    }

    debugPrint(
      '✅ Users für ${usersToUpdate.length}/${sortedUsers.length} User gemeinsam aktualisiert '
      '(score + rank, olympisch)',
    );
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
          int updatedUserCount = 0;
          int correctedTipsCount = 0;

          for (final user in allUsers) {
            try {
              final userTipsResult =
                  await tipRepository.getTipsByUserId(user.id);

              await userTipsResult.fold(
                (failure) async {
                  debugPrint(
                      '❌ Fehler beim Laden der Tips für ${user.name}: $failure');
                },
                (tips) async {
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
                      await tipRepository.updatePoints(
                          tipId: tip.id, points: 0);
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
                        await tipRepository.updatePoints(
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

                  // Update User, wenn Werte unterschiedlich sind
                  if (user.score != totalScore ||
                      user.jokerSum != jokersUsed ||
                      user.sixer != perfectPredictions) {
                    final updatedUser = user.copyWith(
                      score: totalScore,
                      jokerSum: jokersUsed,
                      sixer: perfectPredictions,
                    );
                    await userRepository.updateUser(updatedUser);
                    updatedUserCount++;
                    debugPrint(
                        '✅ ${user.name}: Score=$totalScore, Joker=$jokersUsed, Sixer=$perfectPredictions');
                  }
                },
              );
            } catch (e) {
              debugPrint('❌ Fehler bei User ${user.name}: $e');
            }
          }

          debugPrint(
              '✅ Neuberechnung abgeschlossen: $updatedUserCount User aktualisiert, $correctedTipsCount Tipps korrigiert');

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
