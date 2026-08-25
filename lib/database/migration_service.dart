//  Migration Service — ترحيل البيانات القديمة إلى Isar
//
//  يطبق الهجرة مرة واحدة لكل إصدار schema، مع حالات واضحة وإمكانية
//  إعادة المحاولة بعد الفشل. لا تُحذف البيانات القديمة قبل نجاح الكتابة.
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'isar/ai_diagnostic_collection.dart';
import 'isar/card_collection.dart';
import 'isar/profile_collection.dart';
import 'isar_provider.dart';

class MigrationService {
  MigrationService._();
  static final MigrationService instance = MigrationService._();

  static const int currentMigrationVersion = 2;
  static const _migrationVersionKey = 'isar_migration_version';
  static const _migrationStateKey = 'isar_migration_state';
  static const _legacyMigrationDoneKey = 'isar_migration_done';
  static const _diagnosticsLegacyKey = 'diagnostics_sessions';

  // Prevents two startup paths from running the same migration concurrently.
  Future<void>? _runningMigration;

  Future<bool> isMigrationDone() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_migrationVersionKey) ?? 0) >=
        currentMigrationVersion;
  }

  /// ينفذ الهجرة القديمة مرة واحدة لكل إصدار schema.
  ///
  /// في حال الفشل يُعاد رمي الخطأ وتبقى الحالة failed، كي يعاد التنفيذ
  /// في التشغيل التالي بدل اعتبار الهجرة ناجحة بشكل جزئي.
  Future<void> migrateLegacyDataIfNeeded() {
    final running = _runningMigration;
    if (running != null) return running;

    final future = _runMigration();
    _runningMigration = future;
    return future.whenComplete(() {
      if (identical(_runningMigration, future)) {
        _runningMigration = null;
      }
    });
  }

  Future<void> _runMigration() async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getInt(_migrationVersionKey) ?? 0) >=
        currentMigrationVersion) {
      debugPrint('[Migration] Already done — skipping');
      return;
    }

    await prefs.setString(_migrationStateKey, 'in_progress');
    final stopwatch = Stopwatch()..start();

    try {
      final isar = await IsarProvider().instance;
      final diagnosticsCount = await _migrateDiagnosticsSessions(isar, prefs);
      final cardsCount = await _migrateSavedCards(isar);
      await _repairCardProfileReferences(isar);

      // The version is advanced only after every source has been processed
      // successfully. A failure therefore remains safely retryable.
      await prefs.setInt(_migrationVersionKey, currentMigrationVersion);
      await prefs.setBool(_legacyMigrationDoneKey, true);
      await prefs.setString(_migrationStateKey, 'completed');

      stopwatch.stop();
      debugPrint(
        '[Migration] Completed in ${stopwatch.elapsedMilliseconds}ms '
        '(diagnostics=$diagnosticsCount, cards=$cardsCount)',
      );
    } catch (error, stackTrace) {
      await prefs.setString(_migrationStateKey, 'failed');
      debugPrint('[Migration] Failed: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<int> _migrateDiagnosticsSessions(
    Isar isar,
    SharedPreferences prefs,
  ) async {
    final sessionsJson = prefs.getString(_diagnosticsLegacyKey);
    if (sessionsJson == null || sessionsJson.trim().isEmpty) {
      debugPrint('[Migration] No diagnostics sessions to migrate');
      return 0;
    }

    final decoded = jsonDecode(sessionsJson);
    if (decoded is! List) {
      throw const FormatException('diagnostics_sessions must be a JSON list');
    }

    final diagnostics = <AiDiagnosticCollection>[];
    final seenSnapshots = <String>{};
    for (final rawSession in decoded) {
      if (rawSession is! Map) {
        continue;
      }
      final session = Map<String, dynamic>.from(rawSession);
      final messages = session['messages'] is List
          ? session['messages'] as List
          : const <dynamic>[];

      var userQuery = '';
      for (final rawMessage in messages) {
        if (rawMessage is Map && rawMessage['type'] == 'user') {
          final content = rawMessage['content'];
          if (content is String) userQuery = content;
          break;
        }
      }

      var aiResponse = '';
      for (final rawMessage in messages.reversed) {
        if (rawMessage is Map && rawMessage['type'] == 'assistant') {
          final content = rawMessage['content'];
          if (content is String) aiResponse = content;
          break;
        }
      }

      final startedAt = DateTime.tryParse(
            session['startedAt']?.toString() ?? '',
          ) ??
          DateTime.now();
      final endedAt = DateTime.tryParse(session['endedAt']?.toString() ?? '');
      final snapshotJson = jsonEncode(session);

      // snapshotJson هو مفتاح idempotency للهجرة القديمة.
      if (!seenSnapshots.add(snapshotJson)) continue;
      final alreadyMigrated = await isar.aiDiagnosticCollections
          .filter()
          .snapshotJsonEqualTo(snapshotJson)
          .findFirst();
      if (alreadyMigrated != null) continue;

      diagnostics.add(
        AiDiagnosticCollection.fromData(
          mode: session['mode']?.toString() ?? 'general',
          mikrotikIp: session['mikrotikIp']?.toString(),
          startedAt: startedAt,
          endedAt: endedAt,
          userQuery: userQuery,
          aiResponse: aiResponse,
          snapshotJson: snapshotJson,
          isFavorite: session['isFavorite'] == true ||
              session['isFavorite']?.toString().toLowerCase() == 'true',
        ),
      );
    }

    if (diagnostics.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.aiDiagnosticCollections.putAll(diagnostics);
      });
    }

    // نحذف المصدر فقط بعد نجاح transaction كاملة.
    await prefs.remove(_diagnosticsLegacyKey);
    return diagnostics.length;
  }

  Future<int> _migrateSavedCards(Isar isar) async {
    // saved_cards ملفات محلية؛ لا يوجد مصدر ملفات مماثل على Web.
    if (kIsWeb) return 0;

    final appDir = await getApplicationDocumentsDirectory();
    final cardsDir = Directory(p.join(appDir.path, 'saved_cards'));
    if (!await cardsDir.exists()) {
      debugPrint('[Migration] No saved_cards directory');
      return 0;
    }

    final entities = await cardsDir.list().toList();
    var migratedCount = 0;
    for (final entity in entities) {
      if (entity is! File || p.extension(entity.path).toLowerCase() != '.txt') {
        continue;
      }

      final content = await entity.readAsString();
      final usernames = content
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toSet();
      if (usernames.isEmpty) continue;

      final profileName = p.basenameWithoutExtension(entity.path).trim();
      if (profileName.isEmpty) continue;

      // Profile creation and card insertion are one atomic operation per
      // source file. This prevents a crash from leaving half a migrated file.
      final inserted = await isar.writeTxn(() async {
        var profile = await isar.profileCollections
            .where()
            .nameEqualTo(profileName)
            .findFirst();

        profile ??= ProfileCollection.fromData(
          name: profileName,
          createdAt: DateTime.now(),
        );
        await isar.profileCollections.put(profile);

        final cards = <CardCollection>[];
        for (final username in usernames) {
          final existing = await isar.cardCollections
              .where()
              .usernameEqualTo(username)
              .findFirst();
          if (existing == null) {
            cards.add(
              CardCollection.fromData(
                username: username,
                profileId: profile.id,
                createdAt: DateTime.now(),
              ),
            );
          }
        }

        if (cards.isNotEmpty) {
          await isar.cardCollections.putAll(cards);
        }
        return cards.length;
      });
      migratedCount += inserted;

      // Delete each legacy source only after its transaction committed.
      // Re-running the migration is still safe because the username index
      // makes card insertion idempotent.
      try {
        await entity.delete();
      } catch (error, stackTrace) {
        // Failure to remove the legacy source must not invalidate the data
        // already migrated. The next migration run will safely skip duplicates.
        debugPrint('[Migration] Could not delete ${entity.path}: $error\\n$stackTrace');
      }
    }

    return migratedCount;
  }

  /// Repairs cards whose profile was deleted or never existed in the legacy
  /// source. Isar does not enforce relational foreign keys.
  Future<void> _repairCardProfileReferences(Isar isar) async {
    final cards = await isar.cardCollections.where().findAll();
    if (cards.isEmpty) return;

    final profiles = await isar.profileCollections.where().findAll();
    final validIds = profiles.map((profile) => profile.id).toSet();
    final invalid = cards.where((card) => !validIds.contains(card.profileId)).toList();
    if (invalid.isEmpty) return;

    const fallbackName = '__unassigned__';
    ProfileCollection? fallback;
    for (final profile in profiles) {
      if (profile.name == fallbackName) {
        fallback = profile;
        break;
      }
    }

    await isar.writeTxn(() async {
      fallback ??= ProfileCollection.fromData(
        name: fallbackName,
        createdAt: DateTime.now(),
      );
      await isar.profileCollections.put(fallback!);
      for (final card in invalid) {
        card.profileId = fallback!.id;
        await isar.cardCollections.put(card);
      }
    });
    debugPrint('[Migration] Repaired ${invalid.length} orphan cards');
  }

  /// يعيد ضبط حالة الهجرة للاختبار أو لإعادة المحاولة يدويًا.
  Future<void> resetMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationVersionKey);
    await prefs.remove(_migrationStateKey);
    await prefs.remove(_legacyMigrationDoneKey);
  }
}
