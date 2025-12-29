import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/presentation/core/menu/home_logo.dart';
import 'package:routemaster/routemaster.dart';

import '../../../helpers/test_app.dart';

void main() {
  group('HomeLogo Widget Tests', () {
    testWidgets('should display logo text correctly', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        RoutemasterApp(
          routerDelegate: RoutemasterDelegate(
            routesBuilder: (_) {
              return RouteMap(routes: {
                '/': (_) => MaterialPage(child: Container()),
                '/home': (_) => MaterialPage(child: Container()),
              });
            },
          ),
          child: MaterialApp(
            home: Scaffold(
              body: const HomeLogo(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Shorty Tipp'), findsOneWidget);
    });

    testWidgets('should have clickable mouse cursor', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        RoutemasterApp(
          routerDelegate: RoutemasterDelegate(
            routesBuilder: (_) {
              return RouteMap(routes: {
                '/': (_) => MaterialPage(child: Container()),
                '/home': (_) => MaterialPage(child: Container()),
              });
            },
          ),
          child: MaterialApp(
            home: Scaffold(
              body: const HomeLogo(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(MouseRegion), findsOneWidget);
      
      final mouseRegion = tester.widget<MouseRegion>(find.byType(MouseRegion));
      expect(mouseRegion.cursor, SystemMouseCursors.click);
    });

    testWidgets('should be wrapped in GestureDetector for tap handling', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        RoutemasterApp(
          routerDelegate: RoutemasterDelegate(
            routesBuilder: (_) {
              return RouteMap(routes: {
                '/': (_) => MaterialPage(child: Container()),
                '/home': (_) => MaterialPage(child: Container()),
              });
            },
          ),
          child: MaterialApp(
            home: Scaffold(
              body: const HomeLogo(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('should apply correct container styling', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        RoutemasterApp(
          routerDelegate: RoutemasterDelegate(
            routesBuilder: (_) {
              return RouteMap(routes: {
                '/': (_) => MaterialPage(child: Container()),
                '/home': (_) => MaterialPage(child: Container()),
              });
            },
          ),
          child: MaterialApp(
            home: Scaffold(
              body: const HomeLogo(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Container), findsOneWidget);
      
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.padding, const EdgeInsets.symmetric(horizontal: 16, vertical: 8));
      expect(container.decoration, isNotNull);
    });

    testWidgets('should handle text overflow correctly', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        RoutemasterApp(
          routerDelegate: RoutemasterDelegate(
            routesBuilder: (_) {
              return RouteMap(routes: {
                '/': (_) => MaterialPage(child: Container()),
                '/home': (_) => MaterialPage(child: Container()),
              });
            },
          ),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 50, // Small width to force overflow
                child: const HomeLogo(),
              ),
            ),
          ),
        ),
      );

      // Assert - Should not throw overflow exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('should respond to tap gestures', (tester) async {
      // Arrange
      await tester.pumpWidget(
        RoutemasterApp(
          routerDelegate: RoutemasterDelegate(
            routesBuilder: (_) {
              return RouteMap(routes: {
                '/': (_) => MaterialPage(child: Container()),
                '/home': (_) => MaterialPage(child: Container()),
              });
            },
          ),
          child: MaterialApp(
            home: Scaffold(
              body: const HomeLogo(),
            ),
          ),
        ),
      );

      // Act - Tap on the logo
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Assert - Should not throw any errors (navigation occurs)
      expect(tester.takeException(), isNull);
    });
  });
}