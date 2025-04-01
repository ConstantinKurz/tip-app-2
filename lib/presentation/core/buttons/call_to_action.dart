import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CallToAction extends StatelessWidget {
  final Function callBack;
  final String text;

  const CallToAction({super.key, required this.text, required this.callBack});

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
        onTap: () => callBack(),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicWidth(
            child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: themeData.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    text,
                    style: themeData.textTheme.headlineLarge!.copyWith(
                        fontSize: 14,
                        color: Colors.blueGrey[800],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4),
                  ),

                )),
          ),
        ),
      ),
    );
  }

  Widget inkResponseWidget(BuildContext context) {
    final themeData = Theme.of(context);
    return InkResponse(
      onTap: () {
        callBack();
      },
      child: IntrinsicWidth(
        child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: primaryDark),
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                text,
                style: const TextStyle(
                    fontFamily: fontFamily, fontSize: 15, color: primaryDark),
              ),
            )),
      ),
    );
  }
}
