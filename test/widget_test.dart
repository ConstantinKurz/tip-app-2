// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_web/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/injections.dart' as di;
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_web/main.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    di.sl.registerLazySingleton<FirebaseAuth>(() => MockFirebaseAuth());
    di.sl.registerLazySingleton<FirebaseFirestore>(() => MockFirebaseFirestore());
    await di.init(useMocks: true);
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build a simple counter widget for testing.
    int counter = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                Text('$counter', key: const Key('counterText')),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => counter++),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
