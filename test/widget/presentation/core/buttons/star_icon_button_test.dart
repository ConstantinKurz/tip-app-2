import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/presentation/core/buttons/star_icon_button.dart';

void main() {
  group('StarIconButton Widget', () {
    testWidgets('renders StarIconButton and responds to tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarIconButton(
              isStar: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );
      expect(find.byType(StarIconButton), findsOneWidget);
      await tester.tap(find.byType(StarIconButton));
      expect(tapped, isTrue);
    });
  });
}
