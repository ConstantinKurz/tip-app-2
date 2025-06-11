import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';

class DevPage extends StatelessWidget {
    static String devPagePath = "/development";
    final bool isAuthenticated;
  const DevPage({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return  PageTemplate(isAuthenticated: isAuthenticated,child: const Placeholder(),);
  }
}