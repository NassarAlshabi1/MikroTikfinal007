// ============================================================
//  SshLogger — سجل تدقيق لأوامر RouterOS المنفّذة
//
//  مستوحى من MKT_flutter_scripts/lib/services/ssh_logger.dart
//  - يسجّل كل أمر مُرسل + الاستجابة + الزمن + الحالة
//  - يحفظ السجلات في ملفات JSON محلية
//  - يدعم عرض السجلات في UI
//  - يدعم تصدير السجلات
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// سجل أمر واحد
class AuditLogEntry {
  final String id;
  final String command;
  final String? response;
  final String? error;
  final bool success;
  final DateTime timestamp;
  final int durationMs;
  final String? routerIp;
  final String source; // 'terminal', 'ai', 'auto-fix', 'script'

  const AuditLogEntry({
    required this.id,
    required this.command,
    this.response,
    this.error,
    required this.success,
    required this.timestamp,
    required this.durationMs,
    this.routerIp,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'command': command,
        'response': response,
        'error': error,
        'success': success,
        'timestamp': timestamp.toIso8601String(),
        'durationMs': durationMs,
        'routerIp': routerIp,
        'source': source,
      };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      command: json['command'] as String,
      response: json['response'] as String?,
      error: json['error'] as String?,
      success: json['success'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      durationMs: json['durationMs'] as int,
      routerIp: json['routerIp'] as String?,
      source: json['source'] as String? ?? 'unknown',
    );
  }
}

/// يسجّل كل أوامر RouterOS المنفّذة
class SshLogger {
  SshLogger._();

  static const _maxEntries = 1000; // حد أقصى للسجلات المحفوظة
  static List<AuditLogEntry> _entries = [];

  /// كل السجلات
  static List<AuditLogEntry> get entries => List.unmodifiable(_entries);

  /// عدد السجلات
  static int get count => _entries.length;

  /// يسجّل أمراً مُنفّذاً
  static void log({
    required String command,
    String? response,
    String? error,
    required bool success,
    required int durationMs,
    String? routerIp,
    String source = 'terminal',
  }) {
    final entry = AuditLogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      command: command,
      response: response,
      error: error,
      success: success,
      timestamp: DateTime.now(),
      durationMs: durationMs,
      routerIp: routerIp,
      source: source,
    );

    _entries.insert(0, entry); // الأحدث أولاً

    // الحفاظ على الحد الأقصى
    if (_entries.length > _maxEntries) {
      _entries = _entries.sublist(0, _maxEntries);
    }

    debugPrint('[SshLogger] $source: ${success ? "✅" : "❌"} '
        '$command (${durationMs}ms)');

    // حفظ للملف (async، لا ينتظر)
    _saveToFile();
  }

  /// يحذف كل السجلات
  static void clear() {
    _entries.clear();
    _deleteFile();
    debugPrint('[SshLogger] All logs cleared');
  }

  /// يُرجع السجلات المصفاة حسب المصدر
  static List<AuditLogEntry> filterBySource(String source) {
    return _entries.where((e) => e.source == source).toList();
  }

  /// يُرجع السجلات المصفاة حسب النجاح/الفشل
  static List<AuditLogEntry> filterBySuccess(bool success) {
    return _entries.where((e) => e.success == success).toList();
  }

  /// يحسب إحصائيات سريعة
  static Map<String, dynamic> getStats() {
    if (_entries.isEmpty) {
      return {'total': 0, 'success': 0, 'failed': 0, 'avgDurationMs': 0};
    }

    final success = _entries.where((e) => e.success).length;
    final failed = _entries.where((e) => !e.success).length;
    final avgDuration = _entries.map((e) => e.durationMs).reduce((a, b) => a + b) ~/
        _entries.length;

    return {
      'total': _entries.length,
      'success': success,
      'failed': failed,
      'avgDurationMs': avgDuration,
    };
  }

  // ============================================================
  //  حفظ/قراءة من ملف — مستوحى من MKT_flutter_scripts/logs/
  // ============================================================

  static Future<String> get _logFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${dir.path}/logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    return '${logDir.path}/audit_log.json';
  }

  static Future<void> _saveToFile() async {
    try {
      final path = await _logFilePath;
      final json = jsonEncode({
        'entries': _entries.map((e) => e.toJson()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      await File(path).writeAsString(json);
    } catch (e) {
      debugPrint('[SshLogger] Save error: $e');
    }
  }

  static Future<void> loadFromFile() async {
    try {
      final path = await _logFilePath;
      final file = File(path);
      if (!await file.exists()) return;

      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final entriesJson = json['entries'] as List;
      _entries = entriesJson
          .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      debugPrint('[SshLogger] Loaded ${_entries.length} entries from file');
    } catch (e) {
      debugPrint('[SshLogger] Load error: $e');
    }
  }

  static Future<void> _deleteFile() async {
    try {
      final path = await _logFilePath;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// يُصدّر السجلات كـ CSV
  static Future<String?> exportToCSV() async {
    if (_entries.isEmpty) return null;

    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Source,Command,Success,DurationMs,Error');

    for (final entry in _entries) {
      final ts = entry.timestamp.toIso8601String();
      final cmd = entry.command.replaceAll(',', ';').replaceAll('\n', ' ');
      buffer.writeln(
          '$ts,${entry.source},$cmd,${entry.success},${entry.durationMs},${entry.error ?? ''}');
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/exports/audit_log_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(buffer.toString());
      return path;
    } catch (e) {
      debugPrint('[SshLogger] Export error: $e');
      return null;
    }
  }
}
