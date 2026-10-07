import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/core/app_pages.dart';
import 'package:mikronet/core/app_theme.dart';
import '/controllers/home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) controller.logout();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.page,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.fetchRealData,
                    color: AppColors.info,
                    backgroundColor: AppColors.card,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 22),
                      children: [
                        _buildRouterPanel(),
                        const SizedBox(height: 12),
                        _buildResourceGrid(),
                        const SizedBox(height: 14),
                        _buildMonitoringBanner(),
                        const SizedBox(height: 20),
                        _buildSectionHeading(
                          'الخدمات',
                          'اختصارات إدارة الراوتر',
                        ),
                        const SizedBox(height: 10),
                        _buildServicesGrid(),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'MkCards',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 9),
                Obx(
                  () => FadeTransition(
                    opacity: controller.pulseController,
                    child: Icon(
                      Icons.circle,
                      size: 10,
                      color: controller.isOnline.value
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 6,
            child: Row(
              children: [
                PopupMenuButton<String>(
                  tooltip: 'القائمة',
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.text),
                  onSelected: (value) {
                    switch (value) {
                      case 'cards':
                        Get.toNamed(AppRoutes.cards);
                        break;
                      case 'print':
                        Get.toNamed(AppRoutes.print);
                        break;
                      case 'reports':
                        Get.toNamed(AppRoutes.reports);
                        break;
                      case 'settings':
                        Get.toNamed(AppRoutes.more);
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'cards', child: Text('إدارة الكروت')),
                    PopupMenuItem(value: 'print', child: Text('إدارة الطباعة')),
                    PopupMenuItem(value: 'reports', child: Text('التقارير')),
                    PopupMenuItem(value: 'settings', child: Text('الإعدادات')),
                  ],
                ),
                Obx(
                  () => IconButton(
                    tooltip: controller.isRefreshing.value ? 'جارٍ التحديث' : 'تحديث حالة الراوتر',
                    onPressed: controller.isRefreshing.value
                        ? null
                        : controller.fetchRealData,
                    icon: controller.isRefreshing.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouterPanel() {
    return Obx(() {
      final connected = controller.isOnline.value;
      final address = controller.routerAddress.value;
      final serial = controller.routerSerial.value;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0C707C), Color(0xFF118A9A)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0C707C).withOpacity(0.2),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _iconBubble(Icons.router_rounded, Colors.white.withOpacity(0.14)),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'حالة الراوتر',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address.isNotEmpty ? address : (serial.isNotEmpty ? serial : 'العنوان غير متاح'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: connected
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.danger.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: connected
                          ? AppColors.success.withOpacity(0.55)
                          : AppColors.danger.withOpacity(0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        connected ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        size: 14,
                        color: connected ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        connected ? 'متصل' : 'غير متصل',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _routerInfo(
                    Icons.access_time_rounded,
                    'مدة التشغيل',
                    controller.uptime.value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _routerInfo(
                    Icons.system_update_alt_rounded,
                    'إصدار RouterOS',
                    controller.systemVersion.value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _routerInfo(
                    Icons.memory_rounded,
                    'المعالج',
                    controller.cpuPercent.value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _routerInfo(
                    Icons.people_alt_rounded,
                    'المستخدمون النشطون',
                    controller.activeUsersCount.value,
                  ),
                ),
              ],
            ),
            if (controller.errorMessage.value.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFFDE68A), size: 17),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        controller.errorMessage.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFFFF7ED), fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _routerInfo(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceGrid() {
    final metrics = [
      _HomeMetric('حمل المعالج', controller.cpuPercent, Icons.memory_rounded, AppColors.info),
      _HomeMetric('استخدام الذاكرة', controller.ramPercent, Icons.storage_rounded, AppColors.purple, detail: controller.ramDetails),
      _HomeMetric('التخزين المستخدم', controller.diskSpacePercent, Icons.sd_storage_rounded, AppColors.warning, detail: controller.diskSpaceDetails),
      _HomeMetric('المستخدمون النشطون', controller.activeUsersCount, Icons.people_alt_rounded, AppColors.success),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 9,
        crossAxisSpacing: 9,
        childAspectRatio: 1.9,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.border.withOpacity(0.85)),
            ),
            child: Row(
              children: [
                _iconBubble(metric.icon, metric.color.withOpacity(0.13), foreground: metric.color),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(metric.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
                      const SizedBox(height: 3),
                      Text(metric.value.value, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w900)),
                      if (metric.detail != null) ...[
                        const SizedBox(height: 1),
                        Text(metric.detail!.value, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 8.5)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonitoringBanner() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF171F32),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.55)),
      ),
      child: Row(
        children: [
          _iconBubble(Icons.campaign_rounded, AppColors.warning.withOpacity(0.16), foreground: AppColors.warning),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'مراقبة الشبكة وإدارة الاتصال',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: controller.goToMonitor,
            icon: const Icon(Icons.north_west_rounded, size: 16),
            label: const Text('عرض'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: const Color(0xFF172033),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.text, fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
            ],
          ),
        ),
        const Icon(Icons.grid_view_rounded, color: AppColors.info, size: 20),
      ],
    );
  }

  Widget _buildServicesGrid() {
    final actions = <_HomeAction>[
      _HomeAction('إدارة المايكروتك', Icons.router_rounded, AppColors.info, controller.goToMaintenance),
      _HomeAction('نظام الهوتسبوت', Icons.wifi_rounded, AppColors.success, () => Get.toNamed(AppRoutes.hotspot)),
      _HomeAction('نظام اليوزرمنجر', Icons.people_alt_rounded, AppColors.info, controller.goToUsers),
      _HomeAction('الحسابات المالية', Icons.account_balance_wallet_rounded, AppColors.warning, controller.goToDistributors),
      _HomeAction('مراقبة الشبكة', Icons.radar_rounded, AppColors.warning, controller.goToMonitor),
      _HomeAction('تصاميم الكروت', Icons.palette_rounded, AppColors.success, () => Get.toNamed(AppRoutes.templates)),
      _HomeAction('الباقات', Icons.layers_rounded, AppColors.purple, () => Get.toNamed(AppRoutes.packages)),
      _HomeAction('دفعات الكروت', Icons.add_to_photos_rounded, AppColors.info, () => Get.toNamed(AppRoutes.batches)),
      _HomeAction('المستخدمون المنتهون', Icons.person_remove_alt_1_rounded, AppColors.danger, () => Get.toNamed(AppRoutes.expiredUsers)),
      _HomeAction('الأنشطة والتقارير', Icons.history_rounded, AppColors.success, controller.goToReports),
      _HomeAction('النسخ الاحتياطي', Icons.backup_rounded, AppColors.warning, () => Get.toNamed(AppRoutes.routerBackup)),
      _HomeAction('إدارة الكروت', Icons.credit_card_rounded, AppColors.info, controller.goToCards),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) => _serviceTile(actions[index]),
        );
      },
    );
  }

  Widget _serviceTile(_HomeAction action) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border.withOpacity(0.85)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconBubble(action.icon, action.color.withOpacity(0.12), foreground: action.color),
              const SizedBox(height: 8),
              Text(
                action.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.text, fontSize: 11, fontWeight: FontWeight.w700, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xF2162237),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.info.withOpacity(0.48)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            _navItem(Icons.home_rounded, 'الرئيسية', selected: true, onTap: () {}),
            _navItem(Icons.settings_rounded, 'إعدادات', onTap: controller.goToMoreSettings),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -10),
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showQuickActions,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)]),
                          border: Border.all(color: Colors.white.withOpacity(0.32), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: AppColors.info.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _navItem(Icons.analytics_rounded, 'التقارير', onTap: controller.goToReports),
            _navItem(Icons.credit_card_rounded, 'الكروت', onTap: controller.goToCards),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {bool selected = false, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? AppColors.info : AppColors.textMuted, size: 21),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: selected ? AppColors.info : AppColors.textMuted, fontSize: 9, fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActions() {
    Get.bottomSheet<void>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted.withOpacity(0.5), borderRadius: BorderRadius.circular(9))),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('إجراء سريع', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 8),
              _quickAction('إضافة كرت واحد', Icons.add_card_rounded, AppRoutes.addSingleCard),
              _quickAction('إدارة الكروت', Icons.credit_card_rounded, AppRoutes.cardsList),
              _quickAction('إدارة الدفعات', Icons.layers_rounded, AppRoutes.batches),
              _quickAction('تصاميم الطباعة', Icons.palette_rounded, AppRoutes.templates),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _quickAction(String title, IconData icon, String route) {
    return ListTile(
      leading: _iconBubble(icon, AppColors.info.withOpacity(0.12), foreground: AppColors.info),
      title: Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
      onTap: () {
        Get.back();
        Get.toNamed(route);
      },
    );
  }

  Widget _iconBubble(IconData icon, Color background, {Color foreground = Colors.white}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(13)),
      child: Icon(icon, color: foreground, size: 20),
    );
  }
}

class _HomeMetric {
  final String label;
  final RxString value;
  final IconData icon;
  final Color color;
  final RxString? detail;

  const _HomeMetric(this.label, this.value, this.icon, this.color, {this.detail});
}

class _HomeAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HomeAction(this.title, this.icon, this.color, this.onTap);
}
