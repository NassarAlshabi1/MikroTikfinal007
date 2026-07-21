// ============================================================
//  ExecutedCommandsDao — Audit Trail للأوامر المنفّذة
// ============================================================

import 'package:drift/drift.dart';
import '../app_database.dart';

part 'executed_commands_dao.g.dart';

@DriftAccessor(tables: [ExecutedCommands])
class ExecutedCommandsDao extends DatabaseAccessor<AppDatabase>
    with _$ExecutedCommandsDaoMixin {
  ExecutedCommandsDao(super.db);

  // ============================================================
  //  CRUD
  // ============================================================

  Future<int> insertCommand(ExecutedCommandsCompanion command) =>
      into(executedCommands).insert(command);

  Future<int> deleteCommand(int id) =>
      (delete(executedCommands)..where((c) => c.id.equals(id))).go();

  // ============================================================
  //  Queries
  // ============================================================

  /// كل الأوامر (مرتبة بالأحدث)
  Future<List<ExecutedCommand>> getAllCommands() =>
      (select(executedCommands)
            ..orderBy([(c) => OrderingTerm.desc(c.executedAt)]))
          .get();

  /// آخر N أمر
  Future<List<ExecutedCommand>> getRecentCommands(int limit) =>
      (select(executedCommands)
            ..orderBy([(c) => OrderingTerm.desc(c.executedAt)])
            ..limit(limit))
          .get();

  /// الأوامر الناجحة فقط
  Future<List<ExecutedCommand>> getSuccessfulCommands() =>
      (select(executedCommands)
            ..where((c) => c.success.equals(true))
            ..orderBy([(c) => OrderingTerm.desc(c.executedAt)]))
          .get();

  /// الأوامر الفاشلة فقط
  Future<List<ExecutedCommand>> getFailedCommands() =>
      (select(executedCommands)
            ..where((c) => c.success.equals(false))
            ..orderBy([(c) => OrderingTerm.desc(c.executedAt)]))
          .get();

  /// الأوامر حسب مستوى الخطورة
  Future<List<ExecutedCommand>> getCommandsByRisk(String riskLevel) =>
      (select(executedCommands)
            ..where((c) => c.riskLevel.equals(riskLevel))
            ..orderBy([(c) => OrderingTerm.desc(c.executedAt)]))
          .get();

  /// أوامر جلسة تشخيص محددة
  Future<List<ExecutedCommand>> getCommandsByDiagnostic(int diagnosticId) =>
      (select(executedCommands)
            ..where((c) => c.diagnosticId.equals(diagnosticId))
            ..orderBy([(c) => OrderingTerm.desc(c.executedAt)]))
          .get();

  // ============================================================
  //  Stream
  // ============================================================

  Stream<List<ExecutedCommand>> watchAllCommands() =>
      (select(executedCommands)
            ..orderBy([(c) => OrderingTerm.desc(c.executedAt)]))
          .watch();

  Stream<List<ExecutedCommand>> watchRecentCommands(int limit) =>
      (select(executedCommands)
            ..orderBy([(c) => OrderingTerm.desc(c.executedAt)])
            ..limit(limit))
          .watch();

  // ============================================================
  //  Statistics
  // ============================================================

  /// إحصائيات الأوامر المنفّذة
  Future<CommandsStatistics> getStatistics() async {
    final total = await executedCommands.count().getSingle();

    // عدد الأوامر الناجحة (selectOnly + where لأن count() يُعيد
    // Selectable<int> بدون where في drift 2.31+)
    final successResult = await (selectOnly(executedCommands)
          ..addColumns([executedCommands.id.count()])
          ..where(executedCommands.success.equals(true)))
        .getSingle();
    final successful = successResult.read(executedCommands.id.count()) ?? 0;
    final failed = total - successful;

    // متوسط زمن التنفيذ
    final avgResult = await (selectOnly(executedCommands)
          ..addColumns([executedCommands.durationMs.avg()]))
        .getSingle();
    final avgDuration = avgResult.read(executedCommands.durationMs.avg());

    // إحصائيات حسب مستوى الخطورة
    final byRiskQuery = selectOnly(executedCommands)
      ..addColumns([executedCommands.riskLevel, executedCommands.id.count()])
      ..groupBy([executedCommands.riskLevel]);
    final byRiskResults = await byRiskQuery.get();
    final byRisk = <String, int>{};
    for (final row in byRiskResults) {
      final risk = row.read(executedCommands.riskLevel) ?? 'unknown';
      final count = row.read(executedCommands.id.count()) ?? 0;
      byRisk[risk] = count;
    }

    return CommandsStatistics(
      totalCommands: total,
      successfulCommands: successful,
      failedCommands: failed,
      avgDurationMs: avgDuration?.toInt() ?? 0,
      byRisk: byRisk,
    );
  }

  /// تقرير شهري للأوامر المنفّذة
  Future<List<MonthlyCommandReport>> getMonthlyReport() async {
    // استخدام raw SQL للـ strftime
    final results = await customSelect(
      "SELECT strftime('%Y-%m', datetime(executed_at / 1000, 'unixepoch')) as month, "
      "COUNT(*) as total, "
      "SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as successful, "
      "AVG(duration_ms) as avg_duration "
      "FROM executed_commands "
      "GROUP BY month "
      "ORDER BY month DESC "
      "LIMIT 12",
      readsFrom: {executedCommands},
    ).get();

    return results
        .map((row) => MonthlyCommandReport(
              month: row.read<String>('month'),
              total: row.read<int>('total'),
              successful: row.read<int>('successful'),
              failed: row.read<int>('total') - row.read<int>('successful'),
              avgDurationMs: (row.read<num?>('avg_duration') ?? 0).toInt(),
            ))
        .toList();
  }

  // ============================================================
  //  Cleanup
  // ============================================================

  /// حذف الأوامر الأقدم من تاريخ محدد
  Future<int> deleteOlderThan(DateTime date) =>
      (delete(executedCommands)
            ..where((c) => c.executedAt.isSmallerThanValue(date)))
          .go();
}

class CommandsStatistics {
  final int totalCommands;
  final int successfulCommands;
  final int failedCommands;
  final int avgDurationMs;
  final Map<String, int> byRisk;

  const CommandsStatistics({
    required this.totalCommands,
    required this.successfulCommands,
    required this.failedCommands,
    required this.avgDurationMs,
    required this.byRisk,
  });

  double get successRate =>
      totalCommands > 0 ? (successfulCommands / totalCommands * 100) : 0;
}

class MonthlyCommandReport {
  final String month;
  final int total;
  final int successful;
  final int failed;
  final int avgDurationMs;

  const MonthlyCommandReport({
    required this.month,
    required this.total,
    required this.successful,
    required this.failed,
    required this.avgDurationMs,
  });
}
