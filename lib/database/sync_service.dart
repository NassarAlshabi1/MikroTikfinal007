// ============================================================
//  SyncService — مزامنة الكروت والملفات الشخصية من MikroTik إلى Isar
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:router_os_client/router_os_client.dart';

import '../mikrotik_connector.dart';
import '../services/mikrotik_service_mode.dart';
import 'isar_provider.dart';
import 'isar/card_collection.dart';
import 'isar/profile_collection.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  /// يزامن الكروت والبروفايلات. Hotspot هو الوضع الافتراضي للتطبيق.
  Future<SyncResult> syncAll({
    Isar? database,
    void Function(double progress, String status)? onProgress,
    MikrotikServiceMode mode = MikrotikServiceMode.hotspot,
  }) async {
    Isar? db = database;
    db ??= await IsarProvider().instance;

    final stopwatch = Stopwatch()..start();
    int cardsSynced = 0;
    int profilesSynced = 0;
    String? error;
    RouterOSClient? client;

    try {
      onProgress?.call(0.0, 'جاري الاتصال بـ MikroTik...');
      client = await MikrotikConnector.connect();

      onProgress?.call(0.1, 'جاري جلب بروفايلات Hotspot...');
      final profilesResponse = await _safeTalk(
        client,
        _profilesCommand(mode),
      );
      profilesSynced = await _syncProfiles(db, profilesResponse);
      onProgress?.call(0.3, 'تمت مزامنة $profilesSynced بروفايل');

      onProgress?.call(0.4, 'جاري جلب مستخدمي Hotspot...');
      final usersResponse = await _safeTalk(
        client,
        _usersCommand(mode),
      );
      cardsSynced = await _syncCards(db, usersResponse, mode);
      onProgress?.call(0.7, 'تمت مزامنة $cardsSynced كرت');

      onProgress?.call(0.95, 'جاري تحديث حالات الكروت...');
      if (mode == MikrotikServiceMode.userManager) {
        await _updateCardStatuses(db);
      }
      onProgress?.call(1.0, 'اكتملت المزامنة');
    } on MikrotikCredentialsMissingException catch (e) {
      error = 'بيانات الاعتماد مفقودة: ${e.message}';
    } on MikrotikConnectionException catch (e) {
      error = 'فشل الاتصال: ${e.message}';
    } catch (e) {
      error = 'خطأ في المزامنة: $e';
      debugPrint('[SyncService] Error: $e');
    } finally {
      MikrotikConnector.release(client);
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

  List<String> _profilesCommand(MikrotikServiceMode mode) {
    if (mode == MikrotikServiceMode.hotspot) {
      return [
        '/ip/hotspot/user/profile/print',
        '=.proplist=.id,name,rate-limit,shared-users,session-timeout,idle-timeout',
      ];
    }
    return [
      '/tool/user-manager/profile/print',
      '=.proplist=.id,name,shared-users,rate-limit,uptime-used,upload-used,download-used',
    ];
  }

  List<String> _usersCommand(MikrotikServiceMode mode) {
    if (mode == MikrotikServiceMode.hotspot) {
      return [
        '/ip/hotspot/user/print',
        '=.proplist=.id,name,password,profile,disabled,limit-uptime,limit-bytes-total,comment',
      ];
    }
    return [
      '/tool/user-manager/user/print',
      '=.proplist=.id,username,password,disabled,actual-profile,shared-users,upload-used,download-used,uptime-used,uptime-limit',
    ];
  }

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

  Future<int> _syncProfiles(
      Isar db, List<Map<String, dynamic>> profiles) async {
    if (profiles.isEmpty) return 0;

    int count = 0;
    await db.writeTxn(() async {
      for (final p in profiles) {
        final name = p['name']?.toString().trim();
        if (name == null || name.isEmpty) continue;

        final existing =
            await db.profileCollections.where().nameEqualTo(name).findFirst();
        final sharedUsers = _parseInt(p['shared-users'], defaultValue: 1);
        final rateLimit = p['rate-limit']?.toString();
        final uploadUsed = _parseInt(p['upload-used']);
        final downloadUsed = _parseInt(p['download-used']);
        final uptimeUsed = _parseDuration(p['uptime-used']?.toString());

        final profile = existing ??
            ProfileCollection.fromData(
              name: name,
              createdAt: DateTime.now(),
            );
        profile.mikrotikId = p['.id']?.toString();
        profile.rateLimit = rateLimit;
        profile.sharedUsers = sharedUsers;
        profile.uploadUsedBytes = uploadUsed;
        profile.downloadUsedBytes = downloadUsed;
        profile.uptimeUsedSeconds = uptimeUsed;
        profile.lastSyncedAt = DateTime.now();
        await db.profileCollections.put(profile);
        count++;
      }
    });
    return count;
  }

  Future<int> _syncCards(Isar db, List<Map<String, dynamic>> users,
      MikrotikServiceMode mode) async {
    if (users.isEmpty) return 0;

    int count = 0;
    await db.writeTxn(() async {
      for (final u in users) {
        final usernameKey =
            mode == MikrotikServiceMode.hotspot ? 'name' : 'username';
        final profileKey =
            mode == MikrotikServiceMode.hotspot ? 'profile' : 'actual-profile';
        final username = u[usernameKey]?.toString().trim();
        if (username == null || username.isEmpty) continue;

        final profileName = u[profileKey]?.toString();
        final profile = profileName == null || profileName.isEmpty
            ? null
            : await db.profileCollections
                .where()
                .nameEqualTo(profileName)
                .findFirst();
        final profileId = await _profileId(db, profile);
        final existing = await db.cardCollections
            .where()
            .usernameEqualTo(username)
            .findFirst();

        final card = existing ??
            CardCollection.fromData(
              username: username,
              profileId: profileId,
              createdAt: DateTime.now(),
            );
        card.password = _nullableString(u['password']);
        card.profileId = profileId;
        card.status = _isDisabled(u['disabled']) ? 'disabled' : 'active';
        card.sharedUsers = profile?.sharedUsers ??
            _parseInt(u['shared-users'], defaultValue: 1);
        card.uploadBytes = mode == MikrotikServiceMode.hotspot
            ? 0
            : _parseInt(u['upload-used']);
        card.downloadBytes = mode == MikrotikServiceMode.hotspot
            ? 0
            : _parseInt(u['download-used']);
        card.uptimeSeconds = mode == MikrotikServiceMode.hotspot
            ? 0
            : _parseDuration(u['uptime-used']?.toString());
        card.mikrotikUserId = u['.id']?.toString();
        card.lastUsedAt = DateTime.now();
        await db.cardCollections.put(card);
        count++;
      }
    });
    return count;
  }

  Future<int> _profileId(Isar db, ProfileCollection? profile) async {
    if (profile != null) return profile.id;
    final defaultProfile = await db.profileCollections.where().findFirst();
    if (defaultProfile != null) return defaultProfile.id;

    final fallback = ProfileCollection.fromData(
      name: 'default',
      createdAt: DateTime.now(),
    );
    await db.profileCollections.put(fallback);
    return fallback.id;
  }

  Future<void> _updateCardStatuses(Isar db) async {
    await db.writeTxn(() async {
      final cards = await db.cardCollections.where().findAll();
      for (final card in cards) {
        final profile = await db.profileCollections.get(card.profileId);
        if (profile?.uptimeLimitSeconds != null &&
            profile!.uptimeLimitSeconds! > 0 &&
            card.uptimeSeconds >= profile.uptimeLimitSeconds!) {
          card.status = 'expired';
          await db.cardCollections.put(card);
        }
      }
    });
  }

  int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? defaultValue;
  }

  bool _isDisabled(dynamic value) {
    return value == true || value?.toString().toLowerCase() == 'true';
  }

  String? _nullableString(dynamic value) {
    final text = value?.toString();
    return text == null || text.isEmpty ? null : text;
  }

  int _parseDuration(String? duration) {
    if (duration == null || duration.isEmpty) return 0;

    int totalSeconds = 0;
    final regex = RegExp(r'(\d+)([wdhms])');
    for (final match in regex.allMatches(duration)) {
      final value = int.parse(match.group(1)!);
      switch (match.group(2)!) {
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
