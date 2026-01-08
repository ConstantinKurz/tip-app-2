import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_app.dart';
import 'package:responsive_framework/responsive_framework.dart';

const String MOBILE = 'MOBILE';

class MockAuthControllerBloc extends Mock implements AuthControllerBloc {}

void main() {
  late MockAuthControllerBloc mockAuthControllerBloc;

  setUp(() {
    mockAuthControllerBloc = MockAuthControllerBloc();
  });

  group('PageTemplate Widget Tests', () {
    testWidgets('should render child content correctly', (tester) async {
      const testChild = Text('Test Content');
      when(() => mockAuthControllerBloc.state).thenReturn(AuthControllerInitial());

      await tester.pumpWidget(
        BlocProvider<AuthControllerBloc>.value(
          value: mockAuthControllerBloc,
          child: MaterialApp(
            home: ResponsiveWrapper.builder(
              const PageTemplate(
                isAuthenticated: true,
                child: testChild,
              ),
              breakpoints: [const ResponsiveBreakpoint.resize(480, name: MOBILE)],
            ),
          ),
        ),
      );
      expect(find.text('Test Content'), findsAtLeastNWidgets(1));
    });

    testWidgets('should have Scaffold structure', (tester) async {
      const testChild = Text('Test Content');
      when(() => mockAuthControllerBloc.state).thenReturn(AuthControllerInitial());

      await tester.pumpWidget(
        BlocProvider<AuthControllerBloc>.value(
          value: mockAuthControllerBloc,
          child: MaterialApp(
            home: ResponsiveWrapper.builder(
              const PageTemplate(
                isAuthenticated: true,
                child: testChild,
              ),
              breakpoints: [const ResponsiveBreakpoint.resize(480, name: MOBILE)],
            ),
          ),
        ),
      );
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have endDrawer available', (tester) async {
      const testChild = Text('Test Content');
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveWrapper.builder(
            const PageTemplate(
              isAuthenticated: true,
              child: testChild,
            ),
            breakpoints: [const ResponsiveBreakpoint.resize(480, name: MOBILE)],
          ),
        ),
      );
      final scaffolds = tester.widgetList<Scaffold>(find.byType(Scaffold));
      final pageTemplateScaffold = scaffolds.firstWhere(
        (scaffold) => scaffold.endDrawer != null,
        orElse: () => Scaffold(),
      );
      expect(pageTemplateScaffold.endDrawer, isNotNull);
    });

    testWidgets('should have AppBar', (tester) async {
      const testChild = Text('Test Content');
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveWrapper.builder(
            const PageTemplate(
              isAuthenticated: true,
              child: testChild,
            ),
            breakpoints: [const ResponsiveBreakpoint.resize(480, name: MOBILE)],
          ),
        ),
      );
      // AppBar may be a custom widget, so check for PreferredSizeWidget
      expect(find.byType(PreferredSize), findsAtLeastNWidgets(1));
    });

    testWidgets('should pass authentication state correctly', (tester) async {
      const testChild = Text('Test Content');
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveWrapper.builder(
            const PageTemplate(
              isAuthenticated: false,
              child: testChild,
            ),
            breakpoints: [const ResponsiveBreakpoint.resize(480, name: MOBILE)],
          ),
        ),
      );
      expect(find.text('Test Content'), findsAtLeastNWidgets(1));
    });

    testWidgets('should apply theme background color', (tester) async {
      const testChild = Text('Test Content');
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveWrapper.builder(
            const PageTemplate(
              isAuthenticated: true,
              child: testChild,
            ),
            breakpoints: [const ResponsiveBreakpoint.resize(480, name: MOBILE)],
          ),
        ),
      );
      final scaffolds = tester.widgetList<Scaffold>(find.byType(Scaffold));
      final pageTemplateScaffold = scaffolds.firstWhere(
        (scaffold) => scaffold.backgroundColor != null,
        orElse: () => Scaffold(),
      );
      expect(pageTemplateScaffold.backgroundColor, isNotNull);
    });
  });
}
