import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/presentation/admin_page/admin_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthControllerBloc extends Mock implements AuthControllerBloc {}

void main() {
  late MockAuthControllerBloc mockAuthControllerBloc;

  setUp(() {
    mockAuthControllerBloc = MockAuthControllerBloc();
  });

  group('AdminPage Widget', () {
    testWidgets('renders AdminPage and Scaffold', (tester) async {
      when(() => mockAuthControllerBloc.state).thenReturn(AuthControllerInitial());

      await tester.pumpWidget(
        BlocProvider<AuthControllerBloc>.value(
          value: mockAuthControllerBloc,
          child: MaterialApp(
            home: AdminPage(isAuthenticated: true),
          ),
        ),
      );

      expect(find.byType(AdminPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
