// champion_star_icon.dart
import 'package:flutter/material.dart';

class StarIconButton extends StatefulWidget {
  final bool isStar;
  final VoidCallback onTap;
  final double size;
  final String? tooltipMessage;

  const StarIconButton({
    Key? key,
    required this.isStar,
    required this.onTap,
    this.size = 30.0,
    this.tooltipMessage,
  }) : super(key: key);

  @override
  State<StarIconButton> createState() => _StarIconButtonState();
}

class _StarIconButtonState extends State<StarIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isStar;
    final Color iconColor = isActive 
        ? Colors.amber 
        : (_isHovered ? Colors.amber.withOpacity(0.6) : Colors.grey);
    final Color? backgroundColor = _isHovered 
        ? (isActive ? Colors.amber.withOpacity(0.15) : Colors.grey.withOpacity(0.1))
        : null;

    Widget iconWidget = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.star,
            color: iconColor,
            size: widget.size,
          ),
        ),
      ),
    );

    if (widget.tooltipMessage != null) {
      return Tooltip(
        message: widget.tooltipMessage!,
        child: iconWidget,
      );
    }

    return iconWidget;
  }
}
