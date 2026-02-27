import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/match.dart';
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

  RecalculateMatchTipsUseCase({
    required this.tipRepository,
    required this.userRepository,
    required this.matchRepository,
    required this.teamRepository,
  });

  /// Berechnet Punkte für alle Tips eines Matches neu
  /// und aktualisiert User-Scores
  Future<Either<TipFailure, Unit>> call({
    required CustomMatch match,
  }) async {
    if (!match.hasResult) {
      return right(unit); // Nichts zu berechnen
    }

    try {
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
            final newPoints = TipCalculator.calculatePoints(
              tipHome: tip.tipHome ?? 0,
              tipGuest: tip.tipGuest ?? 0,
              actualHome: match.homeScore ?? 0,
              actualGuest: match.guestScore ?? 0,
              hasJoker: tip.joker,
              phase: match.phase,
            );

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

      // Aktualisiere Score für alle betroffenen User
      await _updateUserScores(affectedUsers);

      return right(unit);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  /// Berechnet Gesamtpunkte für User neu
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

            // ✅ Hole User und prüfe Champion-Tipp
            final userResult = await userRepository.getUserById(userId);
            await userResult.fold(
              (failure) async {
                print('❌ Fehler beim Laden des Users: $failure');
              },
              (user) async {
                // ✅ Neue Logik: Prüfe ob User den richtigen Champion getippt hat
                if (user.championId.isNotEmpty) {
                  // Hole den tatsächlichen Weltmeister (z.B. aus Match mit höchster Phase)
                  final allMatchesResult = await matchRepository.getAllMatches();
                  
                  await allMatchesResult.fold(
                    (failure) async {},
                    (allMatches) async {
                      // Finde das Finale-Match (matchDay 8)
                      final finalMatch = allMatches
                          .cast<CustomMatch?>()
                          .firstWhere(
                            (m) => m != null && m.matchDay == 8 && m.hasResult,
                            orElse: () => null,
                          );
                      
                      if (finalMatch != null) {
                        // Der Sieger des Finals ist der Weltmeister
                        final actualChampionId = 
                            (finalMatch.homeScore ?? 0) > (finalMatch.guestScore ?? 0)
                                ? finalMatch.homeTeamId
                                : finalMatch.guestTeamId;
                        
                        // ✅ Wenn User den richtigen Champion getippt hat
                        if (user.championId == actualChampionId) {
                          // Hole die win_points des Champions
                          final championTeamResult = 
                              await teamRepository.getById(actualChampionId);
                          
                          await championTeamResult.fold(
                            (failure) async {},
                            (championTeam) async {
                              // ✅ Addiere die win_points des Champions
                              totalScore += championTeam.winPoints;
                              print('✅ Champion bonus: +${championTeam.winPoints} Punkte für $userId');
                            },
                          );
                        }
                      }
                    },
                  );
                }

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

  /// Aktualisiert Rankings für alle User mit Tiebreaker-Logik
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

          // Vergebe neue Ranks
          for (int i = 0; i < sortedUsers.length; i++) {
            final user = sortedUsers[i];
            final newRank = i + 1;

            if (user.rank != newRank) {
              final updatedUser = user.copyWith(rank: newRank);
              await userRepository.updateUser(updatedUser);
            }
          }

          print('✅ Rankings für ${sortedUsers.length} User aktualisiert');
        },
      );
    } catch (e) {
      print('❌ Fehler beim Ranking-Update: $e');
    }
  }
}

