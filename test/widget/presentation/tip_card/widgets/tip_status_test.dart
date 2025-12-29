import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_status.dart';
import 'package:dartz/dartz.dart';

import '../../../helpers/test_app.dart';

void main() {
  group('TipStatus Widget Tests', () {
    testWidgets('should show loading indicator when state is TipFormInitialState', (tester) async {
      // Arrange
      final state = TipFormInitialState();

      // Act
      await tester.pumpWidget(
        createTestApp(
          TipStatus(state: state),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('should show loading indicator when state is submitting', (tester) async {
      // Arrange
      final state = TipFormState(
        tipHome: 1,
        tipGuest: 2,
        tipDate: DateTime.now(),
        isSubmitting: true,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
      );

      // Act
      await tester.pumpWidget(
        createTestApp(
          TipStatus(state: state),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('should show check circle when tip is complete', (tester) async {
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
          TipStatus(state: state),
        ),
      );
      
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);

      // Verify tooltip
      expect(find.byTooltip('Tipp vollständig'), findsOneWidget);
    });

    testWidgets('should show error icon when tip is incomplete - missing home', (tester) async {
      // Arrange
      final state = TipFormState(
        tipHome: null,
        tipGuest: 1,
        tipDate: DateTime.now(),
        isSubmitting: false,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
      );

      // Act
      await tester.pumpWidget(
        createTestApp(
          TipStatus(state: state),
        ),
      );
      
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Verify tooltip
      expect(find.byTooltip('Tipp unvollständig'), findsOneWidget);
    });

    testWidgets('should show error icon when tip is incomplete - missing guest', (tester) async {
      // Arrange
      final state = TipFormState(
        tipHome: 2,
        tipGuest: null,
        tipDate: DateTime.now(),
        isSubmitting: false,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
      );

      // Act
      await tester.pumpWidget(
        createTestApp(
          TipStatus(state: state),
        ),
      );
      
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Verify tooltip
      expect(find.byTooltip('Tipp unvollständig'), findsOneWidget);
    });

    testWidgets('should show error icon when both tips are missing', (tester) async {
      // Arrange
      final state = TipFormState(
        tipHome: null,
        tipGuest: null,
        tipDate: DateTime.now(),
        isSubmitting: false,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
      );

      // Act
      await tester.pumpWidget(
        createTestApp(
          TipStatus(state: state),
        ),
      );
      
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should animate between states smoothly', (tester) async {
      // Arrange
      final initialState = TipFormInitialState();

      // Act
      await tester.pumpWidget(
        createTestApp(
          TipStatus(state: initialState),
        ),
      );

      // Verify initial loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Update to complete state
      final completeState = TipFormState(
        tipHome: 2,
        tipGuest: 1,
        tipDate: DateTime.now(),
        isSubmitting: false,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
      );

      await tester.pumpWidget(
        createTestApp(
          TipStatus(state: completeState),
        ),
      );

      // Animation should be in progress
      await tester.pump(const Duration(milliseconds: 150));
      
      // Verify animation completes
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}