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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Shorty Tipp',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 24,
              fontWeight: _isActive(context) ? FontWeight.w900 : FontWeight.bold,
              color: _isActive(context) 
                  ? Theme.of(context).colorScheme.onBackground
                  : Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  bool _isActive(BuildContext context) {
    final currentRoutePath = Routemaster.of(context).currentRoute.path;
    return currentRoutePath == '/' || currentRoutePath == HomePage.homePagePath;
  }
}
