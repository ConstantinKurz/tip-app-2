import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/home_page/home_page.dart';
import 'package:routemaster/routemaster.dart';

class HomeLogo extends StatelessWidget {
  const HomeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Routemaster.of(context).push(HomePage.homePagePath);
        },
        child: Container(
          padding: isMobile
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Shorty Tipp',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight:
                      _isActive(context) ? FontWeight.w900 : FontWeight.bold,
                  color: _isActive(context)
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                  overflow: TextOverflow.ellipsis,
                ),
          ),
        ),
      ),
    );
  }

  bool _isActive(BuildContext context) {
    try {
      final currentRoutePath = Routemaster.of(context).currentRoute.path;
      return currentRoutePath == '/' ||
          currentRoutePath == HomePage.homePagePath;
    } catch (_) {
      return false;
    }
  }
}
