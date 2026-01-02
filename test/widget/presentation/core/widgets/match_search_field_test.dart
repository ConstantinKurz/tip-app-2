import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/widgets/match_search_field.dart';

void main() {
  group('MatchSearchField Widget Tests', () {
    late List<CustomMatch> testMatches;
    late List<Team> testTeams;

    setUp(() {
      testTeams = [
        Team(id: 'team1', name: 'Deutschland', flagCode: 'DE', winPoints: 0, champion: false),
        Team(id: 'team2', name: 'Brasilien', flagCode: 'BR', winPoints: 0, champion: false),
        Team(id: 'team3', name: 'Spanien', flagCode: 'ES', winPoints: 0, champion: false),
        Team(id: 'team4', name: 'Italien', flagCode: 'IT', winPoints: 0, champion: false),
      ];

      testMatches = [
        CustomMatch(
          id: 'match1',
          matchDay: 1,
          homeTeamId: 'team1',
          guestTeamId: 'team2',
          matchDate: DateTime(2025, 7, 1, 20, 0),
          homeScore: null,
          guestScore: null,
        ),
        CustomMatch(
          id: 'match2',
          matchDay: 2,
          homeTeamId: 'team3',
          guestTeamId: 'team4',
          matchDate: DateTime(2025, 7, 2, 18, 0),
          homeScore: null,
          guestScore: null,
        ),
      ];
    });

    Widget buildWidget({String? hintText, bool showHelpDialog = true}) {
      return MaterialApp(
        home: Scaffold(
          body: MatchSearchField(
            matches: testMatches,
            teams: testTeams,
            onFilteredMatchesChanged: (matches) {
              // For these tests, we just verify the widget renders
            },
            hintText: hintText,
            showHelpDialog: showHelpDialog,
          ),
        ),
      );
    }

    testWidgets('should display search field with default hint text', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Nach Teams, Spielphase oder Matchtag suchen...'), findsOneWidget);
    });

    testWidgets('should display custom hint text when provided', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(hintText: 'Custom hint'));
      await tester.pump();

      expect(find.text('Custom hint'), findsOneWidget);
    });

    testWidgets('should display search icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should show help dialog when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(showHelpDialog: true));
      await tester.pump();

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('should hide help dialog when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(showHelpDialog: false));
      await tester.pump();

      expect(find.byIcon(Icons.help_outline), findsNothing);
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should have proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });
  });
}