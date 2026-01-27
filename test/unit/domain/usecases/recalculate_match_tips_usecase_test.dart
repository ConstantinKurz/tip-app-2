import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/domain/usecases/recalculate_match_tips_usecase.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/repositories/user_repository.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';

class MockTipRepository extends Mock implements TipRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('RecalculateMatchTipsUseCase', () {
    late MockTipRepository mockTipRepository;
    late MockUserRepository mockUserRepository;
    late RecalculateMatchTipsUseCase useCase;

    setUp(() {
      mockTipRepository = MockTipRepository();
      mockUserRepository = MockUserRepository();
      useCase = RecalculateMatchTipsUseCase(
        tipRepository: mockTipRepository,
        userRepository: mockUserRepository,
      );
      registerFallbackValue(<String, dynamic>{});
      registerFallbackValue(AppUser(
        id: 'fallback_user',
        email: 'fallback@test.com',
        score: 0,
        rank: 0,
        jokerSum: 0,
        sixer: 0,
        championId: 'TBD',
        name: 'Fallback User',
        admin: false,
      ));
    });

    group('Grundlegende Funktionalität', () {
      test('sollte nichts tun wenn Match kein Ergebnis hat', () async {
        // Arrange
        final match = CustomMatch(
          id: 'match_1',
          homeTeamId: 'team_1',
          guestTeamId: 'team_2',
          matchDate: DateTime(2024, 6, 14),
          matchDay: 1,
          homeScore: null,
          guestScore: null,
        );

        // Act
        final result = await useCase(match: match);

        // Assert
        expect(result, isA<Right<TipFailure, Unit>>());
        verifyNever(() => mockTipRepository.getTipsForMatch(any()));
      });

      test('sollte Punkte neu berechnen wenn Match Ergebnis hat', () async {
        // Arrange
        final match = CustomMatch(
          id: 'match_1',
          homeTeamId: 'team_1',
          guestTeamId: 'team_2',
          matchDate: DateTime(2024, 6, 14),
          matchDay: 1,
          homeScore: 2,
          guestScore: 1,
        );

        final tips = [
          Tip(
            id: 'tip_1',
            userId: 'user_1',
            matchId: 'match_1',
            tipDate: DateTime.now(),
            tipHome: 2,
            tipGuest: 1,
            joker: false,
            points: 0, // Wird neu berechnet
          ),
        ];

        when(() => mockTipRepository.getTipsForMatch('match_1'))
            .thenAnswer((_) async => right(tips));
        when(() => mockTipRepository.updatePoints(
                tipId: any(named: 'tipId'), points: any(named: 'points')))
            .thenAnswer((_) async => right(unit));
        when(() => mockUserRepository.getUserById(any()))
            .thenAnswer((_) async => right(
              AppUser(
                id: 'user_1',
                email: 'test@test.com',
                score: 0,
                rank: 0,
                jokerSum: 0,
                sixer: 0,
                championId: 'TBD',
                name: 'Test User',
                admin: false,
              ),
            ));
        when(() => mockUserRepository.updateUser(any()))
            .thenAnswer((_) async => right(unit));
        when(() => mockTipRepository.getTipsByUserId('user_1'))
            .thenAnswer((_) async => right(tips));

        // Act
        final result = await useCase(match: match);

        // Assert
        expect(result, isA<Right<TipFailure, Unit>>());
        verify(() => mockTipRepository.getTipsForMatch('match_1')).called(1);
      });
    });

    group('Punkte Neuberechnung mit verschiedenen Phasen', () {
      test('sollte Gruppenphasen-Punkte berechnen (matchDay 1-3)', () async {
        // Arrange - matchDay 1-3 = groupStage mit 1x Multiplikator
        final match = CustomMatch(
          id: 'match_group',
          homeTeamId: 'team_1',
          guestTeamId: 'team_2',
          matchDate: DateTime(2024, 6, 14),
          matchDay: 1,
          homeScore: 2,
          guestScore: 1,
        );

        final tip = Tip(
          id: 'tip_exact',
          userId: 'user_1',
          matchId: 'match_group',
          tipDate: DateTime.now(),
          tipHome: 2,
          tipGuest: 1,
          joker: false,
          points: 0,
        );

        when(() => mockTipRepository.getTipsForMatch('match_group'))
            .thenAnswer((_) async => right([tip]));
        when(() => mockTipRepository.updatePoints(
                tipId: 'tip_exact', points: 6)) // 6 * 1 (Gruppe)
            .thenAnswer((_) async => right(unit));
        when(() => mockUserRepository.getUserById('user_1')).thenAnswer(
            (_) async => right(AppUser(
                  id: 'user_1',
                  email: 'test@test.com',
                  score: 0,
                  rank: 0,
                  jokerSum: 0,
                  sixer: 0,
                  championId: 'TBD',
                  name: 'Test User',
                  admin: false,
                )));
        when(() => mockUserRepository.updateUser(any()))
            .thenAnswer((_) async => right(unit));
        when(() => mockTipRepository.getTipsByUserId('user_1'))
            .thenAnswer((_) async => right([tip]));

        // Act
        final result = await useCase(match: match);

        // Assert
        expect(result, isA<Right<TipFailure, Unit>>());
        verify(() => mockTipRepository.updatePoints(
            tipId: 'tip_exact', points: 6)).called(1);
      });

      test('sollte Achtel-Finale-Punkte mit 2x Multiplikator berechnen', () async {
        // Arrange - matchDay 5 = quarterFinal mit 2x Multiplikator
        final match = CustomMatch(
          id: 'match_qf',
          homeTeamId: 'team_1',
          guestTeamId: 'team_2',
          matchDate: DateTime(2024, 6, 25),
          matchDay: 5,
          homeScore: 1,
          guestScore: 0,
        );

        final tip = Tip(
          id: 'tip_qf',
          userId: 'user_1',
          matchId: 'match_qf',
          tipDate: DateTime.now(),
          tipHome: 1,
          tipGuest: 0,
          joker: false,
          points: 0,
        );

        when(() => mockTipRepository.getTipsForMatch('match_qf'))
            .thenAnswer((_) async => right([tip]));
        when(() => mockTipRepository.updatePoints(
                tipId: 'tip_qf', points: 12)) // 6 * 2 (Achtel)
            .thenAnswer((_) async => right(unit));
        when(() => mockUserRepository.getUserById('user_1')).thenAnswer(
            (_) async => right(AppUser(
                  id: 'user_1',
                  email: 'test@test.com',
                  score: 0,
                  rank: 0,
                  jokerSum: 0,
                  sixer: 0,
                  championId: 'TBD',
                  name: 'Test User',
                  admin: false,
                )));
        when(() => mockUserRepository.updateUser(any()))
            .thenAnswer((_) async => right(unit));
        when(() => mockTipRepository.getTipsByUserId('user_1'))
            .thenAnswer((_) async => right([tip]));

        // Act
        final result = await useCase(match: match);

        // Assert
        expect(result, isA<Right<TipFailure, Unit>>());
        verify(() => mockTipRepository.updatePoints(
            tipId: 'tip_qf', points: 12)).called(1);
      });

      test('sollte Viertel-Finale-Punkte mit 3x Multiplikator berechnen', () async {
        // Arrange - matchDay 6 = semiFinal mit 3x Multiplikator
        final match = CustomMatch(
          id: 'match_sf',
          homeTeamId: 'team_1',
          guestTeamId: 'team_2',
          matchDate: DateTime(2024, 7, 9),
          matchDay: 6,
          homeScore: 2,
          guestScore: 0,
        );

        final tip = Tip(
          id: 'tip_sf',
          userId: 'user_1',
          matchId: 'match_sf',
          tipDate: DateTime.now(),
          tipHome: 2,
          tipGuest: 0,
          joker: false,
          points: 0,
        );

        when(() => mockTipRepository.getTipsForMatch('match_sf'))
            .thenAnswer((_) async => right([tip]));
        when(() => mockTipRepository.updatePoints(
                tipId: 'tip_sf', points: 18)) // 6 * 3 (Viertel)
            .thenAnswer((_) async => right(unit));
        when(() => mockUserRepository.getUserById('user_1')).thenAnswer(
            (_) async => right(AppUser(
                  id: 'user_1',
                  email: 'test@test.com',
                  score: 0,
                  rank: 0,
                  jokerSum: 0,
                  sixer: 0,
                  championId: 'TBD',
                  name: 'Test User',
                  admin: false,
                )));
        when(() => mockUserRepository.updateUser(any()))
            .thenAnswer((_) async => right(unit));
        when(() => mockTipRepository.getTipsByUserId('user_1'))
            .thenAnswer((_) async => right([tip]));

        // Act
        final result = await useCase(match: match);

        // Assert
        expect(result, isA<Right<TipFailure, Unit>>());
        verify(() => mockTipRepository.updatePoints(
            tipId: 'tip_sf', points: 18)).called(1);
      });

      test('sollte Finale-Punkte mit 3x Multiplikator berechnen', () async {
        // Arrange - matchDay 8 = finalStage mit 3x Multiplikator
        final match = CustomMatch(
          id: 'match_final',
          homeTeamId: 'team_1',
          guestTeamId: 'team_2',
          matchDate: DateTime(2024, 7, 14),
          matchDay: 8,
          homeScore: 2,
          guestScore: 0,
        );

        final tip = Tip(
          id: 'tip_final',
          userId: 'user_1',
          matchId: 'match_final',
          tipDate: DateTime.now(),
          tipHome: 2,
          tipGuest: 0,
          joker: false,
          points: 0,
        );

        when(() => mockTipRepository.getTipsForMatch('match_final'))
            .thenAnswer((_) async => right([tip]));
        when(() => mockTipRepository.updatePoints(
                tipId: 'tip_final', points: 18)) // 6 * 3 (Finale)
            .thenAnswer((_) async => right(unit));
        when(() => mockUserRepository.getUserById('user_1')).thenAnswer(
            (_) async => right(AppUser(
                  id: 'user_1',
                  email: 'test@test.com',
                  score: 0,
                  rank: 0,
                  jokerSum: 0,
                  sixer: 0,
                  championId: 'TBD',
                  name: 'Test User',
                  admin: false,
                )));
        when(() => mockUserRepository.updateUser(any()))
            .thenAnswer((_) async => right(unit));
        when(() => mockTipRepository.getTipsByUserId('user_1'))
            .thenAnswer((_) async => right([tip]));

        // Act
        final result = await useCase(match: match);

        // Assert
        expect(result, isA<Right<TipFailure, Unit>>());
        verify(() => mockTipRepository.updatePoints(
            tipId: 'tip_final', points: 18)).called(1);
      });
    });

    group('Joker Verdoppelung', () {
      test('sollte Joker-Punkte verdoppeln', () async {
        // Arrange
        final match = CustomMatch(
          id: 'match_joker',
          homeTeamId: 'team_1',
          guestTeamId: 'team_2',
          matchDate: DateTime(2024, 6, 14),
          matchDay: 1,
          homeScore: 2,
          guestScore: 1,
        );

        final jokerTip = Tip(
          id: 'tip_joker',
          userId: 'user_1',
          matchId: 'match_joker',
          tipDate: DateTime.now(),
          tipHome: 2,
          tipGuest: 1,
          joker: true, // Joker aktiviert
          points: 0,
        );

        when(() => mockTipRepository.getTipsForMatch('match_joker'))
            .thenAnswer((_) async => right([jokerTip]));
        when(() => mockTipRepository.updatePoints(
                tipId: 'tip_joker', points: 12)) // 6 * 2 (Joker)
            .thenAnswer((_) async => right(unit));
        when(() => mockUserRepository.getUserById('user_1')).thenAnswer(
            (_) async => right(AppUser(
                  id: 'user_1',
                  email: 'test@test.com',
                  score: 0,
                  rank: 0,
                  jokerSum: 0,
                  sixer: 0,
                  championId: 'TBD',
                  name: 'Test User',
                  admin: false,
                )));
        when(() => mockUserRepository.updateUser(any()))
            .thenAnswer((_) async => right(unit));
        when(() => mockTipRepository.getTipsByUserId('user_1'))
            .thenAnswer((_) async => right([jokerTip]));

        // Act
        final result = await useCase(match: match);

        // Assert
        expect(result, isA<Right<TipFailure, Unit>>());
        verify(() => mockTipRepository.updatePoints(
            tipId: 'tip_joker', points: 12)).called(1);
      });

      test('sollte Joker mit Phase-Multiplikator kombinieren', () async {
        // Arrange - matchDay 8 = finalStage mit 3x, Joker 2x
        final match = CustomMatch(
          id: 'match_joker_final',
          homeTeamId: 'team_1',
          guestTeamId: 'team_2',
          matchDate: DateTime(2024, 7, 14),
          matchDay: 8,
          homeScore: 2,
          guestScore: 1,
        );

        final jokerTip = Tip(
          id: 'tip_joker_final',
          userId: 'user_1',
          matchId: 'match_joker_final',
          tipDate: DateTime.now(),
          tipHome: 2,
          tipGuest: 1,
          joker: true,
          points: 0,
        );

        when(() => mockTipRepository.getTipsForMatch('match_joker_final'))
            .thenAnswer((_) async => right([jokerTip]));
        // 6 (exakt) * 3 (Finale) * 2 (Joker) = 36
        when(() => mockTipRepository.updatePoints(
                tipId: 'tip_joker_final', points: 36))
            .thenAnswer((_) async => right(unit));
        when(() => mockUserRepository.getUserById('user_1')).thenAnswer(
            (_) async => right(AppUser(
                  id: 'user_1',
                  email: 'test@test.com',
                  score: 0,
                  rank: 0,
                  jokerSum: 0,
                  sixer: 0,
                  championId: 'TBD',
                  name: 'Test User',
                  admin: false,
                )));
        when(() => mockUserRepository.updateUser(any()))
            .thenAnswer((_) async => right(unit));
        when(() => mockTipRepository.getTipsByUserId('user_1'))
            .thenAnswer((_) async => right([jokerTip]));

        // Act
        final result = await useCase(match: match);

        // Assert
        expect(result, isA<Right<TipFailure, Unit>>());
        verify(() => mockTipRepository.updatePoints(
            tipId: 'tip_joker_final', points: 36)).called(1);
      });
    });

    group('Multiple Tips pro Match', () {
      test('sollte alle Tips eines Matches neu berechnen', () async {
        // Arrange
        final match = CustomMatch(
          id: 'match_multi',
          homeTeamId: 'team_1',
          guestTeamId: 'team_2',
          matchDate: DateTime(2024, 6, 14),
          matchDay: 1,
          homeScore: 2,
          guestScore: 1,
        );

        final tips = [
          Tip(
            id: 'tip_1',
            userId: 'user_1',
            matchId: 'match_multi',
            tipDate: DateTime.now(),
            tipHome: 2,
            tipGuest: 1,
            joker: false,
            points: 0,
          ),
          Tip(
            id: 'tip_2',
            userId: 'user_2',
            matchId: 'match_multi',
            tipDate: DateTime.now(),
            tipHome: 1,
            tipGuest: 0,
            joker: true,
            points: 0,
          ),
          Tip(
            id: 'tip_3',
            userId: 'user_3',
            matchId: 'match_multi',
            tipDate: DateTime.now(),
            tipHome: 0,
            tipGuest: 2,
            joker: false,
            points: 0,
          ),
        ];

        when(() => mockTipRepository.getTipsForMatch('match_multi'))
            .thenAnswer((_) async => right(tips));
        when(() => mockTipRepository.updatePoints(
                tipId: any(named: 'tipId'), points: any(named: 'points')))
            .thenAnswer((_) async => right(unit));
        when(() => mockUserRepository.getUserById(any())).thenAnswer(
            (_) async => right(AppUser(
                  id: 'user_1',
                  email: 'test@test.com',
                  score: 0,
                  rank: 0,
                  jokerSum: 0,
                  sixer: 0,
                  championId: 'TBD',
                  name: 'Test User',
                  admin: false,
                )));
        when(() => mockUserRepository.updateUser(any()))
            .thenAnswer((_) async => right(unit));
        when(() => mockTipRepository.getTipsByUserId(any()))
            .thenAnswer((_) async => right(tips));

        // Act
        final result = await useCase(match: match);

        // Assert
        expect(result, isA<Right<TipFailure, Unit>>());
        verify(() => mockTipRepository.getTipsForMatch('match_multi')).called(1);
      });
    });

    group('Punkt-Änderungserkennung', () {
      test('sollte nur updaten wenn Punkte sich ändern', () async {
        // Arrange
        final match = CustomMatch(
          id: 'match_no_change',
          homeTeamId: 'team_1',
          guestTeamId: 'team_2',
          matchDate: DateTime(2024, 6, 14),
          matchDay: 1,
          homeScore: 2,
          guestScore: 1,
        );

        // Tip hat schon die richtigen Punkte
        final tip = Tip(
          id: 'tip_no_change',
          userId: 'user_1',
          matchId: 'match_no_change',
          tipDate: DateTime.now(),
          tipHome: 2,
          tipGuest: 1,
          joker: false,
          points: 6, // Schon korrekt
        );

        when(() => mockTipRepository.getTipsForMatch('match_no_change'))
            .thenAnswer((_) async => right([tip]));
        when(() => mockUserRepository.getUserById('user_1')).thenAnswer(
            (_) async => right(AppUser(
                  id: 'user_1',
                  email: 'test@test.com',
                  score: 6,
                  rank: 1,
                  jokerSum: 0,
                  sixer: 0,
                  championId: 'TBD',
                  name: 'Test User',
                  admin: false,
                )));
        when(() => mockUserRepository.updateUser(any()))
            .thenAnswer((_) async => right(unit));
        when(() => mockTipRepository.getTipsByUserId('user_1'))
            .thenAnswer((_) async => right([tip]));

        // Act
        final result = await useCase(match: match);

        // Assert
        expect(result, isA<Right<TipFailure, Unit>>());
        // updatePoints sollte NICHT aufgerufen werden da Punkte gleich sind
        verifyNever(() => mockTipRepository.updatePoints(
            tipId: any(named: 'tipId'), points: any(named: 'points')));
      });

      test('sollte updaten wenn Punkte sich unterscheiden', () async {
        // Arrange
        final match = CustomMatch(
          id: 'match_change',
          homeTeamId: 'team_1',
          guestTeamId: 'team_2',
          matchDate: DateTime(2024, 6, 14),
          matchDay: 1,
          homeScore: 2,
          guestScore: 1,
        );

        // Tip hat falsche Punkte
        final tip = Tip(
          id: 'tip_change',
          userId: 'user_1',
          matchId: 'match_change',
          tipDate: DateTime.now(),
          tipHome: 2,
          tipGuest: 1,
          joker: false,
          points: 0, // Falsch, sollte 6 sein
        );

        when(() => mockTipRepository.getTipsForMatch('match_change'))
            .thenAnswer((_) async => right([tip]));
        when(() => mockTipRepository.updatePoints(
                tipId: 'tip_change', points: 6))
            .thenAnswer((_) async => right(unit));
        when(() => mockUserRepository.getUserById('user_1')).thenAnswer(
            (_) async => right(AppUser(
                  id: 'user_1',
                  email: 'test@test.com',
                  score: 0,
                  rank: 100,
                  jokerSum: 0,
                  sixer: 0,
                  championId: 'TBD',
                  name: 'Test User',
                  admin: false,
                )));
        when(() => mockUserRepository.updateUser(any()))
            .thenAnswer((_) async => right(unit));
        when(() => mockTipRepository.getTipsByUserId('user_1'))
            .thenAnswer((_) async => right([tip]));

        // Act
        final result = await useCase(match: match);

        // Assert
        expect(result, isA<Right<TipFailure, Unit>>());
        // updatePoints sollte aufgerufen werden da Punkte unterschiedlich sind
        verify(() => mockTipRepository.updatePoints(
            tipId: 'tip_change', points: 6)).called(1);
      });
    });
  });
}
