import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/presentation/core/menu/drawer.dart';
import 'package:flutter_web/presentation/core/menu/menu_item.dart';
import 'package:flutter_web/presentation/core/menu/home_logo.dart';
import 'package:routemaster/routemaster.dart';

void main() {
  group('CustomDrawer Widget', () {
    testWidgets('renders drawer and menu items', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: RoutemasterDelegate(
            routesBuilder: (_) => RouteMap(
              routes: {
                '/': (_) => const MaterialPage(
                      child: Scaffold(
                        endDrawer: CustomDrawer(),
                      ),
                    ),
              },
            ),
          ),
          routeInformationParser: const RoutemasterParser(),
        ),
      );

      // Open the endDrawer
      tester.state<ScaffoldState>(find.byType(Scaffold)).openEndDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(CustomDrawer), findsOneWidget);
      expect(find.byType(HomeLogo), findsOneWidget);
      expect(find.byType(MenuItem), findsWidgets);
    });
  });
}
