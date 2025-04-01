import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/presentation/signin/signin_page.dart';
import 'package:routemaster/routemaster.dart';

class SignInButton extends StatelessWidget {
  final bool inDrawer;
  const SignInButton({super.key, required this.inDrawer});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
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
                  border:
                      Border.all(color: inDrawer ? Colors.white : primaryDark),
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Sign In",
                  style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 15,
                      color: inDrawer ? textPrimaryLight : textPrimaryDark),
                ),
              )),
        ),
      ),
    );
  }
}
