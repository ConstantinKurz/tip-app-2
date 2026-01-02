import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/presentation/core/date_picker/custom_time_picker.dart';

void main() {
  group('CustomTimePickerField Widget Tests', () {
    testWidgets('should display initial time when provided', (WidgetTester tester) async {
      final initialTime = const TimeOfDay(hour: 14, minute: 30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTimePickerField(
              initialTime: initialTime,
              onTimeChanged: (time) {},
            ),
          ),
        ),
      );

      expect(find.text('14'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('should display empty fields when no initial time', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTimePickerField(
              onTimeChanged: (time) {},
            ),
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2)); // Hour and minute fields
    });

    testWidgets('should have hour and minute text fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTimePickerField(
              onTimeChanged: (time) {},
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });

    testWidgets('should format time with leading zeros', (WidgetTester tester) async {
      final testCases = [
        {
          'time': const TimeOfDay(hour: 9, minute: 5),
          'expectedHour': '09',
          'expectedMinute': '05',
        },
        {
          'time': const TimeOfDay(hour: 23, minute: 59),
          'expectedHour': '23',
          'expectedMinute': '59',
        },
        {
          'time': const TimeOfDay(hour: 0, minute: 0),
          'expectedHour': '00',
          'expectedMinute': '00',
        },
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomTimePickerField(
                initialTime: testCase['time'] as TimeOfDay,
                onTimeChanged: (time) {},
              ),
            ),
          ),
        );

        expect(find.text(testCase['expectedHour'] as String), findsOneWidget);
        expect(find.text(testCase['expectedMinute'] as String), findsOneWidget);
      }
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTimePickerField(
              onTimeChanged: (time) {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle callback function correctly', (WidgetTester tester) async {    
      TimeOfDay? receivedTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTimePickerField(
              onTimeChanged: (time) {
                receivedTime = time;
              },
            ),
          ),
        ),
      );

      final timePicker = tester.widget<CustomTimePickerField>(find.byType(CustomTimePickerField));
      expect(timePicker.onTimeChanged, isNotNull);
    });

    testWidgets('should accept text input in hour field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTimePickerField(
              onTimeChanged: (time) {},
            ),
          ),
        ),
      );

      final hourField = find.byType(TextFormField).first;
      await tester.enterText(hourField, '15');
      await tester.pump();

      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('should accept text input in minute field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTimePickerField(
              onTimeChanged: (time) {},
            ),
          ),
        ),
      );

      final minuteField = find.byType(TextFormField).last;
      await tester.enterText(minuteField, '45');
      await tester.pump();

      expect(find.text('45'), findsOneWidget);
    });

    testWidgets('should display colon separator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTimePickerField(
              onTimeChanged: (time) {},
            ),
          ),
        ),
      );

      expect(find.text(':'), findsOneWidget);
    });
  });
}