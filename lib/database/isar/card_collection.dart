// ============================================================
//  Card Collection — Isar schema لجدول الكروت
//
//  يحل محل Drift Cards table.
//  المميزات:
//  - بحث فوري عبر @Index (أسرع من FTS5 في Drift)
//  - unique constraint على username
//  - composite index على (status, createdAt) للاستعلامات الشائعة
// ============================================================

import 'package:isar/isar.dart';

part 'card_collection.g.dart';

@collection
class CardCollection {
  /// معرّف Isar التلقائي (يُملا تلقائياً)
  Id id = Isar.autoIncrement;

  /// اسم المستخدم — فريد
  @Index(unique: true)
  late String username;

  /// كلمة المرور (قد تكون null في حالة username_only)
  String? password;

  /// معرّف البروفايل (FK إلى ProfileCollection)
  @Index()
  late int profileId;

  /// عدد المستخدمين المشتركين
  late int sharedUsers;

  /// حالة الكرت: active, disabled, expired
  @Index(composite: [CompositeIndex('createdAt')])
  late String status;

  /// تاريخ الإنشاء
  late DateTime createdAt;

  /// تاريخ الانتهاء
  DateTime? expiresAt;

  /// آخر استخدام
  DateTime? lastUsedAt;

  /// بايتات الرفع
  late int uploadBytes;

  /// بايتات التنزيل
  late int downloadBytes;

  /// مدة التشغيل بالثواني
  late int uptimeSeconds;

  /// معرّف RouterOS (.id)
  String? mikrotikUserId;

  /// معرّف عملية التوليد الجماعي في Isar
  @Index()
  String? generationJobId;

  // ============================================================
  //  Constructors
  // ============================================================

  /// إنشاء كرت جديد بالقيم الافتراضية
  CardCollection();

  /// إنشاء كرت من بيانات خام
  CardCollection.fromData({
    required this.username,
    this.password,
    required this.profileId,
    this.sharedUsers = 1,
    this.status = 'active',
    required this.createdAt,
    this.expiresAt,
    this.lastUsedAt,
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    this.uptimeSeconds = 0,
    this.mikrotikUserId,
    this.generationJobId,
  });

  /// تحويل إلى Map (للتصدير والـ JSON)
  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'password': password,
        'profile_id': profileId,
        'shared_users': sharedUsers,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'last_used_at': lastUsedAt?.toIso8601String(),
        'upload_bytes': uploadBytes,
        'download_bytes': downloadBytes,
        'uptime_seconds': uptimeSeconds,
        'mikrotik_user_id': mikrotikUserId,
        'generation_job_id': generationJobId,
      };

  /// إجمالي البايتات
  int get totalBytes => uploadBytes + downloadBytes;

  /// إجمالي الرفع بالجيجابايت
  double get totalUploadGB => uploadBytes / (1024 * 1024 * 1024);

  /// إجمالي التنزيل بالجيجابايت
  double get totalDownloadGB => downloadBytes / (1024 * 1024 * 1024);
}
