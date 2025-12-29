import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';

class MockTipRepository extends Mock implements TipRepository {}

void main() {
  group('TipControllerBloc', () {
    late TipControllerBloc tipControllerBloc;
    late MockTipRepository mockTipRepository;
    late StreamController<Either<TipFailure, Map<String, List<Tip>>>> streamController;

    setUp(() {
      mockTipRepository = MockTipRepository();
      tipControllerBloc = TipControllerBloc(tipRepository: mockTipRepository);
    });

    tearDown(() {
      tipControllerBloc.close();
    });

    test('initial state is TipControllerInitial', () {
      expect(tipControllerBloc.state, isA<TipControllerInitial>());
    });

    group('TipAllEvent', () {
      blocTest<TipControllerBloc, TipControllerState>(
        'emits [Loading] when tips are being watched',
        build: () {
          streamController = StreamController<Either<TipFailure, Map<String, List<Tip>>>>();
          when(() => mockTipRepository.watchAll())
              .thenAnswer((_) => streamController.stream);
          return tipControllerBloc;
        },
        act: (bloc) => bloc.add(TipAllEvent()),
        expect: () => [isA<TipControllerLoading>()],
        verify: (_) {
          verify(() => mockTipRepository.watchAll()).called(1);
        },
      );

      blocTest<TipControllerBloc, TipControllerState>(
        'emits [Loading, Loaded] when tips are successfully loaded',
        build: () {
          streamController = StreamController<Either<TipFailure, Map<String, List<Tip>>>>();
          when(() => mockTipRepository.watchAll())
              .thenAnswer((_) => streamController.stream);
          return tipControllerBloc;
        },
        act: (bloc) async {
          bloc.add(TipAllEvent());
          await Future.delayed(Duration(milliseconds: 10));
          
          final Map<String, List<Tip>> tipMap = {
            'user_1': [
              Tip(
                id: 'tip_1',
                userId: 'user_1',
                matchId: 'match_1',
                tipDate: DateTime.now(),
                tipHome: 2,
                tipGuest: 1,
                joker: false,
                points: null,
              ),
              Tip(
                id: 'tip_2',
                userId: 'user_1',
                matchId: 'match_2',
                tipDate: DateTime.now(),
                tipHome: 1,
                tipGuest: 3,
                joker: true,
                points: null,
              ),
            ],
            'user_2': [
              Tip(
                id: 'tip_3',
                userId: 'user_2',
                matchId: 'match_1',
                tipDate: DateTime.now(),
                tipHome: 3,
                tipGuest: 0,
                joker: false,
                points: null,
              ),
            ],
          };
          
          streamController.add(right(tipMap));
          await streamController.close();
        },
        expect: () => [
          isA<TipControllerLoading>(),
          isA<TipControllerLoaded>()
              .having((state) => state.tips.length, 'number of users', 2)
              .having((state) => state.tips['user_1']?.length, 'user_1 tips count', 2)
              .having((state) => state.tips['user_2']?.length, 'user_2 tips count', 1)
              .having((state) => state.tips['user_1']?.any((tip) => tip.joker), 'has joker tip', true),
        ],
        verify: (_) {
          verify(() => mockTipRepository.watchAll()).called(1);
        },
      );

      blocTest<TipControllerBloc, TipControllerState>(
        'emits [Loading, Failure] when tips loading fails',
        build: () {
          streamController = StreamController<Either<TipFailure, Map<String, List<Tip>>>>();
          when(() => mockTipRepository.watchAll())
              .thenAnswer((_) => streamController.stream);
          return tipControllerBloc;
        },
        act: (bloc) async {
          bloc.add(TipAllEvent());
          await Future.delayed(Duration(milliseconds: 10));
          streamController.add(left(UnexpectedFailure()));
          await streamController.close();
        },
        expect: () => [
          isA<TipControllerLoading>(),
          isA<TipControllerFailure>()
              .having((state) => state.tipFailure, 'failure type', isA<UnexpectedFailure>()),
        ],
        verify: (_) {
          verify(() => mockTipRepository.watchAll()).called(1);
        },
      );

      blocTest<TipControllerBloc, TipControllerState>(
        'handles empty tips map correctly',
        build: () {
          streamController = StreamController<Either<TipFailure, Map<String, List<Tip>>>>();
          when(() => mockTipRepository.watchAll())
              .thenAnswer((_) => streamController.stream);
          return tipControllerBloc;
        },
        act: (bloc) async {
          bloc.add(TipAllEvent());
          await Future.delayed(Duration(milliseconds: 10));
          streamController.add(right(<String, List<Tip>>{}));
          await streamController.close();
        },
        expect: () => [
          isA<TipControllerLoading>(),
          isA<TipControllerLoaded>()
              .having((state) => state.tips, 'tips map', isEmpty),
        ],
      );

      blocTest<TipControllerBloc, TipControllerState>(
        'handles permission failure correctly',
        build: () {
          streamController = StreamController<Either<TipFailure, Map<String, List<Tip>>>>();
          when(() => mockTipRepository.watchAll())
              .thenAnswer((_) => streamController.stream);
          return tipControllerBloc;
        },
        act: (bloc) async {
          bloc.add(TipAllEvent());
          await Future.delayed(Duration(milliseconds: 10));
          streamController.add(left(InsufficientPermisssons()));
          await streamController.close();
        },
        expect: () => [
          isA<TipControllerLoading>(),
          isA<TipControllerFailure>()
              .having((state) => state.tipFailure, 'failure type', isA<InsufficientPermisssons>()),
        ],
      );
    });

    group('UserTipEvent', () {
      blocTest<TipControllerBloc, TipControllerState>(
        'emits [Loading] when user tips are requested',
        build: () => tipControllerBloc,
        act: (bloc) => bloc.add(UserTipEvent()),
        expect: () => [isA<TipControllerLoading>()],
      );
    });

    group('TipUpdatedEvent', () {
      blocTest<TipControllerBloc, TipControllerState>(
        'emits [Loaded] when tip update is successful',
        build: () => tipControllerBloc,
        act: (bloc) {
          final Map<String, List<Tip>> tipMap = {
            'user_updated': [
              Tip(
                id: 'updated_tip',
                userId: 'user_updated',
                matchId: 'match_updated',
                tipDate: DateTime.now(),
                tipHome: 4,
                tipGuest: 2,
                joker: true,
                points: null,
              ),
            ],
          };
          bloc.add(TipUpdatedEvent(failureOrTip: right(tipMap)));
        },
        expect: () => [
          isA<TipControllerLoaded>()
              .having((state) => state.tips.length, 'users count', 1)
              .having((state) => state.tips['user_updated']?.first.id, 'tip id', 'updated_tip')
              .having((state) => state.tips['user_updated']?.first.tipHome, 'home score', 4)
              .having((state) => state.tips['user_updated']?.first.joker, 'is joker', true),
        ],
      );

      blocTest<TipControllerBloc, TipControllerState>(
        'emits [Failure] when tip update fails',
        build: () => tipControllerBloc,
        act: (bloc) {
          bloc.add(TipUpdatedEvent(failureOrTip: left(NotFoundFailure())));
        },
        expect: () => [
          isA<TipControllerFailure>()
              .having((state) => state.tipFailure, 'failure type', isA<NotFoundFailure>()),
        ],
      );
    });

    test('bloc properly closes and cancels subscriptions', () async {
      streamController = StreamController<Either<TipFailure, Map<String, List<Tip>>>>();
      when(() => mockTipRepository.watchAll())
          .thenAnswer((_) => streamController.stream);
          
      tipControllerBloc.add(TipAllEvent());
      await tipControllerBloc.close();
      
      expect(tipControllerBloc.isClosed, true);
      await streamController.close();
    });
  });
}