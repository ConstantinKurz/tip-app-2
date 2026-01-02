import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test helper class to set up Firebase for unit tests
class FirebaseTestHelper {
  static bool _isInitialized = false;

  /// Initialize Firebase for testing
  static Future<void> initializeFirebase() async {
    if (_isInitialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Setup Firebase Test environment
    setupFirebaseCoreMocks();

    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: 'test-sender-id',
          projectId: 'test-project-id',
        ),
      );
      _isInitialized = true;
    } catch (e) {
      // Firebase might already be initialized
      _isInitialized = true;
    }
  }
}

// Mock setup for Firebase
void setupFirebaseCoreMocks([Iterable<String>? extraApps]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_core'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'Firebase#initializeCore') {
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'test-api-key',
              'appId': 'test-app-id',
              'messagingSenderId': 'test-sender-id',
              'projectId': 'test-project-id',
            },
            'pluginConstants': {},
          }
        ];
      }
      return null;
    },
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/cloud_firestore'),
    (MethodCall methodCall) async {
      return null;
    },
  );
}