import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/core/menu/app_bar.dart';
import 'package:flutter_web/presentation/core/menu/drawer.dart';
import 'package:flutter_web/presentation/core/menu/menu_bar.dart';
import 'package:responsive_framework/responsive_framework.dart';

// Custom animator without animation for instant show/hide
class _NoAnimationFloatingActionButtonAnimator
    extends FloatingActionButtonAnimator {
  @override
  Offset getOffset(
      {required Offset begin, required Offset end, required double progress}) {
    return progress < 1.0 ? begin : end;
  }

  @override
  Animation<double> getRotationAnimation({required Animation<double> parent}) {
    return Tween<double>(begin: 1.0, end: 1.0).animate(parent);
  }

  @override
  Animation<double> getScaleAnimation({required Animation<double> parent}) {
    return Tween<double>(begin: 1.0, end: 1.0).animate(parent);
  }
}

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
      backgroundColor: themeData.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, 80),
        child: MyMenuBar(isAuthenticated: isAuthenticated),
      ),
      body: child,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: _NoAnimationFloatingActionButtonAnimator(),
    );
  }
}
