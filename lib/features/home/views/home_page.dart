import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:mikronet/features/home/controllers/home_controller.dart';

import 'package:mikronet/features/home/views/widgets/home_header.dart';
import 'package:mikronet/features/home/views/widgets/home_carousel.dart';
import 'package:mikronet/features/home/views/widgets/menu_item_card.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if(didPop) return;
        controller.logout();
      },
    child :Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.soft,
        body: Column(
          children: [
            HomeHeader(
              pulseAnimation: controller.pulseController,
              onLogout: controller.logout,
            ),
            
            Obx(() => HomeCarousel(
              controller: controller.pageController,
              currentPage: controller.currentPage.value,
              onPageChanged: controller.updateCurrentPage,
              items: _buildCarouselItems(),
            )),
            
            _buildSectionTitle("إدارة النظام والعمليات"),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildGridMenu(),
              ),
            ),
          ],
        ),
      ),
    )
    );
  }

  List<Widget> _buildCarouselItems() {
    return [
      // 1. توليد كرت واحد
      ActionCarouselItem(
        category: "إجراء سريع",
        title: "توليد كرت واحد",
        subtitle: "إنشاء كرت مستخدم فوري",
        icon: Icons.add_moderator_rounded,
        color: AppColors.blue,
        actionText: "ابدأ الإضافة",
        onTap: controller.generateSingleCard, 
      ),
      // 2. المتصلين النشطين
      ActionCarouselItem(
        category: "مراقبة الشبكة",
        title: "المتصلين النشطين",
        subtitle: "أجهزة تسحب بيانات الآن",
        value: controller.activeUsersCount.value, 
        icon: Icons.online_prediction_rounded,
        color: AppColors.green, 
        actionText: "عرض المتصلين",
        onTap: controller.manageActiveUsers, 
      ),
      // 3. وقت التشغيل (Uptime)
      ActionCarouselItem(
        category: "حالة النظام",
        title: "وقت التشغيل",
        subtitle: "مدة عمل الراوتر (Uptime)",
        value: controller.uptime.value, 
        icon: Icons.timer_rounded,
        color: AppColors.warning, 
        actionText: "تقارير النظام",
        onTap: controller.viewUptimeDetails, 
      ),
      // 4. حمل المعالج
      ResourceCarouselItem(
        category: "مراقبة الأداء",
        label: "حمل المعالج (CPU)",
        percent: controller.cpuPercent.value, 
        icon: Icons.speed_rounded,
        color: Colors.cyanAccent,
      ),
      // 5. استهلاك الرام
      ResourceCarouselItem(
        category: "مراقبة الأداء",
        label: "استهلاك الرام (RAM)",
        percent: controller.ramPercent.value, 
        icon: Icons.memory_rounded,
        color: Colors.purpleAccent,
      ),
      // 6. 🔹 مساحة القرص (تم التحديث هنا)
      ActionCarouselItem(
        category: "تنبيه النظام",
        title: "مساحة التخزين (Disk)",
        subtitle: controller.diskSpaceDetails.value, // الإجمالي والمستخدم
        value: controller.diskSpacePercent.value,    // النسبة المئوية
        icon: Icons.sd_storage_rounded,
        color: AppColors.textMuted,
        actionText: "تفاصيل القرص",
        onTap: controller.checkDiskSpace, 
      ),
    ];
  }

  Widget _buildGridMenu() {
    final List<Map<String, dynamic>> menuData = [
      {
        "title": "إدارة الكروت",
        "icon": Icons.credit_card_rounded,
        "onTap": controller.goToCards
      },
      {
        "title": "المستخدمين",
        "icon": Icons.people_alt_rounded,
        "onTap": controller.goToUsers
      },
      {
        "title": "الموزعين ونقاط البيع",
        "icon": Icons.storefront_rounded,
        "onTap": controller.goToDistributors
      },
      {
        "title": "ادارة عملية الطباعة",
        "icon": Icons.print_rounded,
        "onTap": controller.goToPrint
      },
      {
        "title": "اعدادات المواقع",
        "icon": Icons.dns_rounded,
        "onTap": controller.goToSites
      },
      {
        "title": "التقارير والمبيعات",
        "icon": Icons.analytics_rounded,
        "onTap": controller.goToReports
      },
      {
        "title": "أدوات الصيانة",
        "icon": Icons.build_circle_rounded,
        "onTap": controller.goToMaintenance
      },
      {
        "title": "المزيد من الاعدادات",
        "icon": Icons.tune_rounded,
        "onTap": controller.goToMoreSettings
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 18),
      itemCount: menuData.length,
      // بطاقات أصغر (أعرض من ارتفاعها) لعرض أكبر عدد ممكن في الشاشة
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) => MenuItemCard(
        title: menuData[index]['title'],
        icon: menuData[index]['icon'],
        onTap: menuData[index]['onTap'], 
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.text),
        ),
      ),
    );
  }
}