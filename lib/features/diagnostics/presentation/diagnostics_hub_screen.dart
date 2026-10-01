import 'package:flutter/material.dart';

import '../../../ai/diagnostics_history_screen.dart';
import '../../../ai/log_analysis_screen.dart';
import '../../../ai_diagnostics_screen.dart';
import '../../../network_doctor_screen.dart';
import '../../../network_map_screen.dart';
import '../../../rogue_dhcp_detector_screen.dart';
import '../../../screens/ai_diagnostic_dashboard_screen.dart';
import '../../../core/navigation/custom_page_route.dart';

/// Central entry point for the app's diagnostic tools.
///
/// The hub deliberately shows no fabricated "health score": each destination
/// collects or presents a different kind of evidence and owns its own state.
class DiagnosticsHubScreen extends StatelessWidget {
  const DiagnosticsHubScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      CustomPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryActions = <_DiagnosticDestination>[
      _DiagnosticDestination(
        title: 'فحص اتصال الشبكة',
        description:
            'اختبر البوابة والإنترنت وDNS وفقد الحزم والتذبذب، ثم انسخ أو شارك التقرير. اختبار السرعة اختياري ويحتاج تأكيداً.',
        icon: Icons.network_check,
        badge: 'من الهاتف',
        onTap: () => _open(context, const NetworkDoctorScreen()),
      ),
      _DiagnosticDestination(
        title: 'تشخيص MikroTik بالذكاء الاصطناعي',
        description:
            'اجمع بيانات RouterOS، ابدأ تشخيصاً سريعاً أو عميقاً، ثم راجع الأوامر قبل تنفيذها.',
        icon: Icons.smart_toy_outlined,
        badge: 'من الراوتر',
        onTap: () => _open(context, const AiDiagnosticsScreen()),
      ),
    ];

    final analysisTools = <_DiagnosticDestination>[
      _DiagnosticDestination(
        title: 'تحليل سجلات MikroTik',
        description: 'اجمع السجلات أو حلّل نصاً محفوظاً واعرض الأحداث والتوصيات.',
        icon: Icons.receipt_long_outlined,
        onTap: () => _open(context, const LogAnalysisScreen()),
      ),
      _DiagnosticDestination(
        title: 'سجل جلسات التشخيص',
        description: 'راجع الجلسات السابقة وتفاصيل النتائج والأوامر المسجلة.',
        icon: Icons.history,
        onTap: () => _open(context, const DiagnosticsHistoryScreen()),
      ),
    ];

    final networkTools = <_DiagnosticDestination>[
      _DiagnosticDestination(
        title: 'خريطة الشبكة',
        description: 'استعرض الأجهزة والعلاقات التي تمكن التطبيق من اكتشافها.',
        icon: Icons.hub_outlined,
        onTap: () => _open(context, const NetworkMapScreen()),
      ),
      _DiagnosticDestination(
        title: 'كشف خادم DHCP غير معروف',
        description: 'افحص الشبكة بحثاً عن خوادم DHCP غير مصرح بها.',
        icon: Icons.security_outlined,
        onTap: () => _open(context, const RogueDhcpDetectorScreen()),
      ),
    ];

    final experimentalTools = <_DiagnosticDestination>[
      _DiagnosticDestination(
        title: 'معاينة لوحة QoS',
        description:
            'عرض تجريبي بإعدادات نموذجية؛ لا يقرأ QoS من الراوتر ولا يطبّق أوامر عليه.',
        icon: Icons.tune,
        badge: 'تجريبي',
        onTap: () => _open(context, const AiDiagnosticDashboardScreen()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز التشخيص'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _DiagnosticsIntroCard(),
                  const SizedBox(height: 24),
                  const _SectionHeading(
                    title: 'ابدأ التشخيص',
                    subtitle: 'اختر مصدر الفحص المناسب للمشكلة.',
                  ),
                  const SizedBox(height: 12),
                  _buildCards(context, primaryActions),
                  const SizedBox(height: 24),
                  const _SectionHeading(
                    title: 'التحليل والسجل',
                    subtitle: 'الأدوات التي تساعدك على تفسير النتائج السابقة.',
                  ),
                  const SizedBox(height: 12),
                  _buildCards(context, analysisTools),
                  const SizedBox(height: 24),
                  const _SectionHeading(
                    title: 'أدوات الشبكة',
                    subtitle: 'استكشاف الأجهزة ومصادر DHCP على الشبكة المحلية.',
                  ),
                  const SizedBox(height: 12),
                  _buildCards(context, networkTools),
                  const SizedBox(height: 24),
                  const _SectionHeading(
                    title: 'معاينات تجريبية',
                    subtitle: 'هذه العناصر لا تمثل قراءة حية من الراوتر.',
                  ),
                  const SizedBox(height: 12),
                  _buildCards(context, experimentalTools),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCards(
    BuildContext context,
    List<_DiagnosticDestination> destinations,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth >= 680 ? 2 : 1;
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: destinations
              .map(
                (destination) => SizedBox(
                  width: width,
                  child: _DiagnosticDestinationCard(
                    destination: destination,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _DiagnosticsIntroCard extends StatelessWidget {
  const _DiagnosticsIntroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colors.primaryContainer,
            colors.primaryContainer.withValues(alpha: 0.52),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.health_and_safety_outlined,
                  color: colors.primary,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'كل أدوات التشخيص في مكان واحد',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'ابدأ بفحص الاتصال من الهاتف، أو اجمع معلومات الراوتر لتحليل RouterOS. كل مسار يعرض نتائجه وأدواته بشكل مستقل.',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 19, color: colors.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'الفحص العميق لا يغيّر إعدادات الراوتر تلقائياً. راجع كل أمر أو إصلاح ووافق عليه قبل التنفيذ.',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DiagnosticDestination {
  const _DiagnosticDestination({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;
}

class _DiagnosticDestinationCard extends StatelessWidget {
  const _DiagnosticDestinationCard({required this.destination});

  final _DiagnosticDestination destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: destination.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 126),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(destination.icon, color: colors.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            destination.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (destination.badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              destination.badge!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onSecondaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      destination.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                color: colors.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
