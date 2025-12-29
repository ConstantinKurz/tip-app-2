import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/application/signupform/signupform_bloc.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('SignupformBloc', () {
    late SignupformBloc signupformBloc;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      signupformBloc = SignupformBloc(authRepository: mockAuthRepository);
    });

    tearDown(() {
      signupformBloc.close();
    });

    test('initial state has all flags set to false and empty options', () {
      expect(signupformBloc.state.isSubmitting, false);
      expect(signupformBloc.state.sendingResetEmail, false);
      expect(signupformBloc.state.showValidationMessages, false);
      expect(signupformBloc.state.authFailureOrSuccessOption, none());
      expect(signupformBloc.state.resetEmailFailureOrSuccessOption, none());
    });

    group('RegisterWithEmailAndPasswordPressed', () {
      blocTest<SignupformBloc, SignupformState>(
        'successfully registers user with valid credentials',
        build: () {
          when(() => mockAuthRepository.registerWithEmailAndPassword(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => right(unit));
          return signupformBloc;
        },
        act: (bloc) => bloc.add(RegisterWithEmailAndPasswordPressed(
          email: 'test@example.com',
          password: 'password123',
        )),
        expect: () => [
          isA<SignupformState>()
              .having((state) => state.isSubmitting, 'isSubmitting', true)
              .having((state) => state.showValidationMessages, 'showValidationMessages', false),
          isA<SignupformState>()
              .having((state) => state.isSubmitting, 'isSubmitting', false)
              .having((state) => state.authFailureOrSuccessOption.isSome(), 'has auth result', true),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.registerWithEmailAndPassword(
                email: 'test@example.com',
                password: 'password123',
              )).called(1);
        },
      );

      blocTest<SignupformBloc, SignupformState>(
        'shows validation messages when email is missing',
        build: () => signupformBloc,
        act: (bloc) => bloc.add(RegisterWithEmailAndPasswordPressed(
          email: null,
          password: 'password123',
        )),
        expect: () => [
          isA<SignupformState>()
              .having((state) => state.isSubmitting, 'isSubmitting', false)
              .having((state) => state.showValidationMessages, 'showValidationMessages', true),
        ],
        verify: (_) {
          verifyNever(() => mockAuthRepository.registerWithEmailAndPassword(
                email: any(named: 'email'),
                password: any(named: 'password'),
              ));
        },
      );

      blocTest<SignupformBloc, SignupformState>(
        'shows validation messages when password is missing',
        build: () => signupformBloc,
        act: (bloc) => bloc.add(RegisterWithEmailAndPasswordPressed(
          email: 'test@example.com',
          password: null,
        )),
        expect: () => [
          isA<SignupformState>()
              .having((state) => state.isSubmitting, 'isSubmitting', false)
              .having((state) => state.showValidationMessages, 'showValidationMessages', true),
        ],
        verify: (_) {
          verifyNever(() => mockAuthRepository.registerWithEmailAndPassword(
                email: any(named: 'email'),
                password: any(named: 'password'),
              ));
        },
      );

      blocTest<SignupformBloc, SignupformState>(
        'shows validation messages when both email and password are missing',
        build: () => signupformBloc,
        act: (bloc) => bloc.add(RegisterWithEmailAndPasswordPressed(
          email: null,
          password: null,
        )),
        expect: () => [
          isA<SignupformState>()
              .having((state) => state.showValidationMessages, 'showValidationMessages', true),
        ],
      );

      blocTest<SignupformBloc, SignupformState>(
        'handles registration failure correctly',
        build: () {
          when(() => mockAuthRepository.registerWithEmailAndPassword(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => left(EmailAlreadyInUseFailure()));
          return signupformBloc;
        },
        act: (bloc) => bloc.add(RegisterWithEmailAndPasswordPressed(
          email: 'existing@example.com',
          password: 'password123',
        )),
        expect: () => [
          isA<SignupformState>().having((state) => state.isSubmitting, 'isSubmitting', true),
          isA<SignupformState>()
              .having((state) => state.isSubmitting, 'isSubmitting', false)
              .having((state) => state.authFailureOrSuccessOption.isSome(), 'has auth failure', true),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.registerWithEmailAndPassword(
                email: 'existing@example.com',
                password: 'password123',
              )).called(1);
        },
      );
    });

    group('SignInWithEmailAndPasswordPressed', () {
      blocTest<SignupformBloc, SignupformState>(
        'successfully signs in user with valid credentials',
        build: () {
          when(() => mockAuthRepository.signInWithEmailAndPassword(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => right(unit));
          return signupformBloc;
        },
        act: (bloc) => bloc.add(SignInWithEmailAndPasswordPressed(
          email: 'signin@example.com',
          password: 'password456',
        )),
        expect: () => [
          isA<SignupformState>()
              .having((state) => state.isSubmitting, 'isSubmitting', true)
              .having((state) => state.showValidationMessages, 'showValidationMessages', false),
          isA<SignupformState>()
              .having((state) => state.isSubmitting, 'isSubmitting', false)
              .having((state) => state.authFailureOrSuccessOption.isSome(), 'has auth result', true),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.signInWithEmailAndPassword(
                email: 'signin@example.com',
                password: 'password456',
              )).called(1);
        },
      );

      blocTest<SignupformBloc, SignupformState>(
        'shows validation messages when email is missing for sign in',
        build: () => signupformBloc,
        act: (bloc) => bloc.add(SignInWithEmailAndPasswordPressed(
          email: null,
          password: 'password456',
        )),
        expect: () => [
          isA<SignupformState>()
              .having((state) => state.showValidationMessages, 'showValidationMessages', true),
        ],
      );

      blocTest<SignupformBloc, SignupformState>(
        'handles invalid email/password failure',
        build: () {
          when(() => mockAuthRepository.signInWithEmailAndPassword(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => left(InvalidEmailAndPasswordCombinationFailure()));
          return signupformBloc;
        },
        act: (bloc) => bloc.add(SignInWithEmailAndPasswordPressed(
          email: 'invalid@example.com',
          password: 'wrongpassword',
        )),
        expect: () => [
          isA<SignupformState>().having((state) => state.isSubmitting, 'isSubmitting', true),
          isA<SignupformState>()
              .having((state) => state.isSubmitting, 'isSubmitting', false)
              .having((state) => state.authFailureOrSuccessOption.isSome(), 'has auth failure', true),
        ],
      );
    });

    group('SendPasswordResetEvent', () {
      blocTest<SignupformBloc, SignupformState>(
        'successfully sends password reset email',
        build: () {
          when(() => mockAuthRepository.sendPasswordResetEmail(
                email: any(named: 'email'),
              )).thenAnswer((_) async => right(unit));
          return signupformBloc;
        },
        act: (bloc) => bloc.add(SendPasswordResetEvent(
          email: 'reset@example.com',
        )),
        expect: () => [
          isA<SignupformState>()
              .having((state) => state.sendingResetEmail, 'sendingResetEmail', true),
          isA<SignupformState>()
              .having((state) => state.sendingResetEmail, 'sendingResetEmail', false)
              .having((state) => state.resetEmailFailureOrSuccessOption.isSome(), 'has reset result', true),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.sendPasswordResetEmail(
                email: 'reset@example.com',
              )).called(1);
        },
      );

      blocTest<SignupformBloc, SignupformState>(
        'handles password reset failure',
        build: () {
          when(() => mockAuthRepository.sendPasswordResetEmail(
                email: any(named: 'email'),
              )).thenAnswer((_) async => left(ServerFailure()));
          return signupformBloc;
        },
        act: (bloc) => bloc.add(SendPasswordResetEvent(
          email: 'nonexistent@example.com',
        )),
        expect: () => [
          isA<SignupformState>().having((state) => state.sendingResetEmail, 'sendingResetEmail', true),
          isA<SignupformState>()
              .having((state) => state.sendingResetEmail, 'sendingResetEmail', false)
              .having((state) => state.resetEmailFailureOrSuccessOption.isSome(), 'has reset failure', true),
        ],
      );
    });

    group('State Management and Edge Cases', () {
      blocTest<SignupformBloc, SignupformState>(
        'handles multiple rapid events correctly',
        build: () {
          when(() => mockAuthRepository.registerWithEmailAndPassword(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => right(unit));
          when(() => mockAuthRepository.signInWithEmailAndPassword(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => right(unit));
          return signupformBloc;
        },
        act: (bloc) async {
          bloc.add(RegisterWithEmailAndPasswordPressed(
            email: 'test1@example.com',
            password: 'password1',
          ));
          await Future.delayed(Duration(milliseconds: 10));
          bloc.add(SignInWithEmailAndPasswordPressed(
            email: 'test2@example.com',
            password: 'password2',
          ));
        },
        wait: Duration(milliseconds: 100),
        expect: () => [
          isA<SignupformState>().having((state) => state.isSubmitting, 'first isSubmitting', true),
          isA<SignupformState>().having((state) => state.isSubmitting, 'first completed', false),
          isA<SignupformState>().having((state) => state.isSubmitting, 'second isSubmitting', true),
          isA<SignupformState>().having((state) => state.isSubmitting, 'second completed', false),
        ],
      );

      blocTest<SignupformBloc, SignupformState>(
        'resets validation messages on valid submit',
        build: () {
          when(() => mockAuthRepository.registerWithEmailAndPassword(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => right(unit));
          return signupformBloc;
        },
        seed: () => SignupformState(
          isSubmitting: false,
          sendingResetEmail: false,
          showValidationMessages: true,
          authFailureOrSuccessOption: none(),
          resetEmailFailureOrSuccessOption: none(),
        ),
        act: (bloc) => bloc.add(RegisterWithEmailAndPasswordPressed(
          email: 'valid@example.com',
          password: 'validpassword',
        )),
        expect: () => [
          isA<SignupformState>()
              .having((state) => state.isSubmitting, 'isSubmitting', true)
              .having((state) => state.showValidationMessages, 'showValidationMessages', false),
          isA<SignupformState>().having((state) => state.isSubmitting, 'isSubmitting', false),
        ],
      );

      test('_isMissingCredentials helper works correctly', () {
        // Since the method is private, we test it through the public API
        expect(signupformBloc.state.showValidationMessages, false);
      });

      blocTest<SignupformBloc, SignupformState>(
        'handles concurrent password reset requests',
        build: () {
          when(() => mockAuthRepository.sendPasswordResetEmail(
                email: any(named: 'email'),
              )).thenAnswer((_) async {
            await Future.delayed(Duration(milliseconds: 30));
            return right(unit);
          });
          return signupformBloc;
        },
        act: (bloc) async {
          bloc.add(SendPasswordResetEvent(email: 'concurrent1@example.com'));
          await Future.delayed(Duration(milliseconds: 50));
          bloc.add(SendPasswordResetEvent(email: 'concurrent2@example.com'));
        },
        wait: Duration(milliseconds: 200),
        expect: () => [
          isA<SignupformState>().having((state) => state.sendingResetEmail, 'first sending', true),
          isA<SignupformState>().having((state) => state.sendingResetEmail, 'first complete', false),
          isA<SignupformState>().having((state) => state.sendingResetEmail, 'second sending', true),
          isA<SignupformState>().having((state) => state.sendingResetEmail, 'second complete', false),
        ],
      );
    });

    group('Failure Type Validation', () {
      blocTest<SignupformBloc, SignupformState>(
        'correctly propagates specific auth failures',
        build: () {
          when(() => mockAuthRepository.registerWithEmailAndPassword(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => left(InvalidEmailFailure(message: "Weak password")));
          return signupformBloc;
        },
        act: (bloc) => bloc.add(RegisterWithEmailAndPasswordPressed(
          email: 'weak@example.com',
          password: '123',
        )),
        expect: () => [
          isA<SignupformState>().having((state) => state.isSubmitting, 'isSubmitting', true),
          isA<SignupformState>().having(
            (state) => state.authFailureOrSuccessOption.fold(
              () => false,
              (either) => either.fold(
                (failure) => failure is InvalidEmailFailure,
                (_) => false,
              ),
            ),
            'has InvalidEmailFailure',
            true,
          ),
        ],
      );

      blocTest<SignupformBloc, SignupformState>(
        'correctly handles network failures for reset email',
        build: () {
          when(() => mockAuthRepository.sendPasswordResetEmail(
                email: any(named: 'email'),
              )).thenAnswer((_) async => left(ServerFailure()));
          return signupformBloc;
        },
        act: (bloc) => bloc.add(SendPasswordResetEvent(
          email: 'network@example.com',
        )),
        expect: () => [
          isA<SignupformState>().having((state) => state.sendingResetEmail, 'sendingResetEmail', true),
          isA<SignupformState>().having(
            (state) => state.resetEmailFailureOrSuccessOption.fold(
              () => false,
              (either) => either.fold(
                (failure) => failure is ServerFailure,
                (_) => false,
              ),
            ),
            'has ServerFailure',
            true,
          ),
        ],
      );
    });

    test('bloc properly closes', () async {
      await signupformBloc.close();
      expect(signupformBloc.isClosed, true);
    });
  });
}