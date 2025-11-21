import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/firebase_options.dart';
import 'package:flutter_web/injections.dart' as di;
import 'package:flutter_web/presentation/admin_page/admin_page.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/home_page/home_page.dart';
import 'package:flutter_web/presentation/signin/signin_page.dart';
import 'package:flutter_web/presentation/signup/signup_page.dart';
import 'package:flutter_web/presentation/tip_details_page/tip_details_page.dart';
import 'package:flutter_web/presentation/tip_page/tip_page.dart';
import 'package:flutter_web/theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_strategy/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('de_DE', null);

  setPathUrlStrategy();
  await di.init();
  runApp(const MyApp());
}

class AppRoutes {
  static const signin = '/signin';
  static const signup = '/signup';
  static const admin = '/admin';
  static const home = '/home';
  static const userTips = '/tips';
  static const userTipsDetail = '/tips-detail/:id';
  static const dashboard = '/dashboard';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              di.sl<AuthBloc>()..add(AuthCheckRequestedEvent()),
        ),
        BlocProvider(
          create: (context) => di.sl<AuthControllerBloc>()..add(AuthAllEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<MatchesControllerBloc>()..add(MatchesAllEvent()),
        ),
        BlocProvider(
          create: (_) =>
              di.sl<TeamsControllerBloc>()..add(TeamsControllerAllEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<TipControllerBloc>()..add(TipAllEvent()),
        ),
      ],
      // BlocBuilder rund um dein gesamtes Routing
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isAuthenticated = authState is AuthStateAuthenticated;

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Flutter Web',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            routeInformationParser: const RoutemasterParser(),
            routerDelegate: RoutemasterDelegate(
              routesBuilder: (_) {
                // 1) Initialer Zustand → Splash
                if (authState is AuthInitial) {
                  return RouteMap(
                    //dummy routes
                    routes: const {},
                    onUnknownRoute: (_) => MaterialPage(
                      child: PageTemplate(
                        isAuthenticated: false,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // 2) Eingeloggt → alle geschützten Seiten
                if (isAuthenticated) {
                  return RouteMap(
                      onUnknownRoute: (_) => const Redirect(AppRoutes.home),
                      routes: {
                        AppRoutes.home: (_) => const MaterialPage(
                            child: HomePage(isAuthenticated: true)),
                        AppRoutes.admin: (_) => MaterialPage(
                              child: AdminPage(isAuthenticated: true),
                            ),
                        AppRoutes.userTips: (info) {
                          final scrollToIndex = info.queryParameters['scrollTo'];
                          
                          return MaterialPage(
                            child: TipPage(
                              isAuthenticated: true,
                              initialScrollIndex: scrollToIndex != null
                                  ? int.tryParse(scrollToIndex)
                                  : null,
                            ),
                          );
                        },
                        AppRoutes.userTipsDetail: (info) {
                          final tipId = info.pathParameters['id']!;
                          // Lese alle Query-Parameter
                          final returnIndexString = info.queryParameters['returnIndex'];
                          final from = info.queryParameters['from'];
                          
                          final returnIndex = returnIndexString != null 
                              ? int.tryParse(returnIndexString) 
                              : null;
                          
                          return MaterialPage(
                            child: TipDetailsPage(
                              isAuthenticated: true,
                              tipId: tipId,
                              returnIndex: returnIndex,
                              from: from, // Neuer Parameter
                            ),
                          );
                        },
                      });
                }

                // 3) Nicht eingeloggt → Sign-In & Sign-Up
                return RouteMap(
                  onUnknownRoute: (_) => const Redirect(AppRoutes.signin),
                  routes: {
                    AppRoutes.signin: (_) => const MaterialPage(
                          child: SignInPage(isAuthenticated: false),
                        ),
                    AppRoutes.signup: (_) => const MaterialPage(
                          child: SignUpPage(isAuthenticated: false),
                        ),
                  },
                );
              },
            ),
            builder: (context, child) {
              // Wenn child null ist, zeige Spinner, sonst ResponsiveWrapper
              if (child == null) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                );
              }
              return ResponsiveWrapper.builder(
                child,
                defaultScale: true,
                minWidth: 400,
                defaultName: MOBILE,
                breakpoints: const [
                  ResponsiveBreakpoint.autoScale(450, name: MOBILE),
                  ResponsiveBreakpoint.resize(600, name: TABLET),
                  ResponsiveBreakpoint.resize(1000, name: DESKTOP),
                ],
                background: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
