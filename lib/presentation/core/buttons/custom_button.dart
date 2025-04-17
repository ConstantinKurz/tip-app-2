import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web/constants.dart';

class CustomButton extends StatefulWidget {
  final String buttonText;
  final Function callback;
  final Color? backgroundColor;
  final Color borderColor;
  final Color hoverColor;
  final double? width;

  const CustomButton({
    Key? key,
    required this.buttonText,
    required this.callback,
    this.backgroundColor,
    required this.borderColor,
    required this.hoverColor,
    this.width,
  }) : super(key: key);

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    bool isMobile = !kIsWeb &&
        (Theme.of(context).platform == TargetPlatform.android ||
            Theme.of(context).platform == TargetPlatform.iOS);

    return isMobile ? inkResponseWidget(context) : mouseRegionWidget(context);
  }

  Widget mouseRegionWidget(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          widget.callback();
        },
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            width: widget.width ?? 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered ? widget.hoverColor.withOpacity(0.8) : widget.backgroundColor,
              border: Border.all(color: widget.borderColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                widget.buttonText,
                style: const TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 15,
                  color: textPrimaryDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget inkResponseWidget(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.callback();
      },
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          width: widget.width ?? 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              "Sign Up",
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 15,
                color: textPrimaryLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
