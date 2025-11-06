import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/home_page/home_page.dart';
import 'package:routemaster/routemaster.dart';

class HomeLogo extends StatelessWidget {
  const HomeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Routemaster.of(context).push(HomePage.homePagePath);
        },
        child: Image.asset(
          "assets/images/flutter_logo_text.png",
          height: 27,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
