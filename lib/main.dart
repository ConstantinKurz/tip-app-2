import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/application/tips/services/tip_recalculation_service.dart';
import 'package:flutter_web/firebase_options.dart';
import 'package:flutter_web/injections.dart' as di;
import 'package:flutter_web/presentation/admin_page/admin_page.dart';
import 'package:flutter_web/presentation/admin_page/widget/admin_user_tip_details_page.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/home_page/home_page.dart';
import 'package:flutter_web/presentation/signin/signin_page.dart';
import 'package:flutter_web/presentation/signup/signup_page.dart';
import 'package:flutter_web/presentation/tip_details_page/tip_details_page.dart';
import 'package:flutter_web/presentation/tip_page/tip_page.dart';
import 'package:flutter_web/presentation/user_page/user_profile_page.dart';
import 'package:flutter_web/theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_strategy/url_strategy.dart';
//TODO:ranking wird oft refreshed.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('de_DE', null);

  setPathUrlStrategy();
  await di.init();

  //await setupTournament();

  // ✨ TipRecalculationService starten
  final recalculationService = di.sl<TipRecalculationService>();
  recalculationService.startListening();

  print('🚀 App gestartet - Neuberechnung Service aktiv');

  runApp(const MyApp());
}

class AppRoutes {
  static const signin = '/signin';
  static const signup = '/signup';
  static const admin = '/admin';
  static const home = '/home';
  static const userTips = '/tips';
  static const userTipsDetail = '/tips-detail/:id';
  static const userProfile = '/profile';
  static const dashboard = '/dashboard';
  static const adminUserTips = '/admin/user-tips/:userId';
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
          create: (_) => di.sl<TipControllerBloc>(),
        ),
      ],
      // BlocBuilder rund um dein gesamtes Routing
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isAuthenticated = authState is AuthStateAuthenticated;
          final authControllerState = context.watch<AuthControllerBloc>().state;
          bool isAdmin = false;
          String? userId;
          
          if (authControllerState is AuthControllerLoaded) {
            isAdmin = authControllerState.signedInUser?.admin ?? false;
            userId = authControllerState.signedInUser?.id;
          }

          // ✅ Initialisiere TipControllerBloc basierend auf User-Rolle
          if (isAuthenticated && userId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isAdmin) {
                // Admin sieht ALLE Tips
                context.read<TipControllerBloc>().add(TipAllEvent());
              } else {
                // Normale User sehen nur ihre eigenen Tips (98% weniger Reads)
                context.read<TipControllerBloc>().add(
                  TipLoadForUserEvent(userId: userId!),
                );
              }
            });
          }
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
                        AppRoutes.admin: (_) => 
                          isAdmin
                              ? MaterialPage(
                                  child: AdminPage(isAuthenticated: true),
                                )
                              : const MaterialPage(
                            child: HomePage(isAuthenticated: true)),
                        AppRoutes.adminUserTips : (info) {
                          final userId = info.pathParameters['userId']!;
                          return MaterialPage(
                            child: AdminUserTipDetailsPage(
                              isAuthenticated: true,
                              selectedUserId: userId,
                            ),
                          );
                        },
                        AppRoutes.userProfile: (_) => const MaterialPage(
                              child: UserProfilePage(isAuthenticated: true),
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
