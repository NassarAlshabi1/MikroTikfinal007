// ============================================================
//  ExecutedCommandsDao (Isar) — Audit Trail للأوامر المنفّذة
//
//  يحل محل قاعدة البيانات السابقة ExecutedCommandsDao القديم.
// ============================================================

import 'package:isar/isar.dart';

import '../isar/executed_command_collection.dart';

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

class ExecutedCommandsDao {
  final Isar _isar;
  ExecutedCommandsDao(this._isar);

  // ============================================================
  //  CRUD
  // ============================================================

  Future<int> insertCommand(ExecutedCommandCollection command) async {
    await _isar.writeTxn(() => _isar.executedCommandCollections.put(command));
    return command.id;
  }

  Future<bool> deleteCommand(int id) async {
    return await _isar
        .writeTxn(() => _isar.executedCommandCollections.delete(id));
  }

  // ============================================================
  //  Queries
  // ============================================================

  /// كل الأوامر (مرتبة بالأحدث)
  Future<List<ExecutedCommandCollection>> getAllCommands() async {
    return await _isar.executedCommandCollections
        .where()
        .sortByExecutedAtDesc()
        .findAll();
  }

  /// آخر N أمر
  Future<List<ExecutedCommandCollection>> getRecentCommands(int limit) async {
    return await _isar.executedCommandCollections
        .where()
        .sortByExecutedAtDesc()
        .limit(limit)
        .findAll();
  }

  /// الأوامر الناجحة فقط
  Future<List<ExecutedCommandCollection>> getSuccessfulCommands() async {
    return await _isar.executedCommandCollections
        .filter()
        .successEqualTo(true)
        .sortByExecutedAtDesc()
        .findAll();
  }

  /// الأوامر الفاشلة فقط
  Future<List<ExecutedCommandCollection>> getFailedCommands() async {
    return await _isar.executedCommandCollections
        .filter()
        .successEqualTo(false)
        .sortByExecutedAtDesc()
        .findAll();
  }

  /// الأوامر حسب مستوى الخطورة
  Future<List<ExecutedCommandCollection>> getCommandsByRisk(
      String riskLevel) async {
    return await _isar.executedCommandCollections
        .filter()
        .riskLevelEqualTo(riskLevel)
        .sortByExecutedAtDesc()
        .findAll();
  }

  /// أوامر جلسة تشخيص محددة
  Future<List<ExecutedCommandCollection>> getCommandsByDiagnostic(
      int diagnosticId) async {
    return await _isar.executedCommandCollections
        .filter()
        .diagnosticIdEqualTo(diagnosticId)
        .sortByExecutedAtDesc()
        .findAll();
  }

  // ============================================================
  //  Stream
  // ============================================================

  Stream<List<ExecutedCommandCollection>> watchAllCommands() {
    return _isar.executedCommandCollections
        .where()
        .sortByExecutedAtDesc()
        .watch(fireImmediately: true);
  }

  Stream<List<ExecutedCommandCollection>> watchRecentCommands(int limit) {
    return _isar.executedCommandCollections
        .where()
        .sortByExecutedAtDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  // ============================================================
  //  Statistics
  // ============================================================

  Future<CommandsStatistics> getStatistics() async {
    final all = await _isar.executedCommandCollections.where().findAll();

    int successful = 0;
    int totalDuration = 0;
    int durationCount = 0;
    final byRisk = <String, int>{};

    for (final cmd in all) {
      if (cmd.success) successful++;
      if (cmd.durationMs != null) {
        totalDuration += cmd.durationMs!;
        durationCount++;
      }
      final risk = cmd.riskLevel ?? 'unknown';
      byRisk[risk] = (byRisk[risk] ?? 0) + 1;
    }

    final failed = all.length - successful;
    final avgDuration =
        durationCount > 0 ? (totalDuration ~/ durationCount) : 0;

    return CommandsStatistics(
      totalCommands: all.length,
      successfulCommands: successful,
      failedCommands: failed,
      avgDurationMs: avgDuration,
      byRisk: byRisk,
    );
  }

  /// تقرير شهري للأوامر المنفّذة
  Future<List<MonthlyCommandReport>> getMonthlyReport() async {
    final all = await _isar.executedCommandCollections.where().findAll();

    final byMonth = <String, List<ExecutedCommandCollection>>{};
    for (final cmd in all) {
      final monthKey =
          '${cmd.executedAt.year}-${cmd.executedAt.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(monthKey, () => []).add(cmd);
    }

    final reports = <MonthlyCommandReport>[];
    final sortedMonths = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final month in sortedMonths.take(12)) {
      final commands = byMonth[month]!;
      final successful = commands.where((c) => c.success).length;
      final totalDuration =
          commands.fold<int>(0, (sum, c) => sum + (c.durationMs ?? 0));
      reports.add(MonthlyCommandReport(
        month: month,
        total: commands.length,
        successful: successful,
        failed: commands.length - successful,
        avgDurationMs:
            commands.isNotEmpty ? totalDuration ~/ commands.length : 0,
      ));
    }
    return reports;
  }

  // ============================================================
  //  Cleanup
  // ============================================================

  /// حذف الأوامر الأقدم من تاريخ محدد
  Future<int> deleteOlderThan(DateTime date) async {
    return await _isar.writeTxn(() async {
      final old = await _isar.executedCommandCollections
          .filter()
          .executedAtLessThan(date)
          .findAll();
      for (final cmd in old) {
        await _isar.executedCommandCollections.delete(cmd.id);
      }
      return old.length;
    });
  }
}
