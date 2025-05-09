// champion_star_icon.dart
import 'package:flutter/material.dart';

class StarIconButton extends StatelessWidget {
  final bool isStar;
  final VoidCallback onTap;
  final double size;
  final String? tooltipMessage;

  const StarIconButton({
    Key? key,
    required this.isStar,
    required this.onTap,
    this.size = 30.0, // Standardgröße
    this.tooltipMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
  
    Widget iconWidget = InkWell(
      onTap: onTap,
      child: Icon(
        Icons.star,
        color: isStar ? Colors.amber : Colors.grey,
        size: size,
      ),
    );

    if (tooltipMessage != null) {
      return Tooltip(
        message: tooltipMessage!,
        child: iconWidget,
      );
    }

    return iconWidget;
  }
}
