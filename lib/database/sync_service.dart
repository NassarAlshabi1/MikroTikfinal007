// ============================================================
//  SyncService — مزامنة الكروت والملفات الشخصية من MikroTik إلى SQLite
//  يجلب البيانات عبر RouterOS API أو SSH ثم يخزّنها في drift database
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:drift/drift.dart';

import '../mikrotik_connector.dart';
import 'app_database.dart';
import 'daos/cards_dao.dart';
import 'daos/profiles_dao.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  /// يزامن الكروت والملفات الشخصية من MikroTik إلى SQLite
  ///
  /// [onProgress] — callback لتتبع التقدم (0.0 - 1.0)
  /// [onStatus] — callback لرسائل الحالة
  Future<SyncResult> syncAll({
    AppDatabase? database,
    void Function(double progress, String status)? onProgress,
  }) async {
    final db = database ?? _getDatabase();
    final stopwatch = Stopwatch()..start();
    int cardsSynced = 0;
    int profilesSynced = 0;
    int sessionsSynced = 0;
    String? error;

    try {
      // 1) الاتصال بـ MikroTik
      onProgress?.call(0.0, 'جاري الاتصال بـ MikroTik...');
      final client = await MikrotikConnector.connect();

      // 2) مزامنة الملفات الشخصية
      onProgress?.call(0.1, 'جاري جلب الملفات الشخصية...');
      final profilesResponse = await _safeTalk(
        client,
        ['/tool/user-manager/profile/print',
         '=.proplist=name,shared-users,rate-limit,uptime-used,upload-used,download-used'],
      );
      profilesSynced = await _syncProfiles(db, profilesResponse);
      onProgress?.call(0.3, 'تمت مزامنة $profilesSynced ملف شخصي');

      // 3) مزامنة المستخدمين (الكروت)
      onProgress?.call(0.4, 'جاري جلب المستخدمين...');
      final usersResponse = await _safeTalk(
        client,
        ['/tool/user-manager/user/print',
         '=.proplist=username,password,disabled,actual-profile,shared-users,upload-used,download-used,uptime-used,uptime-limit'],
      );
      cardsSynced = await _syncCards(db, usersResponse);
      onProgress?.call(0.7, 'تمت مزامنة $cardsSynced كرت');

      // 4) مزامنة الجلسات النشطة
      onProgress?.call(0.8, 'جاري جلب الجلسات النشطة...');
      final sessionsResponse = await _safeTalk(
        client,
        ['/ip/hotspot/active/print',
         '=.proplist=user,address,uptime,session-time-left,bytes-in,bytes-out'],
      );
      sessionsSynced = await _syncSessions(db, sessionsResponse);
      onProgress?.call(0.9, 'تمت مزامنة $sessionsSynced جلسة نشطة');

      // 5) تحديث حالة الكروت (active/disabled/expired)
      onProgress?.call(0.95, 'جاري تحديث حالات الكروت...');
      await _updateCardStatuses(db);

      onProgress?.call(1.0, 'اكتملت المزامنة');
    } on MikrotikCredentialsMissingException catch (e) {
      error = 'بيانات الاعتماد مفقودة: ${e.message}';
    } on MikrotikConnectionException catch (e) {
      error = 'فشل الاتصال: ${e.message}';
    } catch (e) {
      error = 'خطأ في المزامنة: $e';
      debugPrint('[SyncService] Error: $e');
    }

    stopwatch.stop();
    return SyncResult(
      success: error == null,
      cardsSynced: cardsSynced,
      profilesSynced: profilesSynced,
      sessionsSynced: sessionsSynced,
      durationMs: stopwatch.elapsedMilliseconds,
      error: error,
    );
  }

  /// يحصل على الـ database العام
  AppDatabase _getDatabase() {
    // appDatabase هو late final معرّف في main.dart
    // نستخدمه مباشرة
    try {
      return _database!;
    } catch (_) {
      throw Exception('Database not initialized. Call setDatabase() first.');
    }
  }

  static AppDatabase? _database;

  /// يضبط الـ database (يُستدعى من main.dart)
  static void setDatabase(AppDatabase db) {
    _database = db;
  }

  /// ينفذ talk بأمان مع timeout
  Future<List<Map<String, dynamic>>> _safeTalk(
      RouterOSClient client, List<String> args) async {
    try {
      final res = await client.talk(args).timeout(const Duration(seconds: 15));
      return res.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('[SyncService] talk error for $args: $e');
      return [];
    }
  }

  /// يزامن الملفات الشخصية (upsert)
  Future<int> _syncProfiles(
      AppDatabase db, List<Map<String, dynamic>> profiles) async {
    if (profiles.isEmpty) return 0;

    int count = 0;
    for (final p in profiles) {
      final name = p['name'] as String?;
      if (name == null || name.isEmpty) continue;

      // تحقق إذا كان موجوداً
      final existing = await (db.select(db.profiles)
            ..where((pr) => pr.name.equals(name)))
          .getSingleOrNull();

      final companion = ProfilesCompanion(
        name: Value(name),
        mikrotikId: Value(p['.id'] as String?),
        rateLimit: Value(p['rate-limit'] as String?),
        sharedUsers: Value(
            int.tryParse(p['shared-users'] as String? ?? '1') ?? 1),
        uploadUsedBytes: Value(
            int.tryParse(p['upload-used'] as String? ?? '0') ?? 0),
        downloadUsedBytes: Value(
            int.tryParse(p['download-used'] as String? ?? '0') ?? 0),
        uptimeUsedSeconds: Value(
            _parseDuration(p['uptime-used'] as String?)),
        lastSyncedAt: Value(DateTime.now()),
      );

      if (existing != null) {
        await (db.update(db.profiles)
              ..where((pr) => pr.id.equals(existing.id)))
            .write(companion);
      } else {
        await db.into(db.profiles).insert(
              companion.copyWith(createdAt: Value(DateTime.now())),
            );
      }
      count++;
    }
    return count;
  }

  /// يزامن الكروت (upsert)
  Future<int> _syncCards(
      AppDatabase db, List<Map<String, dynamic>> users) async {
    if (users.isEmpty) return 0;

    int count = 0;
    for (final u in users) {
      final username = u['username'] as String?;
      if (username == null || username.isEmpty) continue;

      // ابحث عن الـ profile المرتبط
      final profileName = u['actual-profile'] as String?;
      int? profileId;
      if (profileName != null) {
        final profile = await (db.select(db.profiles)
              ..where((p) => p.name.equals(profileName)))
            .getSingleOrNull();
        profileId = profile?.id;
      }
      // لو لم نجد الـ profile، نستخدم أول profile أو ننشئ default
      if (profileId == null) {
        final defaultProfile = await (db.select(db.profiles)
              ..limit(1))
            .getSingleOrNull();
        if (defaultProfile != null) {
          profileId = defaultProfile.id;
        } else {
          // أنشئ profile افتراضي
          profileId = await db.into(db.profiles).insert(
                ProfilesCompanion.insert(
                  name: 'default',
                  createdAt: DateTime.now(),
                ),
              );
        }
      }

      // تحقق إذا كان الكرت موجوداً
      final existing = await (db.select(db.cards)
            ..where((c) => c.username.equals(username)))
          .getSingleOrNull();

      final isDisabled = u['disabled'] as String? == 'true';
      final companion = CardsCompanion(
        username: Value(username),
        password: Value(u['password'] as String?),
        profileId: Value(profileId),
        sharedUsers: Value(
            int.tryParse(u['shared-users'] as String? ?? '1') ?? 1),
        status: Value(isDisabled ? 'disabled' : 'active'),
        uploadBytes: Value(
            int.tryParse(u['upload-used'] as String? ?? '0') ?? 0),
        downloadBytes: Value(
            int.tryParse(u['download-used'] as String? ?? '0') ?? 0),
        uptimeSeconds: Value(
            _parseDuration(u['uptime-used'] as String?)),
        mikrotikUserId: Value(u['.id'] as String?),
        lastUsedAt: Value(DateTime.now()),
      );

      if (existing != null) {
        await (db.update(db.cards)
              ..where((c) => c.id.equals(existing.id)))
            .write(companion);
      } else {
        await db.into(db.cards).insert(
              companion.copyWith(createdAt: Value(DateTime.now())),
            );
      }
      count++;
    }
    return count;
  }

  /// يزامن الجلسات النشطة
  Future<int> _syncSessions(
      AppDatabase db, List<Map<String, dynamic>> sessions) async {
    if (sessions.isEmpty) return 0;

    int count = 0;
    for (final s in sessions) {
      final username = s['user'] as String?;
      if (username == null) continue;

      // ابحث عن الكرت المرتبط
      final card = await (db.select(db.cards)
            ..where((c) => c.username.equals(username)))
          .getSingleOrNull();
      if (card == null) continue; // تجاهل الجلسات بدون كرت معروف

      // ابحث عن جلسة نشطة موجودة
      final existingSession = await (db.select(db.sessions)
            ..where((sess) =>
                sess.cardId.equals(card.id) &
                sess.endedAt.isNull()))
          .getSingleOrNull();

      final bytesIn = int.tryParse(s['bytes-in'] as String? ?? '0') ?? 0;
      final bytesOut = int.tryParse(s['bytes-out'] as String? ?? '0') ?? 0;

      if (existingSession != null) {
        // تحديث الجلسة الموجودة
        await (db.update(db.sessions)
              ..where((sess) => sess.id.equals(existingSession.id)))
            .write(SessionsCompanion(
          uploadBytes: Value(bytesOut),
          downloadBytes: Value(bytesIn),
          framedIpAddress: Value(s['address'] as String?),
          lastSeenAt: Value(DateTime.now()),
        ));
      } else {
        // إنشاء جلسة جديدة
        await db.into(db.sessions).insert(
              SessionsCompanion.insert(
                cardId: card.id,
                startedAt: DateTime.now(),
                lastSeenAt: DateTime.now(),
                uploadBytes: Value(bytesOut),
                downloadBytes: Value(bytesIn),
                framedIpAddress: Value(s['address'] as String?),
              ),
            );
      }
      count++;
    }

    // أنهِ الجلسات التي لم تعد نشطة (لم تُرَ منذ أكثر من 5 دقائق)
    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
    await (db.update(db.sessions)
          ..where((s) =>
              s.endedAt.isNull() & s.lastSeenAt.isSmallerThanValue(cutoff)))
        .write(SessionsCompanion(endedAt: Value(DateTime.now())));

    return count;
  }

  /// يحدّث حالة الكروت (expired للكروت المنتهية)
  Future<void> _updateCardStatuses(AppDatabase db) async {
    // الكروت التي تجاوزت uptime-limit
    final cards = await db.select(db.cards).get();
    for (final card in cards) {
      // لو كان uptime_used >= uptime_limit (إذا كان موجوداً)
      // نحتاج الـ uptime_limit من الـ profile
      if (card.profileId != null) {
        final profile = await (db.select(db.profiles)
              ..where((p) => p.id.equals(card.profileId!)))
            .getSingleOrNull();
        if (profile?.uptimeLimitSeconds != null &&
            profile!.uptimeLimitSeconds! > 0 &&
            card.uptimeSeconds >= profile.uptimeLimitSeconds!) {
          await (db.update(db.cards)
                ..where((c) => c.id.equals(card.id)))
              .write(const CardsCompanion(status: Value('expired')));
        }
      }
    }
  }

  /// يحوّل مدة RouterOS (مثل "1d2h30m") إلى ثوانٍ
  int _parseDuration(String? duration) {
    if (duration == null || duration.isEmpty) return 0;

    int totalSeconds = 0;
    final regex = RegExp(r'(\d+)([wdhms])');
    for (final match in regex.allMatches(duration)) {
      final value = int.parse(match.group(1)!);
      final unit = match.group(2)!;
      switch (unit) {
        case 'w':
          totalSeconds += value * 7 * 24 * 3600;
          break;
        case 'd':
          totalSeconds += value * 24 * 3600;
          break;
        case 'h':
          totalSeconds += value * 3600;
          break;
        case 'm':
          totalSeconds += value * 60;
          break;
        case 's':
          totalSeconds += value;
          break;
      }
    }
    return totalSeconds;
  }
}

/// نتيجة المزامنة
class SyncResult {
  final bool success;
  final int cardsSynced;
  final int profilesSynced;
  final int sessionsSynced;
  final int durationMs;
  final String? error;

  const SyncResult({
    required this.success,
    required this.cardsSynced,
    required this.profilesSynced,
    required this.sessionsSynced,
    required this.durationMs,
    this.error,
  });

  String get summary =>
      'تمت مزامنة $cardsSynced كرت، $profilesSynced ملف شخصي، '
      '$sessionsSynced جلسة في ${durationMs}ms';
}
