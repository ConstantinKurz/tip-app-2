import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/presentation/core/buttons/call_to_action.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:routemaster/routemaster.dart';

import '../home_page/home_page.dart';

class NotFoundPage extends StatelessWidget {
  final bool isAuthenticated;
  const NotFoundPage({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageTemplate(
      isAuthenticated: isAuthenticated,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Sorry, we couldn't find the page you are looking for!",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                Text("Oops, you seem to be lost",
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: 20),
                Text("404", style: theme.textTheme.displayLarge),
                const SizedBox(height: 20),
                ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 300,
                    ),
                    child: Image.asset("assets/images/mixer.png")),
                const SizedBox(height: 20),
                Text("But maybe you find help starting from the homepage",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: 20),
                CallToAction(
                  text: "Back to Homepage",
                  callBack: () {
                    Routemaster.of(context).push(HomePage.homePagePath);
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
