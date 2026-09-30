import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;

import '../../../active_users_screen.dart';
import '../../../add_user_screen.dart';
import '../../../ai/log_analysis_screen.dart';
import '../../../ai_diagnostics_screen.dart';
import '../../../backup_system_screen.dart';
import '../../../bulk_add_screen.dart';
import '../../../card_search_screen.dart';
import '../../../cards_statistics_screen.dart';
import '../../../core/navigation/custom_page_route.dart';
import '../../../extract_cards_screen.dart';
import '../../../mikrotik_connector.dart';
import '../../../monthly_report_screen.dart';
import '../../../mqtt_service.dart';
import '../../../pdf_templates_screen.dart';
import '../../../saved_files_screen.dart';
import '../../../services/mikrotik_service_mode.dart';
import '../../../snackbar_helpers.dart';
import '../../../stats_screen.dart';
import '../../../telegram_bridge_settings_screen.dart';
import '../../../terminal_screen.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_loading_indicator.dart';
import '../../../network_doctor_screen.dart';
import '../../auth/data/auth_repository_impl.dart';
import '../../auth/domain/auth_repository.dart';
import '../data/dashboard_repository_impl.dart';
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_status.dart';

enum MikrotikMode { userManager, hotspot }

class HomeScreen extends StatefulWidget {
  final bool isVersion7OrNewer;
  final String username;
  final AuthRepository? authRepository;
  final DashboardRepository? dashboardRepository;

  const HomeScreen({
    super.key,
    required this.isVersion7OrNewer,
    required this.username,
    this.authRepository,
    this.dashboardRepository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// --- Data class for Service items ---
class ServiceItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  ServiceItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final AuthRepository _authRepository;
  late final DashboardRepository _dashboardRepository;
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoadingProfiles = true;
  // فئات الكروت في شاشة الإدارة مصدرها User Manager فقط.
  bool _isNetworkLinked = false;
  String _clientName = '';

  DashboardStatus? _dashboardStatus;
  bool _isLoadingStatus = true;
  bool _isRefreshingStatus = false;
  String _statusError = '';

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
    _dashboardRepository =
        widget.dashboardRepository ?? DashboardRepositoryImpl();
    WidgetsBinding.instance.addObserver(this);
    _fetchProfiles();
    _loadLinkStatus();
    _initializeDashboardStatus();
  }

  Future<void> _initializeDashboardStatus() async {
    try {
      await _loadCachedDashboardStatus();
    } catch (error) {
      debugPrint('Dashboard cache unavailable: $error');
    }
    if (mounted) await _refreshDashboardStatus();
  }

  Future<void> _loadLinkStatus() async {
    try {
      final status = await _dashboardRepository.loadNetworkLinkStatus();
      if (!mounted) return;
      setState(() {
        _isNetworkLinked = status.isLinked;
        _clientName = status.clientName;
      });
    } catch (error) {
      debugPrint('Network link status unavailable: $error');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (!mounted) return;
      _loadLinkStatus(); // Reload status on resume
      context.read<MqttService>().checkAndReconnect();
      final isLinked = _isNetworkLinked; // Use the state variable
      if (isLinked) {
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          context
              .read<MqttService>()
              .publish({'command': 'get_latest_network_details'});
        });
      }
    }
  }

  Future<void> _loadCachedDashboardStatus() async {
    final cached = await _dashboardRepository.loadCachedStatus();
    if (!mounted || cached == null) return;
    setState(() {
      _dashboardStatus = cached;
      _isLoadingStatus = false;
      _statusError = '';
    });
  }

  Future<void> _refreshDashboardStatus({bool silent = true}) async {
    if (!mounted) return;
    setState(() {
      _statusError = '';
      if (silent && _dashboardStatus != null) {
        _isRefreshingStatus = true;
      } else {
        _isLoadingStatus = true;
      }
    });

    try {
      final status = await _dashboardRepository.refreshStatus();
      if (!mounted) return;
      setState(() {
        _dashboardStatus = status;
        _isLoadingStatus = false;
        _isRefreshingStatus = false;
        _statusError = '';
      });
    } on MikrotikCredentialsMissingException catch (error) {
      _handleStatusError('بيانات الدخول غير متوفرة: ${error.message}');
    } on MikrotikConnectionException catch (error) {
      _handleStatusError('تعذر الاتصال بالجهاز: ${error.message}');
    } catch (error) {
      _handleStatusError('فشل تحديث حالة MikroTik: $error');
    }
  }

  void _handleStatusError(String message) {
    if (!mounted) return;
    setState(() {
      _statusError = message;
      _isLoadingStatus = false;
      _isRefreshingStatus = false;
    });
    showErrorSnackBar(context, message);
  }

  MikrotikServiceMode get _serviceMode => MikrotikServiceMode.userManager;

  Future<void> _fetchProfiles() async {
    if (mounted) setState(() => _isLoadingProfiles = true);
    try {
      final profiles = await _dashboardRepository.fetchUserManagerProfiles();
      if (!mounted) return;
      setState(() => _profiles = profiles);
      if (profiles.isEmpty) {
        showSuccessSnackBar(
          context,
          'تم الاتصال بـ User Manager، لكن لا توجد فئات بروفايل بعد. '
          'أنشئ فئة من User Manager ثم اضغط تحديث.',
        );
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'تعذر جلب فئات User Manager من MikroTik: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfiles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- قائمة الخدمات لتسهيل إدارتها ---
    final List<ServiceItem> services = [
      ServiceItem(
        title: 'إضافة كرت فردي',
        icon: Icons.person_add_alt_1_rounded,
        color: context.theme.appColors.primary,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
            builder: (context) => AddUserScreen(
                profiles: _profiles,
                isVersion7OrNewer: false,
                customer: widget.username,
                serviceMode: _serviceMode),
          ));
        },
      ),
      ServiceItem(
        title: 'إضافة كروت جماعية',
        icon: Icons.group_add_rounded,
        color: context.theme.appColors.success,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
            builder: (context) => BulkAddScreen(
                profiles: _profiles,
                isVersion7OrNewer: false,
                username: widget.username,
                serviceMode: _serviceMode),
          ));
        },
      ),
      ServiceItem(
        title: 'الإحصائيات',
        icon: Icons.query_stats_rounded,
        color: context.theme.appColors.secondary,
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const StatsScreen()));
        },
      ),
      ServiceItem(
        title: 'طبيب الشبكة',
        icon: Icons.health_and_safety_rounded,
        color: context.theme.appColors.info,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const NetworkDoctorScreen()));
        },
      ),
      ServiceItem(
        title: 'الملفات المحفوظة',
        icon: Icons.folder_copy_rounded,
        color: context.theme.appColors.warning,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const SavedFilesScreen()));
        },
      ),
      ServiceItem(
        title: 'إدارة قوالب PDF',
        icon: Icons.picture_as_pdf_rounded,
        color: context.theme.appColors.muted,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => PdfTemplatesScreen(profiles: _profiles)));
        },
      ),
      ServiceItem(
        title: 'استخراج الكروت',
        icon: Icons.document_scanner_rounded,
        color: context.theme.appColors.error,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const ExtractCardsScreen()));
        },
      ),
      ServiceItem(
        title: 'إحصائيات الكروت',
        icon: Icons.analytics_rounded,
        color: context.theme.appColors.primary,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const CardsStatisticsScreen()));
        },
      ),
      ServiceItem(
        title: 'المستخدمين النشطين',
        icon: Icons.people_alt_rounded,
        color: context.theme.appColors.secondary,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const ActiveUsersScreen()));
        },
      ),
      ServiceItem(
        title: 'النسخ الاحتياطي',
        icon: Icons.cloud_upload_rounded,
        color: context.theme.appColors.info,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const BackupSystemScreen()));
        },
      ),
      // ===== شاشات AI + Terminal + إضافات capy/v2-riverpod =====
      ServiceItem(
        title: 'تشخيص بالذكاء الاصطناعي',
        icon: Icons.psychology_alt_rounded,
        color: context.theme.appColors.secondary,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const AiDiagnosticsScreen()));
        },
      ),
      ServiceItem(
        title: 'محطة RouterOS التفاعلية',
        icon: Icons.terminal_rounded,
        color: context.theme.appColors.primary,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const TerminalScreen()));
        },
      ),
      ServiceItem(
        title: 'تحليل Logs MikroTik',
        icon: Icons.monitor_heart_rounded,
        color: context.theme.appColors.success,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const LogAnalysisScreen()));
        },
      ),
      ServiceItem(
        title: 'بحث الكروت',
        icon: Icons.manage_search_rounded,
        color: context.theme.appColors.warning,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const CardSearchScreen()));
        },
      ),
      ServiceItem(
        title: 'التقرير الشهري',
        icon: Icons.calendar_month_rounded,
        color: context.theme.appColors.info,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const MonthlyReportScreen()));
        },
      ),
      ServiceItem(
        title: 'إعداد جسر Telegram',
        icon: Icons.send_rounded,
        color: context.theme.appColors.primary,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const TelegramBridgeSettingsScreen()));
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.theme.appColors.background,
            context.theme.appColors.surface,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MikroTik Manager',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${_profiles.length} فئة متاحة',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.theme.appColors.muted,
                    ),
              ),
            ],
          ),
          centerTitle: false,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Icon(Icons.person_outline,
                  color: context.theme.appColors.onSurface),
            ),
          ),
          actions: [
            // مفتاح تبديل الثيم الفاتح/الغامق
            provider.Consumer<AppTheme>(
              builder: (context, themeProvider, child) => IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    key: ValueKey(themeProvider.isDarkMode),
                    color: themeProvider.isDarkMode
                        ? Theme.of(context).appColors.warning
                        : Theme.of(context).appColors.primary,
                  ),
                ),
                tooltip: themeProvider.isDarkMode
                    ? 'التبديل للثيم الفاتح'
                    : 'التبديل للثيم الغامق',
                onPressed: () async {
                  await themeProvider.toggleTheme();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          themeProvider.isDarkMode
                              ? 'تم التبديل للثيم الغامق'
                              : 'تم التبديل للثيم الفاتح',
                          style: const TextStyle(fontSize: 14),
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث الحالة',
              onPressed: _isRefreshingStatus
                  ? null
                  : () => _refreshDashboardStatus(silent: false),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
              onPressed: () async {
                await _authRepository.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: _isLoadingProfiles
            ? const CustomLoadingIndicator(message: 'جاري التحميل...')
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: _buildDashboardStatusCard(),
                    ),
                    if (_statusError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _statusError,
                          style: TextStyle(
                            color: context.theme.appColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.apps_rounded,
                            size: 20,
                            color: context.theme.appColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'الخدمات والأدوات',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            '${services.length} خدمة',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: context.theme.appColors.muted),
                          ),
                        ],
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 900
                            ? 6
                            : constraints.maxWidth >= 600
                                ? 4
                                : constraints.maxWidth >= 360
                                    ? 3
                                    : 2;
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: columns <= 2 ? 1.25 : 0.95,
                          ),
                          itemCount: services.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final service = services[index];
                            return RepaintBoundary(
                              child: _buildServiceGridItem(
                                title: service.title,
                                icon: service.icon,
                                iconBgColor: service.color,
                                onTap: service.onTap,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDashboardStatusCard() {
    if (_isLoadingStatus && _dashboardStatus == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.theme.appColors.card,
              context.theme.appColors.surfaceVariant,
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

    final status = _dashboardStatus ??
        const DashboardStatus(
          cpuUsage: 0,
          memoryUsage: 0,
          uptime: 'غير متوفر',
          dataDownloadedMb: 0,
          dataUploadedMb: 0,
          activeUsers: 0,
          version: 'غير معروف',
        );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (healthLabel, healthIcon, healthColor) = switch (status.health) {
      DashboardHealth.healthy => (
          'الحالة مستقرة',
          Icons.verified_rounded,
          context.theme.appColors.success,
        ),
      DashboardHealth.warning => (
          'تحتاج متابعة',
          Icons.warning_amber_rounded,
          context.theme.appColors.warning,
        ),
      DashboardHealth.critical => (
          'ضغط مرتفع',
          Icons.error_rounded,
          context.theme.appColors.error,
        ),
    };

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
                            _isNetworkLinked && _clientName.isNotEmpty
                                ? _clientName
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
                            'الإصدار: ${status.version}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.theme.appColors.muted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'وقت التشغيل: ${status.uptime}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.theme.appColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: context.theme.appColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.router_rounded,
                            size: 28,
                            color: context.theme.appColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: healthColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: healthColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(healthIcon, size: 13, color: healthColor),
                              const SizedBox(width: 4),
                              Text(
                                healthLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: healthColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      'مؤشر الاستقرار',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: context.theme.appColors.muted,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${status.healthScore.toStringAsFixed(0)}/100',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: healthColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: status.healthScore / 100,
                    minHeight: 7,
                    color: healthColor,
                    backgroundColor: healthColor.withValues(alpha: 0.14),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusMetric(
                      label: 'المعالج',
                      value: '${status.cpuUsage.toStringAsFixed(1)}%',
                      icon: Icons.speed,
                      color: context.theme.appColors.primary,
                    ),
                    _buildStatusMetric(
                      label: 'الذاكرة',
                      value: '${status.memoryUsage.toStringAsFixed(1)}%',
                      icon: Icons.memory,
                      color: context.theme.appColors.success,
                    ),
                    _buildStatusMetric(
                      label: 'التحميل',
                      value: '${status.dataDownloadedMb.toStringAsFixed(1)} MB',
                      icon: Icons.download_rounded,
                      color: context.theme.appColors.secondary,
                    ),
                    _buildStatusMetric(
                      label: 'الرفع',
                      value: '${status.dataUploadedMb.toStringAsFixed(1)} MB',
                      icon: Icons.upload_rounded,
                      color: context.theme.appColors.warning,
                    ),
                    _buildStatusMetric(
                      label: 'المستخدمون النشطون',
                      value: '${status.activeUsers}',
                      icon: Icons.wifi,
                      color: context.theme.appColors.accent,
                    ),
                  ],
                ),
                if (_isRefreshingStatus)
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

  Widget _buildStatusMetric({
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

  Widget _buildServiceGridItem({
    required String title,
    required IconData icon,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    final colors = context.theme.appColors;
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: colors.card,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          overlayColor: WidgetStatePropertyAll(
            iconBgColor.withValues(alpha: 0.08),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        iconBgColor.withValues(alpha: 0.22),
                        iconBgColor.withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: iconBgColor.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Icon(icon, size: 27, color: iconBgColor),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.onCard,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
