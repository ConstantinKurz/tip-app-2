import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/presentation/signup/signup_page.dart';
import 'package:routemaster/routemaster.dart';

class SignUpButton extends StatelessWidget {
  final bool inDrawer;
  const SignUpButton({super.key, required this.inDrawer});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Routemaster.of(context).push(SignUpPage.signupPagePath);
        },
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(20),
          child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: inDrawer ? Colors.white : primaryDark, borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Sign Up",
                  style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 15,
                      color: inDrawer ?  textPrimaryLight : textPrimaryDark),
                ),
              )),
        ),
      ),
    );
  }
}
