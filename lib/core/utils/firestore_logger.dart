import 'dart:io';

class FirestoreLogger {
  static int _readCount = 0;
  static final Map<String, int> _readsByCollection = {};
  static final List<String> _readLog = [];
  static File? _logFile;

  // ✅ NEU: Initialisiere Log-Datei beim Start
  static Future<void> initialize() async {
    try {
      // Nutze Project-Root statt App Documents
      final projectRoot = Directory.current;
      final logsDir = Directory('${projectRoot.path}/logs');

      if (!logsDir.existsSync()) {
        logsDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      _logFile = File('${logsDir.path}/firestore_$timestamp.log');

      await _logFile!.writeAsString('🔍 Firestore Logger started at ${DateTime.now()}\n');
      print('📝 Log-Datei erstellt: ${_logFile!.path}');
    } catch (e) {
      print('❌ Fehler beim Erstellen der Log-Datei: $e');
    }
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

    // ✅ NEU: Schreibe in lokale Datei
    try {
      if (_logFile != null) {
        await _logFile!.writeAsString('$logEntry\n', mode: FileMode.append);
      }
    } catch (e) {
      print('❌ Fehler beim Schreiben in Log-Datei: $e');
    }

    // Zeige Summary alle 50 Reads
    if (_readCount % 50 == 0) {
      await printSummary();
    }
  }

  static Future<void> printSummary() async {
    final summary = '''
📊 === FIRESTORE READ SUMMARY ===
Total Reads: $_readCount

Reads by Collection:
${_readsByCollection.entries.map((e) => '  ${e.key}: ${e.value} reads').join('\n')}
================================
''';

    print(summary);

    // ✅ NEU: Schreibe auch in Datei
    try {
      if (_logFile != null) {
        await _logFile!.writeAsString('$summary\n', mode: FileMode.append);
      }
    } catch (e) {
      print('❌ Fehler beim Schreiben in Log-Datei: $e');
    }
  }

  static Future<void> reset() async {
    _readCount = 0;
    _readsByCollection.clear();
    _readLog.clear();
    print('🔄 Firestore Logger Reset');

    try {
      if (_logFile != null) {
        await _logFile!.writeAsString('🔄 Logger Reset at ${DateTime.now()}\n',
            mode: FileMode.append);
      }
    } catch (e) {
      print('❌ Fehler beim Schreiben in Log-Datei: $e');
    }
  }

  static File? get logFile => _logFile;
  static List<String> getLog() => List.from(_readLog);
  static int get totalReads => _readCount;
  static Map<String, int> get readsByCollection => Map.from(_readsByCollection);
}
