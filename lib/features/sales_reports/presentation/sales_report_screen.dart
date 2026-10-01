import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';

import '../../../mikrotik_connector.dart';
import '../../../services/router_os_card_gateway.dart'
    show RouterOsClientTalker;
import '../../../services/um_cards_sync_service.dart';
import '../domain/card_usage_report.dart';
import '../services/sales_report_exporter.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<UmSyncedCard> _cards = const [];
  CardUsageReportFilter _filter = CardUsageReportFilter.used;
  String _searchQuery = '';
  DateTime? _lastSyncedAt;
  String? _errorMessage;
  bool _hasSynced = false;
  bool _isLoading = false;
  bool _isExporting = false;
  CardUsageReport? _reportCache;

  CardUsageReport get _report =>
      _reportCache ??= CardUsageReport(_cards);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _syncCards() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Object? lastError;
      for (var attempt = 0; attempt < 2; attempt++) {
        RouterOSClient? client;
        try {
          client = await MikrotikConnector.connect();
          final cards = await const UmCardsSyncService().fetchCards(
            RouterOsClientTalker(client),
          );
          if (!mounted) return;
          setState(() {
            _cards = cards;
            _reportCache = CardUsageReport(cards);
            _lastSyncedAt = DateTime.now();
            _hasSynced = true;
          });
          return;
        } catch (error) {
          lastError = error;
          if (attempt == 0 && MikrotikConnector.isSocketClosedError(error)) {
            MikrotikConnector.forceDisconnect();
            continue;
          }
          break;
        } finally {
          MikrotikConnector.release(client);
        }
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذرت مزامنة User Manager: $lastError';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportCsv() async {
    final lastSyncedAt = _lastSyncedAt;
    final cards = _report.rows(filter: _filter, query: _searchQuery);
    if (cards.isEmpty || lastSyncedAt == null) return;
    await _runExport(() => SalesReportExporter.shareCsv(
          cards: cards,
          filter: _filter,
          lastSyncedAt: lastSyncedAt,
        ));
  }

  Future<void> _exportPdf() async {
    final lastSyncedAt = _lastSyncedAt;
    final report = _report;
    final cards = report.rows(filter: _filter, query: _searchQuery);
    if (cards.isEmpty || lastSyncedAt == null) return;
    await _runExport(() => SalesReportExporter.sharePdf(
          cards: cards,
          filter: _filter,
          lastSyncedAt: lastSyncedAt,
          totalCount: report.totalCount,
          usedCount: report.usedCount,
          expiredCount: report.expiredCount,
          overlappingCount: report.overlappingCount,
        ));
  }

  Future<void> _runExport(Future<void> Function() export) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      await export();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تجهيز التقرير للمشاركة.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تصدير التقرير: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final visibleCards = report.rows(filter: _filter, query: _searchQuery);
    final canExport = visibleCards.isNotEmpty &&
        _lastSyncedAt != null &&
        !_isLoading &&
        !_isExporting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الكروت'),
        actions: [
          IconButton(
            tooltip: 'مزامنة User Manager',
            onPressed: _isLoading ? null : _syncCards,
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'تصدير CSV',
            onPressed: canExport ? _exportCsv : null,
            icon: const Icon(Icons.table_view_outlined),
          ),
          IconButton(
            tooltip: 'تصدير PDF',
            onPressed: canExport ? _exportPdf : null,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            if (_errorMessage != null) _buildErrorBanner(),
            Expanded(
              child: _cards.isEmpty
                  ? _buildEmptyState()
                  : _buildReportContent(report, visibleCards),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _hasSynced ? Icons.inbox_outlined : Icons.assessment_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _hasSynced
                    ? 'لم يعثر User Manager على كروت لعرضها.'
                    : 'مزامنة تقرير الكروت من User Manager',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'المستخدمة تُحدّد من uptime-used الفعلي، والمنتهية حسب تعطيل المستخدم أو استهلاك حد uptime. لا يعتمد التقرير على وقت مزامنة التطبيق، ولا يعرض أسعاراً أو إيرادات.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isLoading ? null : _syncCards,
                icon: const Icon(Icons.sync),
                label: const Text('مزامنة الآن'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(
    CardUsageReport report,
    List<UmSyncedCard> visibleCards,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildSourceNotice(report),
        _buildSummary(report),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                avatar: const Icon(Icons.history, size: 18),
                label: Text('مستخدمة (${report.usedCount})'),
                selected: _filter == CardUsageReportFilter.used,
                onSelected: (_) => setState(
                  () => _filter = CardUsageReportFilter.used,
                ),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.hourglass_bottom, size: 18),
                label: Text('منتهية/معطّلة (${report.expiredCount})'),
                selected: _filter == CardUsageReportFilter.expired,
                onSelected: (_) => setState(
                  () => _filter = CardUsageReportFilter.expired,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'بحث باسم الكرت أو الفئة',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'مسح البحث',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Text(
                _filter.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${visibleCards.length} نتيجة',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: visibleCards.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد نتائج مطابقة لهذا التصنيف أو البحث.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: visibleCards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (context, index) =>
                      _buildCardTile(visibleCards[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSourceNotice(CardUsageReport report) {
    final theme = Theme.of(context);
    final lastSyncedAt = _lastSyncedAt;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المصدر: User Manager. المستخدم = uptime-used أكبر من صفر؛ المنتهي/المعطّل = disabled أو استهلاك حد uptime. قد يظهر الكرت في القائمتين.',
            style: theme.textTheme.bodySmall,
          ),
          if (report.unknownUsageCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${report.unknownUsageCount} كرت لا يحتوي قيمة uptime-used قابلة للقراءة، لذلك لا يُحتسب ضمن المستخدمة.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (lastSyncedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'آخر مزامنة: ${_formatDate(lastSyncedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'تقرير حالة استخدام فقط؛ لا توجد بيانات أسعار أو إيرادات ضمن سجل User Manager.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(CardUsageReport report) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _SummaryTile(
            label: 'إجمالي الكروت',
            value: report.totalCount,
            icon: Icons.credit_card,
          ),
          _SummaryTile(
            label: 'مستخدمة',
            value: report.usedCount,
            icon: Icons.history,
          ),
          _SummaryTile(
            label: 'منتهية',
            value: report.expiredCount,
            icon: Icons.hourglass_bottom,
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(UmSyncedCard card) {
    final theme = Theme.of(context);
    final statusColor = card.isDisabled || card.isExpired
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    final profile = card.profile.isEmpty ? 'غير محددة' : card.profile;
    final used = card.uptimeUsed.isEmpty ? 'غير متاح' : card.uptimeUsed;
    final limit = card.limitUptime.isEmpty ? 'غير محدد' : card.limitUptime;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.credit_card, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('الفئة: $profile', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cardUsageReportStatus(card, _filter),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _DetailText(
                  icon: Icons.timer_outlined,
                  text: 'الاستخدام: $used',
                ),
                _DetailText(
                  icon: Icons.hourglass_empty,
                  text: 'حد الوقت: $limit',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _errorMessage!,
        style: TextStyle(color: theme.colorScheme.onErrorContainer),
      ),
    );
  }

  String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Column(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                '$value',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailText extends StatelessWidget {
  const _DetailText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
