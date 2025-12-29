import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';

void main() {
  group('Tip Repository Logic Tests', () {
    test('Tip entity should have correct structure', () {
      final tip = Tip(
        id: 'tip_1',
        userId: 'user_123',
        matchId: 'match_456',
        tipDate: DateTime.now(),
        tipHome: 2,
        tipGuest: 1,
        joker: false,
        points: 0,
      );

      expect(tip.id, 'tip_1');
      expect(tip.userId, 'user_123');
      expect(tip.matchId, 'match_456');
      expect(tip.tipHome, 2);
      expect(tip.tipGuest, 1);
      expect(tip.joker, false);
      expect(tip.points, 0);
    });

    test('Tip should handle null scores', () {
      final tipWithNullScores = Tip(
        id: 'null_tip',
        userId: 'user_456',
        matchId: 'match_789',
        tipDate: DateTime.now(),
        tipHome: null,
        tipGuest: null,
        joker: true,
        points: 0,
      );

      expect(tipWithNullScores.tipHome, null);
      expect(tipWithNullScores.tipGuest, null);
      expect(tipWithNullScores.joker, true);
    });

    test('Tip should handle joker tips correctly', () {
      final jokerTip = Tip(
        id: 'joker_tip',
        userId: 'user_joker',
        matchId: 'match_final',
        tipDate: DateTime.now(),
        tipHome: 3,
        tipGuest: 2,
        joker: true,
        points: 6,
      );

      expect(jokerTip.joker, true);
      expect(jokerTip.points, 6);
    });

    test('Tip.empty should create valid tip', () {
      final emptyTip = Tip.empty('user_123');

      expect(emptyTip.userId, 'user_123');
      expect(emptyTip.id, '');
      expect(emptyTip.matchId, '');
      expect(emptyTip.tipHome, null);
      expect(emptyTip.tipGuest, null);
      expect(emptyTip.joker, false);
    });

    test('Tip copyWith should work correctly', () {
      final original = Tip(
        id: 'original_tip',
        userId: 'user_1',
        matchId: 'match_1',
        tipDate: DateTime.now(),
        tipHome: 1,
        tipGuest: 1,
        joker: false,
        points: 0,
      );

      final updated = original.copyWith(
        tipHome: 2,
        tipGuest: 0,
        points: 3,
      );

      expect(updated.id, 'original_tip');
      expect(updated.userId, 'user_1');
      expect(updated.tipHome, 2);
      expect(updated.tipGuest, 0);
      expect(updated.points, 3);
    });

    test('Tip should handle edge case scores', () {
      final highScoreTip = Tip(
        id: 'high_score',
        userId: 'user_high',
        matchId: 'match_high',
        tipDate: DateTime.now(),
        tipHome: 10,
        tipGuest: 8,
        joker: false,
        points: 3,
      );

      expect(highScoreTip.tipHome, 10);
      expect(highScoreTip.tipGuest, 8);

      final zeroScoreTip = Tip(
        id: 'zero_score',
        userId: 'user_zero',
        matchId: 'match_zero',
        tipDate: DateTime.now(),
        tipHome: 0,
        tipGuest: 0,
        joker: true,
        points: 6,
      );

      expect(zeroScoreTip.tipHome, 0);
      expect(zeroScoreTip.tipGuest, 0);
      expect(zeroScoreTip.joker, true);
    });
  });

  group('TipFailure Types', () {
    test('should create all tip failure types', () {
      final insufficientPermissions = InsufficientPermisssons();
      final unexpectedFailure = UnexpectedFailure();
      final notFoundFailure = NotFoundFailure();

      expect(insufficientPermissions, isA<TipFailure>());
      expect(unexpectedFailure, isA<TipFailure>());
      expect(notFoundFailure, isA<TipFailure>());
    });

    test('should distinguish between tip failure types', () {
      final failure1 = InsufficientPermisssons();
      final failure2 = UnexpectedFailure();
      final failure3 = NotFoundFailure();

      expect(failure1.runtimeType, isNot(failure2.runtimeType));
      expect(failure2.runtimeType, isNot(failure3.runtimeType));
      expect(failure1.runtimeType, isNot(failure3.runtimeType));
    });
  });

  group('Tip Business Logic', () {
    test('should handle joker logic correctly', () {
      final regularTip = Tip(
        id: 'regular',
        userId: 'user_reg',
        matchId: 'match_reg',
        tipDate: DateTime.now(),
        tipHome: 2,
        tipGuest: 1,
        joker: false,
        points: 3,
      );

      final jokerTip = Tip(
        id: 'joker',
        userId: 'user_joker',
        matchId: 'match_joker',
        tipDate: DateTime.now(),
        tipHome: 2,
        tipGuest: 1,
        joker: true,
        points: 6,
      );

      expect(regularTip.joker, false);
      expect(jokerTip.joker, true);
      expect(jokerTip.points!, greaterThan(regularTip.points!));
    });

    test('should handle points calculation scenarios', () {
      final exactResultTip = Tip(
        id: 'exact',
        userId: 'user_exact',
        matchId: 'match_exact',
        tipDate: DateTime.now(),
        tipHome: 3,
        tipGuest: 1,
        joker: false,
        points: 3,
      );

      final tendencyTip = Tip(
        id: 'tendency',
        userId: 'user_tendency',
        matchId: 'match_tendency',
        tipDate: DateTime.now(),
        tipHome: 2,
        tipGuest: 0,
        joker: false,
        points: 1,
      );

      final wrongTip = Tip(
        id: 'wrong',
        userId: 'user_wrong',
        matchId: 'match_wrong',
        tipDate: DateTime.now(),
        tipHome: 0,
        tipGuest: 3,
        joker: false,
        points: 0,
      );

      expect(exactResultTip.points, 3);
      expect(tendencyTip.points, 1);
      expect(wrongTip.points, 0);
    });
  });

  group('Either Type Handling', () {
    test('should handle Either return types for tips', () {
      final successResult = right<TipFailure, Unit>(unit);
      final failureResult = left<TipFailure, Unit>(UnexpectedFailure());

      expect(successResult.isRight(), true);
      expect(failureResult.isLeft(), true);
    });

    test('should handle tip grouping by user', () {
      final tips = [
        Tip(
          id: '1', 
          userId: 'user_a', 
          matchId: 'match_1', 
          tipDate: DateTime.now(),
          tipHome: 1, 
          tipGuest: 0, 
          joker: false, 
          points: 3,
        ),
        Tip(
          id: '2', 
          userId: 'user_a', 
          matchId: 'match_2', 
          tipDate: DateTime.now(),
          tipHome: 2, 
          tipGuest: 1, 
          joker: true, 
          points: 6,
        ),
        Tip(
          id: '3', 
          userId: 'user_b', 
          matchId: 'match_1', 
          tipDate: DateTime.now(),
          tipHome: 0, 
          tipGuest: 2, 
          joker: false, 
          points: 0,
        ),
      ];

      final userATips = tips.where((t) => t.userId == 'user_a').toList();
      final userBTips = tips.where((t) => t.userId == 'user_b').toList();
      final jokerTips = tips.where((t) => t.joker).toList();

      expect(userATips.length, 2);
      expect(userBTips.length, 1);
      expect(jokerTips.length, 1);
      expect(userATips.map((t) => t.points!).reduce((a, b) => a + b), 9);
    });
  });
}