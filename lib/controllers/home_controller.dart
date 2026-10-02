import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/api/users/active_users_api.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import '../core/app_pages.dart';
import '../core/string_extensions.dart'; 
import '/api/reports_api.dart';

class HomeController extends GetxController with GetSingleTickerProviderStateMixin {
  
  // ================= القيم التفاعلية (المتغيرة) الحقيقية =================
  var cpuPercent = "0%".obs;
  var ramPercent = "0%".obs;
  var activeUsersCount = "0 متصل".obs; 
  var uptime = "00:00:00".obs; 
  
  // 🔹 متغيرات مساحة القرص الجديدة
  var diskSpacePercent = "0%".obs; 
  var diskSpaceDetails = "جاري الفحص...".obs; 
  
  var currentPage = 0.obs;

  // ================= متحكمات الواجهة والحركة =================
  late PageController pageController;
  late AnimationController pulseController;
  Timer? dataRefreshTimer; 

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(viewportFraction: 0.9, initialPage: 0);
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    
    fetchRealData();
    _startDataRefreshTimer();
  }

  @override
  void onClose() {
    dataRefreshTimer?.cancel();
    pageController.dispose();
    pulseController.dispose();
    super.onClose();
  }

  

  void _startDataRefreshTimer() {
    dataRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchRealData();
    });
  }

  // ================= دالة جلب البيانات الحقيقية من السيرفر =================
  Future<void> fetchRealData() async {
    var sysResponse = await ReportsApi.getSystemState();
    if (sysResponse.status && sysResponse.data != null) {
      var sys = sysResponse.data!;
      cpuPercent.value = "${sys.cpu}%";
      uptime.value = sys.uptime.formatUptime.split("\n").join(" "); 

      double totalRam = double.tryParse(sys.totalMemory.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      double freeRam = double.tryParse(sys.freeMemory.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      if (totalRam > 0) {
        int ramUsagePercent = (((totalRam - freeRam) / totalRam) * 100).toInt();
        ramPercent.value = "$ramUsagePercent%";
      }

      // 🔹 حساب مساحة القرص وتحديث المتغيرات
      double totalDisk = double.tryParse(sys.totalDiskSpace.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      double freeDisk = double.tryParse(sys.freeDiskSpace.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      
      if (totalDisk > 0) {
        double usedDisk = totalDisk - freeDisk; // المساحة المستخدمة فعلياً
        int diskUsagePercent = ((usedDisk / totalDisk) * 100).toInt(); // النسبة المئوية
        
        diskSpacePercent.value = "$diskUsagePercent%";
        // تنسيق النص ليعرض رقم واحد بعد الفاصلة (مثل: المستخدم 5.2 MB / الإجمالي 120.5 MB)
        diskSpaceDetails.value = "المستخدم: ${usedDisk.toStringAsFixed(1).toString().formatBytes} / الإجمالي: ${totalDisk.toStringAsFixed(1).toString().formatBytes} MB";
      }
    }

    var activeResponse = await ActiveUsersApi.getAllActive();
    if (activeResponse.status && activeResponse.data != null) {
      activeUsersCount.value = "${activeResponse.data!.length} متصل";
    }
  }

  void updateCurrentPage(int index) {
    currentPage.value = index;
  }

  // ================= دوال أزرار الـ Carousel =================
  void generateSingleCard() => Get.toNamed(AppRoutes.addSingleCard);
  void manageActiveUsers() => Get.toNamed(AppRoutes.users); 
  void viewUptimeDetails() => Get.toNamed(AppRoutes.reports); 
  void checkDiskSpace() => Get.toNamed(AppRoutes.systemStatus);

  // ================= دوال التنقل للأقسام (Grid) =================
  void goToCards() => Get.toNamed(AppRoutes.cards);
  void goToUsers() => Get.toNamed(AppRoutes.users);
  void goToPrint() => Get.toNamed(AppRoutes.print);
  void goToSites() => Get.toNamed(AppRoutes.sites);
  void goToReports() => Get.toNamed(AppRoutes.reports);
  void goToMoreSettings() => Get.toNamed(AppRoutes.more);

  void logout(){
    showConfirmDialog(message: "هل انت متاكد من قطع الاتصال", onConfirm: Get.back);
  }
}