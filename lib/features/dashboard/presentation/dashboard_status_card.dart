import 'package:flutter/material.dart';

import 'package:mikrotik_manager/theme/app_gradients.dart';
import 'package:mikrotik_manager/theme/app_theme.dart';

/// Read-only router summary used by the dashboard and independently testable
/// without a RouterOS session.
class DashboardStatusCard extends StatelessWidget {
  const DashboardStatusCard({
    super.key,
    required this.dashboardStatus,
    required this.isLoadingStatus,
    required this.isNetworkLinked,
    required this.clientName,
    required this.isRefreshing,
  });

  final Map<String, dynamic>? dashboardStatus;
  final bool isLoadingStatus;
  final bool isNetworkLinked;
  final String clientName;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    if (isLoadingStatus && dashboardStatus == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).textTheme.bodySmall!.color!,
              Theme.of(context).colorScheme.onSurface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 16),
            Text('جاري تحديث حالة MikroTik...'),
          ],
        ),
      );
    }

    final status = dashboardStatus ??
        {
          'cpuUsage': 0.0,
          'memoryUsage': 0.0,
          'uptime': 'غير متوفر',
          'dataDownloaded': 0.0,
          'dataUploaded': 0.0,
          'activeUsers': 0,
          'version': 'غير معروف',
        };

    final cpuUsage = _asDouble(status['cpuUsage']);
    final memoryUsage = _asDouble(status['memoryUsage']);
    final downloadMb = _asDouble(status['dataDownloaded']);
    final uploadMb = _asDouble(status['dataUploaded']);
    final activeUsers = (status['activeUsers'] is num)
        ? (status['activeUsers'] as num).toInt()
        : int.tryParse(status['activeUsers']?.toString() ?? '') ?? 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  context.theme.appColors.primary.withValues(alpha: 0.32),
                  context.theme.appColors.accent.withValues(alpha: 0.20),
                ]
              : [
                  context.theme.appColors.primary.withValues(alpha: 0.32),
                  context.theme.appColors.accent.withValues(alpha: 0.20),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          context.theme.appColors.card.withValues(alpha: 0.3),
                          context.theme.appColors.card.withValues(alpha: 0.1),
                        ],
                      )
                    : AppGradients.cardOverlay,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isNetworkLinked && clientName.isNotEmpty
                                ? clientName
                                : 'حالة MikroTik',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.theme.appColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'الإصدار: ${status['version']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.theme.appColors.muted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'وقت التشغيل: ${status['uptime']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.theme.appColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.router,
                      size: 34,
                      color: context.theme.appColors.primary
                          .withValues(alpha: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusMetric(
                      context,
                      label: 'المعالج',
                      value: '${cpuUsage.toStringAsFixed(1)}%',
                      icon: Icons.speed,
                      color: context.theme.appColors.primary,
                    ),
                    _buildStatusMetric(
                      context,
                      label: 'الذاكرة',
                      value: '${memoryUsage.toStringAsFixed(1)}%',
                      icon: Icons.memory,
                      color: context.theme.appColors.success,
                    ),
                    _buildStatusMetric(
                      context,
                      label: 'التحميل',
                      value: '${downloadMb.toStringAsFixed(1)} MB',
                      icon: Icons.download_rounded,
                      color: context.theme.appColors.secondary,
                    ),
                    _buildStatusMetric(
                      context,
                      label: 'الرفع',
                      value: '${uploadMb.toStringAsFixed(1)} MB',
                      icon: Icons.upload_rounded,
                      color: context.theme.appColors.warning,
                    ),
                    _buildStatusMetric(
                      context,
                      label: 'المستخدمون النشطون',
                      value: '$activeUsers',
                      icon: Icons.wifi,
                      color: context.theme.appColors.accent,
                    ),
                  ],
                ),
                if (isRefreshing)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? context.theme.appColors.cardInteractive.withValues(alpha: 0.8)
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: context.theme.appColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.theme.appColors.onSurface,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
