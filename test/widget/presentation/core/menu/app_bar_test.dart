import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/presentation/core/menu/app_bar.dart';

void main() {
  group('CustomAppBar Widget Tests', () {
    testWidgets('should create AppBar widget', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size(double.infinity, 56),
              child: CustomAppBar(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should contain Row widget for title', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size(double.infinity, 56),
              child: CustomAppBar(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('should apply theme background color', (tester) async {
      // Arrange
      const testColor = Colors.blue;
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            appBarTheme: const AppBarTheme(
              backgroundColor: testColor,
            ),
          ),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size(double.infinity, 56),
              child: CustomAppBar(),
            ),
          ),
        ),
      );

      // Assert
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, testColor);
    });

    testWidgets('should render without errors', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size(double.infinity, 56),
              child: CustomAppBar(),
            ),
          ),
        ),
      );

      // Wait for any async operations
      await tester.pumpAndSettle();

      // Assert - No exceptions should be thrown
      expect(tester.takeException(), isNull);
    });
  });
}