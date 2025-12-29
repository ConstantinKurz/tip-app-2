import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/core/failures/match_failures.dart';

void main() {
  group('Match Repository Logic Tests', () {
    test('CustomMatch entity should have correct structure', () {
      final match = CustomMatch(
        id: 'match_1',
        homeTeamId: 'team_a',
        guestTeamId: 'team_b',
        matchDate: DateTime(2024, 1, 15, 18, 30),
        matchDay: 1,
        homeScore: null,
        guestScore: null,
      );

      expect(match.id, 'match_1');
      expect(match.homeTeamId, 'team_a');
      expect(match.guestTeamId, 'team_b');
      expect(match.matchDate, DateTime(2024, 1, 15, 18, 30));
      expect(match.matchDay, 1);
      expect(match.homeScore, null);
      expect(match.guestScore, null);
    });

    test('CustomMatch should correctly determine match result status', () {
      final finishedMatch = CustomMatch(
        id: 'finished_match',
        homeTeamId: 'team_a',
        guestTeamId: 'team_b',
        matchDate: DateTime(2024, 1, 1, 12, 0),
        matchDay: 1,
        homeScore: 3,
        guestScore: 0,
      );

      expect(finishedMatch.homeScore != null && finishedMatch.guestScore != null, true);

      final upcomingMatch = CustomMatch(
        id: 'upcoming_match',
        homeTeamId: 'team_c',
        guestTeamId: 'team_d',
        matchDate: DateTime(2024, 12, 31, 18, 0),
        matchDay: 2,
        homeScore: null,
        guestScore: null,
      );

      expect(upcomingMatch.homeScore == null || upcomingMatch.guestScore == null, true);
    });

    test('CustomMatch copyWith should work correctly', () {
      final original = CustomMatch(
        id: 'original_match',
        homeTeamId: 'home',
        guestTeamId: 'guest',
        matchDate: DateTime(2024, 6, 1),
        matchDay: 1,
        homeScore: null,
        guestScore: null,
      );

      final updated = original.copyWith(
        homeScore: 2,
        guestScore: 1,
      );

      expect(updated.id, 'original_match');
      expect(updated.homeTeamId, 'home');
      expect(updated.guestTeamId, 'guest');
      expect(updated.homeScore, 2);
      expect(updated.guestScore, 1);
      expect(updated.homeScore != null && updated.guestScore != null, true);
    });

    test('CustomMatch should handle edge case scores', () {
      final zeroScoreMatch = CustomMatch(
        id: 'zero_match',
        homeTeamId: 'team_1',
        guestTeamId: 'team_2',
        matchDate: DateTime.now(),
        matchDay: 1,
        homeScore: 0,
        guestScore: 0,
      );

      expect(zeroScoreMatch.homeScore, 0);
      expect(zeroScoreMatch.guestScore, 0);
      expect(zeroScoreMatch.homeScore != null && zeroScoreMatch.guestScore != null, true);
    });
  });

  group('MatchFailure Types', () {
    test('should create all match failure types', () {
      final insufficientPermissions = InsufficientPermisssons();
      final unexpectedFailure = UnexpectedFailure();
      final notFoundFailure = NotFoundFailure();

      expect(insufficientPermissions, isA<MatchFailure>());
      expect(unexpectedFailure, isA<MatchFailure>());
      expect(notFoundFailure, isA<MatchFailure>());
    });

    test('should distinguish between failure types', () {
      final failure1 = InsufficientPermisssons();
      final failure2 = UnexpectedFailure();
      final failure3 = NotFoundFailure();

      expect(failure1.runtimeType, isNot(failure2.runtimeType));
      expect(failure2.runtimeType, isNot(failure3.runtimeType));
      expect(failure1.runtimeType, isNot(failure3.runtimeType));
    });
  });

  group('Either Type Handling', () {
    test('should handle Either return types for matches', () {
      final successResult = right<MatchFailure, Unit>(unit);
      final failureResult = left<MatchFailure, Unit>(UnexpectedFailure());

      expect(successResult.isRight(), true);
      expect(failureResult.isLeft(), true);
    });

    test('should handle match list operations', () {
      final matches = [
        CustomMatch(
          id: '1', 
          homeTeamId: 'h1', 
          guestTeamId: 'g1', 
          matchDate: DateTime.now(), 
          matchDay: 1,
          homeScore: 1, 
          guestScore: 0,
        ),
        CustomMatch(
          id: '2', 
          homeTeamId: 'h2', 
          guestTeamId: 'g2', 
          matchDate: DateTime.now(), 
          matchDay: 1,
          homeScore: null, 
          guestScore: null,
        ),
      ];

      expect(matches.length, 2);
      expect(matches.where((m) => m.homeScore != null && m.guestScore != null).length, 1);
      expect(matches.where((m) => m.homeScore == null || m.guestScore == null).length, 1);
    });
  });
}