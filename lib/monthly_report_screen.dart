// ============================================================
//  MonthlyReportScreen — تقرير شهري للأوامر المنفّذة والإحصائيات
//  يستخدم SQL aggregations عبر drift
// ============================================================

import 'package:flutter/material.dart';
import 'database/daos/executed_commands_dao.dart';
import 'database/daos/cards_dao.dart';
import 'database/daos/ai_diagnostics_dao.dart';
import 'main.dart';

import 'theme/app_theme.dart';
class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  List<MonthlyCommandReport>? _report;
  CommandsStatistics? _stats;
  CardsStatistics? _cardStats;
  DiagnosticsStatistics? _diagStats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final commandsDao = appDatabase.executedCommandsDao;
      final cardsDao = appDatabase.cardsDao;
      final diagDao = appDatabase.aiDiagnosticsDao;

      final results = await Future.wait([
        commandsDao.getMonthlyReport(),
        commandsDao.getStatistics(),
        cardsDao.getStatistics(),
        diagDao.getStatistics(),
      ]);

      setState(() {
        _report = results[0] as List<MonthlyCommandReport>;
        _stats = results[1] as CommandsStatistics;
        _cardStats = results[2] as CardsStatistics;
        _diagStats = results[3] as DiagnosticsStatistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'خطأ في تحميل البيانات: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير الشهرية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Theme.of(context).appColors.error),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ===== بطاقات الإحصائيات السريعة =====
                    _buildStatsGrid(),
                    const SizedBox(height: 24),

                    // ===== تقرير الأوامر الشهري =====
                    const Text(
                      'تقرير الأوامر المنفّذة (آخر 12 شهر)',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    if (_report == null || _report!.isEmpty)
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.info_outline,
                              color: Theme.of(context).hintColor),
                          title: Text('لا توجد أوامر منفّذة بعد'),
                        ),
                      )
                    else
                      ..._report!.map((r) => _buildMonthCard(r)),

                    const SizedBox(height: 24),

                    // ===== إحصائيات الأوامر حسب الخطورة =====
                    if (_stats != null) ...[
                      const Text(
                        'توزيع الأوامر حسب الخطورة',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ..._stats!.byRisk.entries.map(
                          (e) => _buildRiskBar(e.key, e.value, _stats!.totalCommands)),
                    ],
                  ],
                ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'إجمالي الكروت',
          _cardStats?.totalCards.toString() ?? '0',
          Icons.credit_card,
          Theme.of(context).appColors.info,
        ),
        _buildStatCard(
          'الكروت النشطة',
          _cardStats?.activeCards.toString() ?? '0',
          Icons.check_circle,
          Theme.of(context).appColors.success,
        ),
        _buildStatCard(
          'الأوامر المنفّذة',
          _stats?.totalCommands.toString() ?? '0',
          Icons.terminal,
          Colors.purple,
        ),
        _buildStatCard(
          'جلسات التشخيص',
          _diagStats?.totalSessions.toString() ?? '0',
          Icons.psychology,
          Theme.of(context).appColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard(MonthlyCommandReport report) {
    final successRate = report.total > 0
        ? (report.successful / report.total * 100).round()
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: successRate >= 80
              ? Theme.of(context).appColors.success
              : successRate >= 50
                  ? Theme.of(context).appColors.warning
                  : Theme.of(context).appColors.error,
          child: Text(
            report.month.substring(5), // الشهر فقط (MM)
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(report.month), // YYYY-MM
        subtitle: Text(
          '${report.total} أمر • ${report.successful} نجح • ${report.failed} فشل',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '$successRate%',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: successRate >= 80
                ? Theme.of(context).appColors.success
                : successRate >= 50
                    ? Theme.of(context).appColors.warning
                    : Theme.of(context).appColors.error,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('إجمالي الأوامر', '${report.total}'),
                _buildDetailRow('ناجحة', '${report.successful}',
                    color: Theme.of(context).appColors.success),
                _buildDetailRow('فاشلة', '${report.failed}',
                    color: Theme.of(context).appColors.error),
                _buildDetailRow(
                    'متوسط زمن التنفيذ', '${report.avgDurationMs}ms'),
                const SizedBox(height: 8),
                // شريط النجاح
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: report.total > 0
                        ? report.successful / report.total
                        : 0,
                    backgroundColor: Theme.of(context).appColors.error.withValues(alpha: 0.3),
                    color: Theme.of(context).appColors.success,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBar(String risk, int count, int total) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    final color = risk == 'dangerous'
        ? Theme.of(context).appColors.error
        : risk == 'moderate'
            ? Theme.of(context).appColors.warning
            : Theme.of(context).appColors.success;
    final label = risk == 'dangerous'
        ? 'خطير'
        : risk == 'moderate'
            ? 'متوسط'
            : 'آمن';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$label ($risk)'),
              Text('$count ($percentage%)',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
