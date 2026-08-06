// ============================================================
//  Migration Service — ترحيل البيانات من SharedPreferences/Files إلى Isar
//
//  يعمل مرة واحدة عند أول تشغيل بعد التحديث.
//  يحل محل Drift MigrationService القديم.
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import 'isar_provider.dart';
import 'isar/card_collection.dart';
import 'isar/profile_collection.dart';
import 'isar/ai_diagnostic_collection.dart';

class MigrationService {
  MigrationService._();
  static final MigrationService instance = MigrationService._();

  static const _migrationDoneKey = 'isar_migration_done';

  /// يتحقق إذا تم الترحيل مسبقاً
  Future<bool> isMigrationDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationDoneKey) ?? false;
  }

  /// ينفّذ الترحيل الكامل من SharedPreferences/Files إلى Isar
  Future<void> migrateFromDriftIfNeeded() async {
    if (await isMigrationDone()) {
      debugPrint('[Migration] Already done — skipping');
      return;
    }

    debugPrint('[Migration] Starting migration to Isar...');
    final stopwatch = Stopwatch()..start();

    try {
      final isar = await IsarProvider().instance;

      await _migrateDiagnosticsSessions(isar);
      await _migrateSavedCards(isar);

      // وضع علامة أن الترحيل تم
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationDoneKey, true);

      stopwatch.stop();
      debugPrint(
          '[Migration] Completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, st) {
      debugPrint('[Migration] Error: $e\n$st');
      // لا نضع علامة "تم" — سيتكرر المحاولة في التشغيل التالي
    }
  }

  /// ترحيل جلسات التشخيص من SharedPreferences
  Future<void> _migrateDiagnosticsSessions(dynamic isar) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getString('diagnostics_sessions');
    if (sessionsJson == null) {
      debugPrint('[Migration] No diagnostics sessions to migrate');
      return;
    }

    try {
      final List<dynamic> sessions = jsonDecode(sessionsJson);
      debugPrint(
          '[Migration] Migrating ${sessions.length} diagnostic sessions...');

      final diagnostics = <AiDiagnosticCollection>[];
      for (final sessionData in sessions) {
        final session = sessionData as Map<String, dynamic>;
        final messages = (session['messages'] as List?) ?? [];

        // استخراج أول سؤال من المستخدم
        String userQuery = '';
        for (final m in messages) {
          if (m['type'] == 'user') {
            userQuery = m['content'] as String? ?? '';
            break;
          }
        }

        // استخراج آخر رد من الـ AI
        String aiResponse = '';
        for (final m in messages.reversed) {
          if (m['type'] == 'assistant') {
            aiResponse = m['content'] as String? ?? '';
            break;
          }
        }

        final startedAt =
            DateTime.tryParse(session['startedAt'] as String? ?? '') ??
                DateTime.now();
        final endedAt = session['endedAt'] != null
            ? DateTime.tryParse(session['endedAt'] as String)
            : null;

        diagnostics.add(AiDiagnosticCollection.fromData(
          mode: session['mode'] as String? ?? 'general',
          mikrotikIp: session['mikrotikIp'] as String?,
          startedAt: startedAt,
          endedAt: endedAt,
          userQuery: userQuery,
          aiResponse: aiResponse,
          snapshotJson: jsonEncode(session),
          isFavorite: false,
        ));
      }

      await isar.writeTxn(() async {
        await isar.aiDiagnosticCollections.putAll(diagnostics);
      });

      // حذف من SharedPreferences بعد الترحيل الناجح
      await prefs.remove('diagnostics_sessions');
      debugPrint('[Migration] Diagnostics sessions migrated successfully');
    } catch (e) {
      debugPrint('[Migration] Error migrating diagnostics: $e');
    }
  }

  /// ترحيل الكروت المحفوظة من ملفات نصية
  Future<void> _migrateSavedCards(dynamic isar) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cardsDir = Directory('${appDir.path}/saved_cards');

      if (!await cardsDir.exists()) {
        debugPrint('[Migration] No saved_cards directory');
        return;
      }

      final files = await cardsDir.list().toList();
      debugPrint('[Migration] Migrating ${files.length} card files...');

      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.txt')) {
          final content = await entity.readAsString();
          final usernames = content
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList();

          if (usernames.isEmpty) continue;

          // اسم الملف يحتوي عادة على اسم الفئة
          final profileName =
              entity.path.split('/').last.replaceAll('.txt', '');

          // إضافة profile إن لم يكن موجوداً
          ProfileCollection? existingProfile = await isar.profileCollections
              .where()
              .nameEqualTo(profileName)
              .findFirst();

          int profileId;
          if (existingProfile != null) {
            profileId = existingProfile.id;
          } else {
            final newProfile = ProfileCollection.fromData(
              name: profileName,
              createdAt: DateTime.now(),
            );
            await isar.writeTxn(() async {
              await isar.profileCollections.put(newProfile);
            });
            profileId = newProfile.id;
          }

          // إضافة الكروت
          final cards = usernames
              .map((username) => CardCollection.fromData(
                    username: username,
                    profileId: profileId,
                    createdAt: DateTime.now(),
                  ))
              .toList();

          await isar.writeTxn(() async {
            await isar.cardCollections.putAll(cards);
          });
        }
      }

      debugPrint('[Migration] Saved cards migrated successfully');
    } catch (e) {
      debugPrint('[Migration] Error migrating cards: $e');
    }
  }

  /// إعادة الترحيل (للاختبار أو إعادة الضبط)
  Future<void> resetMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationDoneKey);
  }
}
