import 'dart:convert';
import 'package:web/web.dart' as web;

class FirestoreLogger {
  static int _readCount = 0;
  static final Map<String, int> _readsByCollection = {};
  static final List<String> _readLog = [];
  static const String _storageKey = 'firestore_logs';

  static Future<void> initialize() async {
    print('📝 Firestore Logger initialized');
    _loadFromLocalStorage();
  }

  static Future<void> logRead(
    String collection,
    String operation, {
    String? docId,
  }) async {
    _readCount++;
    _readsByCollection[collection] = (_readsByCollection[collection] ?? 0) + 1;

    final timestamp = DateTime.now().toIso8601String();
    final logEntry =
        '[$timestamp] READ #$_readCount: $collection.$operation${docId != null ? ' ($docId)' : ''}';

    _readLog.add(logEntry);
    print('🔍 $logEntry');
    
    // ✅ Speichere in Local Storage
    _saveToLocalStorage();

    if (_readCount % 50 == 0) {
      await printSummary();
    }
  }

  /// Speichert Logs in Local Storage
  static void _saveToLocalStorage() {
    try {
      final data = {
        'readCount': _readCount,
        'readsByCollection': _readsByCollection,
        'readLog': _readLog,
      };
      final jsonString = jsonEncode(data);
      web.window.localStorage.setItem(_storageKey, jsonString);
    } catch (e) {
      print('⚠️ Fehler beim Speichern: $e');
    }
  }

  /// Lädt Logs aus Local Storage
  static void _loadFromLocalStorage() {
    try {
      final stored = web.window.localStorage.getItem(_storageKey);
      if (stored != null) {
        final decoded = jsonDecode(stored) as Map<String, dynamic>;
        _readCount = decoded['readCount'] ?? 0;
        _readsByCollection.clear();
        (decoded['readsByCollection'] as Map<String, dynamic>).forEach((k, v) {
          _readsByCollection[k] = v as int;
        });
        _readLog.clear();
        _readLog.addAll((decoded['readLog'] as List).cast<String>());
      }
    } catch (e) {
      print('⚠️ Fehler beim Laden: $e');
    }
  }

  static Future<void> printSummary() async {
    final summary = '''
╔════════════════════════════════════════╗
║  📊 === FIRESTORE READ SUMMARY ===     ║
║  Total Reads: $_readCount              ║
║                                        ║
║  Reads by Collection:                  ║
${_readsByCollection.entries.map((e) => '║    ${e.key}: ${e.value} reads').join('\n')}
║                                        ║
╚════════════════════════════════════════╝
''';
    print(summary);
  }

  /// Exportiert Logs als Download
  static void exportLogsAsFile() {
    final logContent = _readLog.join('\n');
    
    // Konvertiere zu Base64 data URL
    final base64Content = base64Encode(utf8.encode(logContent));
    final dataUrl = 'data:text/plain;base64,$base64Content';
    
    final anchor = web.HTMLAnchorElement()
      ..href = dataUrl
      ..download = 'firestore_logs_${DateTime.now().toIso8601String()}.txt';
    
    anchor.click();
    print('✅ Logs als .txt exportiert');
  }

  static Future<void> reset() async {
    _readCount = 0;
    _readsByCollection.clear();
    _readLog.clear();
    web.window.localStorage.removeItem(_storageKey);
    print('🔄 Firestore Logger Reset');
  }

  static List<String> getLog() => List.from(_readLog);
}
