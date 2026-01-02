import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';

import '../../../helpers/test_app.dart';
import 'package:responsive_framework/responsive_framework.dart';

const String MOBILE = 'MOBILE';

void main() {
  group('PageTemplate Widget Tests', () {
    testWidgets('should render child content correctly', (tester) async {
      // Arrange
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveWrapper.builder(
            createTestApp(
              const PageTemplate(
                isAuthenticated: true,
                child: testChild,
              ),
            ),
            breakpoints: [const ResponsiveBreakpoint.resize(480, name: MOBILE)],
          ),
        ),
      );

      // Assert
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should have Scaffold structure', (tester) async {
      // Arrange
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveWrapper.builder(
            createTestApp(
              const PageTemplate(
                isAuthenticated: true,
                child: testChild,
              ),
            ),
            breakpoints: [const ResponsiveBreakpoint.resize(480, name: MOBILE)],
          ),
        ),
      );

      // Assert
      expect(find.byType(Scaffold),
          findsAtLeastNWidgets(1)); // createTestApp also creates a Scaffold
    });

    testWidgets('should have endDrawer available', (tester) async {
      // Arrange
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveWrapper.builder(
            MaterialApp(
              home: const PageTemplate(
                isAuthenticated: true,
                child: testChild,
              ),
            ),
            breakpoints: [const ResponsiveBreakpoint.resize(480, name: MOBILE)],
          ),
        ),
      );

      // Assert
      final scaffolds = tester.widgetList<Scaffold>(find.byType(Scaffold));
      final pageTemplateScaffold =
          scaffolds.firstWhere((scaffold) => scaffold.endDrawer != null);
      expect(pageTemplateScaffold.endDrawer, isNotNull);
    });

    testWidgets('should have AppBar', (tester) async {
      // Arrange
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveWrapper.builder(
            MaterialApp(
              home: const PageTemplate(
                isAuthenticated: true,
                child: testChild,
              ),
            ),
            breakpoints: [const ResponsiveBreakpoint.resize(480, name: MOBILE)],
          ),
        ),
      );

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should pass authentication state correctly', (tester) async {
      // Arrange
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveWrapper.builder(
            createTestApp(
              const PageTemplate(
                isAuthenticated: false,
                child: testChild,
              ),
            ),
            breakpoints: [const ResponsiveBreakpoint.resize(480, name: MOBILE)],
          ),
        ),
      );

      // Assert - Widget should render without errors
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should apply theme background color', (tester) async {
      // Arrange
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveWrapper.builder(
            MaterialApp(
              home: const PageTemplate(
                isAuthenticated: true,
                child: testChild,
              ),
            ),
            breakpoints: [const ResponsiveBreakpoint.resize(480, name: MOBILE)],
          ),
        ),
      );

      // Assert
      final scaffolds = tester.widgetList<Scaffold>(find.byType(Scaffold));
      final pageTemplateScaffold =
          scaffolds.firstWhere((scaffold) => scaffold.backgroundColor != null);
      expect(pageTemplateScaffold.backgroundColor, isNotNull);
    });
  });
}
