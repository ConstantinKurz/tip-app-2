import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_status.dart';
import 'package:dartz/dartz.dart';

class MockTipFormBloc extends Mock implements TipFormBloc {}

void main() {
  group('TipStatus Widget Tests', () {
    late MockTipFormBloc mockTipFormBloc;

    setUp(() {
      mockTipFormBloc = MockTipFormBloc();
    });

    testWidgets('should show loading indicator when state is TipFormInitialState', (tester) async {
      // Arrange
      final state = TipFormInitialState();
      when(() => mockTipFormBloc.state).thenReturn(state);
      when(() => mockTipFormBloc.stream).thenAnswer((_) => Stream.value(state));

      // Act
      await tester.pumpWidget(
        BlocProvider<TipFormBloc>.value(
          value: mockTipFormBloc,
          child: MaterialApp(
            home: Scaffold(
              body: TipStatus(),
            ),
          ),
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
        userId: 'user-1',
        matchId: 'match-1',
        matchDay: 1,
        tipHome: 1,
        tipGuest: 2,
        isSubmitting: true,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
        isLoading: false,
      );
      when(() => mockTipFormBloc.state).thenReturn(state);
      when(() => mockTipFormBloc.stream).thenAnswer((_) => Stream.value(state));

      // Act
      await tester.pumpWidget(
        BlocProvider<TipFormBloc>.value(
          value: mockTipFormBloc,
          child: MaterialApp(
            home: Scaffold(
              body: TipStatus(),
            ),
          ),
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
        userId: 'user-1',
        matchId: 'match-1',
        matchDay: 1,
        tipHome: 2,
        tipGuest: 1,
        isSubmitting: false,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
        isLoading: false,
      );
      when(() => mockTipFormBloc.state).thenReturn(state);
      when(() => mockTipFormBloc.stream).thenAnswer((_) => Stream.value(state));

      // Act
      await tester.pumpWidget(
        BlocProvider<TipFormBloc>.value(
          value: mockTipFormBloc,
          child: MaterialApp(
            home: Scaffold(
              body: TipStatus(),
            ),
          ),
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
        userId: 'user-1',
        matchId: 'match-1',
        matchDay: 1,
        tipHome: null,
        tipGuest: 1,
        isSubmitting: false,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
        isLoading: false,
      );
      when(() => mockTipFormBloc.state).thenReturn(state);
      when(() => mockTipFormBloc.stream).thenAnswer((_) => Stream.value(state));

      // Act
      await tester.pumpWidget(
        BlocProvider<TipFormBloc>.value(
          value: mockTipFormBloc,
          child: MaterialApp(
            home: Scaffold(
              body: TipStatus(),
            ),
          ),
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
        userId: 'user-1',
        matchId: 'match-1',
        matchDay: 1,
        tipHome: 2,
        tipGuest: null,
        isSubmitting: false,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
        isLoading: false,
      );
      when(() => mockTipFormBloc.state).thenReturn(state);
      when(() => mockTipFormBloc.stream).thenAnswer((_) => Stream.value(state));

      // Act
      await tester.pumpWidget(
        BlocProvider<TipFormBloc>.value(
          value: mockTipFormBloc,
          child: MaterialApp(
            home: Scaffold(
              body: TipStatus(),
            ),
          ),
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
        userId: 'user-1',
        matchId: 'match-1',
        matchDay: 1,
        tipHome: null,
        tipGuest: null,
        isSubmitting: false,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
        isLoading: false,
      );
      when(() => mockTipFormBloc.state).thenReturn(state);
      when(() => mockTipFormBloc.stream).thenAnswer((_) => Stream.value(state));

      // Act
      await tester.pumpWidget(
        BlocProvider<TipFormBloc>.value(
          value: mockTipFormBloc,
          child: MaterialApp(
            home: Scaffold(
              body: TipStatus(),
            ),
          ),
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
      when(() => mockTipFormBloc.state).thenReturn(initialState);
      when(() => mockTipFormBloc.stream).thenAnswer((_) => Stream.value(initialState));

      // Act
      await tester.pumpWidget(
        BlocProvider<TipFormBloc>.value(
          value: mockTipFormBloc,
          child: MaterialApp(
            home: Scaffold(
              body: TipStatus(),
            ),
          ),
        ),
      );

      // Verify initial loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Update to complete state
      final completeState = TipFormState(
        userId: 'user-1',
        matchId: 'match-1',
        matchDay: 1,
        tipHome: 2,
        tipGuest: 1,
        isSubmitting: false,
        showValidationMessages: false,
        failureOrSuccessOption: none(),
        isLoading: false,
      );

      when(() => mockTipFormBloc.state).thenReturn(completeState);
      await tester.pumpWidget(
        BlocProvider<TipFormBloc>.value(
          value: mockTipFormBloc,
          child: MaterialApp(
            home: Scaffold(
              body: TipStatus(),
            ),
          ),
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