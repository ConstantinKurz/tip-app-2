import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/theme.dart';
import 'package:routemaster/routemaster.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MenuItem extends StatelessWidget {
  final String text;
  final String path;
  final bool inDrawer;
  const MenuItem(
      {super.key,
      required this.text,
      required this.inDrawer,
      required this.path});

  @override
  Widget build(BuildContext context) {
    bool isMobile = !kIsWeb &&
        (Theme.of(context).platform == TargetPlatform.android ||
            Theme.of(context).platform == TargetPlatform.iOS);

    return isMobile ? inkResponseWidget(context) : mouseRegionWidget(context);
  }

  Widget mouseRegionWidget(BuildContext context) {
    final themeData = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Routemaster.of(context).push(path);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: themeData.textTheme.headlineLarge!.copyWith(
                fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 4),
          ),
        ),
      ),
    );
  }

  Widget inkResponseWidget(BuildContext context) {
    final themeData = Theme.of(context);
    return InkResponse(
      onTap: () {
        Routemaster.of(context).push(path);
      },
      child: IntrinsicWidth(
          child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            border: Border.all(color: primaryDark),
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            text,
            style: themeData.textTheme.bodySmall,
          ),
        ),
      )),
    );
  }
}
