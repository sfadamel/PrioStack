import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Logger centralisé PrioStack (Console + RingBuffer consultable en debug)
class AppLogger {
  static final List<String> _logHistory = [];

  static List<String> get history => List.unmodifiable(_logHistory);

  static void info(String message, {String tag = 'PrioStack'}) {
    final line = '[${DateTime.now().toIso8601String()}] [INFO] [$tag] $message';
    _record(line);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String tag = 'PrioStack',
  }) {
    final buffer = StringBuffer(
      '[${DateTime.now().toIso8601String()}] [ERROR] [$tag] $message',
    );
    if (error != null) buffer.write(' | Error: $error');
    if (stackTrace != null) buffer.write('\n$stackTrace');
    _record(buffer.toString(), isError: true);
  }

  static void _record(String line, {bool isError = false}) {
    _logHistory.add(line);
    if (_logHistory.length > 500) {
      _logHistory.removeAt(0);
    }
    debugPrint(line);
    developer.log(line, name: 'PrioStack', level: isError ? 1000 : 800);
  }
}
