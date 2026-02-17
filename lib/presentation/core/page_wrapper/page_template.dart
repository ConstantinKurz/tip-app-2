import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/core/menu/app_bar.dart';
import 'package:flutter_web/presentation/core/menu/drawer.dart';
import 'package:flutter_web/presentation/core/menu/menu_bar.dart';
import 'package:responsive_framework/responsive_framework.dart';

class PageTemplate extends StatelessWidget {
  final bool isAuthenticated;
  final Widget child;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const PageTemplate({
    super.key,
    required this.child,
    required this.isAuthenticated,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final responsiveValue = ResponsiveWrapper.of(context);
    return Scaffold(
      endDrawer: const CustomDrawer(),
      backgroundColor: themeData.scaffoldBackgroundColor,
      appBar: responsiveValue.isSmallerThan(DESKTOP)
          ? const PreferredSize(
              preferredSize: Size(double.infinity, 60), child: CustomAppBar())
          : PreferredSize(
              preferredSize: const Size(double.infinity, 66),
              child: MyMenuBar(isAuthenticated: isAuthenticated),
            ),
      body: child,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
