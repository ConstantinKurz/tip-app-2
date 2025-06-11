import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';

class EcoPage extends StatelessWidget {
  final bool isAuthenticated;
  static String ecoPagePath = "/ecosystem";
  
  const EcoPage({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return  PageTemplate(isAuthenticated: isAuthenticated,  child: const Placeholder(color: Colors.blue));
  }
}