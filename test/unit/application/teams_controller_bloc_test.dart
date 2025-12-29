import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/domain/repositories/team_repository.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/core/failures/team_failures.dart';

class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('TeamsControllerBloc', () {
    late TeamsControllerBloc teamsControllerBloc;
    late MockTeamRepository mockTeamRepository;
    late StreamController<Either<TeamFailure, List<Team>>> streamController;

    setUp(() {
      mockTeamRepository = MockTeamRepository();
      teamsControllerBloc = TeamsControllerBloc(teamRepository: mockTeamRepository);
    });

    tearDown(() {
      teamsControllerBloc.close();
    });

    test('initial state is TeamsControllerInitial', () {
      expect(teamsControllerBloc.state, isA<TeamsControllerInitial>());
    });

    group('TeamsControllerAllEvent', () {
      blocTest<TeamsControllerBloc, TeamsControllerState>(
        'emits [Loading] when teams are being watched',
        build: () {
          streamController = StreamController<Either<TeamFailure, List<Team>>>();
          when(() => mockTeamRepository.watchAllTeams())
              .thenAnswer((_) => streamController.stream);
          return teamsControllerBloc;
        },
        act: (bloc) => bloc.add(TeamsControllerAllEvent()),
        expect: () => [isA<TeamsControllerLoading>()],
        verify: (_) {
          verify(() => mockTeamRepository.watchAllTeams()).called(1);
        },
      );

      blocTest<TeamsControllerBloc, TeamsControllerState>(
        'emits [Loading, Loaded] when teams are successfully loaded',
        build: () {
          streamController = StreamController<Either<TeamFailure, List<Team>>>();
          when(() => mockTeamRepository.watchAllTeams())
              .thenAnswer((_) => streamController.stream);
          return teamsControllerBloc;
        },
        act: (bloc) async {
          bloc.add(TeamsControllerAllEvent());
          await Future.delayed(Duration(milliseconds: 10));
          
          final teams = [
            Team(id: 'team_1', name: 'Germany', flagCode: 'de', winPoints: 0, champion: false),
            Team(id: 'team_2', name: 'Spain', flagCode: 'es', winPoints: 0, champion: false),
            Team(id: 'team_3', name: 'France', flagCode: 'fr', winPoints: 0, champion: false),
            Team(id: 'team_4', name: 'Italy', flagCode: 'it', winPoints: 0, champion: false),
          ];
          
          streamController.add(right(teams));
          await streamController.close();
        },
        expect: () => [
          isA<TeamsControllerLoading>(),
          isA<TeamsControllerLoaded>()
              .having((state) => state.teams.length, 'teams count', 4)
              .having((state) => state.teams.first.name, 'first team name', 'Germany')
              .having((state) => state.teams.any((team) => team.flagCode == 'es'), 'has Spain', true),
        ],
        verify: (_) {
          verify(() => mockTeamRepository.watchAllTeams()).called(1);
        },
      );

      blocTest<TeamsControllerBloc, TeamsControllerState>(
        'emits [Loading, Failure] when teams loading fails',
        build: () {
          streamController = StreamController<Either<TeamFailure, List<Team>>>();
          when(() => mockTeamRepository.watchAllTeams())
              .thenAnswer((_) => streamController.stream);
          return teamsControllerBloc;
        },
        act: (bloc) async {
          bloc.add(TeamsControllerAllEvent());
          await Future.delayed(Duration(milliseconds: 10));
          streamController.add(left(UnexpectedFailure()));
          await streamController.close();
        },
        expect: () => [
          isA<TeamsControllerLoading>(),
          isA<TeamsControllerFailureState>()
              .having((state) => state.teamFailure, 'failure type', isA<UnexpectedFailure>()),
        ],
        verify: (_) {
          verify(() => mockTeamRepository.watchAllTeams()).called(1);
        },
      );

      blocTest<TeamsControllerBloc, TeamsControllerState>(
        'handles empty teams list correctly',
        build: () {
          streamController = StreamController<Either<TeamFailure, List<Team>>>();
          when(() => mockTeamRepository.watchAllTeams())
              .thenAnswer((_) => streamController.stream);
          return teamsControllerBloc;
        },
        act: (bloc) async {
          bloc.add(TeamsControllerAllEvent());
          await Future.delayed(Duration(milliseconds: 10));
          streamController.add(right(<Team>[]));
          await streamController.close();
        },
        expect: () => [
          isA<TeamsControllerLoading>(),
          isA<TeamsControllerLoaded>()
              .having((state) => state.teams, 'teams list', isEmpty),
        ],
      );

      blocTest<TeamsControllerBloc, TeamsControllerState>(
        'handles permission failure correctly',
        build: () {
          streamController = StreamController<Either<TeamFailure, List<Team>>>();
          when(() => mockTeamRepository.watchAllTeams())
              .thenAnswer((_) => streamController.stream);
          return teamsControllerBloc;
        },
        act: (bloc) async {
          bloc.add(TeamsControllerAllEvent());
          await Future.delayed(Duration(milliseconds: 10));
          streamController.add(left(InsufficientPermisssons()));
          await streamController.close();
        },
        expect: () => [
          isA<TeamsControllerLoading>(),
          isA<TeamsControllerFailureState>()
              .having((state) => state.teamFailure, 'failure type', isA<InsufficientPermisssons>()),
        ],
      );
    });

    group('TeamsControllerUpdatedEvent', () {
      blocTest<TeamsControllerBloc, TeamsControllerState>(
        'emits [Loaded] when team update is successful',
        build: () => teamsControllerBloc,
        act: (bloc) {
          final teams = [
            Team(id: 'updated_team', name: 'Netherlands', flagCode: 'nl', winPoints: 0, champion: false),
            Team(id: 'updated_team_2', name: 'Portugal', flagCode: 'pt', winPoints: 0, champion: false),
          ];
          bloc.add(TeamsControllerUpdatedEvent(failureOrTeams: right(teams)));
        },
        expect: () => [
          isA<TeamsControllerLoaded>()
              .having((state) => state.teams.length, 'teams count', 2)
              .having((state) => state.teams.first.name, 'first team name', 'Netherlands')
              .having((state) => state.teams.last.flagCode, 'last team flag', 'pt'),
        ],
      );

      blocTest<TeamsControllerBloc, TeamsControllerState>(
        'emits [Failure] when team update fails',
        build: () => teamsControllerBloc,
        act: (bloc) {
          bloc.add(TeamsControllerUpdatedEvent(failureOrTeams: left(NotFoundFailure())));
        },
        expect: () => [
          isA<TeamsControllerFailureState>()
              .having((state) => state.teamFailure, 'failure type', isA<NotFoundFailure>()),
        ],
      );
    });

    group('Team Data Validation', () {
      blocTest<TeamsControllerBloc, TeamsControllerState>(
        'handles teams with various flag codes correctly',
        build: () {
          streamController = StreamController<Either<TeamFailure, List<Team>>>();
          when(() => mockTeamRepository.watchAllTeams())
              .thenAnswer((_) => streamController.stream);
          return teamsControllerBloc;
        },
        act: (bloc) async {
          bloc.add(TeamsControllerAllEvent());
          await Future.delayed(Duration(milliseconds: 10));
          
          final teams = [
            Team(id: 'eu_team_1', name: 'Germany', flagCode: 'de', winPoints: 0, champion: false),
            Team(id: 'eu_team_2', name: 'United Kingdom', flagCode: 'gb', winPoints: 0, champion: false),
            Team(id: 'sa_team_1', name: 'Brazil', flagCode: 'br', winPoints: 0, champion: false),
            Team(id: 'na_team_1', name: 'United States', flagCode: 'us', winPoints: 0, champion: false),
          ];
          
          streamController.add(right(teams));
          await streamController.close();
        },
        expect: () => [
          isA<TeamsControllerLoading>(),
          isA<TeamsControllerLoaded>()
              .having((state) => state.teams.length, 'total teams', 4)
              .having((state) => state.teams.where((team) => ['de', 'gb'].contains(team.flagCode)).length, 'european teams', 2)
              .having((state) => state.teams.any((team) => team.name.contains('United')), 'has United in name', true),
        ],
      );

      blocTest<TeamsControllerBloc, TeamsControllerState>(
        'correctly handles long team names and special flag codes',
        build: () {
          streamController = StreamController<Either<TeamFailure, List<Team>>>();
          when(() => mockTeamRepository.watchAllTeams())
              .thenAnswer((_) => streamController.stream);
          return teamsControllerBloc;
        },
        act: (bloc) async {
          bloc.add(TeamsControllerAllEvent());
          await Future.delayed(Duration(milliseconds: 10));
          
          final teams = [
            Team(id: 'long_name_team', name: 'Bosnia and Herzegovina', flagCode: 'ba', winPoints: 0, champion: false),
            Team(id: 'short_team', name: 'UAE', flagCode: 'ae', winPoints: 0, champion: false),
          ];
          
          streamController.add(right(teams));
          await streamController.close();
        },
        expect: () => [
          isA<TeamsControllerLoading>(),
          isA<TeamsControllerLoaded>()
              .having((state) => state.teams.any((team) => team.name.length > 15), 'has long name', true)
              .having((state) => state.teams.any((team) => team.name.length <= 3), 'has short name', true),
        ],
      );
    });

    test('bloc properly closes and cancels subscriptions', () async {
      streamController = StreamController<Either<TeamFailure, List<Team>>>();
      when(() => mockTeamRepository.watchAllTeams())
          .thenAnswer((_) => streamController.stream);
          
      teamsControllerBloc.add(TeamsControllerAllEvent());
      await teamsControllerBloc.close();
      
      expect(teamsControllerBloc.isClosed, true);
      await streamController.close();
    });
  });
}