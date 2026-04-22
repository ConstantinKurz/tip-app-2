import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';

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

  RecalculateMatchTipsUseCase({
    required this.tipRepository,
    required this.userRepository,
    required this.matchRepository,
    required this.teamRepository,
  });

  /// Lädt alle benötigten Daten einmal und cached sie
  Future<void> _loadSharedData() async {
    if (_cachedAllMatches != null) return; // Bereits geladen

    final allMatchesResult = await matchRepository.getAllMatches();
    await allMatchesResult.fold(
      (failure) async {
        print('❌ Fehler beim Laden aller Matches: $failure');
      },
      (allMatches) async {
        _cachedAllMatches = allMatches;

        // Finde das Finale-Match: das ZEITLICH LETZTE Spiel mit matchDay 8
        // (nicht das Spiel um Platz 3, das früher stattfindet)
        final matchDay8Matches = allMatches
            .where((m) => m.matchDay == 8 && m.hasResult)
            .toList()
          ..sort((a, b) => b.matchDate.compareTo(a.matchDate));

        _cachedFinalMatch = matchDay8Matches.isNotEmpty ? matchDay8Matches.first : null;

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
                print('❌ Fehler beim Laden der Teams für Champion-Ermittlung: $failure');
              },
              (teams) {
                final champion = teams.cast<Team?>().firstWhere(
                  (t) => t != null && t.champion,
                  orElse: () => null,
                );
                if (champion != null) {
                  _cachedChampionId = champion.id;
                  _cachedChampionTeam = champion;
                  print('🏆 Champion bei Unentschieden aus Flag ermittelt: ${champion.name}');
                } else {
                  print('⚠️ Finale unentschieden, aber kein Team als Champion markiert!');
                }
              },
            );
          }

          // Lade Champion-Team einmal (falls nicht bereits durch Unentschieden-Logik geladen)
          if (_cachedChampionId != null && _cachedChampionTeam == null) {
            final championTeamResult = await teamRepository.getById(_cachedChampionId!);
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
              // Hole User um dessen championId zu prüfen
              final userResult = await userRepository.getUserById(tip.userId);
              userResult.fold(
                (failure) {},
                (user) {
                  if (user.championId == _cachedChampionId) {
                    newPoints += _cachedChampionTeam!.winPoints;
                    print('🏆 [Finale] Champion-Bonus für ${user.name}: +${_cachedChampionTeam!.winPoints} → Total: $newPoints');
                  }
                },
              );
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

      // ✅ Aktualisiere Score für alle betroffenen User (mit gecachten Daten)
      await _updateUserScores(affectedUsers);

      return right(unit);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  /// Berechnet Statistiken für User neu - OPTIMIERT mit Cache
  Future<void> _updateUserScores(Set<String> userIds) async {
    if (userIds.isEmpty) return;

    for (final userId in userIds) {
      try {
        final userTipsResult = await tipRepository.getTipsByUserId(userId);

        await userTipsResult.fold(
          (failure) async {
            print('❌ Fehler beim Laden der Tips für $userId: $failure');
          },
          (tips) async {
            int totalScore = 0;
            int jokersUsed = 0;
            int perfectPredictions = 0;

            for (final tip in tips) {
              totalScore += tip.points ?? 0;
              
              if (tip.joker) {
                jokersUsed++;
              }
              
              if ((tip.points ?? 0) == 6 && !tip.joker) {
                perfectPredictions++;
              }
            }

            // ✅ Hole User
            final userResult = await userRepository.getUserById(userId);
            await userResult.fold(
              (failure) async {
                print('❌ Fehler beim Laden des Users: $failure');
              },
              (user) async {
                // 🏆 Champion-Bonus ist jetzt bereits in den Finale-Tip-Punkten enthalten!
                // (Wird direkt beim Tip-Punkte-Berechnen addiert, nicht mehr hier separat)

                // Update User mit neuen Scores
                if (user.id.isNotEmpty) {
                  final updatedUser = user.copyWith(
                    score: totalScore,
                    jokerSum: jokersUsed,
                    sixer: perfectPredictions,
                  );
                  await userRepository.updateUser(updatedUser);
                }
              },
            );
          },
        );
      } catch (e) {
        print('❌ Fehler beim Berechnen der Scores für $userId: $e');
      }
    }
  }

  /// Aktualisiert Rankings für alle User mit Tiebreaker-Logik - OPTIMIERT
  Future<void> updateAllUserRankings() async {
    try {
      final allUsersResult = await userRepository.getAllUsers();
      
      await allUsersResult.fold(
        (failure) async {
          print('❌ Fehler beim Laden aller User für Ranking-Update: $failure');
        },
        (users) async {
          // Sortiere mit komplexer Tiebreaker-Logik
          final sortedUsers = List.from(users)
            ..sort((a, b) {
              // 1. Nach Punkten (höher = besser)
              final scoreComparison = b.score.compareTo(a.score);
              if (scoreComparison != 0) return scoreComparison;

              // 2. Bei gleichen Punkten: Weniger Joker = besser
              final jokerComparison = a.jokerSum.compareTo(b.jokerSum);
              if (jokerComparison != 0) return jokerComparison;

              // 3. Bei gleichen Jokern: Mehr Sechser = besser
              final sixersComparison = b.sixer.compareTo(a.sixer);
              if (sixersComparison != 0) return sixersComparison;

              // 4. Letzter Tiebreaker: Alphabetisch nach Namen
              return a.name.compareTo(b.name);
            });

          // ✅ Sammle nur User mit geändertem Rang
          final usersToUpdate = [];
          for (int i = 0; i < sortedUsers.length; i++) {
            final user = sortedUsers[i];
            final newRank = i + 1;

            if (user.rank != newRank) {
              usersToUpdate.add(user.copyWith(rank: newRank));
            }
          }

          // ✅ Update nur geänderte User
          for (final user in usersToUpdate) {
            await userRepository.updateUser(user);
          }

          print('✅ Rankings für ${usersToUpdate.length}/${sortedUsers.length} User aktualisiert');
        },
      );

      // ✅ Cache leeren nach Ranking-Update
      clearCache();
    } catch (e) {
      print('❌ Fehler beim Ranking-Update: $e');
    }
  }
}

