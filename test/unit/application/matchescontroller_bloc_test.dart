import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/core/failures/match_failures.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

void main() {
  group('MatchesControllerBloc', () {
    late MatchesControllerBloc matchesControllerBloc;
    late MockMatchRepository mockMatchRepository;
    late StreamController<Either<MatchFailure, List<CustomMatch>>> streamController;

    setUp(() {
      mockMatchRepository = MockMatchRepository();
      matchesControllerBloc = MatchesControllerBloc(matchRepository: mockMatchRepository);
    });

    tearDown(() {
      matchesControllerBloc.close();
    });

    test('initial state is MatchesControllerInitial', () {
      expect(matchesControllerBloc.state, isA<MatchesControllerInitial>());
    });

    group('MatchesAllEvent', () {
      blocTest<MatchesControllerBloc, MatchesControllerState>(
        'emits [Loading] when matches are being watched',
        build: () {
          final streamController = StreamController<Either<MatchFailure, List<CustomMatch>>>();
          when(() => mockMatchRepository.watchAllMatches())
              .thenAnswer((_) => streamController.stream);
          return matchesControllerBloc;
        },
        act: (bloc) => bloc.add(MatchesAllEvent()),
        expect: () => [isA<MatchesControllerLoading>()],
        verify: (_) {
          verify(() => mockMatchRepository.watchAllMatches()).called(1);
        },
      );

      blocTest<MatchesControllerBloc, MatchesControllerState>(
        'emits [Loading, Loaded] when matches are successfully loaded',
        build: () {
          final streamController = StreamController<Either<MatchFailure, List<CustomMatch>>>();
          when(() => mockMatchRepository.watchAllMatches())
              .thenAnswer((_) => streamController.stream);
          return matchesControllerBloc;
        },
        act: (bloc) async {
          final streamController = StreamController<Either<MatchFailure, List<CustomMatch>>>();
          when(() => mockMatchRepository.watchAllMatches())
              .thenAnswer((_) => streamController.stream);
          
          bloc.add(MatchesAllEvent());
          
          await Future.delayed(Duration(milliseconds: 10));
          streamController.add(right([
            CustomMatch(
              id: 'match_1',
              homeTeamId: 'team_home_1',
              guestTeamId: 'team_away_1',
              matchDate: DateTime.now(),
              matchDay: 1,
              homeScore: null,
              guestScore: null,
            ),
            CustomMatch(
              id: 'match_2',
              homeTeamId: 'team_home_2',
              guestTeamId: 'team_away_2',
              matchDate: DateTime.now().add(Duration(days: 1)),
              matchDay: 1,
              homeScore: 2,
              guestScore: 1,
            ),
          ]));
          
          await streamController.close();
        },
        expect: () => [
          isA<MatchesControllerLoading>(),
          isA<MatchesControllerLoaded>()
              .having((state) => state.matches.length, 'matches length', 2),
        ],
        verify: (_) {
          verify(() => mockMatchRepository.watchAllMatches()).called(1);
        },
      );

      blocTest<MatchesControllerBloc, MatchesControllerState>(
        'emits [Loading, Failure] when matches loading fails',
        build: () {
          streamController = StreamController<Either<MatchFailure, List<CustomMatch>>>();
          when(() => mockMatchRepository.watchAllMatches())
              .thenAnswer((_) => streamController.stream);
          return matchesControllerBloc;
        },
        act: (bloc) {
          bloc.add(MatchesAllEvent());
          streamController.add(left(UnexpectedFailure()));
        },
        expect: () => [
          isA<MatchesControllerLoading>(),
          isA<MatchesControllerFailure>()
              .having((state) => state.matchFailure, 'failure type', isA<UnexpectedFailure>()),
        ],
        verify: (_) {
          verify(() => mockMatchRepository.watchAllMatches()).called(1);
        },
      );

      blocTest<MatchesControllerBloc, MatchesControllerState>(
        'handles permission failure correctly',
        build: () {
          // Define streamController outside so it can be accessed in act
          streamController = StreamController<Either<MatchFailure, List<CustomMatch>>>();
          when(() => mockMatchRepository.watchAllMatches())
              .thenAnswer((_) => streamController.stream);
          return matchesControllerBloc;
        },
        act: (bloc) {
          bloc.add(MatchesAllEvent());
          streamController.add(left(InsufficientPermisssons()));
        },
        expect: () => [
          isA<MatchesControllerLoading>(),
          isA<MatchesControllerFailure>()
              .having((state) => state.matchFailure, 'failure type', isA<InsufficientPermisssons>()),
        ],
        verify: (_) {
          verify(() => mockMatchRepository.watchAllMatches()).called(1);
        },
      );

      blocTest<MatchesControllerBloc, MatchesControllerState>(
        'handles empty matches list correctly',
        build: () {
          streamController = StreamController<Either<MatchFailure, List<CustomMatch>>>();
          when(() => mockMatchRepository.watchAllMatches())
              .thenAnswer((_) => streamController.stream);
          return matchesControllerBloc;
        },
        act: (bloc) async {
          bloc.add(MatchesAllEvent());
          await Future.delayed(Duration(milliseconds: 10));
          streamController.add(right([]));
          await streamController.close();
        },
        expect: () => [
          isA<MatchesControllerLoading>(),
          isA<MatchesControllerLoaded>()
              .having((state) => state.matches, 'matches', isEmpty),
        ],
      );
    });

    group('MatchUpdatedEvent', () {
      blocTest<MatchesControllerBloc, MatchesControllerState>(
        'emits [Loaded] when match update is successful',
        build: () => matchesControllerBloc,
        act: (bloc) {
          final matches = [
            CustomMatch(
              id: 'updated_match',
              homeTeamId: 'team_home_updated',
              guestTeamId: 'team_away_updated',
              matchDate: DateTime.now(),
              matchDay: 2,
              homeScore: 3,
              guestScore: 1,
            ),
          ];
          bloc.add(MatchUpdatedEvent(failureOrMatches: right(matches)));
        },
        expect: () => [
          isA<MatchesControllerLoaded>()
              .having((state) => state.matches.length, 'matches length', 1)
              .having((state) => state.matches.first.id, 'match id', 'updated_match')
              .having((state) => state.matches.first.homeScore, 'home score', 3)
              .having((state) => state.matches.first.matchDay, 'match day', 2),
        ],
      );

      blocTest<MatchesControllerBloc, MatchesControllerState>(
        'emits [Failure] when match update fails',
        build: () => matchesControllerBloc,
        act: (bloc) {
          bloc.add(MatchUpdatedEvent(failureOrMatches: left(NotFoundFailure())));
        },
        expect: () => [
          isA<MatchesControllerFailure>()
              .having((state) => state.matchFailure, 'failure type', isA<NotFoundFailure>()),
        ],
      );
    });

    group('Match Data Validation', () {
      blocTest<MatchesControllerBloc, MatchesControllerState>(
        'handles matches with different match days correctly',
        build: () {
          streamController = StreamController<Either<MatchFailure, List<CustomMatch>>>();
          when(() => mockMatchRepository.watchAllMatches())
              .thenAnswer((_) => streamController.stream);
          return matchesControllerBloc;
        },
        act: (bloc) async {
          bloc.add(MatchesAllEvent());
          await Future.delayed(Duration(milliseconds: 10));
          streamController.add(right([
            // Group stage match
            CustomMatch(
              id: 'group_match',
              homeTeamId: 'team_1',
              guestTeamId: 'team_2',
              matchDate: DateTime.now(),
              matchDay: 1,
              homeScore: null,
              guestScore: null,
            ),
            // Final match
            CustomMatch(
              id: 'final_match',
              homeTeamId: 'team_3',
              guestTeamId: 'team_4',
              matchDate: DateTime.now(),
              matchDay: 8,
              homeScore: 1,
              guestScore: 3,
            ),
          ]));
          await streamController.close();
        },
        expect: () => [
          isA<MatchesControllerLoading>(),
          isA<MatchesControllerLoaded>()
              .having((state) => state.matches.length, 'total matches', 2)
              .having((state) => state.matches.where((m) => m.homeScore != null).length, 'matches with results', 1)
              .having((state) => state.matches.where((m) => m.matchDay == 8).length, 'final matches', 1),
        ],
      );

      blocTest<MatchesControllerBloc, MatchesControllerState>(
        'correctly handles match scores and null values',
        build: () {
          streamController = StreamController<Either<MatchFailure, List<CustomMatch>>>();
          when(() => mockMatchRepository.watchAllMatches())
              .thenAnswer((_) => streamController.stream);
          return matchesControllerBloc;
        },
        act: (bloc) async {
          bloc.add(MatchesAllEvent());
          await Future.delayed(Duration(milliseconds: 10));
          streamController.add(right([
            CustomMatch(
              id: 'scored_match',
              homeTeamId: 'team_home',
              guestTeamId: 'team_guest',
              matchDate: DateTime.now(),
              matchDay: 2,
              homeScore: 0,
              guestScore: 5,
            ),
          ]));
          await streamController.close();
        },
        expect: () => [
          isA<MatchesControllerLoading>(),
          isA<MatchesControllerLoaded>()
              .having((state) => state.matches.first.homeScore, 'home score', 0)
              .having((state) => state.matches.first.guestScore, 'guest score', 5),
        ],
      );
    });

    test('bloc properly closes', () async {
      final streamController = StreamController<Either<MatchFailure, List<CustomMatch>>>();
      when(() => mockMatchRepository.watchAllMatches())
          .thenAnswer((_) => streamController.stream);
          
      matchesControllerBloc.add(MatchesAllEvent());
      await matchesControllerBloc.close();
      
      expect(matchesControllerBloc.isClosed, true);
      await streamController.close();
    });
  });
}