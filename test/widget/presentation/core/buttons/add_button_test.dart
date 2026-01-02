import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/presentation/core/buttons/add_button.dart';

void main() {
  group('AddButton Widget Tests', () {
    testWidgets('should display add icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('should trigger callback when pressed', (WidgetTester tester) async {
      bool callbackTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddButton(
              onPressed: () {
                callbackTriggered = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AddButton));
      await tester.pump();

      expect(callbackTriggered, true);
    });

    testWidgets('should be accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      final addButton = tester.widget<AddButton>(find.byType(AddButton));
      expect(addButton.onPressed, isNotNull);
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('should work in different contexts', (WidgetTester tester) async {
      int clickCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                AddButton(
                  onPressed: () {
                    clickCount++;
                  },
                ),
              ],
            ),
            body: const Center(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AddButton));
      await tester.pump();

      expect(clickCount, 1);
      expect(find.text('Test Content'), findsOneWidget);
    });
  });
}