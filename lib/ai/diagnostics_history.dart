// ============================================================
//  Diagnostics History — حفظ ومراجعة جلسات التشخيص السابقة
//  يستخدم Isar database (بعد الهجرة من Drift)
//  مع fallback لـ SharedPreferences للتوافق مع الإصدارات القديمة
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/isar/ai_diagnostic_collection.dart';
import '../database/daos/ai_diagnostics_dao.dart';
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
  final int tokensUsed;

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

  DiagnosticSession copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    DiagnosticMode? mode,
    String? mikrotikIp,
    List<DiagnosticMessage>? messages,
    List<CommandResult>? executedCommands,
    int? tokensUsed,
  }) =>
      DiagnosticSession(
        id: id ?? this.id,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        mode: mode ?? this.mode,
        mikrotikIp: mikrotikIp ?? this.mikrotikIp,
        messages: messages ?? this.messages,
        executedCommands: executedCommands ?? this.executedCommands,
        tokensUsed: tokensUsed ?? this.tokensUsed,
      );

  String get title {
    final dateStr = '${startedAt.day}/${startedAt.month}/${startedAt.year}';
    final userMsg = messages.firstWhere(
      (m) => m.type == MessageType.user,
      orElse: () => DiagnosticMessage.system(''),
    );
    final preview = userMsg.content.isNotEmpty
        ? '${userMsg.content.substring(0, userMsg.content.length > 40 ? 40 : userMsg.content.length)}...'
        : mode.displayName;
    return '$dateStr — $preview';
  }

  factory DiagnosticSession.start({
    required DiagnosticMode mode,
    String? mikrotikIp,
  }) =>
      DiagnosticSession(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        startedAt: DateTime.now(),
        mode: mode,
        mikrotikIp: mikrotikIp,
        messages: const [],
        executedCommands: const [],
      );

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

  /// يحوّل الجلسة إلى AiDiagnosticCollection للحفظ في Isar
  AiDiagnosticCollection toIsarCollection() {
    final userQuery = messages
        .firstWhere((m) => m.type == MessageType.user,
            orElse: () => DiagnosticMessage.user(''))
        .content;
    final aiResponse = messages
        .lastWhere((m) => m.type == MessageType.assistant,
            orElse: () => DiagnosticMessage.assistant(''))
        .content;

    return AiDiagnosticCollection.fromData(
      mode: mode.name,
      mikrotikIp: mikrotikIp,
      startedAt: startedAt,
      endedAt: endedAt,
      userQuery: userQuery,
      aiResponse: aiResponse,
      snapshotJson: jsonEncode({
        'id': id,
        'messages': messages.map((m) => _messageToJson(m)).toList(),
        'executedCommands': executedCommands.map((c) => c.toJson()).toList(),
      }),
      isFavorite: false,
    );
  }

  /// يبني DiagnosticSession من سجل Isar
  factory DiagnosticSession.fromIsar(AiDiagnosticCollection row) {
    Map<String, dynamic>? data;
    try {
      if (row.snapshotJson != null) {
        data = jsonDecode(row.snapshotJson!) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[DiagnosticSession] Error parsing snapshotJson: $e');
    }

    final messages = (data?['messages'] as List?)
            ?.map((m) => _messageFromJson(m as Map<String, dynamic>))
            .toList() ??
        [
          DiagnosticMessage.user(row.userQuery),
          if (row.aiResponse.isNotEmpty)
            DiagnosticMessage.assistant(row.aiResponse),
        ];

    final commands = (data?['executedCommands'] as List?)
            ?.map((c) => CommandResult(
                  command: c['command'] as String,
                  success: c['success'] as bool,
                  output: c['output'] as String? ?? '',
                  error: c['error'] as String?,
                  elapsed: Duration(milliseconds: c['elapsedMs'] as int? ?? 0),
                  executedAt: DateTime.parse(c['executedAt'] as String),
                ))
            .toList() ??
        const [];

    return DiagnosticSession(
      id: 'session_${row.id}',
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      mode: DiagnosticMode.values.firstWhere(
        (m) => m.name == row.mode,
        orElse: () => DiagnosticMode.general,
      ),
      mikrotikIp: row.mikrotikIp,
      messages: messages,
      executedCommands: commands,
    );
  }

  Map<String, dynamic> _messageToJson(DiagnosticMessage m) => {
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

  /// للتصدير (JSON)
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
}

/// خدمة حفظ وقراءة الجلسات
/// تستخدم Isar database (مع fallback لـ SharedPreferences)
class DiagnosticsHistoryService {
  DiagnosticsHistoryService._();
  static final DiagnosticsHistoryService instance =
      DiagnosticsHistoryService._();

  AiDiagnosticsDao? _dao;
  static const _legacyKey = 'diagnostics_sessions';
  static const _maxSessions = 50;

  void setDao(AiDiagnosticsDao dao) {
    _dao = dao;
  }

  /// يحمّل كل الجلسات المحفوظة (مرتبة من الأحدث للأقدم)
  Future<List<DiagnosticSession>> loadAll() async {
    if (_dao != null) {
      try {
        final rows = await _dao!.getAllDiagnostics();
        return rows.map(DiagnosticSession.fromIsar).toList();
      } catch (e) {
        debugPrint('[DiagnosticsHistory] Isar error, falling back: $e');
      }
    }
    return _loadFromPrefs();
  }

  Future<List<DiagnosticSession>> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_legacyKey);
      if (jsonStr == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonStr) as List<dynamic>;
      final sessions = jsonList
          .map((e) => _fromJsonLegacy(e as Map<String, dynamic>))
          .toList();

      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return sessions;
    } catch (e) {
      debugPrint('[DiagnosticsHistory] Load error: $e');
      return [];
    }
  }

  /// يحفظ جلسة
  Future<void> save(DiagnosticSession session) async {
    if (_dao != null) {
      try {
        await _dao!.insertDiagnostic(session.toIsarCollection());
        await _dao!.keepOnlyLatest(_maxSessions);
        return;
      } catch (e) {
        debugPrint('[DiagnosticsHistory] Isar save error, falling back: $e');
      }
    }
    await _saveToPrefs(session);
  }

  Future<void> _saveToPrefs(DiagnosticSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await _loadFromPrefs();

      final idx = existing.indexWhere((s) => s.id == session.id);
      if (idx >= 0) {
        existing[idx] = session;
      } else {
        existing.insert(0, session);
      }

      final toKeep = existing.length > _maxSessions
          ? existing.sublist(0, _maxSessions)
          : existing;

      final jsonStr = jsonEncode(toKeep.map((s) => s.toJson()).toList());
      await prefs.setString(_legacyKey, jsonStr);
    } catch (e) {
      debugPrint('[DiagnosticsHistory] Save error: $e');
    }
  }

  /// يحذف جلسة محددة
  Future<void> delete(String sessionId) async {
    if (_dao != null && sessionId.startsWith('session_')) {
      final id = int.tryParse(sessionId.replaceAll('session_', ''));
      if (id != null) {
        try {
          await _dao!.deleteDiagnostic(id);
          return;
        } catch (e) {
          debugPrint('[DiagnosticsHistory] Isar delete error: $e');
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final existing = await _loadFromPrefs();
    final filtered = existing.where((s) => s.id != sessionId).toList();
    final jsonStr = jsonEncode(filtered.map((s) => s.toJson()).toList());
    await prefs.setString(_legacyKey, jsonStr);
  }

  /// يحذف كل الجلسات
  Future<void> clearAll() async {
    if (_dao != null) {
      try {
        await _dao!.deleteAllDiagnostics();
      } catch (e) {
        debugPrint('[DiagnosticsHistory] Isar clearAll error: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyKey);
  }

  /// يصدّر جلسة كـ JSON
  String exportSession(DiagnosticSession session) {
    return const JsonEncoder.withIndent('  ').convert(session.toJson());
  }

  DiagnosticSession _fromJsonLegacy(Map<String, dynamic> json) {
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
          .map((m) => _messageFromJsonLegacy(m as Map<String, dynamic>))
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

  DiagnosticMessage _messageFromJsonLegacy(Map<String, dynamic> json) {
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
