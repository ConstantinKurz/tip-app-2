import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';

void main() {
  group('CustomButton Widget Tests', () {
    testWidgets('should display button text correctly', (WidgetTester tester) async {
      bool callbackTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              buttonText: 'Test Button',
              callback: () {
                callbackTriggered = true;
              },
              borderColor: Colors.blue,
              hoverColor: Colors.lightBlue,
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(callbackTriggered, false);
    });

    testWidgets('should trigger callback when tapped', (WidgetTester tester) async {
      bool callbackTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              buttonText: 'Click Me',
              callback: () {
                callbackTriggered = true;
              },
              borderColor: Colors.green,
              hoverColor: Colors.lightGreen,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      expect(callbackTriggered, true);
    });

    testWidgets('should apply custom background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              buttonText: 'Colored Button',
              callback: () {},
              backgroundColor: Colors.red,
              borderColor: Colors.red,
              hoverColor: Colors.redAccent,
            ),
          ),
        ),
      );

      expect(find.byType(CustomButton), findsOneWidget);
      expect(find.text('Colored Button'), findsOneWidget);
    });

    testWidgets('should apply custom width', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              buttonText: 'Wide Button',
              callback: () {},
              borderColor: Colors.purple,
              hoverColor: Colors.purpleAccent,
              width: 200.0,
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(CustomButton);
      expect(buttonFinder, findsOneWidget);
      
      final button = tester.widget<CustomButton>(buttonFinder);
      expect(button.width, 200.0);
    });

    testWidgets('should render with required properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              buttonText: 'Required Props',
              callback: () {},
              borderColor: Colors.orange,
              hoverColor: Colors.deepOrange,
            ),
          ),
        ),
      );

      final button = tester.widget<CustomButton>(find.byType(CustomButton));
      expect(button.buttonText, 'Required Props');
      expect(button.borderColor, Colors.orange);
      expect(button.hoverColor, Colors.deepOrange);
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              buttonText: 'Error Test',
              callback: () {},
              borderColor: Colors.black,
              hoverColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle multiple instances', (WidgetTester tester) async {
      int button1Clicks = 0;
      int button2Clicks = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CustomButton(
                  buttonText: 'Button 1',
                  callback: () {
                    button1Clicks++;
                  },
                  borderColor: Colors.blue,
                  hoverColor: Colors.lightBlue,
                ),
                CustomButton(
                  buttonText: 'Button 2',
                  callback: () {
                    button2Clicks++;
                  },
                  borderColor: Colors.red,
                  hoverColor: Colors.redAccent,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Button 1'));
      await tester.pump();
      expect(button1Clicks, 1);
      expect(button2Clicks, 0);

      await tester.tap(find.text('Button 2'));
      await tester.pump();
      expect(button1Clicks, 1);
      expect(button2Clicks, 1);
    });
  });
}