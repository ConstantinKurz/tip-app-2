import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/core/menu/home_logo.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return AppBar(
      backgroundColor: themeData.appBarTheme.backgroundColor,
      title: const Row(children: [HomeLogo()]),
    );
  }
}
