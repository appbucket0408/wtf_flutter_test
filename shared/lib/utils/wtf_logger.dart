import 'package:flutter/foundation.dart';

/// Structured log tags (spec §8).
abstract final class LogTag {
  static const chat = 'CHAT';
  static const rtc = 'RTC';
  static const schedule = 'SCHEDULE';
  static const auth = 'AUTH';
}

class LogEntry {
  final DateTime at;
  final String tag;
  final String message;
  const LogEntry(this.at, this.tag, this.message);

  @override
  String toString() =>
      '${at.toIso8601String().substring(11, 19)} [$tag] $message';
}

/// Tagged logger with an in-memory ring buffer feeding the DevPanel.
/// Values of secret-ish keys are masked before storage.
abstract final class WtfLog {
  static const _capacity = 20;
  static final List<LogEntry> _buffer = [];

  /// Last [_capacity] entries, newest first.
  static List<LogEntry> get recent => List.unmodifiable(_buffer.reversed);

  static final _secretPattern = RegExp(
      r'(token|secret|key|password)([=:]\s*)([^\s,}&"]+)',
      caseSensitive: false);

  static String _mask(String msg) =>
      msg.replaceAllMapped(_secretPattern, (m) => '${m[1]}${m[2]}••••');

  static void d(String tag, String message) {
    final entry = LogEntry(DateTime.now(), tag, _mask(message));
    _buffer.add(entry);
    if (_buffer.length > _capacity) _buffer.removeAt(0);
    debugPrint('[$tag] ${entry.message}');
  }
}
