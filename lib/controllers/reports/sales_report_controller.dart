import 'package:flutter/material.dart';
import 'package:get/get.dart';
// تأكد من صحة هذه المسارات حسب مجلدات مشروعك
import '../../models/selles_model.dart';
import '../../models/response.dart';
import '../../api/reports_api.dart'; // مسار ملف الـ API

class SalesReportController extends GetxController {
  // التواريخ
  Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  Rx<DateTime?> toDate = Rx<DateTime?>(null);

  // حالات التحميل والبيانات
  RxBool isLoading = false.obs;
  RxList<SellesReportModel> salesList = <SellesReportModel>[].obs;

  // إجماليات عامة
  RxInt totalCards = 0.obs;
  RxDouble totalRevenue = 0.0.obs;

  // إجماليات حسب الفئة (الباقة)
  RxMap<String, Map<String, dynamic>> summaryByProfile = <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // تعيين تاريخ اليوم كافتراضي عند فتح الصفحة
    DateTime now = DateTime.now();
    fromDate.value = DateTime(now.year, now.month, now.day-1);
    toDate.value = DateTime(now.year, now.month, now.day); // جعل النهاية آخر اليوم
  }

  // اختيار تاريخ "من"
  Future<void> pickFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      fromDate.value = picked;
    }
  }

  // اختيار تاريخ "إلى"
  Future<void> pickToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      // ضبط الوقت ليكون نهاية اليوم المختار
      toDate.value = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
    }
  }

  // جلب تقرير المبيعات الحقيقي من الـ API
  Future<void> fetchReport() async {
    if (fromDate.value == null || toDate.value == null) {
      Get.snackbar(
        "تنبيه", 
        "يرجى تحديد فترة التقرير أولاً", 
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: Colors.orange, 
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    
    try {
      // استدعاء الـ API الحقيقي مع التمرير المباشر للتواريخ
      AppResponse<List<SellesReportModel>> response = await ReportsApi.getSallesReport(
        from: fromDate.value,
        to: toDate.value,
      );

      if (response.status && response.data != null) {
        // تحديث القائمة بالبيانات الحقيقية
        salesList.assignAll(response.data!);
        _calculateSummary();
      } else {
        Get.snackbar(
          "تنبيه", 
          response.message ?? "لا توجد مبيعات في هذه الفترة أو حدث خطأ", 
          backgroundColor: Colors.redAccent, 
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        "خطأ", 
        "حدث خطأ أثناء جلب البيانات: $e", 
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // دالة لحساب الإجماليات وتقسيمها حسب الباقة
  void _calculateSummary() {
    int tCards = 0;
    double tRevenue = 0.0;
    Map<String, Map<String, dynamic>> profilesMap = {};

    for (var item in salesList) {
      tCards++;
      tRevenue += item.price;

      if (!profilesMap.containsKey(item.profile)) {
        profilesMap[item.profile] = {'count': 0, 'total': 0.0};
      }
      profilesMap[item.profile]!['count'] += 1;
      profilesMap[item.profile]!['total'] += item.price;
    }

    totalCards.value = tCards;
    totalRevenue.value = tRevenue;
    summaryByProfile.assignAll(profilesMap);
  }

  // دالة الطباعة (يتم ربطها لاحقاً بمكتبة الطباعة)
  void printReport() {
    if (salesList.isEmpty) {
      Get.snackbar(
        "تنبيه", 
        "لا توجد بيانات لطباعتها",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.snackbar(
      "نجاح", 
      "جاري تحضير التقرير للطباعة...", 
      backgroundColor: Colors.green, 
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}