import 'package:flutter_test/flutter_test.dart';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_web/infrastructure/models/team_model.dart';
import 'package:flutter_web/domain/entities/team.dart';

void main() {
  group('TeamModel', () {
    group('Constructor', () {
      test('should create team model with valid properties', () {
        // Act
        final teamModel = TeamModel(
          id: 'ger',
          name: 'Deutschland',
          flagCode: 'de',
          winPoints: 9,
          champion: true,
        );

        // Assert
        expect(teamModel.id, 'ger');
        expect(teamModel.name, 'Deutschland');
        expect(teamModel.flagCode, 'de');
        expect(teamModel.winPoints, 9);
        expect(teamModel.champion, true);
      });
    });

    group('toMap', () {
      test('should convert team model to map with correct keys', () {
        // Arrange
        final teamModel = TeamModel(
          id: 'esp',
          name: 'Spain',
          flagCode: 'es',
          winPoints: 6,
          champion: false,
        );

        // Act
        final map = teamModel.toMap();

        // Assert
        expect(map, isA<Map<String, dynamic>>());
        expect(map['id'], 'esp');
        expect(map['name'], 'Spain');
        expect(map['flag_code'], 'es');
        expect(map['win_points'], 6);
        expect(map['champion'], false);
      });

      test('should handle edge case values in map conversion', () {
        // Arrange
        final teamModel = TeamModel(
          id: '',
          name: '',
          flagCode: '',
          winPoints: 0,
          champion: false,
        );

        // Act
        final map = teamModel.toMap();

        // Assert
        expect(map['id'], '');
        expect(map['name'], '');
        expect(map['flag_code'], '');
        expect(map['win_points'], 0);
        expect(map['champion'], false);
      });

      test('should handle special characters in map conversion', () {
        // Arrange
        final teamModel = TeamModel(
          id: 'special-123',
          name: 'Team with Spëcial Chars & Numbers 123',
          flagCode: 'sp-123',
          winPoints: -5,
          champion: true,
        );

        // Act
        final map = teamModel.toMap();

        // Assert
        expect(map['id'], 'special-123');
        expect(map['name'], 'Team with Spëcial Chars & Numbers 123');
        expect(map['flag_code'], 'sp-123');
        expect(map['win_points'], -5);
        expect(map['champion'], true);
      });
    });

    group('fromMap', () {
      test('should create team model from valid map', () {
        // Arrange
        final map = {
          'id': 'fra',
          'name': 'France',
          'flag_code': 'fr',
          'win_points': 12,
          'champion': true,
        };

        // Act
        final teamModel = TeamModel.fromMap(map);

        // Assert
        expect(teamModel.id, 'fra');
        expect(teamModel.name, 'France');
        expect(teamModel.flagCode, 'fr');
        expect(teamModel.winPoints, 12);
        expect(teamModel.champion, true);
      });

      test('should handle missing id field with default value', () {
        // Arrange
        final map = {
          'name': 'No ID Team',
          'flag_code': 'no',
          'win_points': 3,
          'champion': false,
        };

        // Act
        final teamModel = TeamModel.fromMap(map);

        // Assert
        expect(teamModel.id, '');
        expect(teamModel.name, 'No ID Team');
        expect(teamModel.flagCode, 'no');
        expect(teamModel.winPoints, 3);
        expect(teamModel.champion, false);
      });

      test('should handle null values appropriately', () {
        // Arrange
        final map = {
          'id': null,
          'name': 'Null ID Team',
          'flag_code': 'null',
          'win_points': 0,
          'champion': false,
        };

        // Act
        final teamModel = TeamModel.fromMap(map);

        // Assert
        expect(teamModel.id, '');
        expect(teamModel.name, 'Null ID Team');
        expect(teamModel.flagCode, 'null');
        expect(teamModel.winPoints, 0);
        expect(teamModel.champion, false);
      });

      test('should throw when required fields are missing', () {
        // Arrange
        final invalidMap = {
          'id': 'invalid',
          // missing required fields
        };

        // Act & Assert
        expect(
          () => TeamModel.fromMap(invalidMap),
          throwsA(isA<TypeError>()),
        );
      });

      test('should throw when field types are incorrect', () {
        // Arrange
        final invalidMap = {
          'id': 'type_test',
          'name': 'Type Test Team',
          'flag_code': 'test',
          'win_points': 'not_a_number', // Should be int
          'champion': false,
        };

        // Act & Assert
        expect(
          () => TeamModel.fromMap(invalidMap),
          throwsA(isA<TypeError>()),
        );
      });
    });

    group('copyWith', () {
      test('should return new instance with updated properties', () {
        // Arrange
        final originalModel = TeamModel(
          id: 'original',
          name: 'Original Team',
          flagCode: 'or',
          winPoints: 5,
          champion: false,
        );

        // Act
        final updatedModel = originalModel.copyWith(
          name: 'Updated Team',
          winPoints: 10,
          champion: true,
        );

        // Assert
        expect(updatedModel.id, originalModel.id);
        expect(updatedModel.name, 'Updated Team');
        expect(updatedModel.flagCode, originalModel.flagCode);
        expect(updatedModel.winPoints, 10);
        expect(updatedModel.champion, true);
      });

      test('should return identical instance when no properties updated', () {
        // Arrange
        final originalModel = TeamModel(
          id: 'unchanged',
          name: 'Unchanged Team',
          flagCode: 'un',
          winPoints: 7,
          champion: true,
        );

        // Act
        final copiedModel = originalModel.copyWith();

        // Assert
        expect(copiedModel.id, originalModel.id);
        expect(copiedModel.name, originalModel.name);
        expect(copiedModel.flagCode, originalModel.flagCode);
        expect(copiedModel.winPoints, originalModel.winPoints);
        expect(copiedModel.champion, originalModel.champion);
      });
    });

    group('fromFirestore', () {
      late FakeFirebaseFirestore fakeFirestore;

      setUp(() {
        fakeFirestore = FakeFirebaseFirestore();
      });

      test('should create team model from firestore document', () async {
        // Arrange
        const teamId = 'firestore_team';
        final teamData = {
          'name': 'Firestore Team',
          'flag_code': 'fs',
          'win_points': 15,
          'champion': true,
        };

        // Add document to fake firestore
        await fakeFirestore.collection('teams').doc(teamId).set(teamData);
        
        // Get the document
        final doc = await fakeFirestore.collection('teams').doc(teamId).get();

        // Act
        final teamModel = TeamModel.fromFirestore(doc);

        // Assert
        expect(teamModel.id, teamId);
        expect(teamModel.name, 'Firestore Team');
        expect(teamModel.flagCode, 'fs');
        expect(teamModel.winPoints, 15);
        expect(teamModel.champion, true);
      });

      test('should handle document with missing optional fields', () async {
        // Arrange
        const teamId = 'minimal_team';
        final teamData = {
          'name': 'Minimal Team',
          'flag_code': 'min',
          'win_points': 0,
          'champion': false,
        };

        await fakeFirestore.collection('teams').doc(teamId).set(teamData);
        final doc = await fakeFirestore.collection('teams').doc(teamId).get();

        // Act
        final teamModel = TeamModel.fromFirestore(doc);

        // Assert
        expect(teamModel.id, teamId);
        expect(teamModel.name, 'Minimal Team');
        expect(teamModel.flagCode, 'min');
        expect(teamModel.winPoints, 0);
        expect(teamModel.champion, false);
      });
    });

    group('toDomain', () {
      test('should convert team model to domain entity', () {
        // Arrange
        final teamModel = TeamModel(
          id: 'domain_test',
          name: 'Domain Test Team',
          flagCode: 'dt',
          winPoints: 20,
          champion: true,
        );

        // Act
        final domainTeam = teamModel.toDomain();

        // Assert
        expect(domainTeam, isA<Team>());
        expect(domainTeam.id, 'domain_test');
        expect(domainTeam.name, 'Domain Test Team');
        expect(domainTeam.flagCode, 'dt');
        expect(domainTeam.winPoints, 20);
        expect(domainTeam.champion, true);
      });

      test('should handle edge case values in domain conversion', () {
        // Arrange
        final teamModel = TeamModel(
          id: '',
          name: '',
          flagCode: '',
          winPoints: -100,
          champion: false,
        );

        // Act
        final domainTeam = teamModel.toDomain();

        // Assert
        expect(domainTeam.id, '');
        expect(domainTeam.name, '');
        expect(domainTeam.flagCode, '');
        expect(domainTeam.winPoints, -100);
        expect(domainTeam.champion, false);
      });
    });

    group('fromDomain', () {
      test('should create team model from domain entity', () {
        // Arrange
        final domainTeam = Team(
          id: 'from_domain',
          name: 'From Domain Team',
          flagCode: 'fd',
          winPoints: 25,
          champion: false,
        );

        // Act
        final teamModel = TeamModel.fromDomain(domainTeam);

        // Assert
        expect(teamModel, isA<TeamModel>());
        expect(teamModel.id, 'from_domain');
        expect(teamModel.name, 'From Domain Team');
        expect(teamModel.flagCode, 'fd');
        expect(teamModel.winPoints, 25);
        expect(teamModel.champion, false);
      });

      test('should handle empty domain entity', () {
        // Arrange
        final domainTeam = Team.empty();

        // Act
        final teamModel = TeamModel.fromDomain(domainTeam);

        // Assert
        expect(teamModel.id, 'TBD');
        expect(teamModel.name, 'Placeholder');
        expect(teamModel.flagCode, 'Null');
        expect(teamModel.winPoints, 0);
        expect(teamModel.champion, false);
      });
    });

    group('Integration Tests', () {
      test('should maintain data integrity through full conversion cycle', () {
        // Arrange
        final originalDomain = Team(
          id: 'cycle_test',
          name: 'Cycle Test Team',
          flagCode: 'ct',
          winPoints: 30,
          champion: true,
        );

        // Act - Full cycle: Domain -> Model -> Map -> Model -> Domain
        final model1 = TeamModel.fromDomain(originalDomain);
        final map = model1.toMap();
        final model2 = TeamModel.fromMap(map);
        final finalDomain = model2.toDomain();

        // Assert
        expect(finalDomain.id, originalDomain.id);
        expect(finalDomain.name, originalDomain.name);
        expect(finalDomain.flagCode, originalDomain.flagCode);
        expect(finalDomain.winPoints, originalDomain.winPoints);
        expect(finalDomain.champion, originalDomain.champion);
      });

      test('should handle special characters through conversion cycle', () {
        // Arrange
        final originalDomain = Team(
          id: 'special-123_test',
          name: 'Spëcial Team with Nümbers & Symbols!',
          flagCode: 'spë-123',
          winPoints: 999,
          champion: true,
        );

        // Act
        final model = TeamModel.fromDomain(originalDomain);
        final map = model.toMap();
        final reconstructedModel = TeamModel.fromMap(map);
        final reconstructedDomain = reconstructedModel.toDomain();

        // Assert
        expect(reconstructedDomain.id, originalDomain.id);
        expect(reconstructedDomain.name, originalDomain.name);
        expect(reconstructedDomain.flagCode, originalDomain.flagCode);
        expect(reconstructedDomain.winPoints, originalDomain.winPoints);
        expect(reconstructedDomain.champion, originalDomain.champion);
      });

      test('should handle extreme values through conversion cycle', () {
        // Arrange
        final originalDomain = Team(
          id: 'extreme_values',
          name: 'Extreme Values Team',
          flagCode: 'extreme',
          winPoints: -999999,
          champion: false,
        );

        // Act
        final model = TeamModel.fromDomain(originalDomain);
        final map = model.toMap();
        final reconstructedModel = TeamModel.fromMap(map);
        final reconstructedDomain = reconstructedModel.toDomain();

        // Assert
        expect(reconstructedDomain.id, originalDomain.id);
        expect(reconstructedDomain.name, originalDomain.name);
        expect(reconstructedDomain.flagCode, originalDomain.flagCode);
        expect(reconstructedDomain.winPoints, originalDomain.winPoints);
        expect(reconstructedDomain.champion, originalDomain.champion);
      });
    });
  });
}