// ============================================================
//  SyncService — مزامنة الكروت والملفات الشخصية من MikroTik إلى Isar
//
//  يجلب البيانات عبر RouterOS API ثم يخزّنها في Isar database.
//  يحل محل Drift SyncService القديم.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:router_os_client/router_os_client.dart';

import '../mikrotik_connector.dart';
import 'isar_provider.dart';
import 'isar/card_collection.dart';
import 'isar/profile_collection.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  /// يزامن الكروت والملفات الشخصية من MikroTik إلى Isar
  ///
  /// [onProgress] — callback لتتبع التقدم (0.0 - 1.0)
  /// [onStatus] — callback لرسائل الحالة
  Future<SyncResult> syncAll({
    Isar? database,
    void Function(double progress, String status)? onProgress,
  }) async {
    Isar? db = database;
    db ??= await IsarProvider().instance;

    final stopwatch = Stopwatch()..start();
    int cardsSynced = 0;
    int profilesSynced = 0;
    String? error;

    try {
      // 1) الاتصال بـ MikroTik
      onProgress?.call(0.0, 'جاري الاتصال بـ MikroTik...');
      final client = await MikrotikConnector.connect();

      // 2) مزامنة الملفات الشخصية
      onProgress?.call(0.1, 'جاري جلب الملفات الشخصية...');
      final profilesResponse = await _safeTalk(
        client,
        [
          '/tool/user-manager/profile/print',
          '=.proplist=name,shared-users,rate-limit,uptime-used,upload-used,download-used'
        ],
      );
      profilesSynced = await _syncProfiles(db, profilesResponse);
      onProgress?.call(0.3, 'تمت مزامنة $profilesSynced ملف شخصي');

      // 3) مزامنة المستخدمين (الكروت)
      onProgress?.call(0.4, 'جاري جلب المستخدمين...');
      final usersResponse = await _safeTalk(
        client,
        [
          '/tool/user-manager/user/print',
          '=.proplist=username,password,disabled,actual-profile,shared-users,upload-used,download-used,uptime-used,uptime-limit'
        ],
      );
      cardsSynced = await _syncCards(db, usersResponse);
      onProgress?.call(0.7, 'تمت مزامنة $cardsSynced كرت');

      // 4) تحديث حالة الكروت (active/disabled/expired)
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
      sessionsSynced: 0,
      durationMs: stopwatch.elapsedMilliseconds,
      error: error,
    );
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
      Isar db, List<Map<String, dynamic>> profiles) async {
    if (profiles.isEmpty) return 0;

    int count = 0;
    await db.writeTxn(() async {
      for (final p in profiles) {
        final name = p['name'] as String?;
        if (name == null || name.isEmpty) continue;

        // تحقق إذا كان موجوداً
        final existing = await db.profileCollections
            .where()
            .nameEqualTo(name)
            .findFirst();

        if (existing != null) {
          existing.mikrotikId = p['.id'] as String?;
          existing.rateLimit = p['rate-limit'] as String?;
          existing.sharedUsers =
              int.tryParse(p['shared-users'] as String? ?? '1') ?? 1;
          existing.uploadUsedBytes =
              int.tryParse(p['upload-used'] as String? ?? '0') ?? 0;
          existing.downloadUsedBytes =
              int.tryParse(p['download-used'] as String? ?? '0') ?? 0;
          existing.uptimeUsedSeconds = _parseDuration(p['uptime-used'] as String?);
          existing.lastSyncedAt = DateTime.now();
          await db.profileCollections.put(existing);
        } else {
          final newProfile = ProfileCollection.fromData(
            name: name,
            mikrotikId: p['.id'] as String?,
            rateLimit: p['rate-limit'] as String?,
            sharedUsers:
                int.tryParse(p['shared-users'] as String? ?? '1') ?? 1,
            uploadUsedBytes:
                int.tryParse(p['upload-used'] as String? ?? '0') ?? 0,
            downloadUsedBytes:
                int.tryParse(p['download-used'] as String? ?? '0') ?? 0,
            uptimeUsedSeconds: _parseDuration(p['uptime-used'] as String?),
            createdAt: DateTime.now(),
            lastSyncedAt: DateTime.now(),
          );
          await db.profileCollections.put(newProfile);
        }
        count++;
      }
    });
    return count;
  }

  /// يزامن الكروت (upsert)
  Future<int> _syncCards(Isar db, List<Map<String, dynamic>> users) async {
    if (users.isEmpty) return 0;

    int count = 0;
    await db.writeTxn(() async {
      for (final u in users) {
        final username = u['username'] as String?;
        if (username == null || username.isEmpty) continue;

        // ابحث عن الـ profile المرتبط
        final profileName = u['actual-profile'] as String?;
        int? profileId;
        if (profileName != null) {
          final profile = await db.profileCollections
              .where()
              .nameEqualTo(profileName)
              .findFirst();
          profileId = profile?.id;
        }
        // لو لم نجد الـ profile، نستخدم أول profile أو ننشئ default
        if (profileId == null) {
          final defaultProfile =
              await db.profileCollections.where().findFirst();
          if (defaultProfile != null) {
            profileId = defaultProfile.id;
          } else {
            final newProfile = ProfileCollection.fromData(
              name: 'default',
              createdAt: DateTime.now(),
            );
            await db.profileCollections.put(newProfile);
            profileId = newProfile.id;
          }
        }

        // تحقق إذا كان الكرت موجوداً
        final existing = await db.cardCollections
            .where()
            .usernameEqualTo(username)
            .findFirst();

        final isDisabled = (u['disabled'] as String?) == 'true';

        if (existing != null) {
          existing.password = u['password'] as String?;
          existing.profileId = profileId;
          existing.sharedUsers =
              int.tryParse(u['shared-users'] as String? ?? '1') ?? 1;
          existing.status = isDisabled ? 'disabled' : 'active';
          existing.uploadBytes =
              int.tryParse(u['upload-used'] as String? ?? '0') ?? 0;
          existing.downloadBytes =
              int.tryParse(u['download-used'] as String? ?? '0') ?? 0;
          existing.uptimeSeconds = _parseDuration(u['uptime-used'] as String?);
          existing.mikrotikUserId = u['.id'] as String?;
          existing.lastUsedAt = DateTime.now();
          await db.cardCollections.put(existing);
        } else {
          final newCard = CardCollection.fromData(
            username: username,
            password: u['password'] as String?,
            profileId: profileId,
            sharedUsers:
                int.tryParse(u['shared-users'] as String? ?? '1') ?? 1,
            status: isDisabled ? 'disabled' : 'active',
            uploadBytes:
                int.tryParse(u['upload-used'] as String? ?? '0') ?? 0,
            downloadBytes:
                int.tryParse(u['download-used'] as String? ?? '0') ?? 0,
            uptimeSeconds: _parseDuration(u['uptime-used'] as String?),
            mikrotikUserId: u['.id'] as String?,
            createdAt: DateTime.now(),
            lastUsedAt: DateTime.now(),
          );
          await db.cardCollections.put(newCard);
        }
        count++;
      }
    });
    return count;
  }

  /// يحدّث حالة الكروت (expired للكروت المنتهية)
  Future<void> _updateCardStatuses(Isar db) async {
    await db.writeTxn(() async {
      final cards = await db.cardCollections.where().findAll();
      for (final card in cards) {
        final profile =
            await db.profileCollections.get(card.profileId);
        if (profile?.uptimeLimitSeconds != null &&
            profile!.uptimeLimitSeconds! > 0 &&
            card.uptimeSeconds >= profile.uptimeLimitSeconds!) {
          card.status = 'expired';
          await db.cardCollections.put(card);
        }
      }
    });
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
