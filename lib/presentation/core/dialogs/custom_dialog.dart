import 'package:flutter/material.dart';

class CustomDialog extends StatefulWidget {
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
  State<CustomDialog> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  late double _dialogWidth;
  late double _dialogHeight;
  late double _horizontalPadding;
  late double _verticalPadding;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Nur beim ersten Mal berechnen, nicht wenn Tastatur erscheint
    if (!_initialized) {
      _initialized = true;
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      _dialogWidth = screenWidth < 600 ? screenWidth * 0.85 : widget.width;

      _dialogHeight = screenHeight < 700 ? screenHeight * 0.70 : widget.height;

      _horizontalPadding = screenWidth < 600 ? 16 : 40;
      _verticalPadding = screenWidth < 600 ? 24 : 40;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: _verticalPadding,
      ),
      child: Container(
        width: _dialogWidth,
        constraints: BoxConstraints(
          maxHeight: _dialogHeight,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.borderColor ?? Colors.white,
            width: widget.borderWidth,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.dialogText,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: widget.content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
