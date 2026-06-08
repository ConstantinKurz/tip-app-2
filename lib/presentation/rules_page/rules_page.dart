import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';

class RulesPage extends StatefulWidget {
  static const String rulesPagePath = "/rules";
  final bool isAuthenticated;

  const RulesPage({
    Key? key,
    required this.isAuthenticated,
  }) : super(key: key);

  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> {
  final String _viewType =
      'pdf-viewer-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    // Registriere den iframe als Platform View
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'WM2026%20onlineRegeln.pdf'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.overflow = 'auto'
          ..style.display = 'block'
          ..setAttribute('scrolling', 'auto')
          ..setAttribute('allowFullscreen', 'true')
          ..setAttribute('sandbox', 'allow-same-origin');
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      isAuthenticated: widget.isAuthenticated,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            child: HtmlElementView(viewType: _viewType),
          );
        },
      ),
    );
  }
}
