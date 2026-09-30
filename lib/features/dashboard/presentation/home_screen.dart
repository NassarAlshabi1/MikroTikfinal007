import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mikrotik_manager/active_users_screen.dart';
import 'package:mikrotik_manager/add_user_screen.dart';
import 'package:mikrotik_manager/ai/log_analysis_screen.dart';
import 'package:mikrotik_manager/ai_diagnostics_screen.dart';
import 'package:mikrotik_manager/backup_system_screen.dart';
import 'package:mikrotik_manager/bulk_add_screen.dart';
import 'package:mikrotik_manager/card_search_screen.dart';
import 'package:mikrotik_manager/cards_sync_screen.dart';
import 'package:mikrotik_manager/core/navigation/custom_page_route.dart';
import 'package:mikrotik_manager/core/widgets/custom_loading_indicator.dart';
import 'package:mikrotik_manager/extract_cards_screen.dart';
import 'package:mikrotik_manager/mikrotik_connector.dart';
import 'package:mikrotik_manager/monthly_report_screen.dart';
import 'package:mikrotik_manager/network_doctor_screen.dart';
import 'package:mikrotik_manager/pdf_templates_screen.dart';
import 'package:mikrotik_manager/providers/app_theme_provider.dart';
import 'package:mikrotik_manager/providers/mqtt_service_provider.dart';
import 'package:mikrotik_manager/saved_files_screen.dart';
import 'package:mikrotik_manager/services/mikrotik_service_mode.dart';
import 'package:mikrotik_manager/services/user_manager_profile_parser.dart';
import 'package:mikrotik_manager/snackbar_helpers.dart';
import 'package:mikrotik_manager/stats_screen.dart';
import 'package:mikrotik_manager/telegram_bot_settings_screen.dart';
import 'package:mikrotik_manager/terminal_screen.dart';
import 'package:mikrotik_manager/theme/app_theme.dart';

import 'dashboard_status_card.dart';

enum MikrotikMode { userManager, hotspot }

class HomeScreen extends ConsumerStatefulWidget {
  final bool isVersion7OrNewer;
  final String username;

  const HomeScreen({
    super.key,
    required this.isVersion7OrNewer,
    required this.username,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoadingProfiles = true;
  // فئات الكروت في شاشة الإدارة مصدرها User Manager فقط.
  bool _isNetworkLinked = false;
  String _clientName = '';

  Map<String, dynamic>? _dashboardStatus;
  bool _isLoadingStatus = true;
  bool _isRefreshingStatus = false;
  String _statusError = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchProfiles();
    _loadLinkStatus();
    _loadCachedDashboardStatus();
    _refreshDashboardStatus();
  }

  Future<void> _loadLinkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      final isLinked = prefs.getBool('is_network_linked') ?? false;
      String clientName = '';
      if (isLinked) {
        final dataString = prefs.getString('qahtani_linked_data');
        if (dataString != null) {
          try {
            final data = jsonDecode(dataString);
            clientName = data['client_info']?['name'] ?? '';
          } catch (e) {
            debugPrint('Error decoding qahtani_linked_data: $e');
          }
        }
      }
      setState(() {
        _isNetworkLinked = isLinked;
        _clientName = clientName;
      });
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
      _loadLinkStatus(); // Reload status on resume              ref.read(mqttServiceProvider).checkAndReconnect();
      final isLinked = _isNetworkLinked; // Use the state variable
      if (isLinked) {
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          ref
              .read(mqttServiceProvider)
              .publish({'command': 'get_latest_network_details'});
        });
      }
    }
  }

  Future<void> _loadCachedDashboardStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_dashboard_status') ??
        prefs.getString('cached_stats');
    if (cached == null) return;
    try {
      final decoded = jsonDecode(cached);
      if (decoded is! Map<String, dynamic>) return;
      if (!mounted) return;
      setState(() {
        _dashboardStatus = {
          'cpuUsage': (decoded['cpuUsage'] as num?)?.toDouble() ?? 0.0,
          'memoryUsage': (decoded['memoryUsage'] as num?)?.toDouble() ?? 0.0,
          'uptime': decoded['uptime']?.toString() ?? 'غير متوفر',
          'dataDownloaded':
              (decoded['dataDownloaded'] as num?)?.toDouble() ?? 0.0,
          'dataUploaded': (decoded['dataUploaded'] as num?)?.toDouble() ?? 0.0,
          'activeUsers': (decoded['activeUsers'] as num?)?.toInt() ?? 0,
          'version': decoded['version']?.toString() ?? 'غير معروف',
        };
        _isLoadingStatus = false;
        _statusError = '';
      });
    } catch (_) {
      // ignore cache parse errors
    }
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

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      final resourceResponse = await client.talk(['/system/resource/print']);
      Map<String, dynamic> resourceData = {};
      if (resourceResponse.isNotEmpty) {
        resourceData = Map<String, dynamic>.from(resourceResponse[0]);
      }

      final interfaceResponse = await client.talk([
        '/interface/print',
        '=.proplist=name,rx-byte,tx-byte',
        'stats',
      ]);
      double totalDownload = 0.0;
      double totalUpload = 0.0;
      for (var iface in interfaceResponse) {
        final rxBytes =
            double.tryParse(iface['rx-byte']?.toString() ?? '0') ?? 0.0;
        final txBytes =
            double.tryParse(iface['tx-byte']?.toString() ?? '0') ?? 0.0;
        totalDownload += rxBytes;
        totalUpload += txBytes;
      }

      List<Map<String, dynamic>> activeUsers = [];
      try {
        final activeResponse = await client.talk(['/ip/hotspot/active/print']);
        activeUsers =
            activeResponse.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {
        activeUsers = [];
      }

      final cpuLoad =
          double.tryParse(resourceData['cpu-load']?.toString() ?? '0') ?? 0.0;
      final totalMemory =
          double.tryParse(resourceData['total-memory']?.toString() ?? '0') ??
              0.0;
      final freeMemory =
          double.tryParse(resourceData['free-memory']?.toString() ?? '0') ??
              0.0;
      final memoryUsagePercent = totalMemory <= 0
          ? 0.0
          : ((totalMemory - freeMemory) / totalMemory * 100);

      final updatedStatus = {
        'cpuUsage': cpuLoad,
        'memoryUsage': memoryUsagePercent,
        'uptime': resourceData['uptime']?.toString() ?? 'غير متوفر',
        'dataDownloaded': totalDownload / (1024 * 1024),
        'dataUploaded': totalUpload / (1024 * 1024),
        'activeUsers': activeUsers.length,
        'version': resourceData['version']?.toString() ?? 'غير معروف',
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'cached_dashboard_status', jsonEncode(updatedStatus));

      if (mounted) {
        setState(() {
          _dashboardStatus = updatedStatus;
          _isLoadingStatus = false;
          _isRefreshingStatus = false;
          _statusError = '';
        });
      }
    } on MikrotikCredentialsMissingException catch (e) {
      _handleStatusError('بيانات الدخول غير متوفرة: ${e.message}');
    } on MikrotikConnectionException catch (e) {
      _handleStatusError('تعذر الاتصال بالجهاز: ${e.message}');
    } catch (e) {
      _handleStatusError('فشل تحديث حالة MikroTik: ${e.toString()}');
    } finally {
      MikrotikConnector.release(client);
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

  static const _userManagerProfilesCommand = '/tool/user-manager/profile/print';

  MikrotikServiceMode get _serviceMode => MikrotikServiceMode.userManager;

  Future<void> _fetchProfiles() async {
    if (mounted) setState(() => _isLoadingProfiles = true);
    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      var response = await client.talk([
        _userManagerProfilesCommand,
        '=.proplist=.id,name,rate-limit,shared-users,session-timeout',
      ]);
      var profiles = UserManagerProfileParser.parse(
        response
            .whereType<Map>()
            .map((profile) => Map<String, dynamic>.from(profile)),
      );

      // بعض إصدارات User Manager v6 أو wrappers القديمة لا تعيد الحقول
      // عند استخدام proplist؛ أعد القراءة بدون proplist قبل اعتبار النتيجة
      // فارغة، مع إبقاء المسار User Manager فقط.
      if (profiles.isEmpty) {
        response = await client.talk([_userManagerProfilesCommand]);
        profiles = UserManagerProfileParser.parse(
          response
              .whereType<Map>()
              .map((profile) => Map<String, dynamic>.from(profile)),
        );
      }

      if (mounted) {
        setState(() {
          _profiles = profiles;
        });
        if (profiles.isEmpty) {
          showSuccessSnackBar(
            context,
            'تم الاتصال بـ User Manager، لكن لا توجد فئات بروفايل بعد. '
            'أنشئ فئة من User Manager ثم اضغط تحديث.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'تعذر جلب فئات User Manager من MikroTik: $e',
        );
      }
    } finally {
      MikrotikConnector.release(client);
      if (mounted) setState(() => _isLoadingProfiles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- قائمة الخدمات لتسهيل إدارتها ---
    final List<ServiceItem> services = [
      ServiceItem(
        title: 'إضافة كرت فردي',
        icon: Icons.person_add_alt_1,
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
        icon: Icons.groups,
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
        icon: Icons.bar_chart_rounded,
        color: context.theme.appColors.secondary,
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const StatsScreen()));
        },
      ),
      ServiceItem(
        title: 'طبيب الشبكة',
        icon: Icons.local_hospital_outlined,
        color: context.theme.appColors.info,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const NetworkDoctorScreen()));
        },
      ),
      ServiceItem(
        title: 'الملفات المحفوظة',
        icon: Icons.folder_copy,
        color: context.theme.appColors.warning,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const SavedFilesScreen()));
        },
      ),
      ServiceItem(
        title: 'إدارة قوالب PDF',
        icon: Icons.picture_as_pdf,
        color: context.theme.appColors.muted,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => PdfTemplatesScreen(profiles: _profiles)));
        },
      ),
      ServiceItem(
        title: 'استخراج الكروت',
        icon: Icons.document_scanner_outlined,
        color: context.theme.appColors.error,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const ExtractCardsScreen()));
        },
      ),
      ServiceItem(
        title: 'مزامنة كروت اليوزرمنجر',
        icon: Icons.sync,
        color: context.theme.appColors.primary,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const CardsSyncScreen()));
        },
      ),
      ServiceItem(
        title: 'المستخدمين النشطين',
        icon: Icons.people_outline,
        color: context.theme.appColors.secondary,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const ActiveUsersScreen()));
        },
      ),
      ServiceItem(
        title: 'النسخ الاحتياطي',
        icon: Icons.backup,
        color: context.theme.appColors.info,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const BackupSystemScreen()));
        },
      ),
      // ===== شاشات AI + Terminal + إضافات capy/v2-riverpod =====
      ServiceItem(
        title: 'تشخيص بالذكاء الاصطناعي',
        icon: Icons.smart_toy,
        color: context.theme.appColors.secondary,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const AiDiagnosticsScreen()));
        },
      ),
      ServiceItem(
        title: 'محطة RouterOS التفاعلية',
        icon: Icons.terminal,
        color: context.theme.appColors.primary,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const TerminalScreen()));
        },
      ),
      ServiceItem(
        title: 'تحليل Logs MikroTik',
        icon: Icons.analytics,
        color: context.theme.appColors.success,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const LogAnalysisScreen()));
        },
      ),
      ServiceItem(
        title: 'بحث الكروت',
        icon: Icons.search,
        color: context.theme.appColors.warning,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => const CardSearchScreen()));
        },
      ),
      ServiceItem(
        title: 'التقرير الشهري',
        icon: Icons.calendar_month,
        color: context.theme.appColors.info,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const MonthlyReportScreen()));
        },
      ),
      ServiceItem(
        title: 'إعداد Telegram Bot',
        icon: Icons.telegram,
        color: context.theme.appColors.primary,
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
              builder: (context) => const TelegramBotSettingsScreen()));
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
          title: null,
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
            Consumer(
              builder: (context, ref, child) {
                final themeProvider = ref.watch(appThemeProvider);
                return IconButton(
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
                );
              },
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
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil<void>(
                  '/login',
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
                      child: DashboardStatusCard(
                        dashboardStatus: _dashboardStatus,
                        isLoadingStatus: _isLoadingStatus,
                        isNetworkLinked: _isNetworkLinked,
                        clientName: _clientName,
                        isRefreshing: _isRefreshingStatus,
                      ),
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
                    GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
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
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildServiceGridItem({
    required String title,
    required IconData icon,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        // --- التغيير هنا: تم استخدام لون الأيقونة مع شفافية لخلفية الزر ---
        color: iconBgColor.withValues(alpha: 0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // --- التغيير هنا: تم زيادة وضوح خلفية الأيقونة للتباين ---
                color: iconBgColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: iconBgColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
