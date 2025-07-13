import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/home_page/home_page.dart';
import 'package:flutter_web/presentation/signin/signin_page.dart';
import 'package:routemaster/routemaster.dart';

class SplashPage extends StatelessWidget {
  static String splashPagePath = "/splash";
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateAuthenticated) {
          Routemaster.of(context).push(HomePage.homePagePath);
        } else if (state is AuthStateUnAuthenticated) {
          Routemaster.of(context).push(SignInPage.signinPagePath);
        }
      },
      child: Scaffold(
        body: PageTemplate(
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
}
