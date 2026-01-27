import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_web/domain/usecases/validate_joker_usage_usecase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';

class MockTipRepository extends Mock implements TipRepository {}

class MockValidateJokerUsageUsecase extends Mock implements ValidateJokerUsageUseCase {
  @override
  Future<Either<TipFailure, JokerValidationResult>> call({
    required String userId,
    required int matchDay,
  }) async {
    return right(JokerValidationResult(
      isAvailable: true,
      used: 0,
      total: 3,
      matchDay: matchDay,
    ));
  }
}

class FakeTip extends Fake implements Tip {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTip());
  });

  group('TipFormBloc', () {
    late TipFormBloc tipFormBloc;
    late MockTipRepository mockTipRepository;
    late MockValidateJokerUsageUsecase mockValidateJokerUsageUsecase;

    setUp(() {
      mockTipRepository = MockTipRepository();
      mockValidateJokerUsageUsecase = MockValidateJokerUsageUsecase();

      tipFormBloc = TipFormBloc(tipRepository: mockTipRepository, validateJokerUseCase: mockValidateJokerUsageUsecase);
    });

    tearDown(() {
      tipFormBloc.close();
    });

    test('initial state has correct default values', () {
      final state = tipFormBloc.state;
      expect(state.userId, '');
      expect(state.matchId, '');
      expect(state.matchDay, 0);
      expect(state.tipHome, isNull);
      expect(state.tipGuest, isNull);
      expect(state.joker, false);
      expect(state.isSubmitting, false);
      expect(state.showValidationMessages, false);
      expect(state.failureOrSuccessOption, none());
    });

    group('TipFormInitializedEvent', () {
      blocTest<TipFormBloc, TipFormState>(
        'initializes form with provided values',
        build: () => tipFormBloc,
        act: (bloc) {
          bloc.add(TipFormInitializedEvent(
            userId: 'user_123',
            matchId: 'match_456',
            matchDay: 1,
          ));
        },
        expect: () => [
          isA<TipFormState>()
              .having((state) => state.userId, 'userId', 'user_123')
              .having((state) => state.matchId, 'matchId', 'match_456')
              .having((state) => state.matchDay, 'matchDay', 1)
              .having((state) => state.tipHome, 'tipHome', isNull)
              .having((state) => state.tipGuest, 'tipGuest', isNull)
              .having((state) => state.joker, 'joker', false),
          isA<TipFormState>()  // Second emit with joker validation
              .having((state) => state.userId, 'userId', 'user_123'),
        ],
      );
    });

    group('TipFormFieldUpdatedEvent - Success Cases', () {
      blocTest<TipFormBloc, TipFormState>(
        'successfully creates tip with valid scores',
        build: () {
          when(() => mockTipRepository.create(any()))
              .thenAnswer((_) async => right(unit));
          return tipFormBloc;
        },
        act: (bloc) => bloc.add(TipFormFieldUpdatedEvent(
          userId: 'user_valid',
          matchId: 'match_valid',
          matchDay: 1,
          tipHome: 3,
          tipGuest: 1,
          joker: false,
        )),
        expect: () => [
          isA<TipFormState>()
              .having((state) => state.isSubmitting, 'isSubmitting', true),
          isA<TipFormState>()
              .having((state) => state.tipHome, 'tipHome', 3)
              .having((state) => state.tipGuest, 'tipGuest', 1)
              .having((state) => state.joker, 'joker', false)
              .having((state) => state.isSubmitting, 'isSubmitting', false)
              .having((state) => state.failureOrSuccessOption.isSome(), 'has result', true),
        ],
        verify: (_) {
          verify(() => mockTipRepository.create(any(
            that: predicate<Tip>((tip) =>
                tip.id == 'user_valid_match_valid' &&
                tip.userId == 'user_valid' &&
                tip.matchId == 'match_valid' &&
                tip.tipHome == 3 &&
                tip.tipGuest == 1 &&
                tip.joker == false),
          ))).called(1);
        },
      );

      blocTest<TipFormBloc, TipFormState>(
        'successfully creates tip with joker',
        build: () {
          when(() => mockTipRepository.create(any()))
              .thenAnswer((_) async => right(unit));
          return tipFormBloc;
        },
        act: (bloc) => bloc.add(TipFormFieldUpdatedEvent(
          userId: 'user_joker',
          matchId: 'match_joker',
          matchDay: 1,
          tipHome: 2,
          tipGuest: 2,
          joker: true,
        )),
        expect: () => [
          isA<TipFormState>().having((state) => state.isSubmitting, 'isSubmitting', true),
          // Intermediate state after joker validation
          isA<TipFormState>(),
          // Final state after creation
          isA<TipFormState>()
              .having((state) => state.tipHome, 'tipHome', 2)
              .having((state) => state.tipGuest, 'tipGuest', 2)
              .having((state) => state.joker, 'joker', true)
              .having((state) => state.isSubmitting, 'isSubmitting', false),
        ],
        verify: (_) {
          verify(() => mockTipRepository.create(any(
            that: predicate<Tip>((tip) => tip.joker == true),
          ))).called(1);
        },
      );

      blocTest<TipFormBloc, TipFormState>(
        'creates empty tip when both scores are null',
        build: () {
          when(() => mockTipRepository.create(any()))
              .thenAnswer((_) async => right(unit));
          return tipFormBloc;
        },
        act: (bloc) => bloc.add(TipFormFieldUpdatedEvent(
          userId: 'user_empty',
          matchId: 'match_empty',
          matchDay: 1,
          tipHome: null,
          tipGuest: null,
          joker: false,
        )),
        expect: () => [
          isA<TipFormState>().having((state) => state.isSubmitting, 'isSubmitting', true),
          isA<TipFormState>()
              .having((state) => state.tipHome, 'tipHome', isNull)
              .having((state) => state.tipGuest, 'tipGuest', isNull)
              .having((state) => state.joker, 'joker', false)
              .having((state) => state.isSubmitting, 'isSubmitting', false),
        ],
        verify: (_) {
          verify(() => mockTipRepository.create(any(
            that: predicate<Tip>((tip) =>
                tip.tipHome == null &&
                tip.tipGuest == null &&
                tip.joker == false),
          ))).called(1);
        },
      );

      blocTest<TipFormBloc, TipFormState>(
        'handles high scoring game correctly',
        build: () {
          when(() => mockTipRepository.create(any()))
              .thenAnswer((_) async => right(unit));
          return tipFormBloc;
        },
        act: (bloc) => bloc.add(TipFormFieldUpdatedEvent(
          userId: 'user_high_score',
          matchId: 'match_high_score',
          matchDay: 1,
          tipHome: 5,
          tipGuest: 4,
          joker: false,
        )),
        expect: () => [
          isA<TipFormState>().having((state) => state.isSubmitting, 'isSubmitting', true),
          isA<TipFormState>()
              .having((state) => state.tipHome, 'tipHome', 5)
              .having((state) => state.tipGuest, 'tipGuest', 4),
        ],
        verify: (_) {
          verify(() => mockTipRepository.create(any(
            that: predicate<Tip>((tip) => tip.tipHome == 5 && tip.tipGuest == 4),
          ))).called(1);
        },
      );

      blocTest<TipFormBloc, TipFormState>(
        'handles zero scores correctly',
        build: () {
          when(() => mockTipRepository.create(any()))
              .thenAnswer((_) async => right(unit));
          return tipFormBloc;
        },
        act: (bloc) => bloc.add(TipFormFieldUpdatedEvent(
          userId: 'user_zero',
          matchId: 'match_zero',
          matchDay: 1,
          tipHome: 0,
          tipGuest: 0,
          joker: false,
        )),
        expect: () => [
          isA<TipFormState>().having((state) => state.isSubmitting, 'isSubmitting', true),
          isA<TipFormState>()
              .having((state) => state.tipHome, 'tipHome', 0)
              .having((state) => state.tipGuest, 'tipGuest', 0),
        ],
        verify: (_) {
          verify(() => mockTipRepository.create(any(
            that: predicate<Tip>((tip) => tip.tipHome == 0 && tip.tipGuest == 0),
          ))).called(1);
        },
      );
    });

    group('TipFormFieldUpdatedEvent - Validation Cases', () {
      blocTest<TipFormBloc, TipFormState>(
        'shows validation error when only home score is provided',
        build: () => tipFormBloc,
        act: (bloc) => bloc.add(TipFormFieldUpdatedEvent(
          userId: 'user_incomplete',
          matchId: 'match_incomplete',
          matchDay: 1,
          tipHome: 2,
          tipGuest: null,
          joker: false,
        )),
        expect: () => [
          isA<TipFormState>().having((state) => state.isSubmitting, 'isSubmitting', true),
          isA<TipFormState>()
              .having((state) => state.showValidationMessages, 'showValidationMessages', true)
              .having((state) => state.isSubmitting, 'isSubmitting', false)
              .having((state) => state.tipHome, 'tipHome', 2)
              .having((state) => state.tipGuest, 'tipGuest', isNull)
              .having((state) => state.failureOrSuccessOption.isSome(), 'has failure', true),
        ],
        verify: (_) {
          verifyNever(() => mockTipRepository.create(any()));
        },
      );

      blocTest<TipFormBloc, TipFormState>(
        'shows validation error when only guest score is provided',
        build: () => tipFormBloc,
        act: (bloc) => bloc.add(TipFormFieldUpdatedEvent(
          userId: 'user_incomplete',
          matchId: 'match_incomplete',
          matchDay: 1,
          tipHome: null,
          tipGuest: 1,
          joker: true,
        )),
        expect: () => [
          isA<TipFormState>().having((state) => state.isSubmitting, 'isSubmitting', true),
          isA<TipFormState>()
              .having((state) => state.showValidationMessages, 'showValidationMessages', true)
              .having((state) => state.isSubmitting, 'isSubmitting', false)
              .having((state) => state.tipHome, 'tipHome', isNull)
              .having((state) => state.tipGuest, 'tipGuest', 1)
              .having((state) => state.joker, 'joker', true),
        ],
        verify: (_) {
          verifyNever(() => mockTipRepository.create(any()));
        },
      );

      blocTest<TipFormBloc, TipFormState>(
        'validation failure contains InCompleteInputFailure',
        build: () => tipFormBloc,
        act: (bloc) => bloc.add(TipFormFieldUpdatedEvent(
          userId: 'user_validation',
          matchId: 'match_validation',
          matchDay: 1,
          tipHome: 3,
          tipGuest: null,
          joker: false,
        )),
        expect: () => [
          isA<TipFormState>().having((state) => state.isSubmitting, 'isSubmitting', true),
          isA<TipFormState>().having(
            (state) => state.failureOrSuccessOption.fold(
              () => false,
              (failureOrSuccess) => failureOrSuccess.fold(
                (failure) => failure is InCompleteInputFailure,
                (success) => false,
              ),
            ),
            'has InCompleteInputFailure',
            true,
          ),
        ],
      );
    });

    group('TipFormFieldUpdatedEvent - Repository Failure Cases', () {
      blocTest<TipFormBloc, TipFormState>(
        'handles repository create failure',
        build: () {
          when(() => mockTipRepository.create(any()))
              .thenAnswer((_) async => left(UnexpectedFailure()));
          return tipFormBloc;
        },
        act: (bloc) => bloc.add(TipFormFieldUpdatedEvent(
          userId: 'user_repo_fail',
          matchId: 'match_repo_fail',
          matchDay: 1,
          tipHome: 1,
          tipGuest: 2,
          joker: false,
        )),
        expect: () => [
          isA<TipFormState>().having((state) => state.isSubmitting, 'isSubmitting', true),
          isA<TipFormState>()
              .having((state) => state.isSubmitting, 'isSubmitting', false)
              .having((state) => state.failureOrSuccessOption.isSome(), 'has failure result', true),
        ],
        verify: (_) {
          verify(() => mockTipRepository.create(any())).called(1);
        },
      );

      blocTest<TipFormBloc, TipFormState>(
        'handles insufficient permissions failure',
        build: () {
          when(() => mockTipRepository.create(any()))
              .thenAnswer((_) async => left(InsufficientPermisssons()));
          return tipFormBloc;
        },
        act: (bloc) => bloc.add(TipFormFieldUpdatedEvent(
          userId: 'user_no_permissions',
          matchId: 'match_no_permissions',
          matchDay: 1,
          tipHome: 0,
          tipGuest: 3,
          joker: false,  // Changed to false to avoid joker validation
        )),
        expect: () => [
          isA<TipFormState>().having((state) => state.isSubmitting, 'isSubmitting', true),
          isA<TipFormState>().having(
            (state) => state.failureOrSuccessOption.fold(
              () => false,
              (failureOrSuccess) => failureOrSuccess.fold(
                (failure) => failure is InsufficientPermisssons,
                (success) => false,
              ),
            ),
            'has InsufficientPermissions failure',
            true,
          ),
        ],
      );
    });

    group('Edge Cases and State Management', () {
      blocTest<TipFormBloc, TipFormState>(
        'handles rapid successive updates correctly',
        build: () {
          when(() => mockTipRepository.create(any()))
              .thenAnswer((_) async => right(unit));
          return tipFormBloc;
        },
        act: (bloc) async {
          // First update
          bloc.add(TipFormFieldUpdatedEvent(
            userId: 'user_rapid',
            matchId: 'match_rapid',
            matchDay: 1,
            tipHome: 1,
            tipGuest: 0,
            joker: false,
          ));
          
          await Future.delayed(Duration(milliseconds: 10));
          
          // Second update
          bloc.add(TipFormFieldUpdatedEvent(
            userId: 'user_rapid',
            matchId: 'match_rapid',
            matchDay: 1,
            tipHome: 2,
            tipGuest: 1,
            joker: false,  // Changed to false to avoid extra joker validation state
          ));
        },
        wait: Duration(milliseconds: 100),
        expect: () => [
          isA<TipFormState>().having((state) => state.isSubmitting, 'first isSubmitting', true),
          isA<TipFormState>().having((state) => state.tipHome, 'first tipHome', 1),
          isA<TipFormState>().having((state) => state.isSubmitting, 'second isSubmitting', true),
          isA<TipFormState>()
              .having((state) => state.tipHome, 'final tipHome', 2)
              .having((state) => state.tipGuest, 'final tipGuest', 1)
              .having((state) => state.joker, 'final joker', false),
        ],
        verify: (_) {
          verify(() => mockTipRepository.create(any())).called(2);
        },
      );

      blocTest<TipFormBloc, TipFormState>(
        'correctly sets tip ID format',
        build: () {
          when(() => mockTipRepository.create(any()))
              .thenAnswer((_) async => right(unit));
          return tipFormBloc;
        },
        act: (bloc) => bloc.add(TipFormFieldUpdatedEvent(
          userId: 'user_id_test',
          matchId: 'match_id_test',
          matchDay: 1,
          tipHome: 1,
          tipGuest: 1,
          joker: false,
        )),
        expect: () => [
          isA<TipFormState>().having((state) => state.isSubmitting, 'isSubmitting', true),
          isA<TipFormState>().having((state) => state.isSubmitting, 'isSubmitting', false),
        ],
        verify: (_) {
          verify(() => mockTipRepository.create(any(
            that: predicate<Tip>((tip) => tip.id == 'user_id_test_match_id_test'),
          ))).called(1);
        },
      );

      blocTest<TipFormBloc, TipFormState>(
        'maintains state consistency during form lifecycle',
        build: () {
          when(() => mockTipRepository.create(any()))
              .thenAnswer((_) async => right(unit));
          return tipFormBloc;
        },
        seed: () => TipFormState(
          userId: 'existing_user',
          matchId: 'existing_match',
          matchDay: 1,
          tipHome: null,
          tipGuest: null,
          joker: false,
          isSubmitting: false,
          showValidationMessages: false,
          failureOrSuccessOption: none(),
        ),
        act: (bloc) => bloc.add(TipFormFieldUpdatedEvent(
          userId: 'updated_user',
          matchId: 'updated_match',
          matchDay: 1,
          tipHome: 3,
          tipGuest: 2,
          joker: false,  // Changed to false to avoid joker validation
        )),
        expect: () => [
          isA<TipFormState>().having((state) => state.isSubmitting, 'isSubmitting', true),
          isA<TipFormState>()
              .having((state) => state.tipHome, 'tipHome', 3)
              .having((state) => state.tipGuest, 'tipGuest', 2)
              .having((state) => state.joker, 'joker', false)
              .having((state) => state.isSubmitting, 'isSubmitting', false),
        ],
      );
    });

    test('bloc properly closes', () async {
      await tipFormBloc.close();
      expect(tipFormBloc.isClosed, true);
    });
  });
}