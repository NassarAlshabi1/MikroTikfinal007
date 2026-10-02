import 'package:get/get.dart';
import 'package:flutter/material.dart';

// تأكد من صحة هذه المسارات حسب مجلدات مشروعك
import '../../models/selles_model.dart';
import '../../models/response.dart'; 
import '../../api/reports_api.dart';

class SystemStatusReportController extends GetxController {
  // حالة التحميل
  RxBool isLoading = false.obs;
  
  // المتغير الذي سيحمل بيانات النظام
  Rx<SystemStateModel?> systemState = Rx<SystemStateModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchSystemStatus(); // جلب البيانات تلقائياً عند فتح الصفحة
  }

  // دالة جلب بيانات النظام الحقيقية من الـ API
  Future<void> fetchSystemStatus() async {
    isLoading.value = true;
    
    try {
      AppResponse<SystemStateModel> response = await ReportsApi.getSystemState();

      if (response.status && response.data != null) {
        systemState.value = response.data;
      } else {
        Get.snackbar(
          "تنبيه", 
          response.message, 
          backgroundColor: Colors.redAccent, 
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        "خطأ", 
        "حدث خطأ أثناء الاتصال بالراوتر: $e", 
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}