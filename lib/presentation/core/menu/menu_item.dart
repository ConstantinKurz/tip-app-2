import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:routemaster/routemaster.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MenuItem extends StatelessWidget {
  final String text;
  final String path;
  final bool inDrawer;

  const MenuItem({
    super.key,
    required this.text,
    required this.inDrawer,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    bool isMobile = !kIsWeb &&
        (Theme.of(context).platform == TargetPlatform.android ||
            Theme.of(context).platform == TargetPlatform.iOS);

    return isMobile ? inkResponseWidget(context) : mouseRegionWidget(context);
  }

  bool _isActive(BuildContext context) {
    final currentRoutePath = Routemaster.of(context).currentRoute.path;
    if (path.isEmpty) return false;

    return currentRoutePath == path || currentRoutePath.startsWith('$path/');
  }

  Widget mouseRegionWidget(BuildContext context) {
    final themeData = Theme.of(context);
    final isActive = _isActive(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (path.isNotEmpty) {
            Routemaster.of(context).push(path);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: themeData.textTheme.headlineLarge!.copyWith(
              fontSize: 18,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
              color:
                  isActive ? themeData.colorScheme.onBackground : themeData.colorScheme.onBackground.withOpacity(0.7), 
            ),
          ),
        ),
      ),
    );
  }

  Widget inkResponseWidget(BuildContext context) {
    final themeData = Theme.of(context);
    final isActive = _isActive(context);

    return InkResponse(
      onTap: () {
        if (path.isNotEmpty) {
          Routemaster.of(context).push(path);
          Navigator.of(context).pop(); // Drawer schließen
        }
      },
      child: IntrinsicWidth(
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? Colors.white : primaryDark,
              width: isActive ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
            color: isActive
                ? Colors.white.withOpacity(0.2) // Highlight-Hintergrund
                : Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              text,
              style: themeData.textTheme.bodySmall!.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Colors.white
                    : themeData.textTheme.bodySmall!.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
