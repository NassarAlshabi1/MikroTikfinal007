// ============================================================
//  Profile Collection — Isar schema لجدول الملفات الشخصية
//
//  يحل محل Drift Profiles table.
//  المميزات:
//  - unique constraint على name
//  - index على mikrotikId للمزامنة السريعة
// ============================================================

import 'package:isar/isar.dart';

part 'profile_collection.g.dart';

@collection
class ProfileCollection {
  Id id = Isar.autoIncrement;

  /// اسم البروفايل — فريد
  @Index(unique: true)
  late String name;

  /// معرّف MikroTik (.id)
  @Index()
  String? mikrotikId;

  /// حد السرعة (e.g., "1M/1M")
  String? rateLimit;

  /// عدد المستخدمين المشتركين
  late int sharedUsers;

  /// بايتات الرفع المستهلكة
  late int uploadUsedBytes;

  /// بايتات التنزيل المستهلكة
  late int downloadUsedBytes;

  /// الحد الزمني للجلسة (بالثواني)
  int? uptimeLimitSeconds;

  /// الزمن المستهلك (بالثواني)
  late int uptimeUsedSeconds;

  /// تاريخ الإنشاء
  late DateTime createdAt;

  /// آخر مزامنة
  DateTime? lastSyncedAt;

  // ============================================================
  //  Constructors
  // ============================================================

  ProfileCollection();

  ProfileCollection.fromData({
    required this.name,
    this.mikrotikId,
    this.rateLimit,
    this.sharedUsers = 1,
    this.uploadUsedBytes = 0,
    this.downloadUsedBytes = 0,
    this.uptimeLimitSeconds,
    this.uptimeUsedSeconds = 0,
    required this.createdAt,
    this.lastSyncedAt,
  });

  /// إنشاء من بيانات MikroTik (من talk() response)
  factory ProfileCollection.fromMikrotikData(Map<String, dynamic> data) {
    return ProfileCollection.fromData(
      name: data['name'] as String,
      mikrotikId: data['.id'] as String?,
      rateLimit: data['rate-limit'] as String?,
      sharedUsers:
          int.tryParse(data['shared-users'] as String? ?? '1') ?? 1,
      createdAt: DateTime.now(),
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'mikrotik_id': mikrotikId,
        'rate_limit': rateLimit,
        'shared_users': sharedUsers,
        'upload_used_bytes': uploadUsedBytes,
        'download_used_bytes': downloadUsedBytes,
        'uptime_limit_seconds': uptimeLimitSeconds,
        'uptime_used_seconds': uptimeUsedSeconds,
        'created_at': createdAt.toIso8601String(),
        'last_synced_at': lastSyncedAt?.toIso8601String(),
      };
}
