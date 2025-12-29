import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/core/failures/team_failures.dart';

void main() {
  group('Team Repository Logic Tests', () {
    test('Team entity should have correct structure', () {
      final team = Team(
        id: 'test_team',
        name: 'Test Team',
        flagCode: 'tt',
        winPoints: 3,
        champion: false,
      );

      expect(team.id, 'test_team');
      expect(team.name, 'Test Team');
      expect(team.flagCode, 'tt');
      expect(team.winPoints, 3);
      expect(team.champion, false);
    });

    test('Team.empty should create placeholder team', () {
      final emptyTeam = Team.empty();

      expect(emptyTeam.id, 'TBD');
      expect(emptyTeam.name, 'Placeholder');
      expect(emptyTeam.flagCode, 'Null');
      expect(emptyTeam.winPoints, 0);
      expect(emptyTeam.champion, false);
    });

    test('Team should handle copyWith correctly', () {
      final original = Team(
        id: 'original',
        name: 'Original Team',
        flagCode: 'or',
        winPoints: 5,
        champion: false,
      );

      final modified = original.copyWith(
        name: 'Modified Team',
        winPoints: 10,
        champion: true,
      );

      expect(modified.id, 'original');
      expect(modified.name, 'Modified Team');
      expect(modified.flagCode, 'or');
      expect(modified.winPoints, 10);
      expect(modified.champion, true);
    });
  });

  group('TeamFailure Types', () {
    test('should create all failure types correctly', () {
      final insufficientPermissions = InsufficientPermisssons();
      final unexpectedFailure = UnexpectedFailure();
      final notFoundFailure = NotFoundFailure();

      expect(insufficientPermissions, isA<TeamFailure>());
      expect(unexpectedFailure, isA<TeamFailure>());
      expect(notFoundFailure, isA<TeamFailure>());
    });

    test('should have distinct failure types', () {
      final failure1 = InsufficientPermisssons();
      final failure2 = UnexpectedFailure();
      final failure3 = NotFoundFailure();

      expect(failure1.runtimeType, isNot(failure2.runtimeType));
      expect(failure2.runtimeType, isNot(failure3.runtimeType));
      expect(failure1.runtimeType, isNot(failure3.runtimeType));
    });
  });

  group('Either Type Handling', () {
    test('should handle Either return types', () {
      final successResult = right<TeamFailure, Unit>(unit);
      final failureResult = left<TeamFailure, Unit>(UnexpectedFailure());

      expect(successResult.isRight(), true);
      expect(failureResult.isLeft(), true);
    });

    test('should handle list operations', () {
      final teams = [
        Team(id: '1', name: 'Team 1', flagCode: 't1', winPoints: 3, champion: false),
        Team(id: '2', name: 'Team 2', flagCode: 't2', winPoints: 6, champion: false),
        Team(id: '3', name: 'Team 3', flagCode: 't3', winPoints: 9, champion: true),
      ];

      expect(teams.length, 3);
      expect(teams.where((t) => t.champion).length, 1);
      expect(teams.map((t) => t.winPoints).reduce((a, b) => a + b), 18);
    });
  });
}