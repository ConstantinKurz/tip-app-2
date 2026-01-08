import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/presentation/core/menu/home_logo.dart';
import 'package:flutter_web/presentation/core/menu/menu_item.dart';

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
              SingleChildScrollView(
                child: Column(
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
                    const MenuItem(text: "Admin", inDrawer: true, path: "/admin"),
                    const SizedBox(
                      height: 20,
                    ),
                    const MenuItem(text: "Showcase", inDrawer: true, path: ""),
                    const SizedBox(
                      height: 20,
                    )
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
