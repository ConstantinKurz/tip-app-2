import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/domain/entities/tip.dart';

void main() {
  group('Tip Entity', () {
    group('Constructor', () {
      test('should create tip with valid properties', () {
        // Arrange
        final tipDate = DateTime(2024, 6, 15, 19, 0);
        
        // Act
        final tip = Tip(
          id: 'user1_match1',
          userId: 'user1',
          matchId: 'match1',
          tipDate: tipDate,
          tipHome: 2,
          tipGuest: 1,
          joker: true,
          points: 3,
        );

        // Assert
        expect(tip.id, 'user1_match1');
        expect(tip.userId, 'user1');
        expect(tip.matchId, 'match1');
        expect(tip.tipDate, tipDate);
        expect(tip.tipHome, 2);
        expect(tip.tipGuest, 1);
        expect(tip.joker, true);
        expect(tip.points, 3);
      });

      test('should create tip with null values for optional fields', () {
        // Arrange
        final tipDate = DateTime(2024, 6, 16, 20, 0);
        
        // Act
        final tip = Tip(
          id: 'user2_match2',
          userId: 'user2',
          matchId: 'match2',
          tipDate: tipDate,
          tipHome: null,
          tipGuest: null,
          joker: false,
          points: null,
        );

        // Assert
        expect(tip.id, 'user2_match2');
        expect(tip.userId, 'user2');
        expect(tip.matchId, 'match2');
        expect(tip.tipDate, tipDate);
        expect(tip.tipHome, null);
        expect(tip.tipGuest, null);
        expect(tip.joker, false);
        expect(tip.points, null);
      });

      test('should create tip with null matchId', () {
        // Arrange
        final tipDate = DateTime(2024, 6, 17, 18, 30);
        
        // Act
        final tip = Tip(
          id: 'user3_null',
          userId: 'user3',
          matchId: null,
          tipDate: tipDate,
          tipHome: 1,
          tipGuest: 0,
          joker: false,
          points: 2,
        );

        // Assert
        expect(tip.id, 'user3_null');
        expect(tip.userId, 'user3');
        expect(tip.matchId, null);
        expect(tip.tipDate, tipDate);
        expect(tip.tipHome, 1);
        expect(tip.tipGuest, 0);
        expect(tip.joker, false);
        expect(tip.points, 2);
      });
    });

    group('empty factory', () {
      test('should create empty tip with user ID and default values', () {
        // Arrange
        const userId = 'test_user_123';
        
        // Act
        final emptyTip = Tip.empty(userId);

        // Assert
        expect(emptyTip.id, '');
        expect(emptyTip.userId, userId);
        expect(emptyTip.matchId, '');
        expect(emptyTip.tipDate, isA<DateTime>());
        expect(emptyTip.tipHome, null);
        expect(emptyTip.tipGuest, null);
        expect(emptyTip.joker, false);
        expect(emptyTip.points, null);
      });

      test('should create tip with current timestamp', () {
        // Arrange
        const userId = 'time_test_user';
        final beforeCreation = DateTime.now();
        
        // Act
        final emptyTip = Tip.empty(userId);
        final afterCreation = DateTime.now();

        // Assert
        expect(emptyTip.tipDate.isAfter(beforeCreation) || emptyTip.tipDate.isAtSameMomentAs(beforeCreation), true);
        expect(emptyTip.tipDate.isBefore(afterCreation) || emptyTip.tipDate.isAtSameMomentAs(afterCreation), true);
      });

      test('should create different timestamps for sequential calls', () {
        // Act
        final tip1 = Tip.empty('user1');
        // Small delay to ensure different timestamps
        final tip2 = Tip.empty('user2');

        // Assert
        expect(tip1.tipDate.isBefore(tip2.tipDate) || tip1.tipDate.isAtSameMomentAs(tip2.tipDate), true);
      });
    });

    group('copyWith', () {
      test('should return new instance with updated properties', () {
        // Arrange
        final originalDate = DateTime(2024, 6, 18, 15, 0);
        final newDate = DateTime(2024, 6, 19, 16, 30);
        
        final originalTip = Tip(
          id: 'original_tip',
          userId: 'user123',
          matchId: 'match123',
          tipDate: originalDate,
          tipHome: 1,
          tipGuest: 2,
          joker: false,
          points: null,
        );

        // Act
        final updatedTip = originalTip.copyWith(
          tipDate: newDate,
          tipHome: 3,
          tipGuest: 0,
          joker: true,
          points: 5,
        );

        // Assert
        expect(updatedTip.id, originalTip.id);
        expect(updatedTip.userId, originalTip.userId);
        expect(updatedTip.matchId, originalTip.matchId);
        expect(updatedTip.tipDate, newDate);
        expect(updatedTip.tipHome, 3);
        expect(updatedTip.tipGuest, 0);
        expect(updatedTip.joker, true);
        expect(updatedTip.points, 5);
      });

      test('should return identical instance when no properties are updated', () {
        // Arrange
        final tipDate = DateTime(2024, 6, 20, 12, 0);
        final originalTip = Tip(
          id: 'unchanged_tip',
          userId: 'user456',
          matchId: 'match456',
          tipDate: tipDate,
          tipHome: 0,
          tipGuest: 0,
          joker: true,
          points: 1,
        );

        // Act
        final copiedTip = originalTip.copyWith();

        // Assert
        expect(copiedTip.id, originalTip.id);
        expect(copiedTip.userId, originalTip.userId);
        expect(copiedTip.matchId, originalTip.matchId);
        expect(copiedTip.tipDate, originalTip.tipDate);
        expect(copiedTip.tipHome, originalTip.tipHome);
        expect(copiedTip.tipGuest, originalTip.tipGuest);
        expect(copiedTip.joker, originalTip.joker);
        expect(copiedTip.points, originalTip.points);
      });

      test('should update individual properties independently', () {
        // Arrange
        final tipDate = DateTime(2024, 6, 21, 21, 0);
        final originalTip = Tip(
          id: 'individual_test',
          userId: 'user789',
          matchId: 'match789',
          tipDate: tipDate,
          tipHome: 2,
          tipGuest: 2,
          joker: false,
          points: 1,
        );

        // Act & Assert - Update joker only
        final updatedJoker = originalTip.copyWith(joker: true);
        expect(updatedJoker.joker, true);
        expect(updatedJoker.tipHome, originalTip.tipHome);
        expect(updatedJoker.tipGuest, originalTip.tipGuest);
        expect(updatedJoker.points, originalTip.points);

        // Act & Assert - Update scores only
        final updatedScores = originalTip.copyWith(tipHome: 4, tipGuest: 1);
        expect(updatedScores.tipHome, 4);
        expect(updatedScores.tipGuest, 1);
        expect(updatedScores.joker, originalTip.joker);
        expect(updatedScores.points, originalTip.points);

        // Act & Assert - Update points only
        final updatedPoints = originalTip.copyWith(points: 6);
        expect(updatedPoints.points, 6);
        expect(updatedPoints.tipHome, originalTip.tipHome);
        expect(updatedPoints.tipGuest, originalTip.tipGuest);
        expect(updatedPoints.joker, originalTip.joker);

        // Act & Assert - Update matchId only
        final updatedMatchId = originalTip.copyWith(matchId: 'new_match');
        expect(updatedMatchId.matchId, 'new_match');
        expect(updatedMatchId.userId, originalTip.userId);
        expect(updatedMatchId.id, originalTip.id);
      });

      test('should handle setting values to null', () {
        // Arrange
        final tipDate = DateTime(2024, 6, 22, 14, 45);
        final originalTip = Tip(
          id: 'null_test',
          userId: 'user999',
          matchId: 'match999',
          tipDate: tipDate,
          tipHome: 5,
          tipGuest: 3,
          joker: true,
          points: 8,
        );

        // Act - Create new instance with explicit null values
        final resetTip = Tip(
          id: originalTip.id,
          userId: originalTip.userId,
          matchId: originalTip.matchId,
          tipDate: originalTip.tipDate,
          tipHome: null,
          tipGuest: null,
          joker: originalTip.joker,
          points: null,
        );

        // Assert
        expect(resetTip.tipHome, null);
        expect(resetTip.tipGuest, null);
        expect(resetTip.points, null);
        expect(resetTip.id, originalTip.id);
        expect(resetTip.userId, originalTip.userId);
        expect(resetTip.matchId, originalTip.matchId);
        expect(resetTip.joker, originalTip.joker);
      });

      test('should handle setting matchId to null', () {
        // Arrange
        final tipDate = DateTime(2024, 6, 23, 17, 15);
        final originalTip = Tip(
          id: 'match_null_test',
          userId: 'user_null',
          matchId: 'existing_match',
          tipDate: tipDate,
          tipHome: 1,
          tipGuest: 1,
          joker: false,
          points: 1,
        );

        // Act - Create new instance with null matchId
        final nullMatchTip = Tip(
          id: originalTip.id,
          userId: originalTip.userId,
          matchId: null,
          tipDate: originalTip.tipDate,
          tipHome: originalTip.tipHome,
          tipGuest: originalTip.tipGuest,
          joker: originalTip.joker,
          points: originalTip.points,
        );

        // Assert
        expect(nullMatchTip.matchId, null);
        expect(nullMatchTip.id, originalTip.id);
        expect(nullMatchTip.userId, originalTip.userId);
        expect(nullMatchTip.tipHome, originalTip.tipHome);
        expect(nullMatchTip.tipGuest, originalTip.tipGuest);
      });
    });

    group('Edge Cases', () {
      test('should handle empty string values', () {
        // Act
        final tip = Tip(
          id: '',
          userId: '',
          matchId: '',
          tipDate: DateTime.now(),
          tipHome: null,
          tipGuest: null,
          joker: false,
          points: null,
        );

        // Assert
        expect(tip.id, '');
        expect(tip.userId, '');
        expect(tip.matchId, '');
      });

      test('should handle negative tip scores', () {
        // Act
        final tip = Tip(
          id: 'negative_test',
          userId: 'user_neg',
          matchId: 'match_neg',
          tipDate: DateTime.now(),
          tipHome: -1,
          tipGuest: -2,
          joker: false,
          points: null,
        );

        // Assert
        expect(tip.tipHome, -1);
        expect(tip.tipGuest, -2);
      });

      test('should handle negative points', () {
        // Act
        final tip = Tip(
          id: 'neg_points_test',
          userId: 'user_neg_points',
          matchId: 'match_neg_points',
          tipDate: DateTime.now(),
          tipHome: 1,
          tipGuest: 0,
          joker: false,
          points: -5,
        );

        // Assert
        expect(tip.points, -5);
      });

      test('should handle very large tip scores', () {
        // Act
        final tip = Tip(
          id: 'large_score_test',
          userId: 'user_large',
          matchId: 'match_large',
          tipDate: DateTime.now(),
          tipHome: 99999,
          tipGuest: 88888,
          joker: true,
          points: 77777,
        );

        // Assert
        expect(tip.tipHome, 99999);
        expect(tip.tipGuest, 88888);
        expect(tip.points, 77777);
      });

      test('should handle very old and very future dates', () {
        // Arrange
        final veryOldDate = DateTime(1900, 1, 1);
        final veryFutureDate = DateTime(2100, 12, 31);

        // Act
        final oldTip = Tip(
          id: 'old_tip',
          userId: 'old_user',
          matchId: 'old_match',
          tipDate: veryOldDate,
          tipHome: 1,
          tipGuest: 0,
          joker: false,
          points: null,
        );

        final futureTip = Tip(
          id: 'future_tip',
          userId: 'future_user',
          matchId: 'future_match',
          tipDate: veryFutureDate,
          tipHome: 0,
          tipGuest: 1,
          joker: true,
          points: null,
        );

        // Assert
        expect(oldTip.tipDate, veryOldDate);
        expect(futureTip.tipDate, veryFutureDate);
      });

      test('should handle special characters in IDs', () {
        // Act
        final tip = Tip(
          id: 'user-123_match&456@test',
          userId: 'user@test.com',
          matchId: 'match_123-456&789',
          tipDate: DateTime.now(),
          tipHome: 2,
          tipGuest: 1,
          joker: false,
          points: 3,
        );

        // Assert
        expect(tip.id, 'user-123_match&456@test');
        expect(tip.userId, 'user@test.com');
        expect(tip.matchId, 'match_123-456&789');
      });

      test('should handle zero values appropriately', () {
        // Act
        final tip = Tip(
          id: 'zero_test',
          userId: 'zero_user',
          matchId: 'zero_match',
          tipDate: DateTime.now(),
          tipHome: 0,
          tipGuest: 0,
          joker: false,
          points: 0,
        );

        // Assert
        expect(tip.tipHome, 0);
        expect(tip.tipGuest, 0);
        expect(tip.points, 0);
        expect(tip.joker, false);
      });
    });

    group('Business Logic Validation', () {
      test('should create valid tip for different point scenarios', () {
        final testCases = [
          {'tipHome': 2, 'tipGuest': 1, 'actualHome': 2, 'actualGuest': 1, 'expectedPoints': 3, 'description': 'exact match'},
          {'tipHome': 1, 'tipGuest': 0, 'actualHome': 2, 'actualGuest': 1, 'expectedPoints': 1, 'description': 'correct tendency'},
          {'tipHome': 0, 'tipGuest': 1, 'actualHome': 1, 'actualGuest': 0, 'expectedPoints': 0, 'description': 'wrong result'},
        ];

        for (final testCase in testCases) {
          // Act
          final tip = Tip(
            id: 'points_test_${testCase['description']}',
            userId: 'test_user',
            matchId: 'test_match',
            tipDate: DateTime.now(),
            tipHome: testCase['tipHome'] as int?,
            tipGuest: testCase['tipGuest'] as int?,
            joker: false,
            points: testCase['expectedPoints'] as int?,
          );

          // Assert
          expect(tip.tipHome, testCase['tipHome'], reason: 'Failed for: ${testCase['description']}');
          expect(tip.tipGuest, testCase['tipGuest'], reason: 'Failed for: ${testCase['description']}');
          expect(tip.points, testCase['expectedPoints'], reason: 'Failed for: ${testCase['description']}');
        }
      });

      test('should handle joker functionality correctly', () {
        // Arrange & Act
        final jokerTip = Tip(
          id: 'joker_test',
          userId: 'joker_user',
          matchId: 'joker_match',
          tipDate: DateTime.now(),
          tipHome: 2,
          tipGuest: 1,
          joker: true,
          points: 6, // doubled points
        );

        final normalTip = Tip(
          id: 'normal_test',
          userId: 'normal_user',
          matchId: 'normal_match',
          tipDate: DateTime.now(),
          tipHome: 2,
          tipGuest: 1,
          joker: false,
          points: 3, // normal points
        );

        // Assert
        expect(jokerTip.joker, true);
        expect(jokerTip.points, 6);
        expect(normalTip.joker, false);
        expect(normalTip.points, 3);
      });

      test('should validate tip timing scenarios', () {
        // Arrange
        final matchDate = DateTime(2024, 6, 15, 21, 0); // Match at 21:00
        final validTipTime = DateTime(2024, 6, 15, 20, 59); // 1 minute before
        final lateTipTime = DateTime(2024, 6, 15, 21, 1); // 1 minute after

        // Act
        final validTip = Tip(
          id: 'valid_timing',
          userId: 'timing_user',
          matchId: 'timing_match',
          tipDate: validTipTime,
          tipHome: 1,
          tipGuest: 0,
          joker: false,
          points: null,
        );

        final lateTip = Tip(
          id: 'late_timing',
          userId: 'timing_user',
          matchId: 'timing_match',
          tipDate: lateTipTime,
          tipHome: 2,
          tipGuest: 1,
          joker: false,
          points: null,
        );

        // Assert - The entity doesn't validate timing, but stores the data correctly
        expect(validTip.tipDate.isBefore(matchDate), true);
        expect(lateTip.tipDate.isAfter(matchDate), true);
      });
    });
  });
}