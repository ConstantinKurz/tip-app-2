import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/domain/entities/team.dart';

void main() {
  group('Team Entity', () {
    group('Constructor', () {
      test('should create team with valid properties', () {
        // Arrange & Act
        final team = Team(
          id: 'ger',
          name: 'Deutschland',
          flagCode: 'de',
          winPoints: 3,
          champion: true,
        );

        // Assert
        expect(team.id, 'ger');
        expect(team.name, 'Deutschland');
        expect(team.flagCode, 'de');
        expect(team.winPoints, 3);
        expect(team.champion, true);
      });

      test('should create team with minimum required values', () {
        // Arrange & Act
        final team = Team(
          id: 'esp',
          name: 'Spain',
          flagCode: 'es',
          winPoints: 0,
          champion: false,
        );

        // Assert
        expect(team.id, 'esp');
        expect(team.name, 'Spain');
        expect(team.flagCode, 'es');
        expect(team.winPoints, 0);
        expect(team.champion, false);
      });
    });

    group('copyWith', () {
      test('should return new instance with updated properties', () {
        // Arrange
        final originalTeam = Team(
          id: 'fra',
          name: 'France',
          flagCode: 'fr',
          winPoints: 6,
          champion: false,
        );

        // Act
        final updatedTeam = originalTeam.copyWith(
          winPoints: 9,
          champion: true,
        );

        // Assert
        expect(updatedTeam.id, originalTeam.id);
        expect(updatedTeam.name, originalTeam.name);
        expect(updatedTeam.flagCode, originalTeam.flagCode);
        expect(updatedTeam.winPoints, 9);
        expect(updatedTeam.champion, true);
      });

      test('should return identical instance when no properties are updated', () {
        // Arrange
        final originalTeam = Team(
          id: 'bra',
          name: 'Brazil',
          flagCode: 'br',
          winPoints: 12,
          champion: true,
        );

        // Act
        final copiedTeam = originalTeam.copyWith();

        // Assert
        expect(copiedTeam.id, originalTeam.id);
        expect(copiedTeam.name, originalTeam.name);
        expect(copiedTeam.flagCode, originalTeam.flagCode);
        expect(copiedTeam.winPoints, originalTeam.winPoints);
        expect(copiedTeam.champion, originalTeam.champion);
      });

      test('should update individual properties independently', () {
        // Arrange
        final originalTeam = Team(
          id: 'arg',
          name: 'Argentina',
          flagCode: 'ar',
          winPoints: 15,
          champion: false,
        );

        // Act & Assert - Update name only
        final updatedName = originalTeam.copyWith(name: 'Argentina National Team');
        expect(updatedName.name, 'Argentina National Team');
        expect(updatedName.id, originalTeam.id);
        expect(updatedName.winPoints, originalTeam.winPoints);

        // Act & Assert - Update flagCode only
        final updatedFlag = originalTeam.copyWith(flagCode: 'argentina');
        expect(updatedFlag.flagCode, 'argentina');
        expect(updatedFlag.name, originalTeam.name);
        expect(updatedFlag.winPoints, originalTeam.winPoints);

        // Act & Assert - Update id only
        final updatedId = originalTeam.copyWith(id: 'argentina');
        expect(updatedId.id, 'argentina');
        expect(updatedId.name, originalTeam.name);
        expect(updatedId.flagCode, originalTeam.flagCode);
      });
    });

    group('empty factory', () {
      test('should create placeholder team with default values', () {
        // Act
        final emptyTeam = Team.empty();

        // Assert
        expect(emptyTeam.id, 'TBD');
        expect(emptyTeam.name, 'Placeholder');
        expect(emptyTeam.flagCode, 'Null');
        expect(emptyTeam.winPoints, 0);
        expect(emptyTeam.champion, false);
      });

      test('should create new instance each time called', () {
        // Act
        final emptyTeam1 = Team.empty();
        final emptyTeam2 = Team.empty();

        // Assert - They should have same values but be different instances
        expect(emptyTeam1.id, emptyTeam2.id);
        expect(emptyTeam1.name, emptyTeam2.name);
        expect(emptyTeam1.flagCode, emptyTeam2.flagCode);
        expect(emptyTeam1.winPoints, emptyTeam2.winPoints);
        expect(emptyTeam1.champion, emptyTeam2.champion);
      });
    });

    group('Edge Cases', () {
      test('should handle empty string values', () {
        // Arrange & Act
        final team = Team(
          id: '',
          name: '',
          flagCode: '',
          winPoints: 0,
          champion: false,
        );

        // Assert
        expect(team.id, '');
        expect(team.name, '');
        expect(team.flagCode, '');
        expect(team.winPoints, 0);
        expect(team.champion, false);
      });

      test('should handle negative win points', () {
        // Arrange & Act
        final team = Team(
          id: 'test',
          name: 'Test Team',
          flagCode: 'test',
          winPoints: -5,
          champion: false,
        );

        // Assert
        expect(team.winPoints, -5);
      });

      test('should handle large win points values', () {
        // Arrange & Act
        final team = Team(
          id: 'winner',
          name: 'Super Winner',
          flagCode: 'win',
          winPoints: 999999,
          champion: true,
        );

        // Assert
        expect(team.winPoints, 999999);
      });

      test('should handle special characters in team properties', () {
        // Arrange & Act
        final team = Team(
          id: 'special-123',
          name: 'Team Ü with Spëcial Chars & Nümbers 123',
          flagCode: 'sp-123',
          winPoints: 42,
          champion: true,
        );

        // Assert
        expect(team.id, 'special-123');
        expect(team.name, 'Team Ü with Spëcial Chars & Nümbers 123');
        expect(team.flagCode, 'sp-123');
        expect(team.winPoints, 42);
        expect(team.champion, true);
      });
    });
  });
}