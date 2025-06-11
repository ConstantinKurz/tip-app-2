import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/presentation/signin/signin_page.dart';
import 'package:routemaster/routemaster.dart';

class SignOutButton extends StatelessWidget {
  final bool inDrawer;
  const SignOutButton({super.key, required this.inDrawer});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Dispatch the event to the AuthBloc
          context.read<AuthBloc>().add(SignOutPressedEvent());

          // Navigate to the sign-in page
          Routemaster.of(context).push(SignInPage.signinPagePath);
        },
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: themeData.appBarTheme.backgroundColor,
              border: Border.all(color: inDrawer ? Colors.white : primaryDark),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Sign Out",
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 15,
                  color: inDrawer ? textPrimaryLight : textPrimaryDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
