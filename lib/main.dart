import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/auth_guard.dart';
import 'package:flutter_web/firebase_options.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/dev_page/dev_page.dart';
import 'package:flutter_web/presentation/eco_page/eco_page.dart';
import 'package:flutter_web/presentation/home_page/home_page.dart';
import 'package:flutter_web/presentation/not_found_page/no_found_page.dart';
import 'package:flutter_web/presentation/signin/signin_page.dart';
import 'package:flutter_web/presentation/signup/signup_page.dart';
import 'package:flutter_web/presentation/splash_page/splash_page.dart';
import 'package:flutter_web/theme.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_strategy/url_strategy.dart';
import 'injections.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setPathUrlStrategy();
  await di.init();
  runApp(const MyApp());
}

final routes = RouteMap(
    onUnknownRoute: (route) {
      return const MaterialPage(child: NotFoundPage());
    },
    routes: {
      '/': (_) => Redirect(SplashPage.splashPagePath),
      HomePage.homePagePath: (_) => const MaterialPage(
        child: AuthGuard(child: HomePage())
          ),
      // TipPage.tipPagePath: (_) => const MaterialPage(child: TipPage()),
      SignUpPage.signupPagePath: (_) => const MaterialPage(child: SignUpPage()),
      SignInPage.signinPagePath: (_) => const MaterialPage(child: SignInPage()),
      SplashPage.splashPagePath: (_) => const MaterialPage(child: SplashPage()),
      DevPage.devPagePath: (_) => const MaterialPage(child: DevPage()),
      EcoPage.ecoPagePath: (_) => const MaterialPage(child: EcoPage()),
      DevPage.devPagePath + '/plattform/:id': (info) {
        if (info.pathParameters['id'] == 'android')
          return const MaterialPage(child: Placeholder(color: Colors.pink));
        if (info.pathParameters['id'] == 'ios')
          return const MaterialPage(child: Placeholder(color: Colors.teal));
        return Redirect(DevPage.devPagePath);
      }
    });

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // add.. => check at start of webpage if user is already signed in
        BlocProvider(
          create: (context) => sl<AuthBloc>()..add(AuthCheckRequestedEvent()),
        ),
        // Add other BlocProviders here if needed
      ],
      child: MaterialApp.router(
        routeInformationParser: const RoutemasterParser(),
        routerDelegate: RoutemasterDelegate(routesBuilder: (context) => routes),
        debugShowCheckedModeBanner: false,
        title: 'Flutter Web',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
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
          backgroundColor: Colors.blue
        ),
      ),
    );
  }

}

