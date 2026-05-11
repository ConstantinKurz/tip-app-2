import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String dialogText;
  final Widget content;
  final double width;
  final double height;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const CustomDialog({
    Key? key,
    required this.dialogText,
    required this.content,
    this.width = 300,
    this.height = 400,
    this.borderColor,
    this.borderWidth = 1,
    this.borderRadius = 12,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizing: Use provided dimensions or calculate from screen size
    final double dialogWidth = screenWidth < 600
        ? screenWidth * 0.85 // Mobile: 85% of screen width
        : width;

    final double dialogHeight = screenHeight < 700
        ? screenHeight * 0.70 // Mobile: 70% of screen height
        : height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 16 : 40,
        vertical: screenWidth < 600 ? 24 : 40,
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: dialogHeight,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ?? Colors.white,
            width: borderWidth,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(dialogText, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
