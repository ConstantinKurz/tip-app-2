import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/constants.dart';

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
  static const String _pdfPath = 'WM2026%20onlineRegeln.pdf';

  final String _viewType =
      'pdf-viewer-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = '$_pdfPath#view=FitH'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..setAttribute('scrolling', 'yes');

        return iframe;
      },
    );
  }

  void _openPdfInNewTab() {
    html.window.open(_pdfPath, '_blank');
  }

  bool _isMobileOrTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 1280;
  }

  @override
  Widget build(BuildContext context) {
    final isMobileOrTablet = _isMobileOrTablet(context);

    return PageTemplate(
      isAuthenticated: widget.isAuthenticated,
      child: isMobileOrTablet
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ElevatedButton.icon(
                  onPressed: _openPdfInNewTab,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('PDF öffnen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            )
          : SizedBox.expand(
              child: HtmlElementView(viewType: _viewType),
            ),
    );
  }
}
