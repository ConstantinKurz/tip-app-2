import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/admin_page/admin_page.dart';
import 'package:flutter_web/presentation/core/buttons/signin_button.dart';
import 'package:flutter_web/presentation/core/buttons/signout_button.dart';
import 'package:flutter_web/presentation/core/buttons/signup_button.dart';
import 'package:flutter_web/presentation/core/menu/home_logo.dart';
import 'package:flutter_web/presentation/core/menu/menu_item.dart';
import 'package:flutter_web/presentation/dev_page/dev_page.dart';
import 'package:flutter_web/presentation/eco_page/eco_page.dart';

class MyMenuBar extends StatelessWidget {
  final bool isAuthenticated;
  const MyMenuBar({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    print(isAuthenticated);
    return Container(
        height: 66,
        width: double.infinity,
        decoration: BoxDecoration(
            color: themeData.colorScheme.primaryContainer,),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const HomeLogo(),
            MenuItem(text: "Admin", inDrawer: false, path: AdminPage.adminPagePath),
            // MenuItem(text: "Tipp", inDrawer: false, path: TipPage.tipPagePath),
            MenuItem(
                text: "Development",
                inDrawer: false,
                path: DevPage.devPagePath),
            MenuItem(
                text: "Ecosystem", inDrawer: false, path: EcoPage.ecoPagePath),
            const Spacer(),
            isAuthenticated? const SignOutButton(inDrawer: false) : const SignInButton(inDrawer: false,),
            const SizedBox(
              width: 10,
            ),
            const SignUpButton(
              inDrawer: false,
            ),
          ],
        ));
  }
}
