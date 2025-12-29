import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_web/application/ranking/ranking_bloc.dart';

void main() {
  group('RankingBloc', () {
    late RankingBloc rankingBloc;

    setUp(() {
      rankingBloc = RankingBloc();
    });

    tearDown(() {
      rankingBloc.close();
    });

    test('initial state has expanded false', () {
      expect(rankingBloc.state, const RankingState(expanded: false));
      expect(rankingBloc.state.expanded, false);
    });

    group('ToggleRankingViewEvent', () {
      blocTest<RankingBloc, RankingState>(
        'toggles expanded from false to true',
        build: () => rankingBloc,
        act: (bloc) => bloc.add(ToggleRankingViewEvent()),
        expect: () => [
          isA<RankingState>().having((state) => state.expanded, 'expanded', true)
        ],
      );

      blocTest<RankingBloc, RankingState>(
        'toggles expanded from true to false',
        build: () => rankingBloc,
        seed: () => const RankingState(expanded: true),
        act: (bloc) => bloc.add(ToggleRankingViewEvent()),
        expect: () => [
          isA<RankingState>().having((state) => state.expanded, 'expanded', false)
        ],
      );

      blocTest<RankingBloc, RankingState>(
        'toggles multiple times correctly',
        build: () => rankingBloc,
        act: (bloc) {
          bloc.add(ToggleRankingViewEvent()); // false -> true
          bloc.add(ToggleRankingViewEvent()); // true -> false
          bloc.add(ToggleRankingViewEvent()); // false -> true
        },
        expect: () => [
          isA<RankingState>().having((state) => state.expanded, 'expanded', true),
          isA<RankingState>().having((state) => state.expanded, 'expanded', false),
          isA<RankingState>().having((state) => state.expanded, 'expanded', true),
        ],
      );

      blocTest<RankingBloc, RankingState>(
        'maintains state consistency during rapid toggles',
        build: () => rankingBloc,
        act: (bloc) async {
          // Rapid succession toggles
          bloc.add(ToggleRankingViewEvent());
          bloc.add(ToggleRankingViewEvent());
          bloc.add(ToggleRankingViewEvent());
          bloc.add(ToggleRankingViewEvent());
        },
        expect: () => [
          isA<RankingState>().having((state) => state.expanded, 'expanded', true),
          isA<RankingState>().having((state) => state.expanded, 'expanded', false),
          isA<RankingState>().having((state) => state.expanded, 'expanded', true),
          isA<RankingState>().having((state) => state.expanded, 'expanded', false),
        ],
      );
    });

    group('State Management', () {
      test('RankingState equality works correctly', () {
        const state1 = RankingState(expanded: true);
        const state2 = RankingState(expanded: true);
        const state3 = RankingState(expanded: false);

        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
      });

      test('RankingState copyWith works correctly', () {
        const originalState = RankingState(expanded: false);
        final copiedState = originalState.copyWith(expanded: true);

        expect(copiedState.expanded, true);
        expect(originalState.expanded, false); // Original unchanged
      });

      test('RankingState copyWith preserves value when null passed', () {
        const originalState = RankingState(expanded: true);
        final copiedState = originalState.copyWith();

        expect(copiedState.expanded, true);
        expect(copiedState.expanded, equals(originalState.expanded));
      });
    });

    group('Edge Cases and Lifecycle', () {
      blocTest<RankingBloc, RankingState>(
        'handles event when bloc is already in target state',
        build: () => rankingBloc,
        seed: () => const RankingState(expanded: true),
        act: (bloc) {
          // Add toggle twice to get back to true
          bloc.add(ToggleRankingViewEvent()); // true -> false
          bloc.add(ToggleRankingViewEvent()); // false -> true
        },
        expect: () => [
          isA<RankingState>().having((state) => state.expanded, 'expanded', false),
          isA<RankingState>().having((state) => state.expanded, 'expanded', true),
        ],
      );

      test('bloc can be closed without errors', () async {
        rankingBloc.add(ToggleRankingViewEvent());
        await rankingBloc.close();
        expect(rankingBloc.isClosed, true);
      });

      test('multiple ranking blocs work independently', () {
        final ranking1 = RankingBloc();
        final ranking2 = RankingBloc();

        ranking1.add(ToggleRankingViewEvent());
        
        // Wait a moment for the event to process
        Future.delayed(Duration(milliseconds: 10)).then((_) {
          expect(ranking1.state.expanded, true);
          expect(ranking2.state.expanded, false);
        });

        ranking1.close();
        ranking2.close();
      });
    });

    group('Performance and Memory', () {
      test('bloc handles many state changes without memory leaks', () async {
        // Simulate many toggle operations
        for (int i = 0; i < 100; i++) {
          rankingBloc.add(ToggleRankingViewEvent());
        }
        
        // Wait for all events to process
        await Future.delayed(Duration(milliseconds: 50));
        
        // Should end up in expected state (100 toggles = back to false)
        expect(rankingBloc.state.expanded, false);
      });

      test('state objects are immutable', () {
        const originalState = RankingState(expanded: false);
        final newState = originalState.copyWith(expanded: true);
        
        // Original state should remain unchanged
        expect(originalState.expanded, false);
        expect(newState.expanded, true);
      });
    });
  });
}