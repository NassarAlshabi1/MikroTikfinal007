// ============================================================
//  Migration Service — ترحيل البيانات من SharedPreferences/Files إلى SQLite
//  يعمل مرة واحدة عند أول تشغيل بعد التحديث
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

class MigrationService {
  MigrationService._();
  static final MigrationService instance = MigrationService._();

  static const _migrationDoneKey = 'sqlite_migration_done';

  /// يتحقق إذا تم الترحيل مسبقاً
  Future<bool> isMigrationDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationDoneKey) ?? false;
  }

  /// ينفّذ الترحيل الكامل من SharedPreferences/Files إلى SQLite
  Future<void> migrateIfNeeded(AppDatabase db) async {
    if (await isMigrationDone()) {
      debugPrint('[Migration] Already done — skipping');
      return;
    }

    debugPrint('[Migration] Starting migration to SQLite...');
    final stopwatch = Stopwatch()..start();

    try {
      await _migrateDiagnosticsSessions(db);
      await _migrateSavedCards(db);
      await _migratePdfTemplates(db);

      // وضع علامة أن الترحيل تم
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationDoneKey, true);

      stopwatch.stop();
      debugPrint('[Migration] Completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, st) {
      debugPrint('[Migration] Error: $e\n$st');
      // لا نضع علامة "تم" — سيتكرر المحاولة في التشغيل التالي
    }
  }

  /// ترحيل جلسات التشخيص من SharedPreferences
  Future<void> _migrateDiagnosticsSessions(AppDatabase db) async {
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

      await db.batch((b) {
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

          b.insert(
            db.aiDiagnostics,
            AiDiagnosticsCompanion.insert(
              mode: session['mode'] as String? ?? 'general',
              mikrotikIp: Value(session['mikrotikIp'] as String?),
              startedAt: startedAt,
              endedAt: Value(endedAt),
              userQuery: userQuery,
              aiResponse: aiResponse,
              snapshotJson: Value(jsonEncode(session)),
              isFavorite: const Value(false),
            ),
          );
        }
      });

      // حذف من SharedPreferences بعد الترحيل الناجح
      await prefs.remove('diagnostics_sessions');
      debugPrint('[Migration] Diagnostics sessions migrated successfully');
    } catch (e) {
      debugPrint('[Migration] Error migrating diagnostics: $e');
    }
  }

  /// ترحيل الكروت المحفوظة من ملفات نصية
  Future<void> _migrateSavedCards(AppDatabase db) async {
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
          final existingProfile = await (db.select(db.profiles)
                ..where((p) => p.name.equals(profileName)))
              .getSingleOrNull();

          int profileId;
          if (existingProfile != null) {
            profileId = existingProfile.id;
          } else {
            profileId = await db.into(db.profiles).insert(
                  ProfilesCompanion.insert(
                    name: profileName,
                    createdAt: DateTime.now(),
                  ),
                );
          }

          // إضافة الكروت
          await db.batch((b) {
            for (final username in usernames) {
              b.insert(
                db.cards,
                CardsCompanion.insert(
                  username: username,
                  profileId: profileId,
                  createdAt: DateTime.now(),
                ),
                mode: InsertMode.insertOrIgnore, // تجاهل التكرار
              );
            }
          });
        }
      }

      debugPrint('[Migration] Saved cards migrated successfully');
    } catch (e) {
      debugPrint('[Migration] Error migrating cards: $e');
    }
  }

  /// ترحيل PDF templates من SharedPreferences
  Future<void> _migratePdfTemplates(AppDatabase db) async {
    // PDF templates معقدة (تحتوي على نسب وقيم) — نتركها في SharedPreferences
    // لآنها لا تتناسب مع schema الحالي
    // يمكن ترحيلها لاحقاً لو احتجنا
    debugPrint('[Migration] PDF templates skipped (kept in SharedPreferences)');
  }

  /// إعادة الترحيل (للاختبار أو إعادة الضبط)
  Future<void> resetMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationDoneKey);
  }
}
