import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';

class DevPage extends StatelessWidget {
    static String devPagePath = "/development";
  const DevPage({super.key});

  @override
  Widget build(BuildContext context) {
    return  const PageTemplate(child: Placeholder());
  }
}