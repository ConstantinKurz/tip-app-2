import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/domain/entities/match.dart';

void main() {
  group('CustomMatch Entity', () {
    group('Constructor', () {
      test('should create match with valid properties', () {
        // Arrange
        final matchDate = DateTime(2024, 6, 15, 21, 0);
        
        // Act
        final match = CustomMatch(
          id: 'match1',
          homeTeamId: 'ger',
          guestTeamId: 'fra',
          matchDate: matchDate,
          matchDay: 1,
          homeScore: 2,
          guestScore: 1,
        );

        // Assert
        expect(match.id, 'match1');
        expect(match.homeTeamId, 'ger');
        expect(match.guestTeamId, 'fra');
        expect(match.matchDate, matchDate);
        expect(match.matchDay, 1);
        expect(match.homeScore, 2);
        expect(match.guestScore, 1);
      });

      test('should create match with null scores (future match)', () {
        // Arrange
        final matchDate = DateTime(2024, 6, 20, 18, 0);
        
        // Act
        final match = CustomMatch(
          id: 'future_match',
          homeTeamId: 'esp',
          guestTeamId: 'ita',
          matchDate: matchDate,
          matchDay: 2,
          homeScore: null,
          guestScore: null,
        );

        // Assert
        expect(match.id, 'future_match');
        expect(match.homeTeamId, 'esp');
        expect(match.guestTeamId, 'ita');
        expect(match.matchDate, matchDate);
        expect(match.matchDay, 2);
        expect(match.homeScore, null);
        expect(match.guestScore, null);
      });
    });

    group('copyWith', () {
      test('should return new instance with updated properties', () {
        // Arrange
        final originalDate = DateTime(2024, 6, 15, 21, 0);
        final newDate = DateTime(2024, 6, 16, 20, 0);
        
        final originalMatch = CustomMatch(
          id: 'match2',
          homeTeamId: 'bra',
          guestTeamId: 'arg',
          matchDate: originalDate,
          matchDay: 3,
          homeScore: null,
          guestScore: null,
        );

        // Act
        final updatedMatch = originalMatch.copyWith(
          matchDate: newDate,
          homeScore: 3,
          guestScore: 2,
        );

        // Assert
        expect(updatedMatch.id, originalMatch.id);
        expect(updatedMatch.homeTeamId, originalMatch.homeTeamId);
        expect(updatedMatch.guestTeamId, originalMatch.guestTeamId);
        expect(updatedMatch.matchDate, newDate);
        expect(updatedMatch.matchDay, originalMatch.matchDay);
        expect(updatedMatch.homeScore, 3);
        expect(updatedMatch.guestScore, 2);
      });

      test('should return identical instance when no properties are updated', () {
        // Arrange
        final matchDate = DateTime(2024, 6, 17, 19, 0);
        final originalMatch = CustomMatch(
          id: 'match3',
          homeTeamId: 'eng',
          guestTeamId: 'ned',
          matchDate: matchDate,
          matchDay: 1,
          homeScore: 1,
          guestScore: 1,
        );

        // Act
        final copiedMatch = originalMatch.copyWith();

        // Assert
        expect(copiedMatch.id, originalMatch.id);
        expect(copiedMatch.homeTeamId, originalMatch.homeTeamId);
        expect(copiedMatch.guestTeamId, originalMatch.guestTeamId);
        expect(copiedMatch.matchDate, originalMatch.matchDate);
        expect(copiedMatch.matchDay, originalMatch.matchDay);
        expect(copiedMatch.homeScore, originalMatch.homeScore);
        expect(copiedMatch.guestScore, originalMatch.guestScore);
      });

      test('should update individual properties independently', () {
        // Arrange
        final matchDate = DateTime(2024, 6, 18, 21, 0);
        final originalMatch = CustomMatch(
          id: 'match4',
          homeTeamId: 'por',
          guestTeamId: 'bel',
          matchDate: matchDate,
          matchDay: 2,
          homeScore: 0,
          guestScore: 0,
        );

        // Act & Assert - Update match day only
        final updatedDay = originalMatch.copyWith(matchDay: 5);
        expect(updatedDay.matchDay, 5);
        expect(updatedDay.id, originalMatch.id);
        expect(updatedDay.homeScore, originalMatch.homeScore);

        // Act & Assert - Update home team only
        final updatedHome = originalMatch.copyWith(homeTeamId: 'fra');
        expect(updatedHome.homeTeamId, 'fra');
        expect(updatedHome.guestTeamId, originalMatch.guestTeamId);
        expect(updatedHome.matchDay, originalMatch.matchDay);

        // Act & Assert - Update scores only
        final updatedScores = originalMatch.copyWith(homeScore: 2, guestScore: 3);
        expect(updatedScores.homeScore, 2);
        expect(updatedScores.guestScore, 3);
        expect(updatedScores.id, originalMatch.id);
        expect(updatedScores.matchDay, originalMatch.matchDay);
      });

      test('should handle setting scores to null', () {
        // Arrange
        final matchDate = DateTime(2024, 6, 19, 16, 0);
        final originalMatch = CustomMatch(
          id: 'match5',
          homeTeamId: 'ger',
          guestTeamId: 'esp',
          matchDate: matchDate,
          matchDay: 4,
          homeScore: 2,
          guestScore: 1,
        );

        // Act - Create new instance with explicit null values
        final resetScores = CustomMatch(
          id: originalMatch.id,
          homeTeamId: originalMatch.homeTeamId,
          guestTeamId: originalMatch.guestTeamId,
          matchDate: originalMatch.matchDate,
          matchDay: originalMatch.matchDay,
          homeScore: null,
          guestScore: null,
        );

        // Assert
        expect(resetScores.homeScore, null);
        expect(resetScores.guestScore, null);
        expect(resetScores.id, originalMatch.id);
        expect(resetScores.homeTeamId, originalMatch.homeTeamId);
        expect(resetScores.guestTeamId, originalMatch.guestTeamId);
      });
    });

    group('empty factory', () {
      test('should create match with default values when no parameters provided', () {
        // Act
        final emptyMatch = CustomMatch.empty();

        // Assert
        expect(emptyMatch.id, '');
        expect(emptyMatch.homeTeamId, 'TBD');
        expect(emptyMatch.guestTeamId, 'TBD');
        expect(emptyMatch.matchDate, isA<DateTime>());
        expect(emptyMatch.matchDay, 0);
        expect(emptyMatch.homeScore, null);
        expect(emptyMatch.guestScore, null);
      });

      test('should create match with custom values when parameters provided', () {
        // Arrange
        final customDate = DateTime(2024, 12, 25, 15, 0);

        // Act
        final customMatch = CustomMatch.empty(
          id: 'custom1',
          homeTeamId: 'custom_home',
          guestTeamId: 'custom_guest',
          matchDate: customDate,
          matchDay: 99,
          homeScore: 5,
          guestScore: 4,
        );

        // Assert
        expect(customMatch.id, 'custom1');
        expect(customMatch.homeTeamId, 'custom_home');
        expect(customMatch.guestTeamId, 'custom_guest');
        expect(customMatch.matchDate, customDate);
        expect(customMatch.matchDay, 99);
        expect(customMatch.homeScore, 5);
        expect(customMatch.guestScore, 4);
      });

      test('should mix default and custom values appropriately', () {
        // Arrange
        final customDate = DateTime(2024, 7, 4, 12, 30);

        // Act
        final mixedMatch = CustomMatch.empty(
          id: 'mixed1',
          matchDate: customDate,
          homeScore: 1,
        );

        // Assert
        expect(mixedMatch.id, 'mixed1');
        expect(mixedMatch.homeTeamId, 'TBD'); // default
        expect(mixedMatch.guestTeamId, 'TBD'); // default
        expect(mixedMatch.matchDate, customDate);
        expect(mixedMatch.matchDay, 0); // default
        expect(mixedMatch.homeScore, 1);
        expect(mixedMatch.guestScore, null); // default
      });
    });

    group('getStageName method', () {
      late CustomMatch match;

      setUp(() {
        match = CustomMatch(
          id: 'stage_test',
          homeTeamId: 'team1',
          guestTeamId: 'team2',
          matchDate: DateTime.now(),
          matchDay: 1,
          homeScore: null,
          guestScore: null,
        );
      });

      test('should return correct group stage names for days 1-3', () {
        // Act & Assert
        expect(match.getStageName, 'Gruppenphase, Tag 1');
        expect(match.getStageName, 'Gruppenphase, Tag 2');
        expect(match.getStageName, 'Gruppenphase, Tag 3');
      });

      test('should return correct knockout stage names', () {
        // Act & Assert
        expect(match.getStageName, 'Sechszehntelfinale');
        expect(match.getStageName, 'Achtelfinale');
        expect(match.getStageName, 'Viertelfinale');
        expect(match.getStageName, 'Halbfinale');
        expect(match.getStageName, 'Finale');
      });

      test('should return generic name for unknown match days', () {
        // Act & Assert
        expect(match.getStageName, 'Gruppenphase, Tag 0');
        expect(match.getStageName, 'Spieltag 9');
        expect(match.getStageName, 'Spieltag 15');
        expect(match.getStageName, 'Gruppenphase, Tag -1');
        expect(match.getStageName, 'Spieltag 999');
      });
    });

    group('Edge Cases', () {
      test('should handle empty string values', () {
        // Act
        final match = CustomMatch(
          id: '',
          homeTeamId: '',
          guestTeamId: '',
          matchDate: DateTime.now(),
          matchDay: 0,
          homeScore: null,
          guestScore: null,
        );

        // Assert
        expect(match.id, '');
        expect(match.homeTeamId, '');
        expect(match.guestTeamId, '');
      });

      test('should handle negative scores', () {
        // Act
        final match = CustomMatch(
          id: 'negative_test',
          homeTeamId: 'home',
          guestTeamId: 'guest',
          matchDate: DateTime.now(),
          matchDay: 1,
          homeScore: -1,
          guestScore: -2,
        );

        // Assert
        expect(match.homeScore, -1);
        expect(match.guestScore, -2);
      });

      test('should handle very large scores', () {
        // Act
        final match = CustomMatch(
          id: 'large_score_test',
          homeTeamId: 'home',
          guestTeamId: 'guest',
          matchDate: DateTime.now(),
          matchDay: 1,
          homeScore: 99999,
          guestScore: 88888,
        );

        // Assert
        expect(match.homeScore, 99999);
        expect(match.guestScore, 88888);
      });

      test('should handle very old and very future dates', () {
        // Arrange
        final veryOldDate = DateTime(1900, 1, 1);
        final veryFutureDate = DateTime(2100, 12, 31);

        // Act
        final oldMatch = CustomMatch(
          id: 'old',
          homeTeamId: 'home',
          guestTeamId: 'guest',
          matchDate: veryOldDate,
          matchDay: 1,
          homeScore: null,
          guestScore: null,
        );

        final futureMatch = CustomMatch(
          id: 'future',
          homeTeamId: 'home',
          guestTeamId: 'guest',
          matchDate: veryFutureDate,
          matchDay: 1,
          homeScore: null,
          guestScore: null,
        );

        // Assert
        expect(oldMatch.matchDate, veryOldDate);
        expect(futureMatch.matchDate, veryFutureDate);
      });

      test('should handle special characters in team IDs', () {
        // Act
        final match = CustomMatch(
          id: 'special-123_test',
          homeTeamId: 'team-1_special',
          guestTeamId: 'team&2@special',
          matchDate: DateTime.now(),
          matchDay: 1,
          homeScore: null,
          guestScore: null,
        );

        // Assert
        expect(match.id, 'special-123_test');
        expect(match.homeTeamId, 'team-1_special');
        expect(match.guestTeamId, 'team&2@special');
      });
    });
  });
}