import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/presentation/core/date_picker/custom_date_picker.dart';

void main() {
  group('CustomDatePickerField Widget Tests', () {
    testWidgets('should display initial date when provided', (WidgetTester tester) async {
      final initialDate = DateTime(2025, 12, 30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDatePickerField(
              initialDate: initialDate,
              onDateChanged: (date) {},
            ),
          ),
        ),
      );

      expect(find.text('30.12.2025'), findsOneWidget);
    });

    testWidgets('should display placeholder when no initial date', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDatePickerField(
              onDateChanged: (date) {},
            ),
          ),
        ),
      );

      expect(find.text('Kein Datum ausgewählt'), findsOneWidget);
    });

    testWidgets('should display proper label and hint', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDatePickerField(
              onDateChanged: (date) {},
            ),
          ),
        ),
      );

      expect(find.byType(InputDecorator), findsOneWidget);
    });

    testWidgets('should be tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDatePickerField(
              onDateChanged: (date) {},
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('should format date correctly', (WidgetTester tester) async {
      final testCases = [
        {
          'date': DateTime(2025, 1, 5),
          'expected': '05.01.2025',
        },
        {
          'date': DateTime(2025, 12, 25),
          'expected': '25.12.2025',
        },
        {
          'date': DateTime(2024, 7, 15),
          'expected': '15.07.2024',
        },
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomDatePickerField(
                initialDate: testCase['date'] as DateTime,
                onDateChanged: (date) {},
              ),
            ),
          ),
        );

        expect(find.text(testCase['expected'] as String), findsOneWidget);
      }
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDatePickerField(
              onDateChanged: (date) {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle callback function correctly', (WidgetTester tester) async {
      DateTime? receivedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDatePickerField(
              onDateChanged: (date) {
                receivedDate = date;
              },
            ),
          ),
        ),
      );

      final datePicker = tester.widget<CustomDatePickerField>(find.byType(CustomDatePickerField));
      expect(datePicker.onDateChanged, isNotNull);
    });

    testWidgets('should show different text styles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDatePickerField(
              initialDate: DateTime(2025, 6, 15),
              onDateChanged: (date) {},
            ),
          ),
        ),
      );

      final textWidget = find.text('15.06.2025');
      expect(textWidget, findsOneWidget);
      
      final widget = tester.widget<Text>(textWidget);
      expect(widget.style?.color, Colors.white);
    });
  });
}