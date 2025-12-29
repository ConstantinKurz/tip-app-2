import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';

void main() {
  group('Auth Repository Logic Tests', () {
    test('AppUser entity should have correct structure', () {
      final user = AppUser(
        id: 'user_123',
        championId: 'team_456',
        email: 'test@example.com',
        name: 'testuser',
        rank: 5,
        score: 120,
        jokerSum: 2,
        sixer: 1,
        admin: false,
      );

      expect(user.id, 'user_123');
      expect(user.championId, 'team_456');
      expect(user.email, 'test@example.com');
      expect(user.name, 'testuser');
      expect(user.rank, 5);
      expect(user.score, 120);
      expect(user.jokerSum, 2);
      expect(user.sixer, 1);
      expect(user.admin, false);
    });

    test('AppUser.empty should create valid user', () {
      final emptyUser = AppUser.empty();

      expect(emptyUser.id, '');
      expect(emptyUser.championId, 'TBD');
      expect(emptyUser.email, '');
      expect(emptyUser.name, '');
      expect(emptyUser.rank, 0);
      expect(emptyUser.score, 0);
      expect(emptyUser.jokerSum, 0);
      expect(emptyUser.sixer, 0);
      expect(emptyUser.admin, false);
    });

    test('AppUser copyWith should work correctly', () {
      final original = AppUser(
        id: 'user_1',
        championId: 'team_1',
        email: 'original@example.com',
        name: 'original',
        rank: 10,
        score: 50,
        jokerSum: 1,
        sixer: 0,
        admin: false,
      );

      final updated = original.copyWith(
        rank: 3,
        score: 150,
        championId: 'team_winner',
      );

      expect(updated.id, 'user_1');
      expect(updated.name, 'original');
      expect(updated.email, 'original@example.com');
      expect(updated.rank, 3);
      expect(updated.score, 150);
      expect(updated.championId, 'team_winner');
    });

    test('AppUser should handle admin flags correctly', () {
      final regularUser = AppUser(
        id: 'regular',
        championId: 'team_1',
        email: 'regular@example.com',
        name: 'regularuser',
        rank: 1,
        score: 200,
        jokerSum: 3,
        sixer: 2,
        admin: false,
      );

      final adminUser = AppUser(
        id: 'admin',
        championId: 'team_2',
        email: 'admin@example.com',
        name: 'adminuser',
        rank: 0,
        score: 0,
        jokerSum: 0,
        sixer: 0,
        admin: true,
      );

      expect(regularUser.admin, false);
      expect(adminUser.admin, true);
    });
  });

  group('AuthFailure Types', () {
    test('should create all auth failure types', () {
      final emailAlreadyInUse = EmailAlreadyInUseFailure();
      final serverFailure = ServerFailure();
      final insufficientPermissions = InsufficientPermisssons();
      final userNotFound = UserNotFoundFailure(message: 'Not found');

      expect(emailAlreadyInUse, isA<AuthFailure>());
      expect(serverFailure, isA<AuthFailure>());
      expect(insufficientPermissions, isA<AuthFailure>());
      expect(userNotFound, isA<AuthFailure>());
    });

    test('should distinguish between auth failure types', () {
      final failure1 = EmailAlreadyInUseFailure();
      final failure2 = ServerFailure();
      final failure3 = InsufficientPermisssons();

      expect(failure1.runtimeType, isNot(failure2.runtimeType));
      expect(failure2.runtimeType, isNot(failure3.runtimeType));
      expect(failure1.runtimeType, isNot(failure3.runtimeType));
    });
  });

  group('Either Type Handling', () {
    test('should handle Either return types for auth', () {
      final successResult = right<AuthFailure, Unit>(unit);
      final failureResult = left<AuthFailure, Unit>(EmailAlreadyInUseFailure());

      expect(successResult.isRight(), true);
      expect(failureResult.isLeft(), true);
    });
  });

  group('User Data Management Logic', () {
    test('should handle user ranking and scoring', () {
      final users = [
        AppUser(
          id: '1', 
          championId: 'team_1', 
          email: 'user1@test.com', 
          name: 'user1',
          rank: 1, 
          score: 200, 
          jokerSum: 3, 
          sixer: 2, 
          admin: false,
        ),
        AppUser(
          id: '2', 
          championId: 'team_2', 
          email: 'user2@test.com', 
          name: 'user2',
          rank: 2, 
          score: 180, 
          jokerSum: 2, 
          sixer: 1, 
          admin: false,
        ),
      ];

      final sortedByRank = users..sort((a, b) => a.rank.compareTo(b.rank));
      final sortedByScore = users..sort((a, b) => b.score.compareTo(a.score));

      expect(sortedByRank.first.rank, 1);
      expect(sortedByScore.first.score, 200);
    });
  });
}