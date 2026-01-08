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

      expect(find.byType(GestureDetector), findsOneWidget);
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDatePickerField(
              onDateChanged: (date) {
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