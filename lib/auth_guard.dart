import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/presentation/signin/signin_page.dart';
import 'package:routemaster/routemaster.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateUnAuthenticated) {
          Routemaster.of(context).push(SignInPage.signinPagePath);
        }
      },
      // blocbuilder needed here to conditionally rebuild widget tree.
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthStateAuthenticated) {
            return child;
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
