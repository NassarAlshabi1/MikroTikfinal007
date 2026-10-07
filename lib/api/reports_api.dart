import 'package:mikronet/services/mikrotik_client.dart';
import 'package:mikronet/models/response.dart';

// تأكد من استيراد ملفات الموديل حسب مسارها في مشروعك
 import 'package:mikronet/models/selles_model.dart'; 

class ReportsApi {

  // دالة مساعدة: لتحويل صيغة تاريخ الدفع (MMM/DD/YYYY HH:mm:ss) إلى DateTime
  static DateTime? _parsePaymentDate(String dateStr) {
    try {
      // مثال للنص القادم: "jul/16/2025 11:32:32"
      var parts = dateStr.trim().split(' ');
      if (parts.length != 2) return null;

      // تفكيك التاريخ
      var dateParts = parts[0].split('/');
      if (dateParts.length != 3) return null;

      // خريطة لتحويل اسم الشهر المختصر إلى رقم
      const months = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
      };

      // استخراج الشهر كـ int باستخدام الخريطة (افتراضي 1 إذا لم يتطابق)
      int month = months[dateParts[0].toLowerCase()] ?? 1; 
      int day = int.parse(dateParts[1]);   // 16
      int year = int.parse(dateParts[2]);  // 2025

      // تفكيك الوقت
      var timeParts = parts[1].split(':');
      if (timeParts.length != 3) return null;

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      int second = int.parse(timeParts[2]);

      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      print('خطأ في تحويل تاريخ الدفع: $dateStr -> $e');
      return null;
    }
  }

  static Future<List> getPayments() async {
    return await MikrotikClient.printData(
        commands: ["/tool/user-manager/payment/print"],
        fields: "user,trans-start,price" 
      );
  }

  static Future<List> getProfiles() async {
    return await MikrotikClient.printData(
        commands: ["/tool/user-manager/profile/print"],
      );
  }

  // الدالة الرئيسية: جلب المدفوعات وتصفيتها بين تاريخين
  static Future<List<Map<String, dynamic>>> getPaymentsBetweenDates(DateTime startDate, DateTime endDate) async {
    try {
      // تمديد تاريخ النهاية ليشمل آخر ثانية في اليوم
      DateTime adjustedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      
      // 1. جلب البيانات من المايكروتيك
      var allPayments = await getPayments();
      
      // 2. فلترة البيانات
      var matchedPayments = allPayments.where((payment) {
        String? paymentTimeStr = payment['trans-start']; 
        if (paymentTimeStr == null || paymentTimeStr.isEmpty) return false;
        
        // تحويل النص إلى DateTime
        DateTime? paymentDate = _parsePaymentDate(paymentTimeStr);
        if (paymentDate == null) return false;
        
        // التحقق من النطاق الزمني
        bool isAfterStart = paymentDate.compareTo(startDate) >= 0;
        bool isBeforeEnd = paymentDate.compareTo(adjustedEndDate) <= 0;
        return isAfterStart && isBeforeEnd;
      }).toList();    
      
      return List<Map<String, dynamic>>.from(matchedPayments);

    } catch (e) {
      throw('حدث خطأ أثناء جلب أو فلترة المدفوعات: $e');
    }
  }

  // تم التعديل: إرجاع AppResponse محدد النوع <List<SellesReportModel>>
  static Future<AppResponse<List<SellesReportModel>>> getSallesReport({DateTime? from, DateTime? to}) async {
    try {
      var result = await getPaymentsBetweenDates(from ?? DateTime(1900), to ?? DateTime(2200));
      var allProfiles = await getProfiles();
      
      List<SellesReportModel> reportList = [];
      
      for (var i in result) {
        // إضافة orElse لتجنب انهيار التطبيق إذا تم مسح باقة معينة
        Map? profile = allProfiles.cast<Map?>().firstWhere(
          (p) => p != null && p["price"] != null && (int.parse(i["price"].toString()) / 100) == (int.parse(p["price"].toString())),
          orElse: () => null,
        );

        double calculatedPrice = (int.parse(i["price"].toString()) / 100);
        String profileName = profile != null ? profile["name"].toString() : "غير معروف";

        // إنشاء المودل مباشرة وإضافته للقائمة
        reportList.add(
          SellesReportModel(
            card: i["user"]?.toString() ?? "",
            profile: profileName,
            price: calculatedPrice,
            date: i["trans-start"]?.toString() ?? "",
          )
        );
      }
      return AppResponse<List<SellesReportModel>>(status: true, message: "done", data: reportList);
      
    } catch (e) {
      return AppResponse<List<SellesReportModel>>(status: false, message: e.toString());
    }
  }
  
  // تم التعديل: إرجاع AppResponse محدد النوع <SystemStateModel>
  static Future<AppResponse<SystemStateModel>> getSystemState() async {
    try {
      var response = await MikrotikClient.printData(
        commands: ["/system/resource/print"]
      );

      // التأكد من أن المايكروتيك أرجع بيانات قبل تحويلها
      if (response.isNotEmpty) {
        // عادةً أوامر المايكروتيك ترجع List تحتوي على Map، فنأخذ العنصر الأول
        var systemDataMap = response.first as Map;
        SystemStateModel model = SystemStateModel.fromMikrotik(systemDataMap);
        
        return AppResponse<SystemStateModel>(status: true, message: "done", data: model);
      } else {
        return AppResponse<SystemStateModel>(status: false, message: "لا توجد بيانات متاحة لحالة النظام");
      }
      
    } catch (e) {
      return AppResponse<SystemStateModel>(status: false, message: e.toString());
    }
  }

}