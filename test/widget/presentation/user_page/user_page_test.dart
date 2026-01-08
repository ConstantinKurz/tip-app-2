import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/presentation/user_page/user_profile_page.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthControllerBloc extends Mock implements AuthControllerBloc {}


class MockTeamsControllerBloc extends Mock implements TeamsControllerBloc {}

void main() {
  late MockAuthControllerBloc mockAuthControllerBloc;
  late MockTeamsControllerBloc mockTeamsControllerBloc;

  setUp(() {
    mockAuthControllerBloc = MockAuthControllerBloc();
    mockTeamsControllerBloc = MockTeamsControllerBloc();
    when(() => mockAuthControllerBloc.stream).thenAnswer((_) => Stream.value(AuthControllerInitial()));
    when(() => mockTeamsControllerBloc.stream).thenAnswer((_) => Stream.value(TeamsControllerInitial()));
  });

  group('UserPage Widget', () {
    testWidgets('renders UserPage and Scaffold', (tester) async {
      when(() => mockAuthControllerBloc.state).thenReturn(AuthControllerInitial());
      when(() => mockTeamsControllerBloc.state).thenReturn(TeamsControllerInitial());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthControllerBloc>.value(value: mockAuthControllerBloc),
            BlocProvider<TeamsControllerBloc>.value(value: mockTeamsControllerBloc),
          ],
          child: MaterialApp(
            builder: (context, child) => ResponsiveWrapper.builder(
              MediaQuery(
                data: MediaQueryData(),
                child: Theme(
                  data: ThemeData(),
                  child: child!,
                ),
              ),
              breakpoints: [
                const ResponsiveBreakpoint.resize(480, name: MOBILE),
              ],
            ),
            home: const Scaffold(
              body: UserProfilePage(
                isAuthenticated: true,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(UserProfilePage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
