import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/firebase_options.dart';
import 'package:flutter_web/injections.dart' as di;
import 'package:flutter_web/presentation/dev_page/dev_page.dart';
import 'package:flutter_web/presentation/eco_page/eco_page.dart';
import 'package:flutter_web/presentation/home_page/home_page.dart';
import 'package:flutter_web/presentation/not_found_page/no_found_page.dart';
import 'package:flutter_web/presentation/signin/signin_page.dart';
import 'package:flutter_web/presentation/signup/signup_page.dart';
import 'package:flutter_web/presentation/splash_page/splash_page.dart';
import 'package:flutter_web/presentation/tip_page/tip_page.dart';
import 'package:flutter_web/theme.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_strategy/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setPathUrlStrategy();
  await di.init();
  runApp(const MyApp());
}

class AppRoutes {
  static const splash = '/splash';
  static const signin = '/signin';
  static const signup = '/signup';
  static const home = '/home';
  static const dev = '/dev';
  static const eco = '/eco';
  static const platform = '/dev/plattform/:id';
  static const userTips = '/tips/:id';
}

Page authGuard({
  required bool isAuthenticated,
  required Widget page,
  String redirectTo = AppRoutes.signin,
}) {
  return isAuthenticated ? MaterialPage(child: page) : Redirect(redirectTo);
}

Page signedInGuard({ 
  required bool isAuthenticated,
  required Widget page,
  //TODO: Add signout page here
  String redirectTo = AppRoutes.home,
}) {
  return isAuthenticated ? Redirect(redirectTo) : MaterialPage(child: page);
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
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Web',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routeInformationParser: const RoutemasterParser(),
        routerDelegate: RoutemasterDelegate(
          routesBuilder: (context) {
            final authState = context.watch<AuthBloc>().state;
            final isAuthenticated = authState is AuthStateUnAuthenticated;

            return RouteMap(
              onUnknownRoute: (_) => const MaterialPage(child: NotFoundPage()),
              routes: {
                '/': (_) => Redirect(AppRoutes.splash),
                AppRoutes.splash: (_) =>
                    const MaterialPage(child: SplashPage()),
                AppRoutes.signin: (_) => signedInGuard(
                    isAuthenticated: isAuthenticated, page: const SignInPage()),
                AppRoutes.signup: (_) =>
                    const MaterialPage(child: SignUpPage()),
                AppRoutes.home: (_) => authGuard(
                      isAuthenticated: isAuthenticated,
                      page: HomePage(),
                    ),
                AppRoutes.dev: (_) => authGuard(
                      isAuthenticated: isAuthenticated,
                      page: const DevPage(),
                    ),
                AppRoutes.eco: (_) => authGuard(
                      isAuthenticated: isAuthenticated,
                      page: const EcoPage(),
                    ),
                AppRoutes.userTips: (info) {
                  final userId = info.pathParameters['id'];
                  return MaterialPage(child: TipPage(userId: userId!));
                },
                AppRoutes.platform: (info) {
                  if (!isAuthenticated) {
                    return const Redirect(AppRoutes.signin);
                  }

                  final id = info.pathParameters['id'];
                  if (id == 'android') {
                    return const MaterialPage(
                        child: Placeholder(color: Colors.pink));
                  }
                  if (id == 'ios') {
                    return const MaterialPage(
                        child: Placeholder(color: Colors.teal));
                  }

                  return Redirect(AppRoutes.dev);
                },
              },
            );
          },
        ),
        builder: (context, widget) => ResponsiveWrapper.builder(
          widget,
          defaultScale: true,
          minWidth: 400,
          defaultName: MOBILE,
          breakpoints: const [
            ResponsiveBreakpoint.autoScale(450, name: MOBILE),
            ResponsiveBreakpoint.resize(600, name: TABLET),
            ResponsiveBreakpoint.resize(1000, name: DESKTOP),
          ],
          background: Container(color: Colors.blue),
        ),
      ),
    );
  }
}
