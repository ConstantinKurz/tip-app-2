import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/presentation/tip_card/tip_card.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockTipFormBloc extends Mock implements TipFormBloc {}

void main() {
  late MockTipFormBloc mockTipFormBloc;

  setUp(() {
    mockTipFormBloc = MockTipFormBloc();
    GetIt.I.registerSingleton<TipFormBloc>(mockTipFormBloc);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  group('TipCard Widget', () {
    testWidgets('renders TipCard with match and teams', (tester) async {
      final match = CustomMatch(
        id: 'match1',
        homeTeamId: 'team1',
        guestTeamId: 'team2',
        matchDate: DateTime.now(),
        matchDay: 1,
        homeScore: 2,
        guestScore: 1,
      );
      final homeTeam = Team(id: 'team1', name: 'Deutschland', flagCode: 'DE', winPoints: 0, champion: false);
      final guestTeam = Team(id: 'team2', name: 'Brasilien', flagCode: 'BR', winPoints: 0, champion: false);
      final tip = Tip(id: 'tip1', userId: 'user1', matchId: 'match1', tipDate: DateTime.now(), tipHome: 2, tipGuest: 1, joker: false, points: 3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TipCard(
              userId: 'user1',
              match: match,
              homeTeam: homeTeam,
              guestTeam: guestTeam,
              tip: tip,
            ),
          ),
        ),
      );
      expect(find.byType(TipCard), findsOneWidget);
      expect(find.text('Deutschland'), findsOneWidget);
      expect(find.text('Brasilien'), findsOneWidget);
    });
  });
}
