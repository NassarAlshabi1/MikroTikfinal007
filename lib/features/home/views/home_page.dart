import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:mikronet/features/home/controllers/home_controller.dart';
import 'package:mikronet/features/home/views/widgets/dashboard_widgets.dart';
import 'package:mikronet/features/home/views/widgets/home_header.dart';
import 'package:mikronet/features/home/views/widgets/menu_item_card.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        controller.logout();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.soft,
          body: Column(
            children: [
              HomeHeader(
                pulseAnimation: controller.pulseController,
                onLogout: controller.logout,
              ),
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Column(
                          children: [
                            PrimaryActionBanner(
                              title: "توليد كرت واحد",
                              subtitle: "إنشاء كرت مستخدم فوري على الراوتر",
                              icon: Icons.add_moderator_rounded,
                              onTap: controller.generateSingleCard,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 102,
                              child: Obx(() => Row(
                                    children: [
                                      Expanded(
                                        child: StatCard(
                                          title: "المتصلين الآن",
                                          value: controller
                                              .activeUsersCount.value,
                                          icon: Icons
                                              .online_prediction_rounded,
                                          accent: AppColors.green,
                                          onTap:
                                              controller.manageActiveUsers,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: StatCard(
                                          title: "وقت التشغيل",
                                          value: controller.uptime.value,
                                          icon: Icons.timer_rounded,
                                          accent: AppColors.warning,
                                          onTap:
                                              controller.viewUptimeDetails,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: StatCard(
                                          title: "مساحة القرص",
                                          value: controller
                                              .diskSpacePercent.value,
                                          icon: Icons.sd_storage_rounded,
                                          accent: AppColors.info,
                                          onTap: controller.checkDiskSpace,
                                        ),
                                      ),
                                    ],
                                  )),
                            ),
                            const SizedBox(height: 12),
                            Obx(() => ResourcePanel(
                                  cpu: controller.cpuPercent.value,
                                  ram: controller.ramPercent.value,
                                  disk: controller.diskSpacePercent.value,
                                  diskDetails:
                                      controller.diskSpaceDetails.value,
                                  onTap: controller.checkDiskSpace,
                                )),
                            const SizedBox(height: 16),
                            _buildSectionTitle("إدارة النظام والعمليات"),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: _buildGridMenu(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridMenu() {
    final items = <Map<String, dynamic>>[
      {
        "title": "إدارة الكروت",
        "icon": Icons.credit_card_rounded,
        "accent": AppColors.blue,
        "onTap": controller.goToCards
      },
      {
        "title": "المستخدمين",
        "icon": Icons.people_alt_rounded,
        "accent": AppColors.green,
        "onTap": controller.goToUsers
      },
      {
        "title": "إدارة عملية الطباعة",
        "icon": Icons.print_rounded,
        "accent": AppColors.sky,
        "onTap": controller.goToPrint
      },
      {
        "title": "إعدادات المواقع",
        "icon": Icons.dns_rounded,
        "accent": AppColors.teal,
        "onTap": controller.goToSites
      },
      {
        "title": "التقارير والمبيعات",
        "icon": Icons.analytics_rounded,
        "accent": AppColors.pink,
        "onTap": controller.goToReports
      },
      {
        "title": "الموزعين ونقاط البيع",
        "icon": Icons.storefront_rounded,
        "accent": AppColors.violet,
        "onTap": controller.goToDistributors
      },
      {
        "title": "أدوات الصيانة",
        "icon": Icons.build_circle_rounded,
        "accent": AppColors.warning,
        "onTap": controller.goToMaintenance
      },
      {
        "title": "المزيد من الإعدادات",
        "icon": Icons.tune_rounded,
        "accent": AppColors.textMuted,
        "onTap": controller.goToMoreSettings
      },
    ];

    return SliverGrid.builder(
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) => MenuItemCard(
        title: items[index]['title'],
        icon: items[index]['icon'],
        accent: items[index]['accent'],
        onTap: items[index]['onTap'],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: AppColors.textPale),
      ),
    );
  }
}
