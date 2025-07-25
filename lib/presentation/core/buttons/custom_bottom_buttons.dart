import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

class ButtonConfig {
  final String label;
  final String route;
  final IconData icon;
  final ButtonStyle? style;

  ButtonConfig({
    required this.label,
    required this.route,
    required this.icon,
    this.style,
  });
}

class CustomBottomButtons extends StatelessWidget {
  final List<ButtonConfig> buttons;

  const CustomBottomButtons({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double buttonWidth = (screenWidth * 0.5 - 200) / buttons.length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.25, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: buttons.map((btn) {
          return SizedBox(
            width: buttonWidth,
            child: ElevatedButton.icon(
              onPressed: () {
                Routemaster.of(context).push(btn.route);
              },
              icon: Icon(btn.icon),
              label: Text(btn.label, overflow: TextOverflow.ellipsis),
              style: btn.style,
            ),
          );
        }).toList(),
      ),
    );
  }
}
