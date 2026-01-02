import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_card_match_info.dart';

void main() {
  group('TipCardMatchInfo Widget Tests', () {
    late CustomMatch testMatch;
    late Team homeTeam;
    late Team guestTeam;

    setUp(() {
      homeTeam = Team(
        id: 'team1',
        name: 'Deutschland',
        flagCode: 'DE',
        winPoints: 0,
        champion: false,
      );

      guestTeam = Team(
        id: 'team2',
        name: 'Brasilien',
        flagCode: 'BR',
        winPoints: 0,
        champion: false,
      );

      testMatch = CustomMatch(
        id: 'match1',
        matchDay: 1,
        homeTeamId: 'team1',
        guestTeamId: 'team2',
        matchDate: DateTime(2025, 7, 1, 20, 0),
        homeScore: null,
        guestScore: null,
      );
    });

    testWidgets('should display team names correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TipCardMatchInfo(
              match: testMatch,
              homeTeam: homeTeam,
              guestTeam: guestTeam,
              hasResult: false,
            ),
          ),
        ),
      );

      expect(find.text('Deutschland'), findsOneWidget);
      expect(find.text('Brasilien'), findsOneWidget);
    });

    testWidgets('should display flags correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TipCardMatchInfo(
              match: testMatch,
              homeTeam: homeTeam,
              guestTeam: guestTeam,
              hasResult: false,
            ),
          ),
        ),
      );

      expect(find.byType(ClipOval), findsAtLeastNWidgets(2));
    });

    testWidgets('should display score when match has result', (WidgetTester tester) async {
      final matchWithResult = CustomMatch(
        id: 'match1',
        matchDay: 1,
        homeTeamId: 'team1',
        guestTeamId: 'team2',
        matchDate: DateTime(2025, 7, 1, 20, 0),
        homeScore: 2,
        guestScore: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TipCardMatchInfo(
              match: matchWithResult,
              homeTeam: homeTeam,
              guestTeam: guestTeam,
              hasResult: true,
            ),
          ),
        ),
      );

      expect(find.text('2 : 1'), findsOneWidget);
    });

    testWidgets('should handle very long team names with ellipsis', (WidgetTester tester) async {
      final longNameTeam = Team(
        id: 'team3',
        name: 'Very Long Team Name That Should Be Truncated',
        flagCode: 'US',
        winPoints: 0,
        champion: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Constrain width to force overflow
              child: TipCardMatchInfo(
                match: testMatch,
                homeTeam: longNameTeam,
                guestTeam: guestTeam,
                hasResult: false,
              ),
            ),
          ),
        ),
      );

      final textFinder = find.text('Very Long Team Name That Should Be Truncated');
      expect(textFinder, findsOneWidget);
      
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 1);
    });

    testWidgets('should apply proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TipCardMatchInfo(
              match: testMatch,
              homeTeam: homeTeam,
              guestTeam: guestTeam,
              hasResult: false,
            ),
          ),
        ),
      );

      final homeTeamText = find.text('Deutschland');
      final homeTeamWidget = tester.widget<Text>(homeTeamText);
      expect(homeTeamWidget.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('should be rendered without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TipCardMatchInfo(
              match: testMatch,
              homeTeam: homeTeam,
              guestTeam: guestTeam,
              hasResult: false,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}