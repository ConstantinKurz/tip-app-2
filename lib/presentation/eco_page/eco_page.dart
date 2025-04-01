import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';

class EcoPage extends StatelessWidget {
  static String ecoPagePath = "/ecosystem";
  const EcoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return  const PageTemplate(child: Placeholder(color: Colors.blue));
  }
}