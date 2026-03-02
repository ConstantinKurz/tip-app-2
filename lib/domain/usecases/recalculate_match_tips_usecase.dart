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

        // Finde das Finale-Match (matchDay 8)
        _cachedFinalMatch = allMatches.cast<CustomMatch?>().firstWhere(
              (m) => m != null && m.matchDay == 8 && m.hasResult,
              orElse: () => null,
            );

        if (_cachedFinalMatch != null) {
          // Der Sieger des Finals ist der Weltmeister
          _cachedChampionId =
              (_cachedFinalMatch!.homeScore ?? 0) > (_cachedFinalMatch!.guestScore ?? 0)
                  ? _cachedFinalMatch!.homeTeamId
                  : _cachedFinalMatch!.guestTeamId;

          // Lade Champion-Team einmal
          final championTeamResult = await teamRepository.getById(_cachedChampionId!);
          championTeamResult.fold(
            (failure) {},
            (team) {
              _cachedChampionTeam = team;
            },
          );
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
                // ✅ Champion-Bonus mit gecachten Daten (KEIN getAllMatches() mehr!)
                if (user.championId.isNotEmpty &&
                    _cachedChampionId != null &&
                    _cachedChampionTeam != null &&
                    user.championId == _cachedChampionId) {
                  totalScore += _cachedChampionTeam!.winPoints;
                  print('✅ Champion bonus: +${_cachedChampionTeam!.winPoints} Punkte für $userId');
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

