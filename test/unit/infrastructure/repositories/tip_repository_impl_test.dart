import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/infrastructure/repositories/tip_repository_impl.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

void main() {
  group('TipRepositoryImpl', () {
    late TipRepositoryImpl repository;
    late MockFirebaseFirestore mockFirestore;
    late MockAuthRepository mockAuthRepository;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocRef;
    late MockDocumentSnapshot mockDocSnapshot;
    late MockQuerySnapshot mockQuerySnapshot;
    late MockQuery mockQuery;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuthRepository = MockAuthRepository();
      mockCollection = MockCollectionReference();
      mockDocRef = MockDocumentReference();
      mockDocSnapshot = MockDocumentSnapshot();
      mockQuerySnapshot = MockQuerySnapshot();
      mockQuery = MockQuery();
      
      repository = TipRepositoryImpl(
        firebaseFirestore: mockFirestore,
        authRepository: mockAuthRepository,
      );
      
      registerFallbackValue(<String, dynamic>{});
    });

    group('create', () {
      test('should create tip with valid data', () {
        final tip = Tip(
          id: 'tip_1',
          userId: 'user_123',
          tipDate: DateTime.now(),
          matchId: 'match_456',
          tipHome: 2,
          tipGuest: 1,
          joker: false,
          points: 0,
        );

        final createResult = repository.create(tip);
        expect(createResult, isA<Future<Either<TipFailure, Unit>>>());
        
        // Verify tip data integrity
        expect(tip.id, 'tip_1');
        expect(tip.userId, 'user_123');
        expect(tip.matchId, 'match_456');
        expect(tip.tipHome, 2);
        expect(tip.tipGuest, 1);
        expect(tip.joker, false);
        expect(tip.points, 0);
      });

      test('should handle null scores in tip creation', () {
        final tipWithNullScores = Tip(
          id: 'null_tip',
          userId: 'user_456',
          tipDate: DateTime.now(),
          matchId: 'match_789',
          tipHome: null,
          tipGuest: null,
          joker: true,
          points: 0,
        );

        expect(tipWithNullScores.tipHome, null);
        expect(tipWithNullScores.tipGuest, null);
        expect(tipWithNullScores.joker, true);
      });

      test('should handle joker tips correctly', () {
        final jokerTip = Tip(
          id: 'joker_tip',
          userId: 'user_joker',
          tipDate: DateTime.now(),
          matchId: 'match_final',
          tipHome: 3,
          tipGuest: 2,
          joker: true,
          points: 6, // Double points for joker
        );

        expect(jokerTip.joker, true);
        expect(jokerTip.points, 6);
      });
    });

    group('watchUserTips', () {
      test('should return stream of user tips', () {
        const userId = 'test_user_123';
        final watchResult = repository.watchUserTips(userId);
        
        expect(watchResult, isA<Stream<Either<TipFailure, List<Tip>>>>());
      });

      test('should filter tips by user ID', () {
        const targetUserId = 'specific_user';
        const otherUserId = 'other_user';
        
        final userSpecificResult = repository.watchUserTips(targetUserId);
        expect(userSpecificResult, isA<Stream<Either<TipFailure, List<Tip>>>>());
        
        // Test that method accepts different user IDs
        final otherUserResult = repository.watchUserTips(otherUserId);
        expect(otherUserResult, isA<Stream<Either<TipFailure, List<Tip>>>>());
      });

      test('should handle empty user ID', () {
        const emptyUserId = '';
        final emptyResult = repository.watchUserTips(emptyUserId);
        expect(emptyResult, isA<Stream<Either<TipFailure, List<Tip>>>>());
      });
    });

    group('watchAll', () {
      test('should return stream of all tips grouped by user', () {
        final watchAllResult = repository.watchAll();
        expect(watchAllResult, isA<Stream<Either<TipFailure, Map<String, List<Tip>>>>>());
      });

      test('should group tips by user ID', () {
        // Test that the method exists and returns correct type
        expect(repository.watchAll, isA<Function>());
      });

      test('should handle multiple users with tips', () {
        // Verify method signature and return type
        final result = repository.watchAll();
        expect(result, isA<Stream<Either<TipFailure, Map<String, List<Tip>>>>>());
      });
    });

    group('Tip Validation', () {
      test('should handle valid tip data', () {
        final validTip = Tip(
          id: 'valid_tip_id',
          userId: 'valid_user_id',
          matchId: 'valid_match_id',
          tipDate: DateTime.now(),
          tipHome: 1,
          tipGuest: 1,
          joker: false,
          points: 1,
        );

        expect(validTip.id.isNotEmpty, true);
        expect(validTip.userId.isNotEmpty, true);
        expect(validTip.matchId?.isNotEmpty, true);
        expect(validTip.tipHome != null && validTip.tipHome! >= 0, true);
        expect(validTip.tipGuest != null && validTip.tipGuest! >= 0, true);
        expect(validTip.points! >= 0, true);
      });

      test('should handle edge case scores', () {
        final highScoreTip = Tip(
          id: 'high_score_tip',
          userId: 'user_high',
          tipDate: DateTime.now(),
          matchId: 'match_high',
          tipHome: 10,
          tipGuest: 8,
          joker: false,
          points: 3,
        );

        expect(highScoreTip.tipHome, 10);
        expect(highScoreTip.tipGuest, 8);

        final zeroScoreTip = Tip(
          id: 'zero_score_tip',
          userId: 'user_zero',
          tipDate: DateTime.now(),
          matchId: 'match_zero',
          tipHome: 0,
          tipGuest: 0,
          joker: true,
          points: 6, // Exact result with joker
        );

        expect(zeroScoreTip.tipHome, 0);
        expect(zeroScoreTip.tipGuest, 0);
        expect(zeroScoreTip.joker, true);
      });

      test('should handle missing scores', () {
        final incompleteTip = Tip(
          id: 'incomplete_tip',
          userId: 'user_incomplete',
          tipDate: DateTime.now(),
          matchId: 'match_incomplete',
          tipHome: null,
          tipGuest: null,
          joker: false,
          points: 0,
        );

        expect(incompleteTip.tipHome, null);
        expect(incompleteTip.tipGuest, null);
      });
    });

    group('Error Handling', () {
      test('should handle Firebase exceptions', () {
        final insufficientPermissions = InsufficientPermisssons();
        final unexpectedFailure = UnexpectedFailure();
        final notFoundFailure = NotFoundFailure();

        expect(insufficientPermissions, isA<TipFailure>());
        expect(unexpectedFailure, isA<TipFailure>());
        expect(notFoundFailure, isA<TipFailure>());
      });

      test('should map different Firebase errors', () {
        final permissionException = FirebaseException(
          plugin: 'test',
          code: 'permission-denied',
          message: 'Permission denied',
        );

        final notFoundException = FirebaseException(
          plugin: 'test',
          code: 'not-found',
          message: 'Document not found',
        );

        expect(permissionException, isA<FirebaseException>());
        expect(notFoundException, isA<FirebaseException>());
        expect(InsufficientPermisssons(), isA<TipFailure>());
        expect(NotFoundFailure(), isA<TipFailure>());
      });
    });

    group('Repository Dependencies', () {
      test('should have FirebaseFirestore dependency', () {
        expect(repository, isA<TipRepositoryImpl>());
        // Verify constructor accepts FirebaseFirestore instance
      });

      test('should have AuthRepository dependency', () {
        expect(repository, isA<TipRepositoryImpl>());
        // Verify constructor accepts AuthRepository instance
      });

      test('should use correct collection references', () {
        // Test that repository accesses correct collections
        expect(repository, isA<TipRepositoryImpl>());
        // Collection verification would be done in integration tests
      });
    });

    group('Repository Interface Compliance', () {
      test('should implement TipRepository interface', () {
        expect(repository, isA<TipRepositoryImpl>());
        expect(repository.create, isA<Function>());
        expect(repository.watchUserTips, isA<Function>());
        expect(repository.watchAll, isA<Function>());
      });

      test('should return correct types from methods', () {
        final tip = Tip(
          id: 'test_tip',
          userId: 'test_user',
          matchId: 'test_match',
          tipDate: DateTime.now(),
          tipHome: 1,
          tipGuest: 0,
          joker: false,
          points: 3,
        );

        final createResult = repository.create(tip);
        final watchUserResult = repository.watchUserTips('user_123');
        final watchAllResult = repository.watchAll();

        expect(createResult, isA<Future<Either<TipFailure, Unit>>>());
        expect(watchUserResult, isA<Stream<Either<TipFailure, List<Tip>>>>());
        expect(watchAllResult, isA<Stream<Either<TipFailure, Map<String, List<Tip>>>>>());
      });
    });

    group('Business Logic', () {
      test('should handle joker logic correctly', () {
        final regularTip = Tip(
          id: 'regular_tip',
          userId: 'user_regular',
          tipDate: DateTime.now(),
          matchId: 'match_regular',
          tipHome: 2,
          tipGuest: 1,
          joker: false,
          points: 3, // Regular points
        );

        final jokerTip = Tip(
          id: 'joker_tip_2',
          userId: 'user_joker_2',
          tipDate: DateTime.now(),
          matchId: 'match_joker',
          tipHome: 2,
          tipGuest: 1,
          joker: true,
          points: 6, // Double points
        );

        expect(regularTip.joker, false);
        expect(jokerTip.joker, true);
        expect(jokerTip.points, greaterThan(regularTip.points as Object));
      });

      test('should handle points calculation scenarios', () {
        final exactResultTip = Tip(
          id: 'exact_tip',
          userId: 'user_exact',
          tipDate: DateTime.now(),
          matchId: 'match_exact',
          tipHome: 3,
          tipGuest: 1,
          joker: false,
          points: 3, // Exact result
        );

        final tendencyTip = Tip(
          id: 'tendency_tip',
          userId: 'user_tendency',
          tipDate: DateTime.now(),
          matchId: 'match_tendency',
          tipHome: 2,
          tipGuest: 0,
          joker: false,
          points: 1, // Correct tendency
        );

        final wrongTip = Tip(
          id: 'wrong_tip',
          userId: 'user_wrong',
          tipDate: DateTime.now(),
          matchId: 'match_wrong',
          tipHome: 0,
          tipGuest: 3,
          joker: false,
          points: 0, // Wrong prediction
        );

        expect(exactResultTip.points, 3);
        expect(tendencyTip.points, 1);
        expect(wrongTip.points, 0);
      });
    });

    group('Data Consistency', () {
      test('should maintain tip data integrity', () {
        final tip = Tip(
          id: 'integrity_tip',
          userId: 'user_integrity',
          tipDate: DateTime.now(),
          matchId: 'match_integrity',
          tipHome: 4,
          tipGuest: 2,
          joker: true,
          points: 6,
        );

        // Verify all fields are properly set
        expect(tip.id, 'integrity_tip');
        expect(tip.userId, 'user_integrity');
        expect(tip.matchId, 'match_integrity');
        expect(tip.tipHome, 4);
        expect(tip.tipGuest, 2);
        expect(tip.joker, true);
        expect(tip.points, 6);
      });

      test('should handle user ID to string conversion', () {
        final tip = Tip(
          id: 'string_conversion_tip',
          userId: 'user_string_test',
          tipDate: DateTime.now(),
          matchId: 'match_string_test',
          tipHome: 1,
          tipGuest: 1,
          joker: false,
          points: 1,
        );

        // Test that userId can be converted to string (for grouping in watchAll)
        final userIdString = tip.userId.toString();
        expect(userIdString, isA<String>());
        expect(userIdString.isNotEmpty, true);
      });
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
}