import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_web/presentation/core/menu/menu_bar.dart';
import 'package:flutter_web/presentation/core/menu/home_logo.dart';

class MockAuthControllerBloc extends Mock implements AuthControllerBloc {}

void main() {
  late MockAuthControllerBloc mockAuthControllerBloc;

  setUp(() {
    mockAuthControllerBloc = MockAuthControllerBloc();
  });

  testWidgets('renders menu bar and logo', (WidgetTester tester) async {
    when(() => mockAuthControllerBloc.state).thenReturn(AuthControllerInitial());

    await tester.pumpWidget(
      BlocProvider<AuthControllerBloc>.value(
        value: mockAuthControllerBloc,
        child: const MaterialApp(
          home: Scaffold(
            body: MyMenuBar(isAuthenticated: true),
          ),
        ),
      ),
    );

    expect(find.byType(MyMenuBar), findsOneWidget);
    expect(find.byType(HomeLogo), findsOneWidget);
  });
}
