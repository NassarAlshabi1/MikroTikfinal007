import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'active_users_screen.dart';
import 'add_user_screen.dart';
import 'backup_system_screen.dart';
import 'bulk_add_screen.dart';
import 'cards_statistics_screen.dart';
import 'connection_service.dart';
import 'custom_page_route.dart';
import 'extract_cards_screen.dart';
import 'mikrotik_connector.dart';
import 'network_doctor_screen.dart';
import 'pdf_templates_screen.dart';
import 'print_preview_screen.dart';
import 'profile_screen.dart';
import 'qahtani_link_screen.dart';
import 'saved_files_screen.dart';
import 'setup_wizard_screen.dart';
import 'stats_screen.dart';
import 'user_data_usage_chart_screen.dart';

enum MikrotikMode { userManager, hotspot }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isVersion7OrNewer,
    required this.username,
  });

  final bool isVersion7OrNewer;
  final String username;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _ServiceItem {
  const _ServiceItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _profiles = const [];
  bool _isLoading = true;
  bool _isConnected = false;
  bool _isNetworkLinked = false;
  String _clientName = '';
  int _totalUsers = 0;
  int _activeUsers = 0;
  MikrotikMode _selectedMode = MikrotikMode.userManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadDashboard(showLoader: false);
  }

  Future<void> _loadDashboard({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _isLoading = true);
    await _loadLinkStatus();
    await _fetchRouterData();
    if (mounted && showLoader) setState(() => _isLoading = false);
  }

  Future<void> _loadLinkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final linked = prefs.getBool('is_network_linked') ?? false;
    var name = '';
    if (linked) {
      try {
        final rawData = prefs.getString('qahtani_linked_data');
        final data = rawData == null ? null : jsonDecode(rawData) as Map<String, dynamic>;
        name = data?['client_info']?['name']?.toString() ?? '';
      } catch (_) {
        name = '';
      }
    }
    if (mounted) {
      setState(() {
        _isNetworkLinked = linked;
        _clientName = name;
      });
    }
  }

  Future<void> _fetchRouterData() async {
    RouterOSClient? client;
    try {
      await ConnectionService.instance.getClient();
      client = await MikrotikConnector.connect();
      final profilesCommand = _selectedMode == MikrotikMode.userManager
          ? '/tool/user-manager/profile/print'
          : '/ip/hotspot/user/profile/print';
      final profilesResponse = await client.talk([profilesCommand]);

      final usersResponse = await _safeTalk(client, ['/tool/user-manager/user/print', '=.proplist=.id']);
      var activeResponse = await _safeTalk(client, ['/ip/hotspot/active/print']);
      if (activeResponse.isEmpty) {
        activeResponse = await _safeTalk(client, ['/tool/user-manager/session/print']);
      }

      if (mounted) {
        setState(() {
          _profiles = profilesResponse.map((item) => Map<String, dynamic>.from(item)).toList();
          _totalUsers = usersResponse.length;
          _activeUsers = activeResponse.length;
          _isConnected = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _profiles = const [];
          _totalUsers = 0;
          _activeUsers = 0;
          _isConnected = false;
        });
      }
    } finally {
      client?.close();
    }
  }

  Future<List<dynamic>> _safeTalk(RouterOSClient client, List<String> command) async {
    try {
      return await client.talk(command);
    } catch (_) {
      return const [];
    }
  }

  void _switchMode(MikrotikMode value) {
    if (value == _selectedMode) return;
    setState(() => _selectedMode = value);
    _loadDashboard(showLoader: false);
  }

  Future<void> _logout() async {
    await ConnectionService.instance.disconnect();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final services = _buildServices();
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            onPressed: () => _loadDashboard(),
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _logout,
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const CustomLoadingIndicator(message: 'جاري تجهيز بيانات الشبكة…')
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed([
                        _buildWelcomeCard(context),
                        const SizedBox(height: 16),
                        _buildKpis(context),
                        const SizedBox(height: 20),
                        _buildModeSelector(),
                        const SizedBox(height: 24),
                        Text('أدوات الإدارة', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('اختر الخدمة المناسبة لإدارة شبكة MikroTik والكروت.', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 14),
                      ]),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.crossAxisExtent >= 900 ? 4 : constraints.crossAxisExtent >= 620 ? 3 : 2;
                        return SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _ServiceTile(item: services[index]),
                            childCount: services.length,
                          ),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: columns >= 3 ? 1.12 : .92,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = _isNetworkLinked && _clientName.isNotEmpty ? _clientName : widget.username;
    final connectionText = _isConnected ? 'متصل بالراوتر' : 'غير متصل بالراوتر';
    final connectionColor = _isConnected ? const Color(0xFF38C793) : const Color(0xFFF26D85);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF24265F), Color(0xFF151D32)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: .24),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.router_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مرحباً، $displayName', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: connectionColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(connectionText, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: .72))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpis(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 24) / 3;
        return Row(
          children: [
            _MetricCard(width: width, label: 'المستخدمون', value: '$_totalUsers', icon: Icons.people_alt_outlined, color: const Color(0xFF6C7BFF)),
            const SizedBox(width: 12),
            _MetricCard(width: width, label: 'الفئات', value: '${_profiles.length}', icon: Icons.layers_outlined, color: const Color(0xFF38C793)),
            const SizedBox(width: 12),
            _MetricCard(width: width, label: 'المتصلون', value: '$_activeUsers', icon: Icons.wifi_tethering_rounded, color: const Color(0xFFF6B756)),
          ],
        );
      },
    );
  }

  Widget _buildModeSelector() {
    return SegmentedButton<MikrotikMode>(
      segments: const [
        ButtonSegment(value: MikrotikMode.userManager, icon: Icon(Icons.manage_accounts_outlined), label: Text('مدير المستخدمين')),
        ButtonSegment(value: MikrotikMode.hotspot, icon: Icon(Icons.wifi_rounded), label: Text('Hotspot')),
      ],
      selected: {_selectedMode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => _switchMode(selection.first),
    );
  }

  List<_ServiceItem> _buildServices() {
    return [
      _ServiceItem(title: 'إضافة كرت', icon: Icons.person_add_alt_1_outlined, color: const Color(0xFF6C7BFF), onTap: () => _open(AddUserScreen(profiles: _profiles, isVersion7OrNewer: widget.isVersion7OrNewer, customer: widget.username))),
      _ServiceItem(title: 'إنشاء كروت بالجملة', icon: Icons.group_add_outlined, color: const Color(0xFF38C793), onTap: () => _open(BulkAddScreen(profiles: _profiles, isVersion7OrNewer: widget.isVersion7OrNewer, username: widget.username))),
      _ServiceItem(title: 'معالج الإعداد', icon: Icons.auto_fix_high_outlined, color: const Color(0xFFA78BFA), onTap: () => _open(const SetupWizardScreen())),
      _ServiceItem(title: 'ربط الشبكة', icon: Icons.link_rounded, color: const Color(0xFF4DA3FF), onTap: () => _open(const QahtaniLinkScreen())),
      _ServiceItem(title: 'الإحصاءات', icon: Icons.query_stats_outlined, color: const Color(0xFF25B6A1), onTap: () => _open(const StatsScreen())),
      _ServiceItem(title: 'طبيب الشبكة', icon: Icons.health_and_safety_outlined, color: const Color(0xFF4DA3FF), onTap: () => _open(const NetworkDoctorScreen())),
      _ServiceItem(title: 'الملفات المحفوظة', icon: Icons.folder_copy_outlined, color: const Color(0xFFF6B756), onTap: () => _open(const SavedFilesScreen())),
      _ServiceItem(title: 'قوالب PDF', icon: Icons.picture_as_pdf_outlined, color: const Color(0xFF96A5BF), onTap: () => _open(PdfTemplatesScreen(profiles: _profiles))),
      _ServiceItem(title: 'استخراج الكروت', icon: Icons.document_scanner_outlined, color: const Color(0xFFF26D85), onTap: () => _open(const ExtractCardsScreen())),
      _ServiceItem(title: 'طباعة البطاقات', icon: Icons.print_outlined, color: const Color(0xFF96A5BF), onTap: () => _open(const PrintPreviewScreen(cardUsernames: []))),
      _ServiceItem(title: 'إحصاءات الكروت', icon: Icons.bar_chart_rounded, color: const Color(0xFFA78BFA), onTap: () => _open(const CardsStatisticsScreen())),
      _ServiceItem(title: 'استخدام البيانات', icon: Icons.data_usage_outlined, color: const Color(0xFF53C8FF), onTap: () => _open(const UserDataUsageChartScreen())),
      _ServiceItem(title: 'المستخدمون النشطون', icon: Icons.people_outline_rounded, color: const Color(0xFF38C793), onTap: () => _open(const ActiveUsersScreen())),
      _ServiceItem(title: 'الملف الشخصي', icon: Icons.account_circle_outlined, color: const Color(0xFF53C8FF), onTap: () => _open(const ProfileScreen())),
      _ServiceItem(title: 'النسخ الاحتياطي', icon: Icons.backup_outlined, color: const Color(0xFF6C7BFF), onTap: () => _open(const BackupSystemScreen())),
    ];
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(CustomPageRoute(builder: (_) => page));
    if (mounted) _loadDashboard(showLoader: false);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.width, required this.label, required this.value, required this.icon, required this.color});

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(height: 14),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.item});

  final _ServiceItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: item.color.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)),
                child: Icon(item.icon, color: item.color, size: 25),
              ),
              const Spacer(),
              Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('فتح الخدمة', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomLoadingIndicator extends StatelessWidget {
  const CustomLoadingIndicator({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
