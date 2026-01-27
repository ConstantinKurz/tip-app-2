import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/repositories/user_repository.dart';
import 'package:flutter_web/domain/usecases/tip_calculator_usecase.dart';


class RecalculateMatchTipsUseCase {
  final TipRepository tipRepository;
  final UserRepository userRepository;

  RecalculateMatchTipsUseCase({
    required this.tipRepository,
    required this.userRepository,
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
        // Hole alle Tips des Users
        final userTipsResult = await tipRepository.getTipsByUserId(userId);

        await userTipsResult.fold(
          (failure) async {
            // Fehlerbehandlung
          },
          (tips) async {
            // Berechne Summe aller Punkte
            int totalScore = 0;
            for (final tip in tips) {
              totalScore += tip.points ?? 0;
            }

            // Hole User und update Score
            final userResult = await userRepository.getUserById(userId);
            await userResult.fold(
              (failure) async {
                // Fehlerbehandlung
              },
              (user) async {
                if (user.id.isNotEmpty) {
                  final updatedUser = user.copyWith(score: totalScore);
                  await userRepository.updateUser(updatedUser);
                }
              },
            );
          },
        );
      } catch (e) {
        // Fehlerbehandlung pro User
      }
    }
  }
}

