import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/presentation/core/buttons/signup_button.dart';
import 'package:flutter_web/presentation/core/menu/home_logo.dart';
import 'package:flutter_web/presentation/core/menu/menu_item.dart';
import 'package:flutter_web/presentation/dev_page/dev_page.dart';
import 'package:flutter_web/presentation/eco_page/eco_page.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: primaryDark,
      child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const HomeLogo(),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close,
                            color: textPrimaryDark, size: 18),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  const MenuItem(
                    text: "Admin",
                    inDrawer: true,
                    path: "/admin"
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const MenuItem(
                    text: "Showcase",
                    inDrawer: true,
                    path: ""
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  MenuItem(
                    text: "Development",
                    inDrawer: true,
                    path: DevPage.devPagePath
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  MenuItem(
                    text: "Ecosystem",
                    inDrawer: true,
                    path: EcoPage.ecoPagePath
                  ),
                ],
              ),
              const Column(
                children: [
                  Spacer(),
                  SignUpButton(inDrawer: true,),
                  SizedBox(
                    height: 20,
                  )
                ],
              )
            ],
          )),
    );
  }
}
