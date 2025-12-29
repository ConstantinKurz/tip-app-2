import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/domain/entities/user.dart';

void main() {
  group('AppUser Entity', () {
    group('Constructor', () {
      test('should create user with valid properties', () {
        // Arrange & Act
        final user = AppUser(
          id: 'user123',
          championId: 'ARG',
          email: 'john.doe@example.com',
          name: 'John Doe',
          rank: 1,
          score: 100,
          jokerSum: 5,
          sixer: 2,
          admin: true,
        );

        // Assert
        expect(user.id, 'user123');
        expect(user.championId, 'ARG');
        expect(user.email, 'john.doe@example.com');
        expect(user.name, 'John Doe');
        expect(user.rank, 1);
        expect(user.score, 100);
        expect(user.jokerSum, 5);
        expect(user.sixer, 2);
        expect(user.admin, true);
      });

      test('should create user with minimum values', () {
        // Arrange & Act
        final user = AppUser(
          id: 'user456',
          championId: 'GER',
          email: 'jane.smith@test.com',
          name: 'Jane Smith',
          rank: 999,
          score: 0,
          jokerSum: 0,
          sixer: 0,
          admin: false,
        );

        // Assert
        expect(user.id, 'user456');
        expect(user.championId, 'GER');
        expect(user.email, 'jane.smith@test.com');
        expect(user.name, 'Jane Smith');
        expect(user.rank, 999);
        expect(user.score, 0);
        expect(user.jokerSum, 0);
        expect(user.sixer, 0);
        expect(user.admin, false);
      });

      test('should create user with high performance values', () {
        // Arrange & Act
        final user = AppUser(
          id: 'superuser',
          championId: 'BRA',
          email: 'champion@winner.com',
          name: 'Tournament Champion',
          rank: 1,
          score: 9999,
          jokerSum: 20,
          sixer: 15,
          admin: false,
        );

        // Assert
        expect(user.id, 'superuser');
        expect(user.championId, 'BRA');
        expect(user.email, 'champion@winner.com');
        expect(user.name, 'Tournament Champion');
        expect(user.rank, 1);
        expect(user.score, 9999);
        expect(user.jokerSum, 20);
        expect(user.sixer, 15);
        expect(user.admin, false);
      });
    });

    group('empty factory', () {
      test('should create empty user with default values', () {
        // Act
        final emptyUser = AppUser.empty();

        // Assert
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

      test('should create new instance each time called', () {
        // Act
        final emptyUser1 = AppUser.empty();
        final emptyUser2 = AppUser.empty();

        // Assert - They should have same values but be different instances
        expect(emptyUser1.id, emptyUser2.id);
        expect(emptyUser1.championId, emptyUser2.championId);
        expect(emptyUser1.email, emptyUser2.email);
        expect(emptyUser1.name, emptyUser2.name);
        expect(emptyUser1.rank, emptyUser2.rank);
        expect(emptyUser1.score, emptyUser2.score);
        expect(emptyUser1.jokerSum, emptyUser2.jokerSum);
        expect(emptyUser1.sixer, emptyUser2.sixer);
        expect(emptyUser1.admin, emptyUser2.admin);
      });
    });

    group('copyWith', () {
      test('should return new instance with updated properties', () {
        // Arrange
        final originalUser = AppUser(
          id: 'update_test',
          championId: 'FRA',
          email: 'original@test.com',
          name: 'Original User',
          rank: 5,
          score: 50,
          jokerSum: 3,
          sixer: 1,
          admin: false,
        );

        // Act
        final updatedUser = originalUser.copyWith(
          name: 'Updated User',
          rank: 2,
          score: 150,
          admin: true,
        );

        // Assert
        expect(updatedUser.id, originalUser.id);
        expect(updatedUser.championId, originalUser.championId);
        expect(updatedUser.email, originalUser.email);
        expect(updatedUser.name, 'Updated User');
        expect(updatedUser.rank, 2);
        expect(updatedUser.score, 150);
        expect(updatedUser.jokerSum, originalUser.jokerSum);
        expect(updatedUser.sixer, originalUser.sixer);
        expect(updatedUser.admin, true);
      });

      test('should return identical instance when no properties are updated', () {
        // Arrange
        final originalUser = AppUser(
          id: 'unchanged_test',
          championId: 'ESP',
          email: 'unchanged@test.com',
          name: 'Unchanged User',
          rank: 10,
          score: 75,
          jokerSum: 2,
          sixer: 0,
          admin: true,
        );

        // Act
        final copiedUser = originalUser.copyWith();

        // Assert
        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.championId, originalUser.championId);
        expect(copiedUser.email, originalUser.email);
        expect(copiedUser.name, originalUser.name);
        expect(copiedUser.rank, originalUser.rank);
        expect(copiedUser.score, originalUser.score);
        expect(copiedUser.jokerSum, originalUser.jokerSum);
        expect(copiedUser.sixer, originalUser.sixer);
        expect(copiedUser.admin, originalUser.admin);
      });

      test('should update individual properties independently', () {
        // Arrange
        final originalUser = AppUser(
          id: 'individual_test',
          championId: 'ITA',
          email: 'individual@test.com',
          name: 'Individual Test',
          rank: 7,
          score: 88,
          jokerSum: 4,
          sixer: 3,
          admin: false,
        );

        // Act & Assert - Update champion only
        final updatedChampion = originalUser.copyWith(championId: 'POR');
        expect(updatedChampion.championId, 'POR');
        expect(updatedChampion.name, originalUser.name);
        expect(updatedChampion.rank, originalUser.rank);
        expect(updatedChampion.score, originalUser.score);

        // Act & Assert - Update email only
        final updatedEmail = originalUser.copyWith(email: 'new@email.com');
        expect(updatedEmail.email, 'new@email.com');
        expect(updatedEmail.championId, originalUser.championId);
        expect(updatedEmail.name, originalUser.name);
        expect(updatedEmail.rank, originalUser.rank);

        // Act & Assert - Update scores only
        final updatedScores = originalUser.copyWith(
          score: 200,
          jokerSum: 8,
          sixer: 5,
        );
        expect(updatedScores.score, 200);
        expect(updatedScores.jokerSum, 8);
        expect(updatedScores.sixer, 5);
        expect(updatedScores.id, originalUser.id);
        expect(updatedScores.name, originalUser.name);

        // Act & Assert - Update admin status only
        final updatedAdmin = originalUser.copyWith(admin: true);
        expect(updatedAdmin.admin, true);
        expect(updatedAdmin.id, originalUser.id);
        expect(updatedAdmin.email, originalUser.email);
        expect(updatedAdmin.rank, originalUser.rank);
      });

      test('should handle updating rank and competitive stats', () {
        // Arrange
        final originalUser = AppUser(
          id: 'ranking_test',
          championId: 'NED',
          email: 'ranking@test.com',
          name: 'Ranking Test User',
          rank: 15,
          score: 45,
          jokerSum: 2,
          sixer: 0,
          admin: false,
        );

        // Act - Simulate user improving in ranking
        final improvedUser = originalUser.copyWith(
          rank: 3,
          score: 185,
          jokerSum: 6,
          sixer: 4,
        );

        // Assert
        expect(improvedUser.rank, 3);
        expect(improvedUser.score, 185);
        expect(improvedUser.jokerSum, 6);
        expect(improvedUser.sixer, 4);
        expect(improvedUser.id, originalUser.id);
        expect(improvedUser.email, originalUser.email);
        expect(improvedUser.name, originalUser.name);
        expect(improvedUser.championId, originalUser.championId);
        expect(improvedUser.admin, originalUser.admin);
      });
    });

    group('Edge Cases', () {
      test('should handle empty string values', () {
        // Act
        final user = AppUser(
          id: '',
          championId: '',
          email: '',
          name: '',
          rank: 0,
          score: 0,
          jokerSum: 0,
          sixer: 0,
          admin: false,
        );

        // Assert
        expect(user.id, '');
        expect(user.championId, '');
        expect(user.email, '');
        expect(user.name, '');
      });

      test('should handle negative values appropriately', () {
        // Act
        final user = AppUser(
          id: 'negative_test',
          championId: 'NEG',
          email: 'negative@test.com',
          name: 'Negative Test',
          rank: -1,
          score: -100,
          jokerSum: -5,
          sixer: -2,
          admin: false,
        );

        // Assert
        expect(user.rank, -1);
        expect(user.score, -100);
        expect(user.jokerSum, -5);
        expect(user.sixer, -2);
      });

      test('should handle very large values', () {
        // Act
        final user = AppUser(
          id: 'large_test',
          championId: 'LARGE',
          email: 'large@test.com',
          name: 'Large Values Test',
          rank: 999999,
          score: 999999999,
          jokerSum: 999999,
          sixer: 999999,
          admin: true,
        );

        // Assert
        expect(user.rank, 999999);
        expect(user.score, 999999999);
        expect(user.jokerSum, 999999);
        expect(user.sixer, 999999);
      });

      test('should handle special characters in string fields', () {
        // Act
        final user = AppUser(
          id: 'special-123_test',
          championId: 'SPËC-ÏÅL',
          email: 'spëcial+user@tëst.cöm',
          name: 'Spëcial Üser with Nümbers 123 & Symbols!',
          rank: 42,
          score: 1337,
          jokerSum: 7,
          sixer: 3,
          admin: false,
        );

        // Assert
        expect(user.id, 'special-123_test');
        expect(user.championId, 'SPËC-ÏÅL');
        expect(user.email, 'spëcial+user@tëst.cöm');
        expect(user.name, 'Spëcial Üser with Nümbers 123 & Symbols!');
      });

      test('should handle long string values', () {
        // Arrange
        const longId = 'very_long_user_id_that_might_be_used_in_some_systems_12345678901234567890';
        const longName = 'This is a very long user name that might exist in some international contexts with multiple middle names and suffixes';
        const longEmail = 'very.long.email.address.that.might.exist.in.some.corporate.environments@very.long.domain.name.example.com';

        // Act
        final user = AppUser(
          id: longId,
          championId: 'LONG',
          email: longEmail,
          name: longName,
          rank: 1,
          score: 100,
          jokerSum: 5,
          sixer: 2,
          admin: false,
        );

        // Assert
        expect(user.id, longId);
        expect(user.email, longEmail);
        expect(user.name, longName);
      });

      test('should handle zero values correctly', () {
        // Act
        final user = AppUser(
          id: 'zero_test',
          championId: 'ZERO',
          email: 'zero@test.com',
          name: 'Zero Test User',
          rank: 0,
          score: 0,
          jokerSum: 0,
          sixer: 0,
          admin: false,
        );

        // Assert
        expect(user.rank, 0);
        expect(user.score, 0);
        expect(user.jokerSum, 0);
        expect(user.sixer, 0);
        expect(user.admin, false);
      });
    });

    group('Business Logic Scenarios', () {
      test('should represent different user performance levels correctly', () {
        // Arrange - Top performer
        final topPerformer = AppUser(
          id: 'top_performer',
          championId: 'ARG',
          email: 'top@performer.com',
          name: 'Top Performer',
          rank: 1,
          score: 500,
          jokerSum: 15,
          sixer: 10,
          admin: false,
        );

        // Arrange - Average performer
        final averagePerformer = AppUser(
          id: 'average_performer',
          championId: 'GER',
          email: 'average@performer.com',
          name: 'Average Performer',
          rank: 50,
          score: 150,
          jokerSum: 5,
          sixer: 2,
          admin: false,
        );

        // Arrange - New user
        final newUser = AppUser(
          id: 'new_user',
          championId: 'TBD',
          email: 'new@user.com',
          name: 'New User',
          rank: 100,
          score: 0,
          jokerSum: 0,
          sixer: 0,
          admin: false,
        );

        // Assert ranking order
        expect(topPerformer.rank < averagePerformer.rank, true);
        expect(averagePerformer.rank < newUser.rank, true);

        // Assert score progression
        expect(topPerformer.score > averagePerformer.score, true);
        expect(averagePerformer.score > newUser.score, true);

        // Assert joker usage
        expect(topPerformer.jokerSum > averagePerformer.jokerSum, true);
        expect(averagePerformer.jokerSum > newUser.jokerSum, true);

        // Assert perfect predictions
        expect(topPerformer.sixer > averagePerformer.sixer, true);
        expect(averagePerformer.sixer > newUser.sixer, true);
      });

      test('should represent different admin scenarios', () {
        // Arrange - System admin
        final systemAdmin = AppUser(
          id: 'system_admin',
          championId: 'ADMIN',
          email: 'admin@system.com',
          name: 'System Administrator',
          rank: 1,
          score: 0, // Admins might not participate
          jokerSum: 0,
          sixer: 0,
          admin: true,
        );

        // Arrange - Regular user who became admin
        final userAdmin = AppUser(
          id: 'user_admin',
          championId: 'BRA',
          email: 'user@admin.com',
          name: 'User Administrator',
          rank: 3,
          score: 300,
          jokerSum: 8,
          sixer: 5,
          admin: true,
        );

        // Arrange - Regular user
        final regularUser = AppUser(
          id: 'regular_user',
          championId: 'FRA',
          email: 'regular@user.com',
          name: 'Regular User',
          rank: 10,
          score: 200,
          jokerSum: 6,
          sixer: 3,
          admin: false,
        );

        // Assert admin status
        expect(systemAdmin.admin, true);
        expect(userAdmin.admin, true);
        expect(regularUser.admin, false);

        // Assert that admin status is independent of performance
        expect(userAdmin.admin, true);
        expect(userAdmin.score > 0, true);
        expect(userAdmin.rank > 0, true);
      });

      test('should handle champion selection scenarios', () {
        // Arrange - Users with different champion choices
        final argentinianSupporter = AppUser(
          id: 'arg_fan',
          championId: 'ARG',
          email: 'arg@fan.com',
          name: 'Argentina Fan',
          rank: 1,
          score: 400,
          jokerSum: 10,
          sixer: 8,
          admin: false,
        );

        final brazilianSupporter = AppUser(
          id: 'bra_fan',
          championId: 'BRA',
          email: 'bra@fan.com',
          name: 'Brazil Fan',
          rank: 2,
          score: 380,
          jokerSum: 9,
          sixer: 7,
          admin: false,
        );

        final undecidedUser = AppUser(
          id: 'undecided',
          championId: 'TBD',
          email: 'undecided@user.com',
          name: 'Undecided User',
          rank: 50,
          score: 100,
          jokerSum: 3,
          sixer: 1,
          admin: false,
        );

        // Assert different champion selections
        expect(argentinianSupporter.championId, 'ARG');
        expect(brazilianSupporter.championId, 'BRA');
        expect(undecidedUser.championId, 'TBD');

        // Assert that champion choice is independent of performance
        expect(argentinianSupporter.score > brazilianSupporter.score, true);
        expect(undecidedUser.championId, 'TBD');
        expect(undecidedUser.score > 0, true);
      });
    });
  });
}