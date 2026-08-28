// ============================================================
//  ExecutedCommand Collection — Isar schema لسجل الأوامر المنفّذة
//
//  يحل محل قاعدة البيانات السابقة ExecutedCommands table (audit trail).
// ============================================================

import 'package:isar/isar.dart';

part 'executed_command_collection.g.dart';

@collection
class ExecutedCommandCollection {
  Id id = Isar.autoIncrement;

  /// الأمر الذي نُفّذ
  late String command;

  /// مستوى الخطورة: safe, moderate, dangerous
  @Index()
  String? riskLevel;

  /// هل نجح التنفيذ؟
  @Index()
  late bool success;

  /// المخرجات
  String? output;

  /// رسالة الخطأ
  String? error;

  /// مدة التنفيذ بالميلي ثانية
  int? durationMs;

  /// وقت التنفيذ
  @Index(composite: [CompositeIndex('riskLevel')])
  late DateTime executedAt;

  /// معرّف جلسة التشخيص (FK إلى AiDiagnosticCollection)
  int? diagnosticId;

  // ============================================================
  //  Constructors
  // ============================================================

  ExecutedCommandCollection();

  ExecutedCommandCollection.fromData({
    required this.command,
    this.riskLevel,
    required this.success,
    this.output,
    this.error,
    this.durationMs,
    required this.executedAt,
    this.diagnosticId,
  });

  /// تحويل إلى Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'command': command,
        'risk_level': riskLevel,
        'success': success,
        'output': output,
        'error': error,
        'duration_ms': durationMs,
        'executed_at': executedAt.toIso8601String(),
        'diagnostic_id': diagnosticId,
      };
}
