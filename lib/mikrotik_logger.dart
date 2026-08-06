// ============================================================
//  MikrotikLogger — تسجيل جلسات اتصال MikroTik
//
//  مستوحى من MKT_flutter_scripts/services/ssh_logger.dart
//  يطبق نمط Singleton لتسجيل كل عمليات الاتصال
//  مفيد للـ debugging ومراجعة الأخطاء
// ============================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// يسجّل كل عمليات اتصال MikroTik في ملفات log منظمة
class MikrotikLogger {
  static final MikrotikLogger _instance = MikrotikLogger._internal();
  factory MikrotikLogger() => _instance;
  MikrotikLogger._internal();

  File? _currentLogFile;
  // ignore: unused_field — محجوز للاستخدام المستقبلي في تقارير الجلسة
  String? _currentSession;
  final List<String> _sessionLogs = [];

  /// يبدأ جلسة تسجيل جديدة
  Future<void> startSession(String routerName, String host) async {
    final timestamp = DateTime.now();
    final sessionId = '${timestamp.millisecondsSinceEpoch}';
    _currentSession = sessionId;

    // إنشاء مجلد logs إن لم يوجد
    final appDir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${appDir.path}/mikrotik_logs');
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    // إنشاء ملف log للجلسة
    final fileName =
        'session_${routerName.replaceAll(' ', '_')}_${_formatDateTime(timestamp)}.log';
    _currentLogFile = File('${logsDir.path}/$fileName');

    _sessionLogs.clear();

    final header = '''
===============================================================================
MikroTik Communication Log
===============================================================================
Router: $routerName
Host: $host
Session ID: $sessionId
Started: ${timestamp.toIso8601String()}
===============================================================================
''';
    await _writeToFile(header);
    _logToSession('SESSION_START', 'Session started for $routerName ($host)');
  }

  /// يسجّل أمراً مُرسَلاً لـ MikroTik
  Future<void> logCommand(String command) async {
    final timestamp = DateTime.now();
    final logEntry = '[${_formatTime(timestamp)}] >>> COMMAND: $command';
    await _writeToFile('$logEntry\n');
    _logToSession('COMMAND', command);
    debugPrint('🔴 MIKROTIK CMD: $command');
  }

  /// يسجّل رد MikroTik
  Future<void> logResponse(String response) async {
    final timestamp = DateTime.now();
    final lines = response.split('\n');
    final formattedResponse = lines.map((line) => '   $line').join('\n');
    final logEntry =
        '[${_formatTime(timestamp)}] <<< RESPONSE:\n$formattedResponse';
    await _writeToFile('$logEntry\n');
    _logToSession('RESPONSE', response);

    final truncated =
        response.length > 200 ? '${response.substring(0, 200)}...' : response;
    debugPrint('🔵 MIKROTIK RESP: ${truncated.replaceAll('\n', '\\n')}');
  }

  /// يسجّل أحداث الاتصال
  Future<void> logConnection(String event, String details) async {
    final timestamp = DateTime.now();
    final logEntry =
        '[${_formatTime(timestamp)}] === CONNECTION: $event - $details';
    await _writeToFile('$logEntry\n');
    _logToSession('CONNECTION', '$event - $details');
    debugPrint('🟡 MIKROTIK CONN: $event - $details');
  }

  /// يسجّل أخطاء
  Future<void> logError(String error, String context) async {
    final timestamp = DateTime.now();
    final logEntry =
        '[${_formatTime(timestamp)}] !!! ERROR in $context: $error';
    await _writeToFile('$logEntry\n');
    _logToSession('ERROR', '$context: $error');
    debugPrint('🔴 MIKROTIK ERROR: $error');
  }

  /// ينهي الجلسة الحالية
  Future<void> endSession() async {
    if (_currentLogFile == null) return;

    final timestamp = DateTime.now();
    final footer = '''
===============================================================================
Session ended: ${timestamp.toIso8601String()}
Total operations: ${_sessionLogs.length}
===============================================================================
''';
    await _writeToFile(footer);
    _logToSession('SESSION_END', 'Session ended');
  }

  /// يُرجع قائمة بكل ملفات الـ logs
  Future<List<File>> getLogFiles() async {
    final appDir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${appDir.path}/mikrotik_logs');
    if (!await logsDir.exists()) return [];

    final files = await logsDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.log'))
        .map((entity) => entity as File)
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// يحذف كل ملفات الـ logs
  Future<void> clearLogs() async {
    final appDir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${appDir.path}/mikrotik_logs');
    if (await logsDir.exists()) {
      await logsDir.delete(recursive: true);
    }
  }

  /// يقرأ محتوى آخر ملف log
  Future<String?> getLastLogContent() async {
    final files = await getLogFiles();
    if (files.isEmpty) return null;
    return files.first.readAsString();
  }

  // ===== Helpers =====

  Future<void> _writeToFile(String content) async {
    if (_currentLogFile == null) return;
    try {
      await _currentLogFile!.writeAsString(content, mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to write log: $e');
    }
  }

  void _logToSession(String type, String message) {
    _sessionLogs.add('[${DateTime.now().toIso8601String()}] $type: $message');
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}_'
        '${dt.hour.toString().padLeft(2, '0')}'
        '${dt.minute.toString().padLeft(2, '0')}'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
