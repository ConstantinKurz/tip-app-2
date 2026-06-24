import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/core/utils/firestore_logger.dart';
import 'package:flutter_web/domain/services/tip_recalculation_service.dart';
import 'package:flutter_web/firebase_options.dart';
import 'package:flutter_web/injections.dart' as di;
import 'package:flutter_web/presentation/admin_page/admin_page.dart';
import 'package:flutter_web/presentation/admin_page/pages/admin_match_delete_page.dart';
import 'package:flutter_web/presentation/admin_page/pages/admin_match_form_page.dart';
import 'package:flutter_web/presentation/admin_page/pages/admin_team_delete_page.dart';
import 'package:flutter_web/presentation/admin_page/pages/admin_team_form_page.dart';
import 'package:flutter_web/presentation/admin_page/pages/admin_user_form_page.dart';
import 'package:flutter_web/presentation/admin_page/widget/admin_user_tip_details_page.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/home_page/home_page.dart';
import 'package:flutter_web/presentation/signin/signin_page.dart';
import 'package:flutter_web/presentation/signup/signup_page.dart';
import 'package:flutter_web/presentation/tip_details_page/tip_details_page.dart';
import 'package:flutter_web/presentation/tip_page/tip_page.dart';
import 'package:flutter_web/presentation/user_page/user_profile_page.dart';
import 'package:flutter_web/presentation/rules_page/rules_page.dart';
import 'package:flutter_web/theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_strategy/url_strategy.dart';

// ✅ Performance-Optimierungen implementiert:
// - Champion-Logik: Finale-Match wird einmal gecached
// - TipRepository: Batch-Reads statt einzelne Match-Reads
// - RecalculationService: Debouncing und Ergebnis-Änderungs-Filter
// - Ranking-Update: Nur geänderte User werden geschrieben
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('de_DE', null);

  setPathUrlStrategy();
  await di.init();

  // ✅ NEU: Logger initialisieren
  await FirestoreLogger.initialize();
  // ✅ Reset Firestore Logger beim Start
  FirestoreLogger.reset();

  // ✨ TipRecalculationService starten
  final recalculationService = di.sl<TipRecalculationService>();
  recalculationService.startListening();

  debugPrint('🚀 App gestartet - Neuberechnung Service aktiv');
  debugPrint(
      '📊 Firestore Logging aktiv - Nutze FirestoreLogger.printSummary() für Statistiken');

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
  static const rules = '/rules';
  static const dashboard = '/dashboard';
  static const adminUserTips = '/admin/user-tips/:userId';
  // Admin form pages
  static const adminMatchCreate = '/admin/match/create';
  static const adminMatchEdit = '/admin/match/edit/:id';
  static const adminMatchDelete = '/admin/match/delete/:id';
  static const adminUserCreate = '/admin/user/create';
  static const adminUserEdit = '/admin/user/edit/:id';
  static const adminTeamCreate = '/admin/team/create';
  static const adminTeamEdit = '/admin/team/edit/:id';
  static const adminTeamDelete = '/admin/team/delete/:id';
}

// ✅ FIX: Flag verhindert mehrfaches Dispatchen von Tip-Events
bool _tipBlocInitialized = false;
String? _tipBlocInitializedForUser;

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

          // ✅ Verwende BlocBuilder statt context.watch() um excessive Rebuilds zu vermeiden
          return BlocBuilder<AuthControllerBloc, AuthControllerState>(
            buildWhen: (previous, current) {
              // Nur rebuilden wenn signedInUser sich ändert (admin status, userId)
              if (previous is AuthControllerLoaded &&
                  current is AuthControllerLoaded) {
                return previous.signedInUser?.id != current.signedInUser?.id ||
                    previous.signedInUser?.admin != current.signedInUser?.admin;
              }
              return previous.runtimeType != current.runtimeType;
            },
            builder: (context, authControllerState) {
              bool isAdmin = false;
              String? userId;

              if (authControllerState is AuthControllerLoaded) {
                isAdmin = authControllerState.signedInUser?.admin ?? false;
                userId = authControllerState.signedInUser?.id;
              }

              // ✅ FIX: Reset flags und Bloc wenn nicht authentifiziert (Logout)
              if (!isAuthenticated && _tipBlocInitialized) {
                _tipBlocInitialized = false;
                _tipBlocInitializedForUser = null;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  debugPrint(
                      '🚪 [Main] Logout detected: Dispatching TipResetEvent');
                  context.read<TipControllerBloc>().add(TipResetEvent());
                });
              }

              // ✅ Initialisiere TipControllerBloc basierend auf User-Rolle
              // ✅ FIX: Dispatch bei User-Wechsel (neue userId)
              if (isAuthenticated &&
                  userId != null &&
                  (!_tipBlocInitialized ||
                      _tipBlocInitializedForUser != userId)) {
                _tipBlocInitialized = true;
                _tipBlocInitializedForUser = userId;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final tipBloc = context.read<TipControllerBloc>();

                  // ✅ FIX: Immer neu laden bei User-Wechsel (User-ID hat sich geändert)
                  if (isAdmin) {
                    debugPrint(
                        '👑 [Main] Admin: Dispatching TipAllEvent for user: $userId');
                    tipBloc.add(TipAllEvent());
                  } else {
                    debugPrint(
                        '👤 [Main] User: Dispatching TipLoadForUserEvent for user: $userId');
                    tipBloc.add(TipLoadForUserEvent(userId: userId!));
                  }
                });
              }
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: 'Shorty Tipp',
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
                            AppRoutes.rules: (_) => const MaterialPage(
                                child: RulesPage(isAuthenticated: true)),
                            AppRoutes.admin: (_) => isAdmin
                                ? const MaterialPage(
                                    child: AdminPage(isAuthenticated: true),
                                  )
                                : const MaterialPage(
                                    child: HomePage(isAuthenticated: true)),
                            AppRoutes.adminUserTips: (info) {
                              final userId = info.pathParameters['userId']!;
                              return MaterialPage(
                                child: AdminUserTipDetailsPage(
                                  isAuthenticated: true,
                                  selectedUserId: userId,
                                ),
                              );
                            },
                            // Admin Match Routes
                            AppRoutes.adminMatchCreate: (_) => isAdmin
                                ? const MaterialPage(
                                    child: AdminMatchFormPage(
                                        action: MatchFormAction.create))
                                : const Redirect(AppRoutes.home),
                            AppRoutes.adminMatchEdit: (info) {
                              final matchId = info.pathParameters['id']!;
                              return isAdmin
                                  ? MaterialPage(
                                      child: AdminMatchFormPage(
                                        action: MatchFormAction.update,
                                        matchId: matchId,
                                      ),
                                    )
                                  : const Redirect(AppRoutes.home);
                            },
                            AppRoutes.adminMatchDelete: (info) {
                              final matchId = info.pathParameters['id']!;
                              return isAdmin
                                  ? MaterialPage(
                                      child: AdminMatchDeletePage(
                                          matchId: matchId),
                                    )
                                  : const Redirect(AppRoutes.home);
                            },
                            // Admin User Routes
                            AppRoutes.adminUserCreate: (_) => isAdmin
                                ? const MaterialPage(
                                    child: AdminUserFormPage(
                                        action: UserFormAction.create))
                                : const Redirect(AppRoutes.home),
                            AppRoutes.adminUserEdit: (info) {
                              final userId = info.pathParameters['id']!;
                              return isAdmin
                                  ? MaterialPage(
                                      child: AdminUserFormPage(
                                        action: UserFormAction.update,
                                        userId: userId,
                                      ),
                                    )
                                  : const Redirect(AppRoutes.home);
                            },
                            // Admin Team Routes
                            AppRoutes.adminTeamCreate: (_) => isAdmin
                                ? const MaterialPage(
                                    child: AdminTeamFormPage(
                                        action: TeamFormAction.create))
                                : const Redirect(AppRoutes.home),
                            AppRoutes.adminTeamEdit: (info) {
                              final teamId = info.pathParameters['id']!;
                              return isAdmin
                                  ? MaterialPage(
                                      child: AdminTeamFormPage(
                                        action: TeamFormAction.update,
                                        teamId: teamId,
                                      ),
                                    )
                                  : const Redirect(AppRoutes.home);
                            },
                            AppRoutes.adminTeamDelete: (info) {
                              final teamId = info.pathParameters['id']!;
                              return isAdmin
                                  ? MaterialPage(
                                      child:
                                          AdminTeamDeletePage(teamId: teamId),
                                    )
                                  : const Redirect(AppRoutes.home);
                            },
                            AppRoutes.userProfile: (_) => const MaterialPage(
                                  child: UserProfilePage(isAuthenticated: true),
                                ),
                            AppRoutes.userTips: (info) {
                              // Unterstützt beide Parameter: scrollTo (alt) und returnIndex (neu)
                              final scrollToIndex =
                                  info.queryParameters['scrollTo'] ??
                                      info.queryParameters['returnIndex'];
                              final filter = info.queryParameters['filter'];

                              return MaterialPage(
                                child: TipPage(
                                  isAuthenticated: true,
                                  initialScrollIndex: scrollToIndex != null
                                      ? int.tryParse(scrollToIndex)
                                      : null,
                                  initialFilter: filter,
                                ),
                              );
                            },
                            AppRoutes.userTipsDetail: (info) {
                              final tipId = info.pathParameters['id']!;
                              final returnIndexString =
                                  info.queryParameters['returnIndex'];
                              final returnIndex = returnIndexString != null
                                  ? int.tryParse(returnIndexString)
                                  : null;
                              final returnFilter =
                                  info.queryParameters['filter'];

                              return MaterialPage(
                                child: TipDetailsPage(
                                  isAuthenticated: true,
                                  tipId: tipId,
                                  returnIndex: returnIndex,
                                  returnFilter: returnFilter,
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
                        AppRoutes.rules: (_) => const MaterialPage(
                              child: RulesPage(isAuthenticated: false),
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
            }, // Ende BlocBuilder<AuthControllerBloc> builder
          ); // Ende BlocBuilder<AuthControllerBloc>
        }, // Ende BlocBuilder<AuthBloc> builder
      ),
    );
  }
}
