// ============================================================
//  Diagnostics History — حفظ ومراجعة جلسات التشخيص السابقة
//  يخزّن: المحادثة + الـ snapshot + الأوامر المنفّذة + التاريخ
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'command_executor.dart';
import 'diagnostics_models.dart';

/// جلسة تشخيص كاملة (محفوظة)
@immutable
class DiagnosticSession {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DiagnosticMode mode;
  final String? mikrotikIp;
  final List<DiagnosticMessage> messages;
  final List<CommandResult> executedCommands;
  final int tokensUsed; // تقديري

  const DiagnosticSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.mode,
    this.mikrotikIp,
    required this.messages,
    required this.executedCommands,
    this.tokensUsed = 0,
  });

  factory DiagnosticSession.start({
    required DiagnosticMode mode,
    String? mikrotikIp,
  }) =>
      DiagnosticSession(
        id: _generateId(),
        startedAt: DateTime.now(),
        mode: mode,
        mikrotikIp: mikrotikIp,
        messages: const [],
        executedCommands: const [],
      );

  static String _generateId() =>
      'session_${DateTime.now().millisecondsSinceEpoch}';

  DiagnosticSession copyWith({
    DateTime? endedAt,
    List<DiagnosticMessage>? messages,
    List<CommandResult>? executedCommands,
    int? tokensUsed,
  }) =>
      DiagnosticSession(
        id: id,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
        mode: mode,
        mikrotikIp: mikrotikIp,
        messages: messages ?? this.messages,
        executedCommands: executedCommands ?? this.executedCommands,
        tokensUsed: tokensUsed ?? this.tokensUsed,
      );

  /// عنوان الجلسة (للعرض في القائمة)
  String get title {
    if (messages.isEmpty) return 'جلسة فارغة';
    final firstUserMsg = messages.firstWhere(
      (m) => m.type == MessageType.user,
      orElse: () => messages.first,
    );
    final text = firstUserMsg.content;
    return text.length > 50 ? '${text.substring(0, 50)}...' : text;
  }

  /// وصف مختصر للجلسة
  String get subtitle {
    final parts = <String>[];
    parts.add(mode.displayName);
    if (mikrotikIp != null) parts.add(mikrotikIp!);
    parts.add('${messages.length} رسالة');
    if (executedCommands.isNotEmpty) {
      parts.add('${executedCommands.length} أمر منفّذ');
    }
    return parts.join(' • ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'mode': mode.name,
        'mikrotikIp': mikrotikIp,
        'messages': messages.map((m) => _messageToJson(m)).toList(),
        'executedCommands': executedCommands.map((c) => c.toJson()).toList(),
        'tokensUsed': tokensUsed,
      };

  factory DiagnosticSession.fromJson(Map<String, dynamic> json) {
    return DiagnosticSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      mode: DiagnosticMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => DiagnosticMode.general,
      ),
      mikrotikIp: json['mikrotikIp'] as String?,
      messages: (json['messages'] as List)
          .map((m) => _messageFromJson(m as Map<String, dynamic>))
          .toList(),
      executedCommands: (json['executedCommands'] as List? ?? [])
          .map((c) => CommandResult(
                command: c['command'] as String,
                success: c['success'] as bool,
                output: c['output'] as String? ?? '',
                error: c['error'] as String?,
                elapsed: Duration(milliseconds: c['elapsedMs'] as int? ?? 0),
                executedAt: DateTime.parse(c['executedAt'] as String),
              ))
          .toList(),
      tokensUsed: json['tokensUsed'] as int? ?? 0,
    );
  }

  static Map<String, dynamic> _messageToJson(DiagnosticMessage m) => {
        'id': m.id,
        'content': m.content,
        'type': m.type.name,
        'timestamp': m.timestamp.toIso8601String(),
        'suggestedCommands': m.suggestedCommands,
      };

  static DiagnosticMessage _messageFromJson(Map<String, dynamic> json) {
    return DiagnosticMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MessageType.user,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      suggestedCommands: (json['suggestedCommands'] as List?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

/// خدمة حفظ وقراءة الجلسات
class DiagnosticsHistoryService {
  DiagnosticsHistoryService._();
  static final DiagnosticsHistoryService instance =
      DiagnosticsHistoryService._();

  static const _keySessions = 'diagnostics_sessions';
  static const _maxSessions = 50; // حد أقصى للحفظ

  /// يحمّل كل الجلسات المحفوظة (مرتبة من الأحدث للأقدم)
  Future<List<DiagnosticSession>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keySessions);
      if (jsonStr == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonStr) as List<dynamic>;
      final sessions = jsonList
          .map((e) => DiagnosticSession.fromJson(e as Map<String, dynamic>))
          .toList();

      // ترتيب: الأحدث أولاً
      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return sessions;
    } catch (e) {
      debugPrint('[DiagnosticsHistory] Load error: $e');
      return [];
    }
  }

  /// يحفظ جلسة (يُضيفها للأخرى، مع تطبيق الحد الأقصى)
  Future<void> save(DiagnosticSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await loadAll();

      // استبدال إذا كانت موجودة، أو إضافة جديدة
      final idx = existing.indexWhere((s) => s.id == session.id);
      if (idx >= 0) {
        existing[idx] = session;
      } else {
        existing.insert(0, session);
      }

      // تطبيق الحد الأقصى (إزالة الأقدم)
      final toKeep = existing.length > _maxSessions
          ? existing.sublist(0, _maxSessions)
          : existing;

      final jsonStr = jsonEncode(toKeep.map((s) => s.toJson()).toList());
      await prefs.setString(_keySessions, jsonStr);
      debugPrint('[DiagnosticsHistory] Saved session ${session.id}, '
          'total: ${toKeep.length}');
    } catch (e) {
      debugPrint('[DiagnosticsHistory] Save error: $e');
    }
  }

  /// يحذف جلسة محددة
  Future<void> delete(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await loadAll();
      final filtered =
          existing.where((s) => s.id != sessionId).toList();
      final jsonStr = jsonEncode(filtered.map((s) => s.toJson()).toList());
      await prefs.setString(_keySessions, jsonStr);
    } catch (e) {
      debugPrint('[DiagnosticsHistory] Delete error: $e');
    }
  }

  /// يحذف كل الجلسات
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessions);
  }

  /// يصدّر جلسة كـ JSON (للمشاركة)
  String exportSession(DiagnosticSession session) {
    return const JsonEncoder.withIndent('  ').convert(session.toJson());
  }
}
