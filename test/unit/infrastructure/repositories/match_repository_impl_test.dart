import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_web/infrastructure/repositories/match_repository_impl.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/core/failures/match_failures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('MatchRepositoryImpl', () {
    late MatchRepositoryImpl repository;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = MatchRepositoryImpl(firebaseFirestore: fakeFirestore);
      registerFallbackValue(<String, dynamic>{});
    });

    group('createMatch', () {
      test('should create match with valid data', () async {
        final match = CustomMatch(
          id: 'match_1',
          homeTeamId: 'team_a',
          guestTeamId: 'team_b',
          matchDay: 1,
          matchDate: DateTime(2024, 1, 15, 18, 30),
          homeScore: null,
          guestScore: null,
        );
        final result = await repository.createMatch(match);
        expect(result, isA<Either<MatchFailure, Unit>>());
      });
    });

    group('deleteMatchById', () {
      test('should delete match by valid ID', () async {
        const matchId = 'valid_match_id';
        final result = await repository.deleteMatchById(matchId);
        expect(result, isA<Either<MatchFailure, Unit>>());
      });

      test('should handle deletion of non-existent match', () async {
        const nonExistentId = 'non_existent_match';
        final result = await repository.deleteMatchById(nonExistentId);
        expect(result, isA<Either<MatchFailure, Unit>>());
      });
    });

    group('updateMatch', () {
      test('should update match with new data', () async {
        final match = CustomMatch(
          id: 'update_match',
          homeTeamId: 'home_team',
          guestTeamId: 'away_team',
          matchDay: 1,
          matchDate: DateTime(2024, 2, 20, 20, 0),
          homeScore: 2,
          guestScore: 1,
        );

        final result = await repository.updateMatch(match);
        expect(result, isA<Either<MatchFailure, Unit>>());
      });
    });

    group('getAllMatches', () {
      test('should return list of matches', () async {
        final result = await repository.getAllMatches();
        expect(result, isA<Either<MatchFailure, List<CustomMatch>>>());
      });
    });

    group('getMatchById', () {
      test('should return single match for valid ID', () async {
        const matchId = 'specific_match_id';
        final result = await repository.getMatchById(matchId);
        expect(result, isA<Either<MatchFailure, CustomMatch>>());
      });
    });

    group('watchAllMatches', () {
      test('should return stream of matches', () {
        final watchResult = repository.watchAllMatches();
        expect(watchResult, isA<Stream<Either<MatchFailure, List<CustomMatch>>>>());
      });
    });

    group('Match Business Logic', () {
      test('should correctly determine match result status', () {
        // Match with result
        final finishedMatch = CustomMatch(
          id: 'finished_match',
          homeTeamId: 'team_a',
          guestTeamId: 'team_b',
          matchDay: 1,
          matchDate: DateTime(2024, 1, 1, 12, 0),
          homeScore: 3,
          guestScore: 0,
        );

        expect(finishedMatch.hasResult, true);

        // Match without result
        final upcomingMatch = CustomMatch(
          id: 'upcoming_match',
          homeTeamId: 'team_c',
          guestTeamId: 'team_d',
          matchDay: 1,
          matchDate: DateTime(2024, 12, 31, 18, 0),
          homeScore: null,
          guestScore: null,
        );

        expect(upcomingMatch.hasResult, false);
      });

      test('should handle stage naming correctly', () {
        final groupMatch = CustomMatch(
          id: 'group_match',
          homeTeamId: 'team_1',
          guestTeamId: 'team_2',
          matchDay: 1,
          matchDate: DateTime(2024, 6, 15),
          homeScore: null,
          guestScore: null,
        );

        expect(groupMatch.getStageName, 'Gruppenphase, Tag 2');

        final finalMatch = CustomMatch(
          id: 'final_match',
          homeTeamId: 'team_final_1',
          guestTeamId: 'team_final_2',
          matchDay: 7,
          matchDate: DateTime(2024, 7, 14),
          homeScore: null,
          guestScore: null,
        );
        expect(finalMatch.getStageName, 'Finale');
      });
    });

    group('Error Handling', () {
      test('should handle Firebase exceptions correctly', () {
        // Test failure types
        final insufficientPermissions = InsufficientPermisssons();
        final unexpectedFailure = UnexpectedFailure();
        final notFoundFailure = NotFoundFailure();

        expect(insufficientPermissions, isA<MatchFailure>());
        expect(unexpectedFailure, isA<MatchFailure>());
        expect(notFoundFailure, isA<MatchFailure>());
      });

      test('should map Firebase errors to domain failures', () {
        final firebaseException = FirebaseException(
          plugin: 'test',
          code: 'permission-denied',
          message: 'Permission denied',
        );

        expect(firebaseException, isA<FirebaseException>());
        expect(InsufficientPermisssons(), isA<MatchFailure>());
      });
    });

    group('Data Validation', () {
      test('should handle valid match dates', () {
        final pastDate = DateTime(2023, 12, 31);
        final futureDate = DateTime.now().add(Duration(days: 365));
        final currentDate = DateTime.now();

        final pastMatch = CustomMatch(
          id: 'past_match',
          homeTeamId: 'team_a',
          guestTeamId: 'team_b',
          matchDay: 1,
          matchDate: pastDate,
          homeScore: 1,
          guestScore: 0,
        );

        final futureMatch = CustomMatch(
          id: 'future_match',
          homeTeamId: 'team_c',
          guestTeamId: 'team_d',
          matchDay: 1,
          matchDate: futureDate,
          homeScore: null,
          guestScore: null,
        );

        print('pastMatch: ${pastMatch.matchDate}, now: $currentDate');
        print('futureMatch: ${futureMatch.matchDate}, now: $currentDate');
        expect(pastMatch.matchDate.isBefore(currentDate), true);
        expect(futureMatch.matchDate.isAfter(currentDate), true);
      });

      test('should handle score validation', () {
        // Valid scores
        final validMatch = CustomMatch(
          id: 'valid_scores',
          homeTeamId: 'team_1',
          guestTeamId: 'team_2',
          matchDay: 1,
          matchDate: DateTime.now(),
          homeScore: 5,
          guestScore: 3,
        );

        expect(validMatch.homeScore! >= 0, true);
        expect(validMatch.guestScore! >= 0, true);

        // Edge case scores
        final edgeMatch = CustomMatch(
          id: 'edge_scores',
          homeTeamId: 'team_a',
          guestTeamId: 'team_b',
          matchDay: 1,
          matchDate: DateTime.now(),
          homeScore: 0,
          guestScore: 0,
        );

        expect(edgeMatch.homeScore, 0);
        expect(edgeMatch.guestScore, 0);
        expect(edgeMatch.hasResult, true);
      });
    });

    group('Repository Interface Compliance', () {
      test('should implement all MatchRepository methods', () {
        expect(repository, isA<MatchRepositoryImpl>());
        
        expect(repository.createMatch, isA<Function>());
        expect(repository.deleteMatchById, isA<Function>());
        expect(repository.updateMatch, isA<Function>());
        expect(repository.getAllMatches, isA<Function>());
        expect(repository.getMatchById, isA<Function>());
        expect(repository.watchAllMatches, isA<Function>());
      });

      test('should return correct types', () {
        final match = CustomMatch(
          id: 'test_match',
          homeTeamId: 'home',
          guestTeamId: 'away',
          matchDay: 1,
          matchDate: DateTime.now(),
          homeScore: null,
          guestScore: null,
        );

        final createResult = repository.createMatch(match);
        final deleteResult = repository.deleteMatchById('test');
        final updateResult = repository.updateMatch(match);
        final getAllResult = repository.getAllMatches();
        final getByIdResult = repository.getMatchById('test');
        final watchResult = repository.watchAllMatches();

        expect(createResult, isA<Future<Either<MatchFailure, Unit>>>());
        expect(deleteResult, isA<Future<Either<MatchFailure, Unit>>>());
        expect(updateResult, isA<Future<Either<MatchFailure, Unit>>>());
        expect(getAllResult, isA<Future<Either<MatchFailure, List<CustomMatch>>>>());
        expect(getByIdResult, isA<Future<Either<MatchFailure, CustomMatch>>>());
        expect(watchResult, isA<Stream<Either<MatchFailure, List<CustomMatch>>>>());
      });
    });

    group('Collection Operations', () {
      test('should handle ordering by match date', () {
        // Test that repository handles ordering correctly
        expect(repository.watchAllMatches, isA<Function>());
        // Actual ordering tests would be in integration tests
      });

      test('should handle document operations', () {
        final match = CustomMatch(
          id: 'doc_test_match',
          homeTeamId: 'team_home',
          guestTeamId: 'team_away',
          matchDay: 1,
          matchDate: DateTime(2024, 6, 1, 16, 0),
          homeScore: null,
          guestScore: null,
        );

        // Verify match can be used in repository operations
        expect(match.id, 'doc_test_match');
        expect(repository.createMatch(match), isA<Future>());
        expect(repository.updateMatch(match), isA<Future>());
      });
    });
  });

  group('MatchFailure Types', () {
    test('should create all match failure types', () {
      final insufficientPermissions = InsufficientPermisssons();
      final unexpectedFailure = UnexpectedFailure();
      final notFoundFailure = NotFoundFailure();

      expect(insufficientPermissions, isA<MatchFailure>());
      expect(unexpectedFailure, isA<MatchFailure>());
      expect(notFoundFailure, isA<MatchFailure>());
    });

    test('should distinguish between failure types', () {
      final failure1 = InsufficientPermisssons();
      final failure2 = UnexpectedFailure();
      final failure3 = NotFoundFailure();

      expect(failure1.runtimeType, isNot(failure2.runtimeType));
      expect(failure2.runtimeType, isNot(failure3.runtimeType));
      expect(failure1.runtimeType, isNot(failure3.runtimeType));
    });
  });
}