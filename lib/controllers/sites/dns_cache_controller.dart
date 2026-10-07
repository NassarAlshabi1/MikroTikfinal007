import 'package:flutter/material.dart';
import 'package:get/get.dart';
// تأكد من مسارات الاستيراد لمودل الـ DNS وملف الـ API
import '/models/sites_model.dart'; 
import '/api/sites_api.dart'; 

class DnsCacheController extends GetxController {
  // قائمة تفاعلية (Reactive) لتخزين السجلات باستخدام المودل
  RxList<DNSCacheModel> dnsCacheList = <DNSCacheModel>[].obs;
  
  // متغير لمتابعة حالة التحميل
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDnsCache();
  }

  // دالة جلب البيانات من المايكروتك
  Future<void> fetchDnsCache() async {
    isLoading.value = true;
    var response = await SitesApi.getDnsCache();
    
    if (response.status && response.data != null) {
      dnsCacheList.value = response.data!;
    } else {
      Get.snackbar(
        "تنبيه", 
        response.message ?? "حدث خطأ أثناء جلب السجلات",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  // دالة مسح كل التخزين المؤقت
  void clearCache() {
    // ملاحظة: هنا يجب استدعاء API لعمل Flush للمايكروتك
    // await MikrotikClient.printData(commands: ["/ip/dns/cache/flush"]);
    
    dnsCacheList.clear();
    Get.snackbar(
      "نجاح", 
      "تم مسح التخزين المؤقت بنجاح", 
      backgroundColor: Colors.green.shade600, 
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // دالة حذف سجل محدد
  void deleteSite(String id) {
    // ملاحظة: هنا يجب استدعاء API لحذف السجل من المايكروتك إذا كان مدعوماً
    dnsCacheList.removeWhere((item) => item.id == id);
  }
}