// ============================================================
//  AiDiagnosticsDao (Isar) — Data Access Object لسجل التشخيصات AI
//
//  يحل محل قاعدة البيانات السابقة AiDiagnosticsDao القديم.
// ============================================================

import 'package:isar/isar.dart';

import '../isar/ai_diagnostic_collection.dart';

class DiagnosticsStatistics {
  final int totalSessions;
  final int favoriteSessions;
  final Map<String, int> byMode;

  const DiagnosticsStatistics({
    required this.totalSessions,
    required this.favoriteSessions,
    required this.byMode,
  });
}

class AiDiagnosticsDao {
  final Isar _isar;
  AiDiagnosticsDao(this._isar);

  // ============================================================
  //  CRUD
  // ============================================================

  Future<int> insertDiagnostic(AiDiagnosticCollection diagnostic) async {
    await _isar.writeTxn(
        () => _isar.aiDiagnosticCollections.put(diagnostic));
    return diagnostic.id;
  }

  Future<bool> updateDiagnostic(AiDiagnosticCollection diagnostic) async {
    await _isar.writeTxn(() => _isar.aiDiagnosticCollections.put(diagnostic));
    return true;
  }

  Future<bool> deleteDiagnostic(int id) async {
    return await _isar.writeTxn(() => _isar.aiDiagnosticCollections.delete(id));
  }

  Future<int> deleteAllDiagnostics() async {
    return await _isar.writeTxn(() async {
      final count = await _isar.aiDiagnosticCollections.count();
      await _isar.aiDiagnosticCollections.clear();
      return count;
    });
  }

  // ============================================================
  //  Queries
  // ============================================================

  /// كل الجلسات (مرتبة بالأحدث)
  Future<List<AiDiagnosticCollection>> getAllDiagnostics() async {
    return await _isar.aiDiagnosticCollections
        .where()
        .sortByStartedAtDesc()
        .findAll();
  }

  /// جلسة بالـ ID
  Future<AiDiagnosticCollection?> getDiagnosticById(int id) async {
    return await _isar.aiDiagnosticCollections.get(id);
  }

  /// الجلسات المفضلة فقط
  Future<List<AiDiagnosticCollection>> getFavoriteDiagnostics() async {
    return await _isar.aiDiagnosticCollections
        .filter()
        .isFavoriteEqualTo(true)
        .sortByStartedAtDesc()
        .findAll();
  }

  /// الجلسات حسب الـ mode
  Future<List<AiDiagnosticCollection>> getDiagnosticsByMode(String mode) async {
    return await _isar.aiDiagnosticCollections
        .filter()
        .modeEqualTo(mode)
        .sortByStartedAtDesc()
        .findAll();
  }

  /// آخر N جلسة
  Future<List<AiDiagnosticCollection>> getRecentDiagnostics(int limit) async {
    return await _isar.aiDiagnosticCollections
        .where()
        .sortByStartedAtDesc()
        .limit(limit)
        .findAll();
  }

  /// بحث في الـ user query أو الـ response
  Future<List<AiDiagnosticCollection>> searchDiagnostics(String query) async {
    if (query.isEmpty) return getAllDiagnostics();
    return await _isar.aiDiagnosticCollections
        .filter()
        .userQueryContains(query, caseSensitive: false)
        .or()
        .aiResponseContains(query, caseSensitive: false)
        .sortByStartedAtDesc()
        .findAll();
  }

  // ============================================================
  //  Stream (reactive)
  // ============================================================

  Stream<List<AiDiagnosticCollection>> watchAllDiagnostics() {
    return _isar.aiDiagnosticCollections
        .where()
        .sortByStartedAtDesc()
        .watch(fireImmediately: true);
  }

  Stream<List<AiDiagnosticCollection>> watchFavoriteDiagnostics() {
    return _isar.aiDiagnosticCollections
        .filter()
        .isFavoriteEqualTo(true)
        .sortByStartedAtDesc()
        .watch(fireImmediately: true);
  }

  // ============================================================
  //  Toggle Favorite
  // ============================================================

  Future<void> toggleFavorite(int id) async {
    await _isar.writeTxn(() async {
      final diagnostic = await _isar.aiDiagnosticCollections.get(id);
      if (diagnostic != null) {
        diagnostic.isFavorite = !diagnostic.isFavorite;
        await _isar.aiDiagnosticCollections.put(diagnostic);
      }
    });
  }

  // ============================================================
  //  Statistics
  // ============================================================

  Future<DiagnosticsStatistics> getStatistics() async {
    final all = await _isar.aiDiagnosticCollections.where().findAll();

    int favorites = 0;
    final byMode = <String, int>{};
    for (final d in all) {
      if (d.isFavorite) favorites++;
      byMode[d.mode] = (byMode[d.mode] ?? 0) + 1;
    }

    return DiagnosticsStatistics(
      totalSessions: all.length,
      favoriteSessions: favorites,
      byMode: byMode,
    );
  }

  /// إجمالي tokens المستخدمة
  Future<int> getTotalTokensUsed() async {
    final all = await _isar.aiDiagnosticCollections.where().findAll();
    int total = 0;
    for (final d in all) {
      total += d.tokensUsed ?? 0;
    }
    return total;
  }

  // ============================================================
  //  Cleanup
  // ============================================================

  /// حذف الجلسات الأقدم من تاريخ محدد
  Future<int> deleteOlderThan(DateTime date) async {
    return await _isar.writeTxn(() async {
      final old = await _isar.aiDiagnosticCollections
          .filter()
          .startedAtLessThan(date)
          .findAll();
      for (final d in old) {
        await _isar.aiDiagnosticCollections.delete(d.id);
      }
      return old.length;
    });
  }

  /// الاحتفاظ بآخر N جلسة فقط
  Future<void> keepOnlyLatest(int keepCount) async {
    await _isar.writeTxn(() async {
      final all = await getAllDiagnostics();
      if (all.length > keepCount) {
        final toDelete = all.skip(keepCount);
        for (final d in toDelete) {
          await _isar.aiDiagnosticCollections.delete(d.id);
        }
      }
    });
  }
}
