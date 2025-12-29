import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_web/infrastructure/models/tip_model.dart';
import 'package:flutter_web/domain/entities/tip.dart';

void main() {
  group('TipModel', () {
    late DateTime testDate;
    
    setUp(() {
      testDate = DateTime(2024, 6, 15, 19, 30);
    });

    group('Constructor', () {
      test('should create tip model with valid properties', () {
        // Act
        final tipModel = TipModel(
          id: 'user1_match1',
          matchId: 'match1',
          tipDate: testDate,
          tipHome: 2,
          tipGuest: 1,
          joker: true,
          userId: 'user1',
          points: 3,
        );

        // Assert
        expect(tipModel.id, 'user1_match1');
        expect(tipModel.matchId, 'match1');
        expect(tipModel.tipDate, testDate);
        expect(tipModel.tipHome, 2);
        expect(tipModel.tipGuest, 1);
        expect(tipModel.joker, true);
        expect(tipModel.userId, 'user1');
        expect(tipModel.points, 3);
      });

      test('should create tip model with null values', () {
        // Act
        final tipModel = TipModel(
          id: 'user2_match2',
          matchId: null,
          tipDate: testDate,
          tipHome: null,
          tipGuest: null,
          joker: false,
          userId: 'user2',
          points: null,
        );

        // Assert
        expect(tipModel.id, 'user2_match2');
        expect(tipModel.matchId, null);
        expect(tipModel.tipDate, testDate);
        expect(tipModel.tipHome, null);
        expect(tipModel.tipGuest, null);
        expect(tipModel.joker, false);
        expect(tipModel.userId, 'user2');
        expect(tipModel.points, null);
      });
    });

    group('toMap', () {
      test('should convert tip model to map with correct keys', () {
        // Arrange
        final tipModel = TipModel(
          id: 'map_test',
          matchId: 'match_map',
          tipDate: testDate,
          tipHome: 1,
          tipGuest: 0,
          joker: false,
          userId: 'user_map',
          points: 2,
        );

        // Act
        final map = tipModel.toMap();

        // Assert
        expect(map, isA<Map<String, dynamic>>());
        expect(map['id'], 'map_test');
        expect(map['matchId'], 'match_map');
        expect(map['tipDate'], testDate);
        expect(map['tipHome'], 1);
        expect(map['tipGuest'], 0);
        expect(map['joker'], false);
        expect(map['userId'], 'user_map');
        expect(map['points'], 2);
      });

      test('should handle null values in map conversion', () {
        // Arrange
        final tipModel = TipModel(
          id: 'null_test',
          matchId: null,
          tipDate: testDate,
          tipHome: null,
          tipGuest: null,
          joker: true,
          userId: 'user_null',
          points: null,
        );

        // Act
        final map = tipModel.toMap();

        // Assert
        expect(map['matchId'], null);
        expect(map['tipHome'], null);
        expect(map['tipGuest'], null);
        expect(map['points'], null);
        expect(map['joker'], true);
        expect(map['userId'], 'user_null');
      });
    });

    group('fromMap', () {
      test('should create tip model from valid map with Timestamp', () {
        // Arrange
        final timestamp = Timestamp.fromDate(testDate);
        final map = {
          'id': 'frommap_test',
          'matchId': 'match_frommap',
          'tipDate': timestamp,
          'tipHome': 3,
          'tipGuest': 2,
          'joker': true,
          'userId': 'user_frommap',
          'points': 5,
        };

        // Act
        final tipModel = TipModel.fromMap(map);

        // Assert
        expect(tipModel.id, 'frommap_test');
        expect(tipModel.matchId, 'match_frommap');
        expect(tipModel.tipDate, testDate);
        expect(tipModel.tipHome, 3);
        expect(tipModel.tipGuest, 2);
        expect(tipModel.joker, true);
        expect(tipModel.userId, 'user_frommap');
        expect(tipModel.points, 5);
      });

      test('should handle missing optional fields with default values', () {
        // Arrange
        final timestamp = Timestamp.fromDate(testDate);
        final map = {
          'tipDate': timestamp,
          'userId': 'minimal_user',
          // missing optional fields
        };

        // Act
        final tipModel = TipModel.fromMap(map);

        // Assert
        expect(tipModel.id, '');
        expect(tipModel.matchId, null);
        expect(tipModel.tipDate, testDate);
        expect(tipModel.tipHome, null);
        expect(tipModel.tipGuest, null);
        expect(tipModel.joker, false);
        expect(tipModel.userId, 'minimal_user');
        expect(tipModel.points, null);
      });

      test('should handle null values in map', () {
        // Arrange
        final timestamp = Timestamp.fromDate(testDate);
        final map = {
          'id': 'null_values_test',
          'matchId': null,
          'tipDate': timestamp,
          'tipHome': null,
          'tipGuest': null,
          'joker': null, // Should default to false
          'userId': 'user_null_values',
          'points': null,
        };

        // Act
        final tipModel = TipModel.fromMap(map);

        // Assert
        expect(tipModel.matchId, null);
        expect(tipModel.tipHome, null);
        expect(tipModel.tipGuest, null);
        expect(tipModel.joker, false);
        expect(tipModel.points, null);
      });

      test('should handle matchId as number conversion', () {
        // Arrange - Test the toString() conversion in fromMap
        final timestamp = Timestamp.fromDate(testDate);
        final map = {
          'id': 'number_matchid_test',
          'matchId': 12345, // Number instead of string
          'tipDate': timestamp,
          'userId': 'user_number',
          'joker': false,
        };

        // Act
        final tipModel = TipModel.fromMap(map);

        // Assert
        expect(tipModel.matchId, '12345');
      });

      test('should throw when required fields are missing', () {
        // Arrange
        final invalidMap = {
          'id': 'invalid',
          'userId': 'user',
          // missing required tipDate
        };

        // Act & Assert
        expect(
          () => TipModel.fromMap(invalidMap),
          throwsA(isA<TypeError>()),
        );
      });
    });

    group('copyWith', () {
      test('should return new instance with updated properties', () {
        // Arrange
        final newDate = DateTime(2024, 6, 20, 18, 0);
        final originalModel = TipModel(
          id: 'original',
          matchId: 'orig_match',
          tipDate: testDate,
          tipHome: 1,
          tipGuest: 1,
          joker: false,
          userId: 'orig_user',
          points: null,
        );

        // Act
        final updatedModel = originalModel.copyWith(
          tipDate: newDate,
          tipHome: 3,
          tipGuest: 0,
          joker: true,
          points: 6,
        );

        // Assert
        expect(updatedModel.id, originalModel.id);
        expect(updatedModel.matchId, originalModel.matchId);
        expect(updatedModel.tipDate, newDate);
        expect(updatedModel.tipHome, 3);
        expect(updatedModel.tipGuest, 0);
        expect(updatedModel.joker, true);
        expect(updatedModel.userId, originalModel.userId);
        expect(updatedModel.points, 6);
      });

      test('should return identical instance when no properties updated', () {
        // Arrange
        final originalModel = TipModel(
          id: 'unchanged',
          matchId: 'unchanged_match',
          tipDate: testDate,
          tipHome: 2,
          tipGuest: 2,
          joker: true,
          userId: 'unchanged_user',
          points: 1,
        );

        // Act
        final copiedModel = originalModel.copyWith();

        // Assert
        expect(copiedModel.id, originalModel.id);
        expect(copiedModel.matchId, originalModel.matchId);
        expect(copiedModel.tipDate, originalModel.tipDate);
        expect(copiedModel.tipHome, originalModel.tipHome);
        expect(copiedModel.tipGuest, originalModel.tipGuest);
        expect(copiedModel.joker, originalModel.joker);
        expect(copiedModel.userId, originalModel.userId);
        expect(copiedModel.points, originalModel.points);
      });
    });

    group('fromFirestore', () {
      late FakeFirebaseFirestore fakeFirestore;

      setUp(() {
        fakeFirestore = FakeFirebaseFirestore();
      });

      test('should create tip model from firestore document', () async {
        // Arrange
        const tipId = 'firestore_tip';
        final tipData = {
          'matchId': 'fs_match',
          'tipDate': Timestamp.fromDate(testDate),
          'tipHome': 1,
          'tipGuest': 2,
          'joker': false,
          'userId': 'fs_user',
          'points': 1,
        };

        // Add document to fake firestore
        await fakeFirestore.collection('tips').doc(tipId).set(tipData);
        
        // Get the document
        final doc = await fakeFirestore.collection('tips').doc(tipId).get();

        // Act
        final tipModel = TipModel.fromFirestore(doc);

        // Assert
        expect(tipModel.id, tipId);
        expect(tipModel.matchId, 'fs_match');
        expect(tipModel.tipDate, testDate);
        expect(tipModel.tipHome, 1);
        expect(tipModel.tipGuest, 2);
        expect(tipModel.joker, false);
        expect(tipModel.userId, 'fs_user');
        expect(tipModel.points, 1);
      });
    });

    group('toDomain', () {
      test('should convert tip model to domain entity', () {
        // Arrange
        final tipModel = TipModel(
          id: 'domain_test',
          matchId: 'domain_match',
          tipDate: testDate,
          tipHome: 4,
          tipGuest: 1,
          joker: true,
          userId: 'domain_user',
          points: 3,
        );

        // Act
        final domainTip = tipModel.toDomain();

        // Assert
        expect(domainTip, isA<Tip>());
        expect(domainTip.id, 'domain_test');
        expect(domainTip.matchId, 'domain_match');
        expect(domainTip.tipDate, testDate);
        expect(domainTip.tipHome, 4);
        expect(domainTip.tipGuest, 1);
        expect(domainTip.joker, true);
        expect(domainTip.userId, 'domain_user');
        expect(domainTip.points, 3);
      });

      test('should handle null values in domain conversion', () {
        // Arrange
        final tipModel = TipModel(
          id: 'null_domain',
          matchId: null,
          tipDate: testDate,
          tipHome: null,
          tipGuest: null,
          joker: false,
          userId: 'null_user',
          points: null,
        );

        // Act
        final domainTip = tipModel.toDomain();

        // Assert
        expect(domainTip.matchId, null);
        expect(domainTip.tipHome, null);
        expect(domainTip.tipGuest, null);
        expect(domainTip.points, null);
      });
    });

    group('fromDomain', () {
      test('should create tip model from domain entity', () {
        // Arrange
        final domainTip = Tip(
          id: 'from_domain',
          matchId: 'fd_match',
          tipDate: testDate,
          tipHome: 0,
          tipGuest: 3,
          joker: false,
          userId: 'fd_user',
          points: 0,
        );

        // Act
        final tipModel = TipModel.fromDomain(domainTip);

        // Assert
        expect(tipModel, isA<TipModel>());
        expect(tipModel.id, 'from_domain');
        expect(tipModel.matchId, 'fd_match');
        expect(tipModel.tipDate, testDate);
        expect(tipModel.tipHome, 0);
        expect(tipModel.tipGuest, 3);
        expect(tipModel.joker, false);
        expect(tipModel.userId, 'fd_user');
        expect(tipModel.points, 0);
      });

      test('should handle empty domain entity', () {
        // Arrange
        final domainTip = Tip.empty('empty_user');

        // Act
        final tipModel = TipModel.fromDomain(domainTip);

        // Assert
        expect(tipModel.id, '');
        expect(tipModel.matchId, '');
        expect(tipModel.userId, 'empty_user');
        expect(tipModel.tipHome, null);
        expect(tipModel.tipGuest, null);
        expect(tipModel.joker, false);
        expect(tipModel.points, null);
      });
    });

    group('Integration Tests', () {
      test('should maintain data integrity through full conversion cycle', () {
        // Arrange
        final originalDomain = Tip(
          id: 'cycle_test',
          matchId: 'cycle_match',
          tipDate: testDate,
          tipHome: 2,
          tipGuest: 1,
          joker: true,
          userId: 'cycle_user',
          points: 6,
        );

        // Act - Full cycle: Domain -> Model -> Domain
        final model = TipModel.fromDomain(originalDomain);
        final finalDomain = model.toDomain();

        // Assert
        expect(finalDomain.id, originalDomain.id);
        expect(finalDomain.matchId, originalDomain.matchId);
        expect(finalDomain.tipDate, originalDomain.tipDate);
        expect(finalDomain.tipHome, originalDomain.tipHome);
        expect(finalDomain.tipGuest, originalDomain.tipGuest);
        expect(finalDomain.joker, originalDomain.joker);
        expect(finalDomain.userId, originalDomain.userId);
        expect(finalDomain.points, originalDomain.points);
      });

      test('should handle null values through conversion cycle', () {
        // Arrange
        final originalDomain = Tip(
          id: 'null_cycle',
          matchId: null,
          tipDate: testDate,
          tipHome: null,
          tipGuest: null,
          joker: false,
          userId: 'null_cycle_user',
          points: null,
        );

        // Act
        final model = TipModel.fromDomain(originalDomain);
        final finalDomain = model.toDomain();

        // Assert
        expect(finalDomain.matchId, null);
        expect(finalDomain.tipHome, null);
        expect(finalDomain.tipGuest, null);
        expect(finalDomain.points, null);
        expect(finalDomain.id, originalDomain.id);
        expect(finalDomain.userId, originalDomain.userId);
        expect(finalDomain.joker, originalDomain.joker);
      });

      test('should handle extreme values through conversion cycle', () {
        // Arrange
        final extremeDate = DateTime(2100, 12, 31);
        final originalDomain = Tip(
          id: 'extreme_test',
          matchId: 'extreme_match',
          tipDate: extremeDate,
          tipHome: -999,
          tipGuest: 999,
          joker: true,
          userId: 'extreme_user',
          points: -100,
        );

        // Act
        final model = TipModel.fromDomain(originalDomain);
        final finalDomain = model.toDomain();

        // Assert
        expect(finalDomain.tipHome, -999);
        expect(finalDomain.tipGuest, 999);
        expect(finalDomain.points, -100);
        expect(finalDomain.tipDate, extremeDate);
      });

      test('should handle joker functionality scenarios', () {
        // Test cases for different joker scenarios
        final testCases = [
          {
            'description': 'joker with exact match',
            'tipHome': 2,
            'tipGuest': 1,
            'joker': true,
            'points': 6,
          },
          {
            'description': 'normal tip with tendency',
            'tipHome': 1,
            'tipGuest': 0,
            'joker': false,
            'points': 1,
          },
          {
            'description': 'joker with wrong result',
            'tipHome': 0,
            'tipGuest': 1,
            'joker': true,
            'points': 0,
          },
        ];

        for (final testCase in testCases) {
          // Arrange
          final originalDomain = Tip(
            id: 'joker_test_${testCase['description']}',
            matchId: 'joker_match',
            tipDate: testDate,
            tipHome: testCase['tipHome'] as int,
            tipGuest: testCase['tipGuest'] as int,
            joker: testCase['joker'] as bool,
            userId: 'joker_user',
            points: testCase['points'] as int,
          );

          // Act
          final model = TipModel.fromDomain(originalDomain);
          final finalDomain = model.toDomain();

          // Assert
          expect(finalDomain.joker, testCase['joker'], 
            reason: 'Failed for: ${testCase['description']}');
          expect(finalDomain.points, testCase['points'], 
            reason: 'Failed for: ${testCase['description']}');
          expect(finalDomain.tipHome, testCase['tipHome'], 
            reason: 'Failed for: ${testCase['description']}');
          expect(finalDomain.tipGuest, testCase['tipGuest'], 
            reason: 'Failed for: ${testCase['description']}');
        }
      });
    });
  });
}