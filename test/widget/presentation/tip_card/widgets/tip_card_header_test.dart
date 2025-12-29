import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_card_header.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_status.dart';
import 'package:dartz/dartz.dart';

import '../../../helpers/test_app.dart';

void main() {
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
        tipHome: 2,
        tipGuest: 1,
        tipDate: DateTime.now(),
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
      // Check for stage name (should be "1. Spieltag" for matchDay 1)
      expect(find.text('1. Spieltag'), findsOneWidget);
      
      // Check for formatted date
      expect(find.textContaining('Fr, 14.06. 15:00 Uhr'), findsOneWidget);
      
      // Check for points display
      expect(find.textContaining('3'), findsOneWidget);
      expect(find.textContaining('pkt'), findsOneWidget);
    });

    testWidgets('should display points correctly when tip has no points', (tester) async {
      // Arrange
      final tipWithoutPoints = testTip.copyWith(points: null);
      final state = TipFormState(
        tipHome: 1,
        tipGuest: 0,
        tipDate: DateTime.now(),
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
      expect(find.textContaining('0'), findsOneWidget);
      expect(find.textContaining('pkt'), findsOneWidget);
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
      expect(find.text('2. Spieltag'), findsOneWidget);
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

      // Assert - Knockout stages should show different stage names
      expect(find.text('Achtelfinale'), findsOneWidget);
    });

    testWidgets('should display TipStatus widget correctly', (tester) async {
      // Arrange
      final state = TipFormState(
        tipHome: 2,
        tipGuest: 1,
        tipDate: DateTime.now(),
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
      final stageNameText = find.text('1. Spieltag');
      expect(stageNameText, findsOneWidget);

      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsOneWidget);
      
      final RichText richText = tester.widget(richTextFinder);
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