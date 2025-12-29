import 'package:flutter/material.dart';
import 'package:flutter_web/theme.dart';

// Simple helper for creating test apps without complex BLoC mocking

/// Creates a minimal test app wrapper for simple widget tests
Widget createTestApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: child),
  );
}