import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';

void main() {
  group('FancyIconButton Widget Tests', () {
    testWidgets('should display icon correctly', (WidgetTester tester) async {
      bool callbackTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FancyIconButton(
              icon: Icons.favorite,
              callback: () {
                callbackTriggered = true;
              },
              backgroundColor: Colors.white,
              hoverColor: Colors.red,
              borderColor: Colors.red,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(callbackTriggered, false);
    });

    testWidgets('should trigger callback when tapped', (WidgetTester tester) async {
      bool callbackTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FancyIconButton(
              icon: Icons.star,
              callback: () {
                callbackTriggered = true;
              },
              backgroundColor: Colors.yellow,
              hoverColor: Colors.orange,
              borderColor: Colors.orange,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FancyIconButton));
      await tester.pump();

      expect(callbackTriggered, true);
    });

    testWidgets('should apply correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FancyIconButton(
              icon: Icons.settings,
              callback: () {},
              backgroundColor: Colors.blue,
              hoverColor: Colors.lightBlue,
              borderColor: Colors.blue,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<FancyIconButton>(find.byType(FancyIconButton));
      expect(iconButton.icon, Icons.settings);
      expect(iconButton.backgroundColor, Colors.blue);
      expect(iconButton.hoverColor, Colors.lightBlue);
      expect(iconButton.borderColor, Colors.blue);
    });

    testWidgets('should have AnimatedContainer with correct properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FancyIconButton(
              icon: Icons.add,
              callback: () {},
              backgroundColor: Colors.green,
              hoverColor: Colors.green,
              borderColor: Colors.green,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedContainer), findsOneWidget);
      expect(find.byType(GestureDetector), findsOneWidget);
      expect(find.byType(MouseRegion), findsAtLeastNWidgets(1));
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FancyIconButton(
              icon: Icons.delete,
              callback: () {},
              backgroundColor: Colors.red,
              hoverColor: Colors.redAccent,
              borderColor: Colors.red,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('should support different icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FancyIconButton(
                  icon: Icons.home,
                  callback: () {},
                  backgroundColor: Colors.blue,
                  hoverColor: Colors.lightBlue,
                  borderColor: Colors.blue,
                ),
                FancyIconButton(
                  icon: Icons.search,
                  callback: () {},
                  backgroundColor: Colors.purple,
                  hoverColor: Colors.purpleAccent,
                  borderColor: Colors.purple,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(FancyIconButton), findsNWidgets(2));
    });
  });
}