import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/presentation/core/buttons/call_to_action.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:routemaster/routemaster.dart';

import '../core/page_wrapper/centered_constrained_wrapper.dart';
import '../home_page/home_page.dart';

class NotFoundPage extends StatelessWidget {
  final bool isAuthenticated;
  const NotFoundPage({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      isAuthenticated: isAuthenticated,
        child: ListView(children: [
      CenterConstrainedWrapper(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                  "Sorry, we couldn't find the page you are looking for!",
                  style: TextStyle(
                      fontFamily: fontFamily,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
              const SizedBox(
                height: 20,
              ),
              const Text("404",
                  style: TextStyle(
                      fontFamily: fontFamily,
                      fontWeight: FontWeight.bold,
                      height: .9,
                      fontSize: 60)),
              const SizedBox(
                height: 20,
              ),
              ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 300,
                  ),
                  child: Image.asset("assets/images/mixer.png")),
              const SizedBox(
                height: 20,
              ),
              const Text("But maybe you find help starting from the homepage",
                  style: TextStyle(
                      fontFamily: fontFamily,
                      fontWeight: FontWeight.bold,
                      height: .9,
                      fontSize: 20)),
              const SizedBox(
                height: 20,
              ),
              CallToAction(
                text: "Back to Homepage",
                callBack: () {
                  Routemaster.of(context).push(HomePage.homePagePath);
                },
              )
            ],
          ),
        ),
      )
    ]));
  }
}
