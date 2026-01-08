import 'package:flutter/material.dart';

class HoverLinkButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData icon;

  const HoverLinkButton({
    Key? key,
    required this.label,
    required this.onTap,
    required this.color,
    this.icon = Icons.chevron_right,
  }) : super(key: key);

  @override
  State<HoverLinkButton> createState() => _HoverLinkButtonState();
}

class _HoverLinkButtonState extends State<HoverLinkButton> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {},
      onExit: (_) {},
      child: InkWell(
        onTap: widget.onTap,
        child: Row(
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.color
                    // decoration: _isHovered
                    //     ? TextDecoration.underline
                    //     : TextDecoration.none,
                    // decorationColor:
                    //     _isHovered ? widget.color : widget.color.withOpacity(.5)),
                  ),
            ),
            Icon(
              widget.icon,
              size: 20,
              color: widget.color,
            ),
          ],
        ),
      ),
    );
  }
}
