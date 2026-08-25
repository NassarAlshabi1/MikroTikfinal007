import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mikrotik_diagnostic_provider.dart';
import '../providers/mikrotik_qos_provider.dart';
import '../models/qos_config.dart';
import '../models/diagnostic_result.dart';

import '../theme/app_theme.dart';

class AiDiagnosticDashboardScreen extends ConsumerWidget {
  const AiDiagnosticDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagState = ref.watch(diagnosticProvider);
    final qosState = ref.watch(qosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 AI تشخيص + QoS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(diagnosticProvider.notifier).runDiagnostic();
              ref.read(qosProvider.notifier).loadConfig();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAIBanner(context, ref, diagState),
            const SizedBox(height: 16),
            if (diagState.result != null)
              _buildHealthScoreCard(context, diagState),
            if (diagState.result != null) const SizedBox(height: 16),
            if (diagState.result != null) _buildQuickStats(context, diagState),
            if (diagState.result != null) const SizedBox(height: 16),
            if (diagState.result != null && diagState.result!.issues.isNotEmpty)
              _buildIssuesSection(context, diagState),
            if (diagState.result != null && diagState.result!.issues.isNotEmpty)
              const SizedBox(height: 16),
            _buildQoSSection(context, ref, qosState),
          ],
        ),
      ),
    );
  }

  Widget _buildAIBanner(
      BuildContext context, WidgetRef ref, DiagnosticState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.onSurface, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Diagnostic',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تحليل ذكي وشامل لحالة الشبكة',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  state.isLoading ? null : () => _runDiagnostic(context, ref),
              icon: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(state.isLoading
                  ? (state.currentStage ?? 'جاري التشخيص...')
                  : 'بدء التشخيص'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(BuildContext context, DiagnosticState state) {
    final score = state.healthScore;
    final color = score >= 80
        ? Theme.of(context).appColors.success
        : score >= 50
            ? Theme.of(context).appColors.warning
            : Theme.of(context).appColors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'درجة صحة الشبكة',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.result?.summary.status ?? 'UNKNOWN',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.result?.summary.criticalIssues ?? 0} مشاكل حرجة • ${state.result?.summary.warnings ?? 0} تحذيرات',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, DiagnosticState state) {
    final r = state.result!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 إحصائيات سريعة',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatChip(
                    context,
                    'CPU',
                    r.resources.cpuLoad,
                    r.resources.cpuLoad.contains('%') &&
                        int.tryParse(r.resources.cpuLoad.replaceAll('%', ''))! >
                            80),
                _buildStatChip(
                    context,
                    'RAM',
                    r.resources.memoryUsage,
                    r.resources.memoryUsage.contains('%') &&
                        int.tryParse(
                                r.resources.memoryUsage.replaceAll('%', ''))! >
                            80),
                _buildStatChip(
                    context,
                    'Ping',
                    '${r.connectivity.pingTimeMs}ms',
                    r.connectivity.pingTimeMs > 100),
                _buildStatChip(context, 'Connections',
                    '${r.quality.activeConnections}', false),
                _buildStatChip(context, 'Uptime', r.resources.uptime, false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
      BuildContext context, String label, String value, bool isWarning) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning
            ? Theme.of(context).appColors.warning.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWarning
              ? Theme.of(context).appColors.warning.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).hintColor,
              )),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isWarning ? Theme.of(context).appColors.warning : null,
              )),
        ],
      ),
    );
  }

  Widget _buildIssuesSection(BuildContext context, DiagnosticState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🚨 المشاكل المكتشفة',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...state.result!.issues
                .map((issue) => _buildIssueTile(context, issue)),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueTile(BuildContext context, DiagnosticIssue issue) {
    final isCritical = issue.severity == 'critical';
    final isHigh = issue.severity == 'high';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isCritical
                ? Theme.of(context).appColors.error
                : isHigh
                    ? Theme.of(context).appColors.warning
                    : Theme.of(context).appColors.info)
            .withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isCritical
                  ? Theme.of(context).appColors.error
                  : isHigh
                      ? Theme.of(context).appColors.warning
                      : Theme.of(context).appColors.info)
              .withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCritical
                    ? Icons.error
                    : isHigh
                        ? Icons.warning
                        : Icons.info,
                color: isCritical
                    ? Theme.of(context).appColors.error
                    : isHigh
                        ? Theme.of(context).appColors.warning
                        : Theme.of(context).appColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue.message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isCritical
                          ? Theme.of(context).appColors.error
                          : isHigh
                              ? Theme.of(context).appColors.warning
                              : Theme.of(context).appColors.info)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  issue.type,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCritical
                        ? Theme.of(context).appColors.error
                        : isHigh
                            ? Theme.of(context).appColors.warning
                            : Theme.of(context).appColors.info,
                  ),
                ),
              ),
            ],
          ),
          if (issue.solution.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 16, color: Theme.of(context).hintColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      issue.solution,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQoSSection(BuildContext context, WidgetRef ref, QosState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('📊 QoS', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (state.config != null)
                  Switch(
                    value: state.config!.enabled,
                    onChanged: (_) =>
                        ref.read(qosProvider.notifier).toggleEnabled(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.config == null)
              Text('لا توجد إعدادات QoS',
                  style: TextStyle(color: Theme.of(context).hintColor))
            else ...[
              Text('النطاق الكلي: ${state.config!.totalBandwidth} Mbps',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              ...state.config!.rules
                  .map((rule) => _buildQosRuleTile(context, rule)),
              const SizedBox(height: 12),
              if (state.isApplying)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _applyQos(context, ref),
                    icon: const Icon(Icons.check),
                    label: const Text('تطبيق على MikroTik'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQosRuleTile(BuildContext context, QosRule rule) {
    final priorityColor = rule.priority <= 2
        ? Theme.of(context).appColors.success
        : rule.priority <= 5
            ? Theme.of(context).appColors.warning
            : Theme.of(context).appColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: rule.enabled
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).disabledColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${rule.targetIp} • ${rule.protocol} • ${rule.maxBandwidth}Mbps',
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'P${rule.priority}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: priorityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _runDiagnostic(BuildContext context, WidgetRef ref) {
    ref.read(diagnosticProvider.notifier).runDiagnostic();
    ref.read(qosProvider.notifier).loadConfig();
  }

  Future<void> _applyQos(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(qosProvider.notifier).applyConfig();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }
}
