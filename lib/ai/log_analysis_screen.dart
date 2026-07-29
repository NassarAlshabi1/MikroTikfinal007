// ============================================================
//  LogAnalysisScreen — شاشة تحليل logs MikroTik
//
//  تعرض:
//  1. زر "جمع + تحليل logs" (يجمع من الراوتر عبر SSH/API)
//  2. لوحة صحة الـ log (Health Score) مع توزيع الأحداث
//  3. قائمة الأحداث المُحلّلة (مع فلاتر حسب Severity/Category)
//  4. أهم المشاكل + التوصيات
//  5. زر "تحليل AI عميق" (يستخدم AiService للتحليل الذكي)
//  6. زر "تحليل سحابي legacy integration" (يستخدم OomolCloudAiService)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/secure_credentials_storage.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors_extension.dart';
import 'ai_service.dart';
import 'diagnostics_models.dart';
import 'diagnostics_provider.dart';
import 'mikrotik_log_analyzer.dart';
import 'legacy_integration_cloud_ai_service.dart';
import 'legacy_integration_mcp_client.dart';
import '../snackbar_helpers.dart';

class LogAnalysisScreen extends ConsumerStatefulWidget {
  const LogAnalysisScreen({super.key});

  @override
  ConsumerState<LogAnalysisScreen> createState() => _LogAnalysisScreenState();
}

class _LogAnalysisScreenState extends ConsumerState<LogAnalysisScreen> {
  bool _loading = false;
  bool _analyzingCloud = false;
  bool _analyzingAi = false;
  LogAnalysisResult? _result;
  OomolDashboard? _dashboard;
  String? _cloudAnalysis;
  String? _aiAnalysis;
  String? _errorMessage;

  // فلاتر
  LogSeverity? _filterSeverity;
  LogCategory? _filterCategory;

  @override
  void initState() {
    super.initState();
    _loadCachedResult();
  }

  Future<void> _loadCachedResult() async {
    // إن كان هناك logs في الـ DiagnosticsState الحالي، حلّله فوراً
    final diagState = ref.read(diagnosticsProvider);
    if (diagState.lastSnapshot?.logs.isNotEmpty == true) {
      setState(() => _loading = true);
      try {
        final result = MikrotikLogAnalyzer.analyze(diagState.lastSnapshot!.logs);
        setState(() {
          _result = result;
          _loading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'فشل التحليل: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _collectAndAnalyze() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // جمع logs من الراوتر
      final logs = await MikrotikLogAnalyzer.collectLogs(
        method: MikrotikConnectionMethod.routerOS,
        maxLines: 500,
      );

      // تحليل محلي
      final result = MikrotikLogAnalyzer.analyze(logs);
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل جمع/تحليل الـ logs: $e';
        _loading = false;
      });
    }
  }

  Future<void> _analyzeWithAi() async {
    if (_result == null) return;
    setState(() {
      _analyzingAi = true;
      _errorMessage = null;
    });

    try {
      final diagState = ref.read(diagnosticsProvider);
      final settings = diagState.settings;

      if (!settings.isConfigured) {
        showSuccessSnackBar(context, 'ضبط مزود AI أولاً من شاشة الإعدادات');
        setState(() => _analyzingAi = false);
        return;
      }

      final localContext = MikrotikLogAnalyzer.toAiContext(_result!);
      final userQuery = 'حلل هذه الـ logs من MikroTik واكتشف المشاكل الأمنية '
          'والأدائية. اقترح أوامر RouterOS v6 للإصلاح.';

      final snapshotContext = '''$localContext

=== MikrotikSnapshot ===
IP: ${diagState.lastSnapshot?.ipAddress ?? 'unknown'}
Time: ${DateTime.now().toIso8601String()}
''';

      final result = await AiService.analyze(
        settings: settings,
        userQuery: userQuery,
        snapshotContext: snapshotContext,
      );

      setState(() {
        _aiAnalysis = result.content;
        _analyzingAi = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل تحليل AI: $e';
        _analyzingAi = false;
      });
    }
  }

  Future<void> _analyzeWithOomolCloud() async {
    if (_result == null) return;
    setState(() {
      _analyzingCloud = true;
      _errorMessage = null;
    });

    try {
      // 🔒 قراءة API key من flutter_secure_storage + باقي الإعدادات من prefs
      final apiKey = await SecureCredentialsStorage.instance.getOomolApiKey() ?? '';
      final prefs = await SharedPreferences.getInstance();
      final packageName = prefs.getString('legacy_integration_package_name');
      final packageVersion = prefs.getString('legacy_integration_package_version');

      if (apiKey.isEmpty) {
        showSuccessSnackBar(context, 'ضبط legacy integration API key أولاً من شاشة legacy integration Settings');
        setState(() => _analyzingCloud = false);
        return;
      }

      final settings = OomolAiSettings(
        apiKey: apiKey,
        packageName: packageName,
        packageVersion: packageVersion,
      );

      final service = OomolCloudAiService(settings: settings);
      await service.connect();

      try {
        // جلب dashboard لعرض معلومات الحساب
        final dash = await service.getDashboard();
        if (dash != null) {
          setState(() => _dashboard = dash);
        }

        // تنفيذ التحليل السحابي
        final result = await service.analyzeLogs(
          ref.read(diagnosticsProvider).lastSnapshot?.logs ?? '',
        );

        setState(() {
          _cloudAnalysis = result.content;
          if (result.usedFallback) {
            _errorMessage = result.error ?? 'استُخدم التحليل المحلي (cloud غير متاح)';
          }
        });
      } finally {
        await service.disconnect();
      }

      setState(() => _analyzingCloud = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل تحليل legacy integration Cloud: $e';
        _analyzingCloud = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 تحليل Logs MikroTik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'جمع + تحليل',
            onPressed: _loading ? null : _collectAndAnalyze,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'نسخ النتائج',
            onPressed: _result == null
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: _result!.summary));
                    if (mounted) showSuccessSnackBar(context, 'تم نسخ التقرير');
                  },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _result == null
              ? _buildEmptyState(colors)
              : _buildResults(colors),
    );
  }

  // ─── Empty state ───
  Widget _buildEmptyState(AppColorsExtension colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: colors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'تحليل Logs MikroTik',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اجمع logs من الراوتر وحللها تلقائياً\n'
              'لاكتشاف المشاكل الأمنية والأدائية',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _collectAndAnalyze,
              icon: const Icon(Icons.download),
              label: const Text('جمع + تحليل'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Results ───
  Widget _buildResults(AppColorsExtension colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health score card
          _buildHealthCard(colors),
          const SizedBox(height: 16),

          // Stats grid
          _buildStatsGrid(colors),
          const SizedBox(height: 16),

          // Action buttons
          _buildActionButtons(colors),
          const SizedBox(height: 16),

          // Top issues
          if (_result!.topIssues.isNotEmpty) ...[
            _buildTopIssuesCard(colors),
            const SizedBox(height: 16),
          ],

          // Cloud analysis (if available)
          if (_cloudAnalysis != null) ...[
            _buildCloudAnalysisCard(colors),
            const SizedBox(height: 16),
          ],

          // AI analysis (if available)
          if (_aiAnalysis != null) ...[
            _buildAiAnalysisCard(colors),
            const SizedBox(height: 16),
          ],

          // Recommendations
          if (_result!.recommendations.isNotEmpty) ...[
            _buildRecommendationsCard(colors),
            const SizedBox(height: 16),
          ],

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: colors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      _errorMessage!,
                      style: TextStyle(fontSize: 12, color: colors.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Events list with filters
          _buildEventsList(colors),
        ],
      ),
    );
  }

  // ─── Health score card ───
  Widget _buildHealthCard(AppColorsExtension colors) {
    final score = _result!.healthScore;
    final scoreColor = score >= 80
        ? colors.success
        : score >= 50
            ? colors.warning
            : colors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.15),
            scoreColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Score circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: scoreColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
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
                  'صحة الـ Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_result!.events.length} حدث مُحلّل من ${_result!.totalLines} سطر',
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_result!.criticalCount} حرج • ${_result!.warningCount} تحذير',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats grid ───
  Widget _buildStatsGrid(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 التوزيع حسب الخطورة:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: LogSeverity.values.map((s) {
              final count = _result!.severityCounts[s] ?? 0;
              return Expanded(
                child: _buildStatChip(
                  colors,
                  emoji: s.emoji,
                  label: s.displayName,
                  count: count,
                  color: _severityColor(colors, s),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            '📁 التوزيع حسب الفئة:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (_result!.categoryCounts.entries
                .where((e) => e.value > 0)
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
                .map((e) => _buildCategoryChip(colors, e.key, e.value))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(AppColorsExtension colors, {
    required String emoji,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
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

  Widget _buildCategoryChip(AppColorsExtension colors, LogCategory cat, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(cat.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            cat.displayName,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(AppColorsExtension colors, LogSeverity s) {
    switch (s) {
      case LogSeverity.critical: return colors.error;
      case LogSeverity.warning:  return colors.warning;
      case LogSeverity.info:     return colors.success;
      case LogSeverity.debug:    return colors.textTertiary;
    }
  }

  // ─── Action buttons ───
  Widget _buildActionButtons(AppColorsExtension colors) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _analyzingAi ? null : _analyzeWithAi,
            icon: _analyzingAi
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology),
            label: const Text('تحليل AI'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _analyzingCloud ? null : _analyzeWithOomolCloud,
            icon: _analyzingCloud
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud),
            label: const Text('legacy integration Cloud'),
          ),
        ),
      ],
    );
  }

  // ─── Top issues ───
  Widget _buildTopIssuesCard(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.priority_high, color: colors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                '🚨 أهم المشاكل المكتشفة:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.onErrorContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...(_result!.topIssues.map((issue) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•', style: TextStyle(color: colors.error, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        issue,
                        style: TextStyle(fontSize: 12, color: colors.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ))),
        ],
      ),
    );
  }

  // ─── Cloud analysis card ───
  Widget _buildCloudAnalysisCard(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.infoContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_done, color: colors.info, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '☁️ تحليل legacy integration Cloud:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.onInfoContainer,
                  ),
                ),
              ),
              if (_dashboard != null)
                Text(
                  '5/${_dashboard!.maxConcurrency}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onInfoContainer.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: SelectableText(
                _cloudAnalysis!,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: colors.onInfoContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── AI analysis card ───
  Widget _buildAiAnalysisCard(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: colors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                '🧠 تحليل AI:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: SelectableText(
                _aiAnalysis!,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: colors.onSecondaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recommendations ───
  Widget _buildRecommendationsCard(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.warningContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: colors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                '💡 توصيات الإصلاح:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.onWarningContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...(_result!.recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_circle_right, size: 14, color: colors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SelectableText(
                        rec,
                        style: TextStyle(fontSize: 12, color: colors.onWarningContainer),
                      ),
                    ),
                  ],
                ),
              ))),
        ],
      ),
    );
  }

  // ─── Events list with filters ───
  Widget _buildEventsList(AppColorsExtension colors) {
    var events = _result!.events;
    if (_filterSeverity != null) {
      events = events.where((e) => e.severity == _filterSeverity).toList();
    }
    if (_filterCategory != null) {
      events = events.where((e) => e.category == _filterCategory).toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '📋 الأحداث (${events.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                // فلتر Severity
                DropdownButton<LogSeverity?>(
                  value: _filterSeverity,
                  hint: const Text('الكل'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('الكل')),
                    ...LogSeverity.values.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.emoji} ${s.displayName}'),
                        )),
                  ],
                  onChanged: (v) => setState(() => _filterSeverity = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length > 100 ? 100 : events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final e = events[i];
              return _buildEventTile(colors, e);
            },
          ),
          if (events.length > 100)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  '(${events.length - 100} حدث آخر غير معروض)',
                  style: TextStyle(fontSize: 11, color: colors.textTertiary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventTile(AppColorsExtension colors, AnalyzedLogEvent e) {
    final sevColor = _severityColor(colors, e.severity);
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: sevColor.withValues(alpha: 0.15),
        radius: 16,
        child: Text(e.category.emoji, style: const TextStyle(fontSize: 12)),
      ),
      title: Text(
        e.topic,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: sevColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${e.severity.emoji} ${e.severity.displayName}',
              style: TextStyle(fontSize: 9, color: sevColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
          // 🎨flutter-fix-layout-issues: استخدم Flexible لمنع overflow
          // عند الأسماء الطويلة + ellipsis
          Flexible(
            child: Text(
              e.category.displayName,
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (e.source != null) ...[
            const SizedBox(width: 6),
            Icon(Icons.router, size: 10, color: colors.textTertiary),
            const SizedBox(width: 2),
            // 🎨flutter-fix-layout-issues: Flexible للـ IP أيضاً
            Flexible(
              child: Text(
                e.source!,
                style: TextStyle(fontSize: 10, color: colors.textTertiary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  e.rawLine,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (e.recommendation != null) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 14, color: colors.warning),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        e.recommendation!,
                        style: TextStyle(fontSize: 11, color: colors.warning),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
