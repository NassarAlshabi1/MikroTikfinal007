// ============================================================
//  Fix Plan Dialog — UI لعرض خطة إصلاح + dry-run + execute + rollback
//
//  مستوحى من router diagnostics (plan_changes + apply_plan + rollback_change)
//
//  المميزات:
//  1. عرض الخطة (displayPlan) مع إحصائيات + قائمة fixes
//  2. زر "معاينة (dry-run)" → يحلل الأوامر ويعرض risks/idempotency
//  3. زر "تنفيذ آمن" → snapshot + apply all + rollback عند الفشل
//  4. زر "استعادة (rollback)" → يظهر بعد فشل التطبيق
//  5. عرض النتائج بعد التنفيذ (نجاح/فشل لكل fix)
//  6. استخدام Theme.of(context) بالكامل — بدون ألوان ثابتة
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../theme/app_colors_extension.dart';
import 'auto_fix_service.dart';
import 'command_executor.dart';
import 'diagnostics_models.dart';
import 'script_executor.dart';

/// نافذة عرض + تنفيذ خطة إصلاح
///
/// الاستخدام:
/// ```dart
/// final fixes = AutoFixService.analyze(snapshot, mode: DiagnosticMode.security);
/// final plan = PlanService.createPlan(
///   fixes: fixes,
///   snapshot: snapshot,
///   title: 'إصلاح أمني شامل',
/// );
/// await showDialog(
///   context: context,
///   builder: (_) => FixPlanDialog(plan: plan),
/// );
/// ```
class FixPlanDialog extends ConsumerStatefulWidget {
  final FixPlan plan;
  final MikrotikConnectionMethod method;

  const FixPlanDialog({
    super.key,
    required this.plan,
    this.method = MikrotikConnectionMethod.routerOS,
  });

  @override
  ConsumerState<FixPlanDialog> createState() => _FixPlanDialogState();
}

class _FixPlanDialogState extends ConsumerState<FixPlanDialog> {
  bool _executing = false;
  bool _executed = false;
  PlanApplyResult? _result;
  String? _dryRunReport;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            // ─── Header ───
            _buildHeader(colors),

            // ─── Content ───
            Expanded(
              child: _executed
                  ? _buildResultView(colors)
                  : (_dryRunReport != null
                      ? _buildDryRunView(colors)
                      : _buildPlanView(colors)),
            ),

            // ─── Actions ───
            _buildActions(colors),
          ],
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.checklist, color: colors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 خطة الإصلاح',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.plan.title,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'إغلاق',
          ),
        ],
      ),
    );
  }

  // ─── Plan View ───
  Widget _buildPlanView(AppColorsExtension colors) {
    final plan = widget.plan;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Stats ───
          _buildStatsGrid(colors, plan),
          const SizedBox(height: 16),

          // ─── Snapshot warning ───
          if (plan.needsSnapshot)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.warningContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: colors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الخطة تحتوي على تغييرات — سيُنشأ snapshot تلقائياً قبل التنفيذ.',
                      style: TextStyle(fontSize: 12, color: colors.onWarningContainer),
                    ),
                  ),
                ],
              ),
            ),
          if (plan.needsSnapshot) const SizedBox(height: 16),

          // ─── Fixes list ───
          Text(
            '🔧 الإصلاحات (${plan.length}):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          ...plan.fixes.asMap().entries.map((entry) {
            final idx = entry.key;
            final fix = entry.value;
            return _buildFixCard(colors, idx + 1, fix);
          }),
        ],
      ),
    );
  }

  // ─── Stats Grid ───
  Widget _buildStatsGrid(AppColorsExtension colors, FixPlan plan) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem(colors, Icons.build_circle, '${plan.length}',
                  'إصلاح', colors.primary),
              _buildStatItem(colors, Icons.code, '${plan.totalCommands}',
                  'أمر', colors.secondary),
              _buildStatItem(colors, Icons.check_circle,
                  '${plan.autoApplySafeCount}', 'آمن تلقائي', colors.success),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatItem(colors, Icons.dangerous, '${plan.dangerousCount}',
                  'خطير', colors.error),
              _buildStatItem(colors, Icons.save, plan.needsSnapshot ? 'نعم' : 'لا',
                  'snapshot', plan.needsSnapshot ? colors.warning : colors.success),
              _buildStatItem(colors, Icons.category,
                  '${plan.categoriesPresent.length}', 'فئات', colors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(AppColorsExtension colors, IconData icon, String value,
      String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── Fix Card ───
  Widget _buildFixCard(AppColorsExtension colors, int idx, ProposedFix fix) {
    final riskColor = fix.risk == CommandRiskLevel.dangerous
        ? colors.error
        : fix.risk == CommandRiskLevel.moderate
            ? colors.warning
            : colors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: riskColor.withValues(alpha: 0.15),
          radius: 16,
          child: Text(fix.category.icon, style: const TextStyle(fontSize: 14)),
        ),
        title: Row(
          children: [
            Text('$idx. ', style: TextStyle(
                fontWeight: FontWeight.bold, color: colors.textTertiary, fontSize: 12)),
            Expanded(
              child: Text(
                fix.title,
                style: TextStyle(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                fix.risk.displayName,
                style: TextStyle(fontSize: 9, color: riskColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              fix.category.displayName,
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
            ),
            if (fix.autoApplySafe) ...[
              const SizedBox(width: 6),
              Icon(Icons.verified, size: 12, color: colors.success),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fix.description,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    fix.script.commands.join('\n'),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dry-Run View ───
  Widget _buildDryRunView(AppColorsExtension colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, color: colors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                '🔍 تقرير Dry-Run',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: SelectableText(
              _dryRunReport ?? '',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.4,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Result View ───
  Widget _buildResultView(AppColorsExtension colors) {
    final result = _result!;
    final statusColor = result.isSuccess
        ? colors.success
        : (result.canRollback ? colors.warning : colors.error);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Status Banner ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(
                  result.isSuccess
                      ? Icons.check_circle
                      : (result.canRollback
                          ? Icons.warning_amber
                          : Icons.error),
                  color: statusColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.status.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'نجاح: ${result.successCount} | فشل: ${result.failureCount} من ${result.plan.length}',
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Snapshot info ───
          if (result.snapshot != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.save, color: colors.info, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Snapshot: ${result.snapshot!.backupName}',
                      style: TextStyle(fontSize: 12, color: colors.textPrimary),
                    ),
                  ),
                  Text(
                    '${result.snapshot!.createdAt.toLocal().toString().substring(0, 19)}',
                    style: TextStyle(fontSize: 10, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ─── Per-fix results ───
          Text(
            '📊 نتائج كل إصلاح:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...result.fixResults.asMap().entries.map((entry) {
            final idx = entry.key;
            final res = entry.value;
            final fix = result.plan.fixes[idx];
            return _buildFixResultCard(colors, idx + 1, fix, res);
          }),

          // ─── Rollback script preview ───
          if (result.rollbackScript != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.undo, color: colors.error, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '↩️ استعادة متاحة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اضغط زر "استعادة" بالأسفل لتنفيذ rollback من الـ snapshot.',
                    style: TextStyle(fontSize: 12, color: colors.onErrorContainer),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFixResultCard(AppColorsExtension colors, int idx,
      ProposedFix fix, ScriptExecutionResult res) {
    final color = res.overallSuccess ? colors.success : colors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            res.overallSuccess ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$idx. ${fix.title}',
                  style: TextStyle(fontSize: 12, color: colors.textPrimary, fontWeight: FontWeight.w500),
                ),
                Text(
                  '✅ ${res.successCount} نجح، ❌ ${res.failureCount} فشل • ${res.totalElapsed.inMilliseconds}ms',
                  style: TextStyle(fontSize: 10, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions Bar ───
  Widget _buildActions(AppColorsExtension colors) {
    if (_executing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('جارٍ التنفيذ... قد يستغرق عدة دقائق'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_executed && _result != null && _result!.canRollback) ...[
            OutlinedButton.icon(
              onPressed: _rollback,
              icon: Icon(Icons.undo, color: colors.error),
              label: Text('استعادة', style: TextStyle(color: colors.error)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.error),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (!_executed) ...[
            TextButton.icon(
              onPressed: _showDryRun,
              icon: Icon(Icons.science_outlined, color: colors.info),
              label: Text('معاينة (dry-run)', style: TextStyle(color: colors.info)),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _executePlan,
              icon: const Icon(Icons.play_arrow),
              label: const Text('تنفيذ آمن'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
            ),
          ],
          if (_executed) ...[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              child: const Text('إغلاق'),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Actions ───
  void _showDryRun() {
    setState(() {
      _dryRunReport = PlanService.planDryRunReport(widget.plan);
    });
  }

  Future<void> _executePlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: context.appColors.warning),
            const SizedBox(width: 8),
            const Text('تأكيد التنفيذ'),
          ],
        ),
        content: Text(
          'سيتم تنفيذ ${widget.plan.length} إصلاح بالتسلسل.\n'
          'إن احتوت الخطة على تغييرات، سيُنشأ snapshot تلقائياً.\n\n'
          'متأكد من المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تنفيذ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _executing = true;
      _dryRunReport = null;
    });

    try {
      final result = await PlanService.applyPlan(
        plan: widget.plan,
        method: widget.method,
        requireSnapshot: true,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _executed = true;
          _executing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _executing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ غير متوقع: $e')),
        );
      }
    }
  }

  Future<void> _rollback() async {
    if (_result?.rollbackScript == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.dangerous, color: context.appColors.error),
            const SizedBox(width: 8),
            const Text('استعادة من snapshot'),
          ],
        ),
        content: Text(
          '⚠️ تحذير: سيتم استعادة الإعدادات إلى حالتها قبل التطبيق.\n'
          'هذا قد يقطع الاتصال مؤقتاً.\n\n'
          'Snapshot: ${_result!.snapshot!.backupName}\n\n'
          'متابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _executing = true);

    try {
      await ScriptExecutor.execute(
        script: _result!.rollbackScript!,
        method: widget.method,
        stopOnError: true,
        perCommandTimeout: const Duration(seconds: 60),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تمت الاستعادة من snapshot')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الاستعادة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _executing = false);
    }
  }
}
