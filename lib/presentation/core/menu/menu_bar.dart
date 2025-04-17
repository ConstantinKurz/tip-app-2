import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/core/buttons/signin_button.dart';
import 'package:flutter_web/presentation/core/buttons/signup_button.dart';
import 'package:flutter_web/presentation/core/menu/home_logo.dart';
import 'package:flutter_web/presentation/core/menu/menu_item.dart';
import 'package:flutter_web/presentation/dev_page/dev_page.dart';
import 'package:flutter_web/presentation/eco_page/eco_page.dart';
import 'package:flutter_web/presentation/tip_page/tip_page.dart';

class MyMenuBar extends StatelessWidget {
  const MyMenuBar({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Container(
        height: 66,
        width: double.infinity,
        decoration: BoxDecoration(
            color: themeData.colorScheme.primaryContainer,),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const HomeLogo(),
            const MenuItem(text: "Docs", inDrawer: false, path: ""),
            // MenuItem(text: "Tipp", inDrawer: false, path: TipPage.tipPagePath),
            MenuItem(
                text: "Development",
                inDrawer: false,
                path: DevPage.devPagePath),
            MenuItem(
                text: "Ecosystem", inDrawer: false, path: EcoPage.ecoPagePath),
            const Spacer(),
            const SignInButton(inDrawer: false),
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
