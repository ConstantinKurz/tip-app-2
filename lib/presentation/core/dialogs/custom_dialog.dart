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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ?? Colors.white,
            width: borderWidth,
          ),
          // boxShadow: boxShadow ??
          //     [
          //       BoxShadow(
          //         color: Colors.black.withOpacity(0.5),
          //         blurRadius: 20,
          //         offset: const Offset(0, 10),
          //       ),
          //     ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(dialogText, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            SizedBox(
              width: width,
              height: height,
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}
