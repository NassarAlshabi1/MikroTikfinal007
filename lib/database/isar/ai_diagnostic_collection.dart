// ============================================================
//  AiDiagnostic Collection — Isar schema لسجل التشخيصات AI
//
//  يحل محل Drift AiDiagnostics table.
//  المميزات:
//  - index على mode للاستعلامات حسب النوع
//  - composite index على (startedAt desc) للأحدث أولاً
//  - index على isFavorite لجلب المفضلة بسرعة
// ============================================================

import 'package:isar/isar.dart';

part 'ai_diagnostic_collection.g.dart';

@collection
class AiDiagnosticCollection {
  Id id = Isar.autoIncrement;

  /// نوع التشخيص: general, security, qos, etc.
  @Index(composite: [CompositeIndex('startedAt')])
  late String mode;

  /// IP MikroTik (اختياري)
  String? mikrotikIp;

  /// وقت بدء الجلسة
  late DateTime startedAt;

  /// وقت انتهاء الجلسة
  DateTime? endedAt;

  /// استعلام المستخدم
  late String userQuery;

  /// رد الـ AI
  late String aiResponse;

  /// المزود: openAI, gemini, openRouter, oomol
  String? aiProvider;

  /// النموذج: gpt-4o-mini, gemini-2.5-flash, etc.
  String? aiModel;

  /// عدد الـ tokens المستخدمة
  int? tokensUsed;

  /// snapshot من حالة RouterOS (JSON)
  String? snapshotJson;

  /// هل الجلسة مفضّلة؟
  @Index()
  late bool isFavorite;

  // ============================================================
  //  Constructors
  // ============================================================

  AiDiagnosticCollection();

  AiDiagnosticCollection.fromData({
    required this.mode,
    this.mikrotikIp,
    required this.startedAt,
    this.endedAt,
    required this.userQuery,
    required this.aiResponse,
    this.aiProvider,
    this.aiModel,
    this.tokensUsed,
    this.snapshotJson,
    this.isFavorite = false,
  });

  /// تحويل إلى Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'mode': mode,
        'mikrotik_ip': mikrotikIp,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'user_query': userQuery,
        'ai_response': aiResponse,
        'ai_provider': aiProvider,
        'ai_model': aiModel,
        'tokens_used': tokensUsed,
        'snapshot_json': snapshotJson,
        'is_favorite': isFavorite,
      };
}
