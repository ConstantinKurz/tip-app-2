import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/presentation/core/date_picker/custom_time_picker.dart';

void main() {
  group('CustomTimePickerField Widget Additional', () {
    testWidgets('renders colon separator', (tester) async {
      final initialTime = TimeOfDay(hour: 8, minute: 15);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTimePickerField(
              initialTime: initialTime,
              onTimeChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text(':'), findsOneWidget);
    });
  });
}
