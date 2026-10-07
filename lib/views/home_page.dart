import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/controllers/home_controller.dart';
import '/core/app_theme.dart';
import '/core/app_pages.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController());
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRouterStatusCard(),
                        const SizedBox(height: 10),
                        _buildStatisticsGrid(),
                        const SizedBox(height: 10),
                        _buildSyncNotice(),
                        const SizedBox(height: 16),
                        const Text('الخدمات', textAlign: TextAlign.right, style: TextStyle(color: AppColors.text, fontSize: 23, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 9),
                        _buildServicesGrid(),
                      ],
                    ),
                  ),
                ),
                _buildBottomNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 5, 14, 8),
      child: Row(
        children: [
          _roundIcon(Icons.more_vert_rounded, () {}),
          const SizedBox(width: 16),
          _roundIcon(Icons.wb_sunny_outlined, () {}),
          const Spacer(),
          const Text('MkCards', style: TextStyle(color: AppColors.info, fontSize: 23, fontWeight: FontWeight.w700)),
          const SizedBox(width: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF4B3728), borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFB69A62))),
            child: const Text('جيبي', style: TextStyle(color: Color(0xFFF5E6B7), fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Obx(() => Icon(Icons.circle, color: controller.isOnline.value ? const Color(0xFF70D98A) : AppColors.warning, size: 13)),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, color: AppColors.text, size: 28)));
  }

  Widget _buildRouterStatusCard() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF087D84), Color(0xFF1B9AA3)], begin: Alignment.topRight, end: Alignment.bottomLeft),
          borderRadius: BorderRadius.circular(29),
          boxShadow: [BoxShadow(color: const Color(0xFF18A5AC).withOpacity(.16), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Row(children: [
              _statusPill(Icons.router_outlined, controller.routerAddress.value, flex: 3),
              const SizedBox(width: 7),
              _statusPill(Icons.devices_other_outlined, 'الأجهزة المتصلة  ${controller.activeUsersCount.value}', flex: 3),
              const SizedBox(width: 7),
              _statusPill(Icons.cloud_outlined, 'كلاود', flex: 2),
              _refreshButton(),
            ]),
            const SizedBox(height: 7),
            Row(children: [
              _statusPill(Icons.access_time_rounded, 'مدة التشغيل  ${controller.uptime.value}', flex: 1),
              const SizedBox(width: 7),
              _statusPill(Icons.system_update_alt_rounded, 'الإصدار  ${controller.version.value}', flex: 1),
            ]),
            const SizedBox(height: 7),
            Row(children: [
              _statusPill(Icons.memory_rounded, 'المعالج  ${controller.cpuPercent.value}', flex: 1),
              const SizedBox(width: 7),
              _statusPill(Icons.thermostat_outlined, 'الحرارة  --', flex: 1, danger: true),
            ]),
            const SizedBox(height: 7),
            Row(children: [
              _statusPill(Icons.storage_outlined, 'الذاكرة  ${controller.ramPercent.value}', flex: 1),
              const SizedBox(width: 7),
              _statusPill(Icons.wifi_tethering_rounded, 'المستخدمون النشطون  ${controller.activeUsersCount.value}', flex: 1),
            ]),
          ],
        ),
      );
    });
  }

  Widget _statusPill(IconData icon, String text, {required int flex, bool danger = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 39,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.09), borderRadius: BorderRadius.circular(13)),
        child: Row(children: [Icon(icon, color: danger ? const Color(0xFFFFA0A0) : const Color(0xFFDDFBFF), size: 19), const SizedBox(width: 5), Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))) ]),
      ),
    );
  }

  Widget _refreshButton() {
    return InkWell(
      onTap: controller.fetchRealData,
      borderRadius: BorderRadius.circular(20),
      child: const Padding(padding: EdgeInsets.all(5), child: Icon(Icons.refresh_rounded, color: Colors.white, size: 25)),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: 2.25,
      children: [
        _statCard('الكروت المولدة', '—', 'الكروت خلال 30 يوماً', Icons.credit_card_outlined, const Color(0xFFF1C51B)),
        _statCard('إجمالي البيع', '—', 'نظام البوزرمينجر', Icons.storefront_outlined, AppColors.info),
        _statCard('الكروت المتبقية', '—', 'كروت الهوتسبوت: 0', Icons.inventory_2_outlined, const Color(0xFF4ADCCB)),
        _statCard('الكروت المباعة', '—', 'كروت بوزرمينجر: 0', Icons.check_circle_outline, const Color(0xFF43D9A0)),
      ],
    );
  }

  Widget _statCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(19), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(.13), shape: BoxShape.circle), child: Icon(icon, color: color, size: 21)),
        const SizedBox(width: 7),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
        ])),
      ]),
    );
  }

  Widget _buildSyncNotice() {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: const Color(0xFF121B2B), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF83721C), width: 1.4)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF75631A).withOpacity(.38), shape: BoxShape.circle), child: const Icon(Icons.campaign_outlined, color: Color(0xFFFFD51E), size: 22)),
        const SizedBox(width: 9),
        const Expanded(child: Text('مراقبة خطوط الإنترنت والشحن الفوري يمكنك التحكم', maxLines: 2, style: TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.bold))),
        ElevatedButton(onPressed: controller.fetchRealData, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFBD18), foregroundColor: const Color(0xFF1B1A10), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('عرض', style: TextStyle(fontWeight: FontWeight.w900))),
      ]),
    );
  }

  Widget _buildServicesGrid() {
    final items = <_HomeService>[
      _HomeService('نظام البوزرمينجر', Icons.groups_rounded, const Color(0xFF16A5DE), controller.goToCards),
      _HomeService('نظام الهوتسبوت', Icons.wifi_rounded, const Color(0xFF19B99A), controller.goToUsers),
      _HomeService('إدارة المايكروتك', Icons.map_rounded, const Color(0xFF2B9EEB), controller.goToSites),
      _HomeService('تصاميم الكروت', Icons.palette_outlined, const Color(0xFF25C9A5), controller.goToPrint),
      _HomeService('الاكستن والهوتسبوت', Icons.podcasts_rounded, const Color(0xFFD2A91A), controller.goToMonitor),
      _HomeService('الحسابات المالية', Icons.account_balance_wallet_outlined, const Color(0xFFF0C21F), controller.goToDistributors),
      _HomeService('الأنشطة الحديثة', Icons.history_rounded, const Color(0xFF20C8A6), controller.goToReports),
      _HomeService('النسخ الاحتياطية', Icons.archive_outlined, const Color(0xFFE2B71A), controller.goToMoreSettings),
      _HomeService('الملف الشخصي', Icons.person_outline_rounded, const Color(0xFF48C3DD), controller.goToMoreSettings),
    ];
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: .93),
      itemBuilder: (_, index) => _serviceCard(items[index]),
    );
  }

  Widget _serviceCard(_HomeService item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 7),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 43, height: 43, decoration: BoxDecoration(color: item.color.withOpacity(.14), shape: BoxShape.circle), child: Icon(item.icon, color: item.color, size: 25)),
          const SizedBox(height: 8),
          Text(item.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.text, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 78,
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 8),
      decoration: BoxDecoration(color: const Color(0xE9122034), borderRadius: BorderRadius.circular(35), border: Border.all(color: const Color(0xFF1C7E9D), width: 1.3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 12)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _navItem(Icons.person_outline_rounded, 'الملف', false, controller.goToMoreSettings),
        _navItem(Icons.receipt_long_outlined, 'التقارير', false, controller.goToReports),
        _navItem(Icons.add_rounded, '', true, controller.generateSingleCard),
        _navItem(Icons.settings_outlined, 'إعدادات', false, controller.goToMoreSettings),
        _navItem(Icons.home_rounded, 'الرئيسية', true, () {}),
      ]),
    );
  }

  Widget _navItem(IconData icon, String title, bool active, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(30), child: active && title.isEmpty
        ? Container(width: 68, height: 68, decoration: const BoxDecoration(color: Color(0xFF27B9E7), shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white, size: 38))
        : Padding(padding: const EdgeInsets.symmetric(horizontal: 7), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: active ? AppColors.info : AppColors.text, size: 26), const SizedBox(height: 3), Text(title, style: TextStyle(color: active ? AppColors.info : AppColors.text, fontSize: 11, fontWeight: FontWeight.bold))])));
  }
}

class _HomeService {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _HomeService(this.title, this.icon, this.color, this.onTap);
}
