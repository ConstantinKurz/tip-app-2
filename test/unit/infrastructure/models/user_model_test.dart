import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_web/infrastructure/models/user_model.dart';
import 'package:flutter_web/domain/entities/user.dart';

void main() {
  group('UserModel', () {
    group('Constructor', () {
      test('should create user model with valid properties', () {
        // Act
        final userModel = UserModel(
          id: 'user123',
          championId: 'ARG',
          email: 'test@example.com',
          name: 'Test User',
          rank: 1,
          score: 100,
          jokerSum: 5,
          sixer: 3,
          admin: true,
        );

        // Assert
        expect(userModel.id, 'user123');
        expect(userModel.championId, 'ARG');
        expect(userModel.email, 'test@example.com');
        expect(userModel.name, 'Test User');
        expect(userModel.rank, 1);
        expect(userModel.score, 100);
        expect(userModel.jokerSum, 5);
        expect(userModel.sixer, 3);
        expect(userModel.admin, true);
      });

      test('should create user model with minimum values', () {
        // Act
        final userModel = UserModel(
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
        expect(userModel.id, '');
        expect(userModel.championId, '');
        expect(userModel.email, '');
        expect(userModel.name, '');
        expect(userModel.rank, 0);
        expect(userModel.score, 0);
        expect(userModel.jokerSum, 0);
        expect(userModel.sixer, 0);
        expect(userModel.admin, false);
      });
    });

    group('fromMap', () {
      test('should create user model from valid map', () {
        // Arrange
        final map = {
          'id': 'frommap_user',
          'champion_id': 'GER',
          'email': 'frommap@test.com',
          'name': 'FromMap User',
          'rank': 5,
          'score': 250,
          'jokerSum': 8,
          'sixer': 4,
          'admin': true,
        };

        // Act
        final userModel = UserModel.fromMap(map);

        // Assert
        expect(userModel.id, 'frommap_user');
        expect(userModel.championId, 'GER');
        expect(userModel.email, 'frommap@test.com');
        expect(userModel.name, 'FromMap User');
        expect(userModel.rank, 5);
        expect(userModel.score, 250);
        expect(userModel.jokerSum, 8);
        expect(userModel.sixer, 4);
        expect(userModel.admin, true);
      });

      test('should handle missing fields with default values', () {
        // Arrange
        final map = {
          'email': 'minimal@test.com',
          'name': 'Minimal User',
          // missing optional fields
        };

        // Act
        final userModel = UserModel.fromMap(map);

        // Assert
        expect(userModel.id, '');
        expect(userModel.championId, '');
        expect(userModel.email, 'minimal@test.com');
        expect(userModel.name, 'Minimal User');
        expect(userModel.rank, 0);
        expect(userModel.score, 0);
        expect(userModel.jokerSum, 0);
        expect(userModel.sixer, 0);
        expect(userModel.admin, false);
      });

      test('should handle null values with defaults', () {
        // Arrange
        final map = {
          'id': null,
          'champion_id': null,
          'email': null,
          'name': null,
          'rank': null,
          'score': null,
          'jokerSum': null,
          'sixer': null,
          'admin': null,
        };

        // Act
        final userModel = UserModel.fromMap(map);

        // Assert
        expect(userModel.id, '');
        expect(userModel.championId, '');
        expect(userModel.email, '');
        expect(userModel.name, '');
        expect(userModel.rank, 0);
        expect(userModel.score, 0);
        expect(userModel.jokerSum, 0);
        expect(userModel.sixer, 0);
        expect(userModel.admin, false);
      });

      test('should handle mixed valid and null values', () {
        // Arrange
        final map = {
          'id': 'mixed_test',
          'champion_id': 'FRA',
          'email': null,
          'name': 'Mixed User',
          'rank': 10,
          'score': null,
          'jokerSum': 3,
          'sixer': null,
          'admin': true,
        };

        // Act
        final userModel = UserModel.fromMap(map);

        // Assert
        expect(userModel.id, 'mixed_test');
        expect(userModel.championId, 'FRA');
        expect(userModel.email, '');
        expect(userModel.name, 'Mixed User');
        expect(userModel.rank, 10);
        expect(userModel.score, 0);
        expect(userModel.jokerSum, 3);
        expect(userModel.sixer, 0);
        expect(userModel.admin, true);
      });
    });

    group('fromFirestore', () {
      late FakeFirebaseFirestore fakeFirestore;

      setUp(() {
        fakeFirestore = FakeFirebaseFirestore();
      });

      test('should create user model from firestore document', () async {
        // Arrange
        const userId = 'firestore_user';
        final userData = {
          'champion_id': 'ESP',
          'email': 'firestore@test.com',
          'name': 'Firestore User',
          'rank': 3,
          'score': 180,
          'jokerSum': 6,
          'sixer': 2,
          'admin': false,
        };

        // Add document to fake firestore
        await fakeFirestore.collection('users').doc(userId).set(userData);
        
        // Get the document
        final doc = await fakeFirestore.collection('users').doc(userId).get();

        // Act
        final userModel = UserModel.fromFirestore(doc);

        // Assert
        expect(userModel.id, userId);
        expect(userModel.championId, 'ESP');
        expect(userModel.email, 'firestore@test.com');
        expect(userModel.name, 'Firestore User');
        expect(userModel.rank, 3);
        expect(userModel.score, 180);
        expect(userModel.jokerSum, 6);
        expect(userModel.sixer, 2);
        expect(userModel.admin, false);
      });

      test('should handle firestore document with missing fields', () async {
        // Arrange
        const userId = 'minimal_firestore_user';
        final userData = {
          'email': 'minimal@firestore.com',
          'name': 'Minimal Firestore User',
        };

        await fakeFirestore.collection('users').doc(userId).set(userData);
        final doc = await fakeFirestore.collection('users').doc(userId).get();

        // Act
        final userModel = UserModel.fromFirestore(doc);

        // Assert
        expect(userModel.id, userId);
        expect(userModel.email, 'minimal@firestore.com');
        expect(userModel.name, 'Minimal Firestore User');
        expect(userModel.championId, '');
        expect(userModel.rank, 0);
        expect(userModel.score, 0);
        expect(userModel.jokerSum, 0);
        expect(userModel.sixer, 0);
        expect(userModel.admin, false);
      });
    });

    group('copyWith', () {
      test('should return new instance with updated properties', () {
        // Arrange
        final originalModel = UserModel(
          id: 'original',
          championId: 'ITA',
          email: 'original@test.com',
          name: 'Original User',
          rank: 15,
          score: 75,
          jokerSum: 4,
          sixer: 1,
          admin: false,
        );

        // Act
        final updatedModel = originalModel.copyWith(
          name: 'Updated User',
          rank: 5,
          score: 200,
          admin: true,
        );

        // Assert
        expect(updatedModel.id, originalModel.id);
        expect(updatedModel.championId, originalModel.championId);
        expect(updatedModel.email, originalModel.email);
        expect(updatedModel.name, 'Updated User');
        expect(updatedModel.rank, 5);
        expect(updatedModel.score, 200);
        expect(updatedModel.jokerSum, originalModel.jokerSum);
        expect(updatedModel.sixer, originalModel.sixer);
        expect(updatedModel.admin, true);
      });

      test('should return identical instance when no properties updated', () {
        // Arrange
        final originalModel = UserModel(
          id: 'unchanged',
          championId: 'POR',
          email: 'unchanged@test.com',
          name: 'Unchanged User',
          rank: 8,
          score: 125,
          jokerSum: 7,
          sixer: 5,
          admin: true,
        );

        // Act
        final copiedModel = originalModel.copyWith();

        // Assert
        expect(copiedModel.id, originalModel.id);
        expect(copiedModel.championId, originalModel.championId);
        expect(copiedModel.email, originalModel.email);
        expect(copiedModel.name, originalModel.name);
        expect(copiedModel.rank, originalModel.rank);
        expect(copiedModel.score, originalModel.score);
        expect(copiedModel.jokerSum, originalModel.jokerSum);
        expect(copiedModel.sixer, originalModel.sixer);
        expect(copiedModel.admin, originalModel.admin);
      });
    });

    group('toMap', () {
      test('should convert user model to map with correct keys', () {
        // Arrange
        final userModel = UserModel(
          id: 'map_test',
          championId: 'NED',
          email: 'map@test.com',
          name: 'Map Test User',
          rank: 12,
          score: 300,
          jokerSum: 9,
          sixer: 6,
          admin: false,
        );

        // Act
        final map = userModel.toMap();

        // Assert
        expect(map, isA<Map<String, dynamic>>());
        expect(map['id'], 'map_test');
        expect(map['champion_id'], 'NED');
        expect(map['email'], 'map@test.com');
        expect(map['name'], 'Map Test User');
        expect(map['rank'], 12);
        expect(map['score'], 300);
        expect(map['jokerSum'], 9);
        expect(map['sixer'], 6);
        expect(map['admin'], false);
      });

      test('should handle edge case values in map conversion', () {
        // Arrange
        final userModel = UserModel(
          id: '',
          championId: '',
          email: '',
          name: '',
          rank: 0,
          score: 0,
          jokerSum: 0,
          sixer: 0,
          admin: true,
        );

        // Act
        final map = userModel.toMap();

        // Assert
        expect(map['id'], '');
        expect(map['champion_id'], '');
        expect(map['email'], '');
        expect(map['name'], '');
        expect(map['rank'], 0);
        expect(map['score'], 0);
        expect(map['jokerSum'], 0);
        expect(map['sixer'], 0);
        expect(map['admin'], true);
      });
    });

    group('toDomain', () {
      test('should convert user model to domain entity', () {
        // Arrange
        final userModel = UserModel(
          id: 'domain_test',
          championId: 'BRA',
          email: 'domain@test.com',
          name: 'Domain Test User',
          rank: 2,
          score: 400,
          jokerSum: 12,
          sixer: 8,
          admin: true,
        );

        // Act
        final domainUser = userModel.toDomain();

        // Assert
        expect(domainUser, isA<AppUser>());
        expect(domainUser.id, 'domain_test');
        expect(domainUser.championId, 'BRA');
        expect(domainUser.email, 'domain@test.com');
        expect(domainUser.name, 'Domain Test User');
        expect(domainUser.rank, 2);
        expect(domainUser.score, 400);
        expect(domainUser.jokerSum, 12);
        expect(domainUser.sixer, 8);
        expect(domainUser.admin, true);
      });

      test('should handle minimal values in domain conversion', () {
        // Arrange
        final userModel = UserModel(
          id: '',
          championId: 'TBD',
          email: '',
          name: '',
          rank: 0,
          score: 0,
          jokerSum: 0,
          sixer: 0,
          admin: false,
        );

        // Act
        final domainUser = userModel.toDomain();

        // Assert
        expect(domainUser.id, '');
        expect(domainUser.championId, 'TBD');
        expect(domainUser.email, '');
        expect(domainUser.name, '');
        expect(domainUser.rank, 0);
        expect(domainUser.score, 0);
        expect(domainUser.jokerSum, 0);
        expect(domainUser.sixer, 0);
        expect(domainUser.admin, false);
      });
    });

    group('fromDomain', () {
      test('should create user model from domain entity', () {
        // Arrange
        final domainUser = AppUser(
          id: 'from_domain',
          championId: 'ARG',
          email: 'fromdomain@test.com',
          name: 'From Domain User',
          rank: 6,
          score: 150,
          jokerSum: 5,
          sixer: 3,
          admin: false,
        );

        // Act
        final userModel = UserModel.fromDomain(domainUser);

        // Assert
        expect(userModel, isA<UserModel>());
        expect(userModel.id, 'from_domain');
        expect(userModel.championId, 'ARG');
        expect(userModel.email, 'fromdomain@test.com');
        expect(userModel.name, 'From Domain User');
        expect(userModel.rank, 6);
        expect(userModel.score, 150);
        expect(userModel.jokerSum, 5);
        expect(userModel.sixer, 3);
        expect(userModel.admin, false);
      });

      test('should handle empty domain entity', () {
        // Arrange
        final domainUser = AppUser.empty();

        // Act
        final userModel = UserModel.fromDomain(domainUser);

        // Assert
        expect(userModel.id, '');
        expect(userModel.championId, 'TBD');
        expect(userModel.email, '');
        expect(userModel.name, '');
        expect(userModel.rank, 0);
        expect(userModel.score, 0);
        expect(userModel.jokerSum, 0);
        expect(userModel.sixer, 0);
        expect(userModel.admin, false);
      });
    });

    group('empty factory', () {
      test('should create empty user model with provided username and email', () {
        // Act
        final emptyModel = UserModel.empty('testuser', 'test@empty.com');

        // Assert
        expect(emptyModel.id, 'testuser');
        expect(emptyModel.championId, 'TBD');
        expect(emptyModel.name, 'testuser');
        expect(emptyModel.email, 'test@empty.com');
        expect(emptyModel.rank, 0);
        expect(emptyModel.score, 0);
        expect(emptyModel.jokerSum, 0);
        expect(emptyModel.sixer, 0);
        expect(emptyModel.admin, false);
      });

      test('should create empty user with different usernames', () {
        // Act
        final model1 = UserModel.empty('user1', 'user1@test.com');
        final model2 = UserModel.empty('user2', 'user2@test.com');

        // Assert
        expect(model1.id, 'user1');
        expect(model1.name, 'user1');
        expect(model1.email, 'user1@test.com');
        expect(model2.id, 'user2');
        expect(model2.name, 'user2');
        expect(model2.email, 'user2@test.com');
      });
    });

    group('Integration Tests', () {
      test('should maintain data integrity through full conversion cycle', () {
        // Arrange
        final originalDomain = AppUser(
          id: 'cycle_test',
          championId: 'GER',
          email: 'cycle@test.com',
          name: 'Cycle Test User',
          rank: 4,
          score: 275,
          jokerSum: 8,
          sixer: 4,
          admin: true,
        );

        // Act - Full cycle: Domain -> Model -> Map -> Model -> Domain
        final model1 = UserModel.fromDomain(originalDomain);
        final map = model1.toMap();
        final model2 = UserModel.fromMap(map);
        final finalDomain = model2.toDomain();

        // Assert
        expect(finalDomain.id, originalDomain.id);
        expect(finalDomain.championId, originalDomain.championId);
        expect(finalDomain.email, originalDomain.email);
        expect(finalDomain.name, originalDomain.name);
        expect(finalDomain.rank, originalDomain.rank);
        expect(finalDomain.score, originalDomain.score);
        expect(finalDomain.jokerSum, originalDomain.jokerSum);
        expect(finalDomain.sixer, originalDomain.sixer);
        expect(finalDomain.admin, originalDomain.admin);
      });

      test('should handle extreme values through conversion cycle', () {
        // Arrange
        final originalDomain = AppUser(
          id: 'extreme_test',
          championId: 'EXTREME_CHAMPION',
          email: 'extreme@verylongdomainname.example.com',
          name: 'Extreme Test User with Very Long Name',
          rank: -999,
          score: 999999,
          jokerSum: -100,
          sixer: 500,
          admin: false,
        );

        // Act
        final model = UserModel.fromDomain(originalDomain);
        final map = model.toMap();
        final reconstructedModel = UserModel.fromMap(map);
        final reconstructedDomain = reconstructedModel.toDomain();

        // Assert
        expect(reconstructedDomain.rank, -999);
        expect(reconstructedDomain.score, 999999);
        expect(reconstructedDomain.jokerSum, -100);
        expect(reconstructedDomain.sixer, 500);
        expect(reconstructedDomain.id, originalDomain.id);
      });

      test('should handle special characters through conversion cycle', () {
        // Arrange
        final originalDomain = AppUser(
          id: 'special-123_test',
          championId: 'SPËC-ÏÅL',
          email: 'spëcial+user@tëst.cöm',
          name: 'Spëcial Üser with Nümbers 123 & Symbols!',
          rank: 42,
          score: 1337,
          jokerSum: 7,
          sixer: 3,
          admin: true,
        );

        // Act
        final model = UserModel.fromDomain(originalDomain);
        final map = model.toMap();
        final reconstructedModel = UserModel.fromMap(map);
        final reconstructedDomain = reconstructedModel.toDomain();

        // Assert
        expect(reconstructedDomain.id, originalDomain.id);
        expect(reconstructedDomain.championId, originalDomain.championId);
        expect(reconstructedDomain.email, originalDomain.email);
        expect(reconstructedDomain.name, originalDomain.name);
      });

      test('should handle admin flag scenarios correctly', () {
        final testCases = [
          {'isAdmin': true, 'description': 'admin user'},
          {'isAdmin': false, 'description': 'regular user'},
        ];

        for (final testCase in testCases) {
          // Arrange
          final originalDomain = AppUser(
            id: 'admin_test_${testCase['description']}',
            championId: 'ADMIN_TEST',
            email: 'admin@test.com',
            name: 'Admin Test User',
            rank: 1,
            score: 500,
            jokerSum: 10,
            sixer: 5,
            admin: testCase['isAdmin'] as bool,
          );

          // Act
          final model = UserModel.fromDomain(originalDomain);
          final reconstructedDomain = model.toDomain();

          // Assert
          expect(reconstructedDomain.admin, testCase['isAdmin'],
            reason: 'Failed for: ${testCase['description']}');
        }
      });

      test('should handle ranking scenarios correctly', () {
        final testCases = [
          {'rank': 1, 'score': 500, 'description': 'top performer'},
          {'rank': 50, 'score': 100, 'description': 'average performer'},
          {'rank': 999, 'score': 0, 'description': 'new user'},
        ];

        for (final testCase in testCases) {
          // Arrange
          final originalDomain = AppUser(
            id: 'ranking_test_${testCase['description']}',
            championId: 'RANKING_TEST',
            email: 'ranking@test.com',
            name: 'Ranking Test User',
            rank: testCase['rank'] as int,
            score: testCase['score'] as int,
            jokerSum: 5,
            sixer: 2,
            admin: false,
          );

          // Act
          final model = UserModel.fromDomain(originalDomain);
          final reconstructedDomain = model.toDomain();

          // Assert
          expect(reconstructedDomain.rank, testCase['rank'],
            reason: 'Failed for: ${testCase['description']}');
          expect(reconstructedDomain.score, testCase['score'],
            reason: 'Failed for: ${testCase['description']}');
        }
      });
    });
  });
}