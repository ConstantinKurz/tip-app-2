import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/presentation/home_page/home_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthControllerBloc extends Mock implements AuthControllerBloc {}


void main() {
  late MockAuthControllerBloc mockAuthControllerBloc;

  setUp(() {
    mockAuthControllerBloc = MockAuthControllerBloc();
  });

  testWidgets('renders HomePage and main elements', (WidgetTester tester) async {
    when(() => mockAuthControllerBloc.state).thenReturn(AuthControllerInitial());

    await tester.pumpWidget(
      BlocProvider<AuthControllerBloc>.value(
        value: mockAuthControllerBloc,
        child: const MaterialApp(
          home: HomePage(isAuthenticated: true),
        ),
      ),
    );

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.textContaining('Tipp'), findsWidgets);
  });
}
