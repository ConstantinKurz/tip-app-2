import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CustomButton extends StatelessWidget {
  final String buttonText;
  final Function callback;
  final Color? backgroundColor; // Optionaler Parameter für die Hintergrundfarbe

  const CustomButton({
    Key? key,
    required this.buttonText,
    required this.callback,
    this.backgroundColor, // Füge den backgroundColor-Parameter hinzu
  }) : super(key: key);

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
        onTap: () => callback(),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(20),
          color: backgroundColor,
          child: IntrinsicWidth(
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: backgroundColor ?? themeData.colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  buttonText,
                  style: themeData.textTheme.headlineLarge!.copyWith(
                    fontSize: 14,
                    color: Colors.blueGrey[800],
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget inkResponseWidget(BuildContext context) {
    final themeData = Theme.of(context);
    return InkResponse(
      onTap: () {
        callback();
      },
      child: Container(
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor ?? themeData.colorScheme.secondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            buttonText,
            style: themeData.textTheme.headlineLarge!.copyWith(
              fontSize: 14,
              color: Colors.blueGrey[800],
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }
}
