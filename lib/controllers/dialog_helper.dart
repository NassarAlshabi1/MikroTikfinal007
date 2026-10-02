import 'package:flutter/material.dart';
import 'package:get/get.dart';
enum MsgType{
  success,
  warning,
  error,
  info,
  msg
}

Future<bool> showConfirmDialog({
  required String message,
  required VoidCallback onConfirm,
}) async {
  await Future.delayed(const Duration(milliseconds: 1));
  
  // انتظار نتيجة النافذة المنبثقة
  final bool? result = await Get.dialog<bool>(
    Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.help_outline_rounded, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 15),
            const Text(
              "تأكيد العملية",
              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  // إرجاع false عند الإلغاء
                  onPressed: () => Get.back(result: false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("إلغاء", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      await Future.delayed(const Duration(milliseconds: 1));
                      onConfirm(); // تنفيذ الدالة الممررة كما هي
                      // إرجاع true عند الموافقة
                      Get.back(result: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("نعم، استمرار", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // إذا كانت النتيجة null (مثلاً المستخدم ضغط خارج النافذة لإغلاقها) نعتبرها false
  return result ?? false;
}
Future<void> showMsgDialog({required String message, MsgType type = MsgType.msg}) async{
  await Future.delayed(const Duration(milliseconds: 1));
  // تحديد الخصائص ديناميكياً بناءً على نوع الرسالة
  final (icon, baseColor, titleText, gradientColors) = switch (type) {
    MsgType.success => (
        Icons.check_circle_outline_rounded,
        const Color(0xFF10B981), // أخضر
        "نجاح",
        [const Color(0xFF047857), const Color(0xFF10B981)]
      ),
    MsgType.warning => (
        Icons.warning_amber_rounded,
        const Color(0xFFF59E0B), // برتقالي
        "تحذير",
        [const Color(0xFFB45309), const Color(0xFFF59E0B)]
      ),
    MsgType.error => (
        Icons.error_outline_rounded,
        const Color(0xFFEF4444), // أحمر
        "خطأ",
        [const Color(0xFFB91C1C), const Color(0xFFEF4444)]
      ),
    MsgType.info => (
        Icons.info_outline_rounded,
        const Color(0xFF1E3A8A), // أزرق (لونك الأصلي)
        "معلومة",
        [const Color(0xFF0F172A), const Color(0xFF1E3A8A)]
      ),
    MsgType.msg => (
        Icons.notifications_none_rounded,
        const Color(0xFF475569), // رمادي مزرق للرسائل العادية
        "تنبيه",
        [const Color(0xFF334155), const Color(0xFF475569)]
      ),
  };

  return Get.dialog(
    Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.1), // لون الخلفية شفاف بناءً على النوع
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: baseColor, size: 28), // تغيير الأيقونة ولونها
            ),
            const SizedBox(width: 15),
            Text(
              titleText, // تغيير العنوان
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors, // تدرج الزر يتغير حسب النوع
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withOpacity(0.3), // ظل الزر يأخذ نفس اللون الأساسي
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("حسناً", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ),
  );
}
void showLoadingDialog({
  String message = "جاري التحميل...", // معامل اختياري بقيمة افتراضية
  String buttonText = "مقاطعة / إلغاء", // معامل اختياري بقيمة افتراضية
  Future<void> Function()? onCancel,    // معامل اختياري للدالة (Nullable)
})async {  
  if (Get.isSnackbarOpen) {
    Get.closeAllSnackbars();
  }
  await Future.delayed(const Duration(milliseconds: 1));

  Get.dialog(
    AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      content: Row(
        children: [
          const CircularProgressIndicator(color: Color(0xFF38BDF8)),
          const SizedBox(width: 20),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            
            Get.back(); // إغلاق النافذة فوراً
            
            // تنفيذ الدالة الاختيارية في الخلفية (بدون await)
            if (onCancel != null) {
              onCancel().catchError((error) {
                // اصطياد أي خطأ لمنع حدوث Crash في التطبيق
                print("حدث خطأ في دالة الإلغاء بالخلفية: $error");
              });
            }
          },
          child: Text(buttonText, style: const TextStyle(color: Colors.redAccent)),
        )
      ],
    ),
    barrierDismissible: false, // منع الإغلاق بالنقر خارج النافذة
  );
}
void hideDialog(){
  if(Get.isOverlaysOpen){
    Get.back();
  }
}