// ============================================================
//  AiDiagnosticsDao — Data Access Object لسجل التشخيصات AI
//  يحل محل التخزين في SharedPreferences (أسرع بكثير)
// ============================================================

import 'package:drift/drift.dart';
import '../app_database.dart';

part 'ai_diagnostics_dao.g.dart';

@DriftAccessor(tables: [AiDiagnostics, ExecutedCommands])
class AiDiagnosticsDao extends DatabaseAccessor<AppDatabase>
    with _$AiDiagnosticsDaoMixin {
  AiDiagnosticsDao(super.db);

  // ============================================================
  //  CRUD
  // ============================================================

  /// إضافة جلسة تشخيص جديدة
  Future<int> insertDiagnostic(AiDiagnosticsCompanion diagnostic) =>
      into(aiDiagnostics).insert(diagnostic);

  /// تحديث جلسة
  Future<bool> updateDiagnostic(AiDiagnostic diagnostic) =>
      update(aiDiagnostics).replace(diagnostic);

  /// حذف جلسة
  Future<int> deleteDiagnostic(int id) =>
      (delete(aiDiagnostics)..where((d) => d.id.equals(id))).go();

  /// حذف كل الجلسات
  Future<int> deleteAllDiagnostics() => delete(aiDiagnostics).go();

  // ============================================================
  //  Queries
  // ============================================================

  /// كل الجلسات (مرتبة بالأحدث)
  Future<List<AiDiagnostic>> getAllDiagnostics() =>
      (select(aiDiagnostics)
            ..orderBy([(d) => OrderingTerm.desc(d.startedAt)]))
          .get();

  /// جلسة واحدة بالـ ID
  Future<AiDiagnostic?> getDiagnosticById(int id) =>
      (select(aiDiagnostics)..where((d) => d.id.equals(id)))
          .getSingleOrNull();

  /// الجلسات المفضلة فقط
  Future<List<AiDiagnostic>> getFavoriteDiagnostics() =>
      (select(aiDiagnostics)
            ..where((d) => d.isFavorite.equals(true))
            ..orderBy([(d) => OrderingTerm.desc(d.startedAt)]))
          .get();

  /// الجلسات حسب الـ mode
  Future<List<AiDiagnostic>> getDiagnosticsByMode(String mode) =>
      (select(aiDiagnostics)
            ..where((d) => d.mode.equals(mode))
            ..orderBy([(d) => OrderingTerm.desc(d.startedAt)]))
          .get();

  /// آخر N جلسة
  Future<List<AiDiagnostic>> getRecentDiagnostics(int limit) =>
      (select(aiDiagnostics)
            ..orderBy([(d) => OrderingTerm.desc(d.startedAt)])
            ..limit(limit))
          .get();

  /// بحث في الـ user query أو الـ response
  Future<List<AiDiagnostic>> searchDiagnostics(String query) =>
      (select(aiDiagnostics)
            ..where((d) =>
                d.userQuery.like('%$query%') |
                d.aiResponse.like('%$query%'))
            ..orderBy([(d) => OrderingTerm.desc(d.startedAt)]))
          .get();

  // ============================================================
  //  Stream (reactive)
  // ============================================================

  Stream<List<AiDiagnostic>> watchAllDiagnostics() =>
      (select(aiDiagnostics)
            ..orderBy([(d) => OrderingTerm.desc(d.startedAt)]))
          .watch();

  Stream<List<AiDiagnostic>> watchFavoriteDiagnostics() =>
      (select(aiDiagnostics)
            ..where((d) => d.isFavorite.equals(true))
            ..orderBy([(d) => OrderingTerm.desc(d.startedAt)]))
          .watch();

  // ============================================================
  //  Toggle Favorite
  // ============================================================

  Future<void> toggleFavorite(int id) async {
    final diagnostic = await getDiagnosticById(id);
    if (diagnostic != null) {
      await (update(aiDiagnostics)..where((d) => d.id.equals(id)))
          .write(AiDiagnosticsCompanion(
        isFavorite: Value(!diagnostic.isFavorite),
      ));
    }
  }

  // ============================================================
  //  Statistics
  // ============================================================

  /// إحصائيات التشخيصات
  Future<DiagnosticsStatistics> getStatistics() async {
    final total = await aiDiagnostics.count().get();

    // عدد المفضّلة (selectOnly + where لأن count() يُعيد Selectable<int>
    // بدون where في drift 2.31+)
    final favResult = await (selectOnly(aiDiagnostics)
          ..addColumns([aiDiagnostics.count()])
          ..where(aiDiagnostics.isFavorite.equals(true)))
        .getSingle();
    final favorites = favResult.read(aiDiagnostics.count()) ?? 0;

    // إحصائيات حسب الـ mode
    final byModeQuery = selectOnly(aiDiagnostics)
      ..addColumns([aiDiagnostics.mode, aiDiagnostics.count()])
      ..groupBy([aiDiagnostics.mode]);
    final byModeResults = await byModeQuery.get();
    final byMode = <String, int>{};
    for (final row in byModeResults) {
      final mode = row.read(aiDiagnostics.mode) as String;
      final count = row.read(aiDiagnostics.count()) as int;
      byMode[mode] = count;
    }

    return DiagnosticsStatistics(
      totalSessions: total,
      favoriteSessions: favorites,
      byMode: byMode,
    );
  }

  /// إجمالي tokens المستخدمة
  Future<int> getTotalTokensUsed() async {
    final result = await (selectOnly(aiDiagnostics)
          ..addColumns([aiDiagnostics.tokensUsed.sum()]))
        .getSingle();
    return result.read(aiDiagnostics.tokensUsed.sum()) ?? 0;
  }

  // ============================================================
  //  Cleanup
  // ============================================================

  /// حذف الجلسات الأقدم من تاريخ محدد (للحفاظ على حجم الـ DB)
  Future<int> deleteOlderThan(DateTime date) =>
      (delete(aiDiagnostics)
            ..where((d) => d.startedAt.isSmallerThanValue(date)))
          .go();

  /// الاحتفاظ بآخر N جلسة فقط (حذف الباقي)
  Future<void> keepOnlyLatest(int keepCount) async {
    final all = await getAllDiagnostics();
    if (all.length > keepCount) {
      final toDelete = all.skip(keepCount);
      for (final d in toDelete) {
        await deleteDiagnostic(d.id);
      }
    }
  }
}

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
