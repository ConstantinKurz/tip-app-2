import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:flutter_web/domain/entities/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(authRepository: mockAuthRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    group('SignOutPressedEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthStateUnAuthenticated] when sign out is called',
        build: () {
          when(() => mockAuthRepository.signOut())
              .thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) => bloc.add(SignOutPressedEvent()),
        expect: () => [isA<AuthStateUnAuthenticated>()],
        verify: (_) {
          verify(() => mockAuthRepository.signOut()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'handles multiple sign out events correctly',
        build: () {
          when(() => mockAuthRepository.signOut())
              .thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) {
          bloc.add(SignOutPressedEvent());
          bloc.add(SignOutPressedEvent());
        },
        expect: () => [
          isA<AuthStateUnAuthenticated>(),
          isA<AuthStateUnAuthenticated>(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.signOut()).called(2);
        },
      );
    });

    group('AuthCheckRequestedEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthStateAuthenticated] when user is signed in',
        build: () {
          final user = AppUser(
            id: 'test_user',
            championId: 'team_1',
            email: 'test@example.com',
            name: 'Test User',
            rank: 1,
            score: 100,
            jokerSum: 2,
            sixer: 1,
            admin: false,
          );
          when(() => mockAuthRepository.getSignedInUser())
              .thenAnswer((_) async => some(user));
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequestedEvent()),
        expect: () => [isA<AuthStateAuthenticated>()],
        verify: (_) {
          verify(() => mockAuthRepository.getSignedInUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthStateUnAuthenticated] when user is not signed in',
        build: () {
          when(() => mockAuthRepository.getSignedInUser())
              .thenAnswer((_) async => none());
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequestedEvent()),
        expect: () => [isA<AuthStateUnAuthenticated>()],
        verify: (_) {
          verify(() => mockAuthRepository.getSignedInUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'handles multiple auth check events correctly',
        build: () {
          final user = AppUser(
            id: 'test_user_2',
            championId: 'team_2',
            email: 'test2@example.com',
            name: 'Test User 2',
            rank: 2,
            score: 80,
            jokerSum: 1,
            sixer: 0,
            admin: false,
          );
          when(() => mockAuthRepository.getSignedInUser())
              .thenAnswer((_) async => some(user));
          return authBloc;
        },
        act: (bloc) {
          bloc.add(AuthCheckRequestedEvent());
          bloc.add(AuthCheckRequestedEvent());
        },
        expect: () => [
          isA<AuthStateAuthenticated>(),
          isA<AuthStateAuthenticated>(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.getSignedInUser()).called(2);
        },
      );
    });

    group('State Transitions', () {
      blocTest<AuthBloc, AuthState>(
        'transitions from AuthInitial to AuthStateAuthenticated to AuthStateUnAuthenticated',
        build: () {
          final user = AppUser(
            id: 'transition_user',
            championId: 'team_trans',
            email: 'transition@example.com',
            name: 'Transition User',
            rank: 5,
            score: 50,
            jokerSum: 0,
            sixer: 0,
            admin: false,
          );
          when(() => mockAuthRepository.getSignedInUser())
              .thenAnswer((_) async => some(user));
          when(() => mockAuthRepository.signOut())
              .thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) {
          bloc.add(AuthCheckRequestedEvent());
          bloc.add(SignOutPressedEvent());
        },
        expect: () => [
          isA<AuthStateAuthenticated>(),
          isA<AuthStateUnAuthenticated>(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.getSignedInUser()).called(1);
          verify(() => mockAuthRepository.signOut()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'handles alternating events correctly',
        build: () {
          final user = AppUser(
            id: 'alt_user',
            championId: 'team_alt',
            email: 'alt@example.com',
            name: 'Alt User',
            rank: 3,
            score: 75,
            jokerSum: 1,
            sixer: 1,
            admin: true,
          );
          when(() => mockAuthRepository.getSignedInUser())
              .thenAnswer((_) async => some(user));
          when(() => mockAuthRepository.signOut())
              .thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) {
          bloc.add(AuthCheckRequestedEvent());
          bloc.add(SignOutPressedEvent());
          bloc.add(AuthCheckRequestedEvent());
        },
        expect: () => [
          isA<AuthStateAuthenticated>(),
          isA<AuthStateUnAuthenticated>(),
          isA<AuthStateAuthenticated>(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.getSignedInUser()).called(2);
          verify(() => mockAuthRepository.signOut()).called(1);
        },
      );
    });

    group('Edge Cases', () {
      blocTest<AuthBloc, AuthState>(
        'handles rapid successive events',
        build: () {
          final user = AppUser(
            id: 'rapid_user',
            championId: 'team_rapid',
            email: 'rapid@example.com',
            name: 'Rapid User',
            rank: 1,
            score: 200,
            jokerSum: 3,
            sixer: 2,
            admin: false,
          );
          when(() => mockAuthRepository.getSignedInUser())
              .thenAnswer((_) async => some(user));
          when(() => mockAuthRepository.signOut())
              .thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) {
          for (int i = 0; i < 3; i++) {
            bloc.add(AuthCheckRequestedEvent());
          }
          for (int i = 0; i < 2; i++) {
            bloc.add(SignOutPressedEvent());
          }
        },
        expect: () => [
          isA<AuthStateAuthenticated>(),
          isA<AuthStateAuthenticated>(),
          isA<AuthStateAuthenticated>(),
          isA<AuthStateUnAuthenticated>(),
          isA<AuthStateUnAuthenticated>(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.getSignedInUser()).called(3);
          verify(() => mockAuthRepository.signOut()).called(2);
        },
      );

      test('bloc can be closed and reopened', () async {
        await authBloc.close();
        
        final newAuthBloc = AuthBloc(authRepository: mockAuthRepository);
        expect(newAuthBloc.state, isA<AuthInitial>());
        
        await newAuthBloc.close();
      });
    });

    group('Repository Integration', () {
      blocTest<AuthBloc, AuthState>(
        'correctly handles repository returning admin user',
        build: () {
          final adminUser = AppUser(
            id: 'admin_user',
            championId: 'team_admin',
            email: 'admin@example.com',
            name: 'Admin User',
            rank: 0,
            score: 0,
            jokerSum: 0,
            sixer: 0,
            admin: true,
          );
          when(() => mockAuthRepository.getSignedInUser())
              .thenAnswer((_) async => some(adminUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequestedEvent()),
        expect: () => [isA<AuthStateAuthenticated>()],
        verify: (_) {
          verify(() => mockAuthRepository.getSignedInUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'correctly handles repository returning regular user',
        build: () {
          final regularUser = AppUser(
            id: 'regular_user',
            championId: 'team_regular',
            email: 'regular@example.com',
            name: 'Regular User',
            rank: 15,
            score: 45,
            jokerSum: 1,
            sixer: 0,
            admin: false,
          );
          when(() => mockAuthRepository.getSignedInUser())
              .thenAnswer((_) async => some(regularUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequestedEvent()),
        expect: () => [isA<AuthStateAuthenticated>()],
        verify: (_) {
          verify(() => mockAuthRepository.getSignedInUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'handles empty user option correctly',
        build: () {
          when(() => mockAuthRepository.getSignedInUser())
              .thenAnswer((_) async => none());
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequestedEvent()),
        expect: () => [isA<AuthStateUnAuthenticated>()],
        verify: (_) {
          verify(() => mockAuthRepository.getSignedInUser()).called(1);
        },
      );
    });

    group('Mixed Event Scenarios', () {
      blocTest<AuthBloc, AuthState>(
        'handles sign out followed by auth check with no user',
        build: () {
          when(() => mockAuthRepository.signOut())
              .thenAnswer((_) async => {});
          when(() => mockAuthRepository.getSignedInUser())
              .thenAnswer((_) async => none());
          return authBloc;
        },
        act: (bloc) {
          bloc.add(SignOutPressedEvent());
          bloc.add(AuthCheckRequestedEvent());
        },
        expect: () => [
          isA<AuthStateUnAuthenticated>(),
          isA<AuthStateUnAuthenticated>(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.signOut()).called(1);
          verify(() => mockAuthRepository.getSignedInUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'handles auth check with user followed by sign out',
        build: () {
          final user = AppUser(
            id: 'mixed_user',
            championId: 'team_mixed',
            email: 'mixed@example.com',
            name: 'Mixed User',
            rank: 8,
            score: 65,
            jokerSum: 2,
            sixer: 1,
            admin: false,
          );
          when(() => mockAuthRepository.getSignedInUser())
              .thenAnswer((_) async => some(user));
          when(() => mockAuthRepository.signOut())
              .thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) {
          bloc.add(AuthCheckRequestedEvent());
          bloc.add(SignOutPressedEvent());
        },
        expect: () => [
          isA<AuthStateAuthenticated>(),
          isA<AuthStateUnAuthenticated>(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.getSignedInUser()).called(1);
          verify(() => mockAuthRepository.signOut()).called(1);
        },
      );
    });
  });
}