import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/admin_page/widget/team_item.dart';

void main() {
  group('TeamItem Widget Tests', () {
    late Team testTeam;

    setUp(() {
      testTeam = Team(
        id: 'team1',
        name: 'Deutschland',
        flagCode: 'DE',
        winPoints: 9,
        champion: false,
      );
    });

    testWidgets('should display team name correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamItem(team: testTeam),
          ),
        ),
      );

      expect(find.text('Deutschland'), findsOneWidget);
    });

    testWidgets('should display flag widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamItem(team: testTeam),
          ),
        ),
      );

      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('should display win points', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamItem(team: testTeam),
          ),
        ),
      );

      expect(find.textContaining('9'), findsOneWidget);
    });

    testWidgets('should apply proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamItem(team: testTeam),
          ),
        ),
      );

      expect(find.byType(Container), findsAtLeastNWidgets(1));
      expect(find.byType(Row), findsAtLeastNWidgets(1));
      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle champion team correctly', (WidgetTester tester) async {
      final championTeam = Team(
        id: 'team2',
        name: 'Brasilien',
        flagCode: 'BR',
        winPoints: 15,
        champion: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamItem(team: championTeam),
          ),
        ),
      );

      expect(find.text('Brasilien'), findsOneWidget);
      expect(find.textContaining('15'), findsOneWidget);
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamItem(team: testTeam),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('should display team with different flag codes', (WidgetTester tester) async {
      final teams = [
        Team(id: '1', name: 'Spanien', flagCode: 'ES', winPoints: 6, champion: false),
        Team(id: '2', name: 'Italien', flagCode: 'IT', winPoints: 12, champion: false),
        Team(id: '3', name: 'Frankreich', flagCode: 'FR', winPoints: 3, champion: false),
      ];

      for (final team in teams) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TeamItem(team: team),
            ),
          ),
        );

        expect(find.text(team.name), findsOneWidget);
        expect(find.textContaining(team.winPoints.toString()), findsOneWidget);
      }
    });

    testWidgets('should handle zero win points', (WidgetTester tester) async {
      final zeroPointsTeam = Team(
        id: 'team3',
        name: 'Niederlande',
        flagCode: 'NL',
        winPoints: 0,
        champion: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamItem(team: zeroPointsTeam),
          ),
        ),
      );

      expect(find.text('Niederlande'), findsOneWidget);
      expect(find.textContaining('0'), findsOneWidget);
    });
  });
}