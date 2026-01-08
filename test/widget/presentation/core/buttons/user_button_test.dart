import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/presentation/core/buttons/user_button.dart';

void main() {
  group('UserButton Widget', () {
    testWidgets('renders UserButton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserButton(),
          ),
        ),
      );
      expect(find.byType(UserButton), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byTooltip('Profil'), findsOneWidget);
    });
  });
}