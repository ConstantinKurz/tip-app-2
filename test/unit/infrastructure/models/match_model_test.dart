import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_web/infrastructure/models/match_model.dart';
import 'package:flutter_web/domain/entities/match.dart';

void main() {
  group('MatchModel', () {
    late DateTime testDate;
    
    setUp(() {
      testDate = DateTime(2024, 6, 15, 21, 0);
    });

    group('Constructor', () {
      test('should create match model with valid properties', () {
        // Act
        final matchModel = MatchModel(
          id: 'match1',
          homeTeamId: 'ger',
          guestTeamId: 'fra',
          matchDate: testDate,
          matchDay: 1,
          homeScore: 2,
          guestScore: 1,
        );

        // Assert
        expect(matchModel.id, 'match1');
        expect(matchModel.homeTeamId, 'ger');
        expect(matchModel.guestTeamId, 'fra');
        expect(matchModel.matchDate, testDate);
        expect(matchModel.matchDay, 1);
        expect(matchModel.homeScore, 2);
        expect(matchModel.guestScore, 1);
      });

      test('should create match model with null scores', () {
        // Act
        final matchModel = MatchModel(
          id: 'future_match',
          homeTeamId: 'esp',
          guestTeamId: 'ita',
          matchDate: testDate,
          matchDay: 2,
          homeScore: null,
          guestScore: null,
        );

        // Assert
        expect(matchModel.id, 'future_match');
        expect(matchModel.homeTeamId, 'esp');
        expect(matchModel.guestTeamId, 'ita');
        expect(matchModel.matchDate, testDate);
        expect(matchModel.matchDay, 2);
        expect(matchModel.homeScore, null);
        expect(matchModel.guestScore, null);
      });
    });

    group('toMap', () {
      test('should convert match model to map with correct keys', () {
        // Arrange
        final matchModel = MatchModel(
          id: 'map_test',
          homeTeamId: 'bra',
          guestTeamId: 'arg',
          matchDate: testDate,
          matchDay: 3,
          homeScore: 1,
          guestScore: 0,
        );

        // Act
        final map = matchModel.toMap();

        // Assert
        expect(map, isA<Map<String, dynamic>>());
        expect(map['homeTeamId'], 'bra');
        expect(map['guestTeamId'], 'arg');
        expect(map['matchDate'], testDate);
        expect(map['matchDay'], 3);
        expect(map['homeScore'], 1);
        expect(map['guestScore'], 0);
        // Note: id is not included in toMap() method
        expect(map.containsKey('id'), false);
      });

      test('should handle null scores in map conversion', () {
        // Arrange
        final matchModel = MatchModel(
          id: 'null_scores',
          homeTeamId: 'team1',
          guestTeamId: 'team2',
          matchDate: testDate,
          matchDay: 1,
          homeScore: null,
          guestScore: null,
        );

        // Act
        final map = matchModel.toMap();

        // Assert
        expect(map['homeScore'], null);
        expect(map['guestScore'], null);
        expect(map['homeTeamId'], 'team1');
        expect(map['guestTeamId'], 'team2');
      });
    });

    group('fromMap', () {
      test('should create match model from valid map with Timestamp', () {
        // Arrange
        final timestamp = Timestamp.fromDate(testDate);
        final map = {
          'id': 'frommap_test',
          'homeTeamId': 'por',
          'guestTeamId': 'bel',
          'matchDate': timestamp,
          'matchDay': 4,
          'homeScore': 3,
          'guestScore': 2,
        };

        // Act
        final matchModel = MatchModel.fromMap(map);

        // Assert
        expect(matchModel.id, 'frommap_test');
        expect(matchModel.homeTeamId, 'por');
        expect(matchModel.guestTeamId, 'bel');
        expect(matchModel.matchDate, testDate);
        expect(matchModel.matchDay, 4);
        expect(matchModel.homeScore, 3);
        expect(matchModel.guestScore, 2);
      });

      test('should handle missing optional fields with default values', () {
        // Arrange
        final timestamp = Timestamp.fromDate(testDate);
        final map = {
          'homeTeamId': 'home',
          'guestTeamId': 'guest',
          'matchDate': timestamp,
          // missing id, matchDay, scores
        };

        // Act
        final matchModel = MatchModel.fromMap(map);

        // Assert
        expect(matchModel.id, '');
        expect(matchModel.homeTeamId, 'home');
        expect(matchModel.guestTeamId, 'guest');
        expect(matchModel.matchDate, testDate);
        expect(matchModel.matchDay, 0);
        expect(matchModel.homeScore, null);
        expect(matchModel.guestScore, null);
      });

      test('should handle null scores in map', () {
        // Arrange
        final timestamp = Timestamp.fromDate(testDate);
        final map = {
          'id': 'null_test',
          'homeTeamId': 'team_a',
          'guestTeamId': 'team_b',
          'matchDate': timestamp,
          'matchDay': 1,
          'homeScore': null,
          'guestScore': null,
        };

        // Act
        final matchModel = MatchModel.fromMap(map);

        // Assert
        expect(matchModel.homeScore, null);
        expect(matchModel.guestScore, null);
      });

      test('should throw when required fields are missing', () {
        // Arrange
        final invalidMap = {
          'id': 'invalid',
          'homeTeamId': 'home',
          // missing required fields
        };

        // Act & Assert
        expect(
          () => MatchModel.fromMap(invalidMap),
          throwsA(isA<TypeError>()),
        );
      });
    });

    group('copyWith', () {
      test('should return new instance with updated properties', () {
        // Arrange
        final newDate = DateTime(2024, 6, 20, 18, 0);
        final originalModel = MatchModel(
          id: 'original',
          homeTeamId: 'orig_home',
          guestTeamId: 'orig_guest',
          matchDate: testDate,
          matchDay: 1,
          homeScore: null,
          guestScore: null,
        );

        // Act
        final updatedModel = originalModel.copyWith(
          matchDate: newDate,
          matchDay: 5,
          homeScore: 2,
          guestScore: 1,
        );

        // Assert
        expect(updatedModel.id, originalModel.id);
        expect(updatedModel.homeTeamId, originalModel.homeTeamId);
        expect(updatedModel.guestTeamId, originalModel.guestTeamId);
        expect(updatedModel.matchDate, newDate);
        expect(updatedModel.matchDay, 5);
        expect(updatedModel.homeScore, 2);
        expect(updatedModel.guestScore, 1);
      });

      test('should return identical instance when no properties updated', () {
        // Arrange
        final originalModel = MatchModel(
          id: 'unchanged',
          homeTeamId: 'home_unchanged',
          guestTeamId: 'guest_unchanged',
          matchDate: testDate,
          matchDay: 2,
          homeScore: 1,
          guestScore: 1,
        );

        // Act
        final copiedModel = originalModel.copyWith();

        // Assert
        expect(copiedModel.id, originalModel.id);
        expect(copiedModel.homeTeamId, originalModel.homeTeamId);
        expect(copiedModel.guestTeamId, originalModel.guestTeamId);
        expect(copiedModel.matchDate, originalModel.matchDate);
        expect(copiedModel.matchDay, originalModel.matchDay);
        expect(copiedModel.homeScore, originalModel.homeScore);
        expect(copiedModel.guestScore, originalModel.guestScore);
      });
    });

    group('fromFirestore', () {
      late FakeFirebaseFirestore fakeFirestore;

      setUp(() {
        fakeFirestore = FakeFirebaseFirestore();
      });

      test('should create match model from firestore document', () async {
        // Arrange
        const matchId = 'firestore_match';
        final matchData = {
          'homeTeamId': 'fs_home',
          'guestTeamId': 'fs_guest',
          'matchDate': Timestamp.fromDate(testDate),
          'matchDay': 6,
          'homeScore': 4,
          'guestScore': 0,
        };

        // Add document to fake firestore
        await fakeFirestore.collection('matches').doc(matchId).set(matchData);
        
        // Get the document
        final doc = await fakeFirestore.collection('matches').doc(matchId).get();

        // Act
        final matchModel = MatchModel.fromFirestore(doc);

        // Assert
        expect(matchModel.id, matchId);
        expect(matchModel.homeTeamId, 'fs_home');
        expect(matchModel.guestTeamId, 'fs_guest');
        expect(matchModel.matchDate, testDate);
        expect(matchModel.matchDay, 6);
        expect(matchModel.homeScore, 4);
        expect(matchModel.guestScore, 0);
      });
    });

    group('toDomain', () {
      test('should convert match model to domain entity', () {
        // Arrange
        final matchModel = MatchModel(
          id: 'domain_test',
          homeTeamId: 'domain_home',
          guestTeamId: 'domain_guest',
          matchDate: testDate,
          matchDay: 7,
          homeScore: 1,
          guestScore: 3,
        );

        // Act
        final domainMatch = matchModel.toDomain();

        // Assert
        expect(domainMatch, isA<CustomMatch>());
        expect(domainMatch.id, 'domain_test');
        expect(domainMatch.homeTeamId, 'domain_home');
        expect(domainMatch.guestTeamId, 'domain_guest');
        expect(domainMatch.matchDate, testDate);
        expect(domainMatch.matchDay, 7);
        expect(domainMatch.homeScore, 1);
        expect(domainMatch.guestScore, 3);
      });

      test('should handle null scores in domain conversion', () {
        // Arrange
        final matchModel = MatchModel(
          id: 'null_domain',
          homeTeamId: 'null_home',
          guestTeamId: 'null_guest',
          matchDate: testDate,
          matchDay: 1,
          homeScore: null,
          guestScore: null,
        );

        // Act
        final domainMatch = matchModel.toDomain();

        // Assert
        expect(domainMatch.homeScore, null);
        expect(domainMatch.guestScore, null);
      });
    });

    group('fromDomain', () {
      test('should create match model from domain entity', () {
        // Arrange
        final domainMatch = CustomMatch(
          id: 'from_domain',
          homeTeamId: 'fd_home',
          guestTeamId: 'fd_guest',
          matchDate: testDate,
          matchDay: 8,
          homeScore: 5,
          guestScore: 2,
        );

        // Act
        final matchModel = MatchModel.fromDomain(domainMatch);

        // Assert
        expect(matchModel, isA<MatchModel>());
        expect(matchModel.id, 'from_domain');
        expect(matchModel.homeTeamId, 'fd_home');
        expect(matchModel.guestTeamId, 'fd_guest');
        expect(matchModel.matchDate, testDate);
        expect(matchModel.matchDay, 8);
        expect(matchModel.homeScore, 5);
        expect(matchModel.guestScore, 2);
      });

      test('should handle empty domain entity', () {
        // Arrange
        final domainMatch = CustomMatch.empty();

        // Act
        final matchModel = MatchModel.fromDomain(domainMatch);

        // Assert
        expect(matchModel.id, '');
        expect(matchModel.homeTeamId, 'TBD');
        expect(matchModel.guestTeamId, 'TBD');
        expect(matchModel.matchDay, 0);
        expect(matchModel.homeScore, null);
        expect(matchModel.guestScore, null);
      });
    });

    group('Integration Tests', () {
      test('should maintain data integrity through full conversion cycle', () {
        // Arrange
        final originalDomain = CustomMatch(
          id: 'cycle_test',
          homeTeamId: 'cycle_home',
          guestTeamId: 'cycle_guest',
          matchDate: testDate,
          matchDay: 4,
          homeScore: 2,
          guestScore: 3,
        );

        // Act - Full cycle: Domain -> Model -> Map -> Domain (via toDomain)
        final model1 = MatchModel.fromDomain(originalDomain);
        // ...existing code...
        // Note: We can't complete full cycle easily due to Timestamp requirement
        // But we can test domain -> model -> domain
        final model2 = MatchModel.fromDomain(originalDomain);
        final finalDomain = model2.toDomain();

        // Assert
        expect(finalDomain.id, originalDomain.id);
        expect(finalDomain.homeTeamId, originalDomain.homeTeamId);
        expect(finalDomain.guestTeamId, originalDomain.guestTeamId);
        expect(finalDomain.matchDate, originalDomain.matchDate);
        expect(finalDomain.matchDay, originalDomain.matchDay);
        expect(finalDomain.homeScore, originalDomain.homeScore);
        expect(finalDomain.guestScore, originalDomain.guestScore);
      });

      test('should handle extreme values through conversion cycle', () {
        // Arrange
        final extremeDate = DateTime(1900, 1, 1);
        final originalDomain = CustomMatch(
          id: 'extreme_test',
          homeTeamId: 'extreme_home',
          guestTeamId: 'extreme_guest',
          matchDate: extremeDate,
          matchDay: -999,
          homeScore: -100,
          guestScore: 999,
        );

        // Act
        final model = MatchModel.fromDomain(originalDomain);
        final reconstructedDomain = model.toDomain();

        // Assert
        expect(reconstructedDomain.id, originalDomain.id);
        expect(reconstructedDomain.homeTeamId, originalDomain.homeTeamId);
        expect(reconstructedDomain.guestTeamId, originalDomain.guestTeamId);
        expect(reconstructedDomain.matchDate, originalDomain.matchDate);
        expect(reconstructedDomain.matchDay, originalDomain.matchDay);
        expect(reconstructedDomain.homeScore, originalDomain.homeScore);
        expect(reconstructedDomain.guestScore, originalDomain.guestScore);
      });

      test('should handle null scores through conversion cycle', () {
        // Arrange
        final originalDomain = CustomMatch(
          id: 'null_cycle',
          homeTeamId: 'null_home',
          guestTeamId: 'null_guest',
          matchDate: testDate,
          matchDay: 1,
          homeScore: null,
          guestScore: null,
        );

        // Act
        final model = MatchModel.fromDomain(originalDomain);
        final reconstructedDomain = model.toDomain();

        // Assert
        expect(reconstructedDomain.homeScore, null);
        expect(reconstructedDomain.guestScore, null);
        expect(reconstructedDomain.id, originalDomain.id);
        expect(reconstructedDomain.matchDate, originalDomain.matchDate);
      });
    });
  });
}