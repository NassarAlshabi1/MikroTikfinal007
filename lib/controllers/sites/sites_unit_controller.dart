import 'package:get/get.dart';
import '../../core/app_pages.dart'; // لتتمكن من الوصول لـ AppRoutes

class SitesUnitController extends GetxController {
  
  @override
  void onInit() {
    super.onInit();
    // استدعاء الدالة عند فتح الصفحة كبديل لـ DataMgmtVM()..fetchFromMikrotik()
    fetchFromMikrotik();
  }

  void fetchFromMikrotik() {
    // اكتب هنا منطق جلب البيانات من المايكروتك
    print("Fetching data from Mikrotik...");
  }

  // ================= دوال الانتقالات =================

  void goBack() {
    Get.back();
  }

  // إذا ما زلت تحتاج صفحة إعدادات الـ DNS لاحقاً
  void goToDnsSettings() {
    Get.toNamed(AppRoutes.dnsSettings);
  }

  void goToDnsCache() {
    Get.toNamed(AppRoutes.dnsCache);
  }

  // ================= دوال الانتقال لصفحات الحظر (مع تمرير النوع) =================
  
  void goToBlockedIps() {
    Get.toNamed(AppRoutes.blockedSites, arguments: 'IP');
  }

  void goToBlockedDomains() {
    Get.toNamed(AppRoutes.blockedSites, arguments: 'Domain');
  }

  void goToBlockedContent() {
    Get.toNamed(AppRoutes.blockedSites, arguments: 'Content');
  }
}