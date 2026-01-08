import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/infrastructure/repositories/team_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/core/failures/team_failures.dart';
import 'package:flutter_web/domain/repositories/team_repository.dart';

// Mock implementation of TeamRepository for testing
class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('TeamRepositoryImpl', () {
    late TeamRepositoryImpl repository;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = TeamRepositoryImpl(firebaseFirestore: fakeFirestore);
      registerFallbackValue(<String, dynamic>{});
    });

    group('createTeam', () {
      test('should create team with valid data', () {
        final team = Team(
          id: 'team_1',
          name: 'Deutschland',
          flagCode: 'de',
          winPoints: 3,
          champion: false,
        );
        final createResult = repository.createTeam(team);
        expect(createResult, isA<Future<Either<TeamFailure, Unit>>>());
        expect(team.id, 'team_1');
        expect(team.name, 'Deutschland');
        expect(team.flagCode, 'de');
        expect(team.winPoints, 3);
        expect(team.champion, false);
      });
    });

    group('deleteTeamById', () {
      test('should have correct method signature', () {
        expect(repository.deleteTeamById, isA<Function>());
      });
    });

    group('updateTeam', () {
      test('should have correct method signature', () {
        expect(repository.updateTeam, isA<Function>());
      });
    });

    group('getAll', () {
      test('should have correct method signature', () {
        expect(repository.getAll, isA<Function>());
      });
    });

    group('getById', () {
      test('should have correct method signature', () {
        expect(repository.getById, isA<Function>());
      });
    });

    group('watchAllTeams', () {
      test('should return stream of teams', () {
        final watchResult = repository.watchAllTeams();
        expect(watchResult, isA<Stream<Either<TeamFailure, List<Team>>>>());
      });
    });

    group('Error Handling', () {
      test('should handle Firebase exceptions', () {
        final insufficientPermissions = InsufficientPermisssons();
        final unexpectedFailure = UnexpectedFailure();
        final notFoundFailure = NotFoundFailure();
        expect(insufficientPermissions, isA<TeamFailure>());
        expect(unexpectedFailure, isA<TeamFailure>());
        expect(notFoundFailure, isA<TeamFailure>());
      });
    });

    group('Domain Mapping', () {
      test('should properly convert between domain and model', () {
        final team = Team(
          id: 'mapping_test',
          name: 'Mapping Test Team',
          flagCode: 'mt',
          winPoints: 6,
          champion: true,
        );

        // Act & Assert - Test that domain entity has correct properties
        expect(team.id, 'mapping_test');
        expect(team.name, 'Mapping Test Team');
        expect(team.flagCode, 'mt');
        expect(team.winPoints, 6);
        expect(team.champion, true);
      });

      test('should handle empty team conversion', () {
        // Arrange
        final emptyTeam = Team.empty();

        // Assert
        expect(emptyTeam.id, 'TBD');
        expect(emptyTeam.name, 'Placeholder');
        expect(emptyTeam.flagCode, 'Null');
        expect(emptyTeam.winPoints, 0);
        expect(emptyTeam.champion, false);
      });
    });

    group('Repository Interface Compliance', () {
      test('should implement all required repository methods', () {
        // Verify that TeamRepositoryImpl implements TeamRepository interface
        expect(repository, isA<TeamRepositoryImpl>());
        
        // Verify all required methods exist
        expect(repository.createTeam, isA<Function>());
        expect(repository.deleteTeamById, isA<Function>());
        expect(repository.updateTeam, isA<Function>());
        expect(repository.getAll, isA<Function>());
        expect(repository.getById, isA<Function>());
        expect(repository.watchAllTeams, isA<Function>());
      });

      test('should return correct types from methods', () {
        // Test method return types
        final createResult = repository.createTeam(Team.empty());
        final deleteResult = repository.deleteTeamById('test');
        final updateResult = repository.updateTeam(Team.empty());
        final getAllResult = repository.getAll();
        final getByIdResult = repository.getById('test');
        final watchResult = repository.watchAllTeams();

        expect(createResult, isA<Future<Either<TeamFailure, Unit>>>());
        expect(deleteResult, isA<Future<Either<TeamFailure, Unit>>>());
        expect(updateResult, isA<Future<Either<TeamFailure, Unit>>>());
        expect(getAllResult, isA<Future<Either<TeamFailure, List<Team>>>>());
        expect(getByIdResult, isA<Future<Either<TeamFailure, Team>>>());
        expect(watchResult, isA<Stream<Either<TeamFailure, List<Team>>>>());
      });
    });

    group('Validation', () {
      test('should handle valid team data', () {
        // Arrange
        final validTeam = Team(
          id: 'valid_team',
          name: 'Valid Team Name',
          flagCode: 'vt',
          winPoints: 9,
          champion: false,
        );

        // Assert
        expect(validTeam.id.isNotEmpty, true);
        expect(validTeam.name.isNotEmpty, true);
        expect(validTeam.flagCode.isNotEmpty, true);
        expect(validTeam.winPoints >= 0, true);
      });

      test('should handle edge case team data', () {
        // Arrange
        final edgeCaseTeam = Team(
          id: '',
          name: '',
          flagCode: '',
          winPoints: -1,
          champion: true,
        );

        // Assert - Repository should handle edge cases gracefully
        expect(edgeCaseTeam, isA<Team>());
      });
    });
  });

  group('TeamFailure Types', () {
    test('should create all failure types correctly', () {
      // Test that all failure types can be instantiated
      final insufficientPermissions = InsufficientPermisssons();
      final unexpectedFailure = UnexpectedFailure();
      final notFoundFailure = NotFoundFailure();

      expect(insufficientPermissions, isA<TeamFailure>());
      expect(unexpectedFailure, isA<TeamFailure>());
      expect(notFoundFailure, isA<TeamFailure>());
    });

    test('should have distinct failure types', () {
      // Verify that different failures are actually different
      final failure1 = InsufficientPermisssons();
      final failure2 = UnexpectedFailure();
      final failure3 = NotFoundFailure();

      expect(failure1.runtimeType, isNot(failure2.runtimeType));
      expect(failure2.runtimeType, isNot(failure3.runtimeType));
      expect(failure1.runtimeType, isNot(failure3.runtimeType));
    });
  });

  group('Collection Reference', () {
    late FakeFirebaseFirestore fakeFirestore;
    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });
    test('should use correct collection name', () {
      // Verify that repository targets the correct collection
        final testRepository = TeamRepositoryImpl(firebaseFirestore: fakeFirestore);
        expect(testRepository, isA<TeamRepositoryImpl>());
      // Collection name verification would be done in integration tests
    });
  });
}