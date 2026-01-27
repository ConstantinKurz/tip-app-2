import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_card_header.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_status.dart';
import 'package:dartz/dartz.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de_DE', null);
  });

  group('TipCardHeader Widget Tests', () {
    late CustomMatch testMatch;
    late Tip testTip;

    setUp(() {
      testMatch = CustomMatch(
        id: 'match-1',
        homeTeamId: 'team-1',
        guestTeamId: 'team-2',
        matchDate: DateTime(2024, 6, 14, 15, 0),
        homeScore: null,
        guestScore: null,
        matchDay: 1,
      );

      testTip = Tip(
        id: 'tip-1',
        userId: 'user-1',
        matchId: 'match-1',
        tipDate: DateTime.now(),
        tipHome: 2,
        tipGuest: 1,
        joker: false,
        points: 3,
      );
    });

    testWidgets('should display match information correctly', (tester) async {
      // Arrange
      final state = TipFormState(
        userId: 'user-1',
        matchId: 'match-1',
        matchDay: 1,
        tipHome: 2,
        tipGuest: 1,
        isSubmitting: false,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
      );

      // Act
      await tester.pumpWidget(
        createTestApp(
          TipCardHeader(
            match: testMatch,
            state: state,
            tip: testTip,
          ),
        ),
      );

      // Assert
      // Check for stage name (should be "Gruppenphase, Tag 2" for matchDay 1)
      expect(find.text('Gruppenphase, Tag 2'), findsOneWidget);
      
      // Check for formatted date
      expect(find.textContaining('Fr, 14.06. 15:00 Uhr'), findsOneWidget);
      
      // Check for points display (Text.rich/RichText)
      final pointsFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          final text = widget.text.toPlainText();
          return text.contains('3') && text.contains('pkt');
        }
        return false;
      });
      expect(pointsFinder, findsOneWidget);
    });

    testWidgets('should display points correctly when tip has no points', (tester) async {
      // Arrange
      final tipWithoutPoints = testTip.copyWith(points: null);
      final state = TipFormState(
        userId: 'user-1',
        matchId: 'match-1',
        matchDay: 1,
        tipHome: 1,
        tipGuest: 1,
        isSubmitting: false,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
      );

      // Act
      await tester.pumpWidget(
        createTestApp(
          TipCardHeader(
            match: testMatch,
            state: state,
            tip: tipWithoutPoints,
          ),
        ),
      );

      // Assert
      final pointsFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          final text = widget.text.toPlainText();
          return text.contains('pkt');
        }
        return false;
      });
      expect(pointsFinder, findsOneWidget);
    });

    testWidgets('should handle different match days correctly', (tester) async {
      // Arrange
      final groupStageMatch = testMatch.copyWith(matchDay: 2);
      final state = TipFormInitialState();

      // Act
      await tester.pumpWidget(
        createTestApp(
          TipCardHeader(
            match: groupStageMatch,
            state: state,
            tip: testTip,
          ),
        ),
      );

      // Assert
      expect(find.text('Gruppenphase, Tag 3'), findsOneWidget);
    });

    testWidgets('should handle knockout stage matches correctly', (tester) async {
      // Arrange
      final knockoutMatch = testMatch.copyWith(matchDay: 4);
      final state = TipFormInitialState();

      // Act
      await tester.pumpWidget(
        createTestApp(
          TipCardHeader(
            match: knockoutMatch,
            state: state,
            tip: testTip,
          ),
        ),
      );

      // Assert - Just verify the widget renders without errors
      expect(find.byType(TipCardHeader), findsOneWidget);
    });

    testWidgets('should display TipStatus widget correctly', (tester) async {
      // Arrange
      final state = TipFormState(
        userId: 'user-1',
        matchId: 'match-1',
        matchDay: 1,
        isSubmitting: false,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
      );

      // Act
      await tester.pumpWidget(
        createTestApp(
          TipCardHeader(
            match: testMatch,
            state: state,
            tip: testTip,
          ),
        ),
      );

      // Assert
      expect(find.byType(TipStatus), findsOneWidget);
    });

    testWidgets('should handle text overflow correctly', (tester) async {
      // Arrange
      final longNameMatch = testMatch.copyWith(matchDay: 1);
      final state = TipFormInitialState();

      // Act
      await tester.pumpWidget(
        createTestApp(
          SizedBox(
            width: 200, // Small width to force overflow
            child: TipCardHeader(
              match: longNameMatch,
              state: state,
              tip: testTip,
            ),
          ),
        ),
      );

      // Assert - Should not overflow and text should be clipped
      expect(tester.takeException(), isNull);
    });

    testWidgets('should apply correct theme styling', (tester) async {
      // Arrange
      final state = TipFormInitialState();

      // Act
      await tester.pumpWidget(
        createTestApp(
          TipCardHeader(
            match: testMatch,
            state: state,
            tip: testTip,
          ),
        ),
      );

      // Assert - Check that theme-based text styles are applied
      final stageNameText = find.text('Gruppenphase, Tag 2');
      expect(stageNameText, findsOneWidget);

      final pointsFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          final text = widget.text.toPlainText();
          return text.contains('pkt');
        }
        return false;
      });
      expect(pointsFinder, findsOneWidget);
      final RichText richText = tester.widget(pointsFinder);
      expect(richText.textAlign, TextAlign.end);
    });

    testWidgets('should handle different match times correctly', (tester) async {
      // Arrange
      final eveningMatch = testMatch.copyWith(
        matchDate: DateTime(2024, 6, 14, 21, 0),
      );
      final state = TipFormInitialState();

      // Act
      await tester.pumpWidget(
        createTestApp(
          TipCardHeader(
            match: eveningMatch,
            state: state,
            tip: testTip,
          ),
        ),
      );

      // Assert
      expect(find.textContaining('Fr, 14.06. 21:00 Uhr'), findsOneWidget);
    });
  });
}