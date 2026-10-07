import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/maintenance/maintenance_hub_controller.dart';

class MaintenanceHubPage extends GetView<MaintenanceHubController> {
  const MaintenanceHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MaintenanceHubController>()) {
      Get.put(MaintenanceHubController());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF070F1E),
        body: SafeArea(
          child: Column(
            children: [
              // 1. شريط التطبيق العلوي (MkCards)
              _buildTopAppBar(),

              // 2. المحتوى الرئيسي لخطوات صيانة اليوزر مانجر
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // الخطوة 1: إغلاق وحذف الجلسات
                      _buildStepCard(
                        stepNumber: 1,
                        title: "إغلاق وحذف الجلسات (اختياري)",
                        subtitle: "يغلق جميع جلسات User Manager، ينتظر 20 ثانية، يحذفها، ثم ينتظر 20 ثانية أخرى. يمكن تجاوز هذه الخطوة.",
                        icon: Icons.logout_rounded,
                        accentColor: const Color(0xFFF59E0B),
                        buttonColor: const Color(0xFFF59E0B),
                        controller: controller,
                      ),
                      const SizedBox(height: 12),

                      // الخطوة 2: تنظيف سجلات User Manager
                      _buildStepCard(
                        stepNumber: 2,
                        title: "تنظيف سجلات User Manager",
                        subtitle: "ينظف سجلات User Manager القديمة من الراوتر.",
                        icon: Icons.cleaning_services_rounded,
                        accentColor: const Color(0xFF38E5FF),
                        buttonColor: const Color(0xFF38E5FF),
                        controller: controller,
                      ),
                      const SizedBox(height: 12),

                      // الخطوة 3: إعادة بناء قاعدة User Manager
                      _buildStepCard(
                        stepNumber: 3,
                        title: "إعادة بناء قاعدة User Manager",
                        subtitle: "يعيد بناء قاعدة User Manager بعد الحذف.",
                        icon: Icons.dns_rounded,
                        accentColor: const Color(0xFF38BDF8),
                        buttonColor: const Color(0xFF38BDF8),
                        controller: controller,
                      ),
                      const SizedBox(height: 12),

                      // الخطوة 4: إعادة بناء سجلات User Manager
                      _buildStepCard(
                        stepNumber: 4,
                        title: "إعادة بناء سجلات User Manager",
                        subtitle: "يعيد بناء مخزن سجلات User Manager.",
                        icon: Icons.fact_check_rounded,
                        accentColor: const Color(0xFF34D399),
                        buttonColor: const Color(0xFF34D399),
                        controller: controller,
                      ),
                      const SizedBox(height: 12),

                      // الخطوة 5: تفعيل الهوتسبوت
                      _buildStepCard(
                        stepNumber: 5,
                        title: "تفعيل الهوتسبوت",
                        subtitle: "يعيد تفعيل الهوتسبوت بعد أوامر الصيانة.",
                        icon: Icons.wifi_rounded,
                        accentColor: const Color(0xFF0EA5E9),
                        buttonColor: const Color(0xFF0EA5E9),
                        controller: controller,
                      ),
                      const SizedBox(height: 12),

                      // الخطوة 6: إعادة تشغيل الراوتر
                      _buildStepCard(
                        stepNumber: 6,
                        title: "إعادة تشغيل الراوتر",
                        subtitle: "يفتح الهوتسبوت ويتحقق من حالته أولاً، ثم يرسل أمر إعادة تشغيل الراوتر النهائي.",
                        icon: Icons.restart_alt_rounded,
                        accentColor: const Color(0xFFEF4444),
                        buttonColor: const Color(0xFFEF4444),
                        controller: controller,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ================= 1. شريط التطبيق العلوي ================= */
  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF070F1E),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _topIconBtn(Icons.language_rounded, () {}),
              const SizedBox(width: 8),
              _topIconBtn(Icons.wb_sunny_outlined, () {}),
              const SizedBox(width: 8),
              _topIconBtn(Icons.logout_rounded, () {}),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "MkCards",
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          _topIconBtn(Icons.arrow_forward_rounded, () => Get.back()),
        ],
      ),
    );
  }

  Widget _topIconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E293B), width: 1),
        ),
        child: Icon(icon, color: const Color(0xFF38BDF8), size: 18),
      ),
    );
  }

  /* ================= 2. بطاقة خطوة الصيانة ================= */
  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color buttonColor,
    required MaintenanceHubController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1726),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2E44), width: 1),
      ),
      child: Column(
        children: [
          // رأس البطاقة مع الأيقونة والنص
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // صف الزر وحالة التنفيذ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // زر تنفيذ الخطوة
              Obx(() {
                final isExecuting = controller.stepLoading[stepNumber] ?? false;
                return InkWell(
                  onTap: isExecuting ? null : () => controller.executeStep(stepNumber),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: buttonColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: isExecuting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Color(0xFF070F1E), strokeWidth: 2),
                          )
                        : const Text(
                            "تنفيذ الخطوة",
                            style: TextStyle(
                              color: Color(0xFF070F1E),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              }),

              // نص حالة التنفيذ
              Obx(() => Text(
                controller.stepStatus[stepNumber] ?? "بانتظار التنفيذ",
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }
}
