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
          ..src = 'WM2026%20onlineRegeln.pdf#view=FitH'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..setAttribute('scrolling', 'yes');
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return PageTemplate(
      isAuthenticated: widget.isAuthenticated,
      child: isMobile
          ? _buildMobileView(context)
          : SizedBox.expand(
              child: HtmlElementView(viewType: _viewType),
            ),
    );
  }

  Widget _buildMobileView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'WM 2026 Regeln',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tippe auf den Button, um das vollständige PDF mit allen Seiten zu öffnen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              html.window.open('WM2026%20onlineRegeln.pdf', '_blank');
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('PDF öffnen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
