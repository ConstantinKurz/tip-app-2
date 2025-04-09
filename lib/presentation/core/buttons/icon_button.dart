import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web/constants.dart';

class FancyIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback callback;
  final Color backgroundColor;
  final Color hoverColor;
  final Color borderColor;

  const FancyIconButton({
    Key? key,
    required this.icon,
    required this.callback,
    required this.backgroundColor,
    required this.hoverColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  _FancyIconButtonState createState() => _FancyIconButtonState();
}

class _FancyIconButtonState extends State<FancyIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.callback,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor.withOpacity(0.8) : widget.backgroundColor,
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            widget.icon,
            color: _isHovered ? Colors.white : widget.borderColor,
          ),
        ),
      ),
    );
  }
}
