import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_score_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

class MockTipFormBloc extends Mock implements TipFormBloc {
  @override
  Future<void> close() async {
    // Mock implementation - return completed future
  }
}

void main() {
  group('TipScoreField Widget Tests', () {
    late MockTipFormBloc mockTipFormBloc;
    late TextEditingController controller;

    setUp(() {
      mockTipFormBloc = MockTipFormBloc();
      controller = TextEditingController();
      
      // Setup mock stream with a simple state
      when(() => mockTipFormBloc.stream).thenAnswer(
        (_) => Stream.value(TipFormState(
          tipDate: DateTime.now(),
          isSubmitting: false,
          showValidationMessages: false,
          failureOrSuccessOption: none(),
        )),
      );
      
      when(() => mockTipFormBloc.state).thenReturn(TipFormState(
        tipDate: DateTime.now(),
        isSubmitting: false,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
      ));
    });

    tearDown(() {
      controller.dispose();
    });

    Widget createTestWidget() {
      return BlocProvider<TipFormBloc>(
        create: (_) => mockTipFormBloc,
        child: MaterialApp(
          home: Scaffold(
            body: TipScoreField(
              controller: controller,
              scoreType: 'home',
              userId: 'user-1',
              matchId: 'match-1',
            ),
          ),
        ),
      );
    }

    testWidgets('should display text field', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should have correct container width', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - find SizedBox with specific width
      final sizedBoxFinder = find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.width == 50.0,
      );
      expect(sizedBoxFinder, findsOneWidget);
      
      final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
      expect(sizedBox.width, 50);
    });

    testWidgets('should accept only digit input', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      
      final textField = find.byType(TextFormField);
      
      // Try to enter letters
      await tester.enterText(textField, 'abc');
      await tester.pump();

      // Assert
      expect(controller.text, isEmpty);
      
      // Try to enter numbers
      await tester.enterText(textField, '5');
      await tester.pump();

      // Assert
      expect(controller.text, '5');
    });

    testWidgets('should limit input to single character', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      
      final textField = find.byType(TextFormField);
      
      // Try to enter multiple digits
      await tester.enterText(textField, '123');
      await tester.pump();

      // Assert - Only first character should be accepted
      expect(controller.text, '1');
    });

    testWidgets('should have text form field present', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Just verify the field exists and renders properly
      expect(find.byType(TextFormField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle empty input', (tester) async {
      // Arrange
      controller.text = '5';
      
      // Act
      await tester.pumpWidget(createTestWidget());
      
      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '');
      await tester.pump();

      // Assert
      expect(controller.text, isEmpty);
    });

    testWidgets('should handle controller changes', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Change controller value programmatically
      controller.text = '3';
      await tester.pump();

      // Assert
      expect(find.text('3'), findsOneWidget);
    });
  });
}