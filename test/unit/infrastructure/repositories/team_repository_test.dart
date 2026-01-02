import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/core/failures/team_failures.dart';
import 'package:flutter_web/domain/repositories/team_repository.dart';

// Mock implementation of TeamRepository for testing
class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('TeamRepository Interface Tests', () {
    late MockTeamRepository repository;

    setUp(() {
      repository = MockTeamRepository();
    });

    group('createTeam', () {
      test('should return unit when team is created successfully', () async {
        // Arrange
        final team = Team(
          id: 'team-1',
          name: 'Germany',
          flagCode: 'de',
          winPoints: 0,
          champion: false,
        );
        when(() => repository.createTeam(team))
            .thenAnswer((_) async => right(unit));

        // Act
        final result = await repository.createTeam(team);

        // Assert
        expect(result, right(unit));
        verify(() => repository.createTeam(team)).called(1);
      });

      test('should return failure when creation fails', () async {
        // Arrange
        final team = Team(
          id: 'team-1',
          name: 'Germany',
          flagCode: 'de',
          winPoints: 0,
          champion: false,
        );
        when(() => repository.createTeam(team))
            .thenAnswer((_) async => left(UnexpectedFailure()));

        // Act
        final result = await repository.createTeam(team);

        // Assert
        expect(result.isLeft(), true);
        expect((result as Left).value, isA<TeamFailure>());
        verify(() => repository.createTeam(team)).called(1);
      });
    });

    group('getAll', () {
      test('should return list of teams when successful', () async {
        // Arrange
        final teams = <Team>[
          Team(id: '1', name: 'Germany', flagCode: 'de', winPoints: 0, champion: false),
          Team(id: '2', name: 'Spain', flagCode: 'es', winPoints: 0, champion: false),
        ];
        when(() => repository.getAll())
            .thenAnswer((_) async => right(teams));

        // Act
        final result = await repository.getAll();

        // Assert
        expect(result, right(teams));
        verify(() => repository.getAll()).called(1);
      });

      test('should return failure when get all fails', () async {
        // Arrange
        when(() => repository.getAll())
            .thenAnswer((_) async => left(UnexpectedFailure()));

        // Act
        final result = await repository.getAll();

        // Assert
        expect(result.isLeft(), true);
        expect((result as Left).value, isA<TeamFailure>());
      });
    });

    group('getById', () {
      test('should return team when found', () async {
        // Arrange
        final team = Team(id: '1', name: 'Germany', flagCode: 'de', winPoints: 0, champion: false);
        when(() => repository.getById('1'))
            .thenAnswer((_) async => right(team));

        // Act
        final result = await repository.getById('1');

        // Assert
        expect(result, right(team));
        verify(() => repository.getById('1')).called(1);
      });

      test('should return not found when team does not exist', () async {
        // Arrange
        when(() => repository.getById('nonexistent'))
            .thenAnswer((_) async => left(NotFoundFailure()));

        // Act
        final result = await repository.getById('nonexistent');

        // Assert
        expect(result.isLeft(), true);
        expect((result as Left).value, isA<NotFoundFailure>());
      });
    });

    group('updateTeam', () {
      test('should return unit when team is updated successfully', () async {
        // Arrange
        final team = Team(id: '1', name: 'Germany', flagCode: 'de', winPoints: 0, champion: true);
        when(() => repository.updateTeam(team))
            .thenAnswer((_) async => right(unit));

        // Act
        final result = await repository.updateTeam(team);

        // Assert
        expect(result, right(unit));
        verify(() => repository.updateTeam(team)).called(1);
      });
    });

    group('deleteTeamById', () {
      test('should return unit when team is deleted successfully', () async {
        // Arrange
        when(() => repository.deleteTeamById('1'))
            .thenAnswer((_) async => right(unit));

        // Act
        final result = await repository.deleteTeamById('1');

        // Assert
        expect(result, right(unit));
        verify(() => repository.deleteTeamById('1')).called(1);
      });
    });

    group('watchAllTeams', () {
      test('should return stream of teams', () {
        // Arrange
        final teams = <Team>[
          Team(id: '1', name: 'Germany', flagCode: 'de', winPoints: 0, champion: false),
        ];
        when(() => repository.watchAllTeams())
            .thenAnswer((_) => Stream.value(right(teams)));

        // Act
        final stream = repository.watchAllTeams();

        // Assert
        expect(stream, isA<Stream<Either<TeamFailure, List<Team>>>>());
        verify(() => repository.watchAllTeams()).called(1);
      });
    });
  });
}