import 'package:flutter/material.dart';
import 'package:get/get.dart';
 
// استيراد الويجيت الموحدة
import '/controllers/sites/dns_settings_controller.dart';
import '../widgets/shared/layouts/sub_page_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../widgets/shared/typography/section_title.dart';

// 1. التعديل هنا: الوراثة من GetView بدلاً من StatelessWidget
class DnsSettingsPage extends GetView<DnsSettingsController> {
  const DnsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // تم إزالة Get.put من هنا لأن GetView يوفر المتغير "controller" تلقائياً
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Column(
          children: [
            // الهيدر
            const PremiumHeader(
              title: "إعدادات المخدّم",
              subtitle: "ضبط عناوين DNS وصلاحيات الوصول للشبكة",
              icon: Icons.settings_ethernet_rounded,
            ),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)));
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    const SectionTitle(title: "أمن الشبكة"),

                    /// مفتاح السماح بالطلبات الخارجية
                    _buildSwitchCard(
                      title: "السماح بالطلبات الخارجية",
                      subtitle: "Allow Remote DNS Requests",
                      value: controller.allowRemoteRequest.value,
                      onChanged: (v) {
                        controller.allowRemoteRequest.value = v;
                      },
                    ),

                    const SizedBox(height: 25),
                    const SectionTitle(title: "عناوين التوجيه (DNS)"),

                    /// الحقول النصية
                    _dnsField(
                      textCtrl: controller.primaryCtrl,
                      label: "DNS الأساسي",
                      hint: "8.8.8.8",
                      icon: Icons.dns_rounded,
                    ),

                    const SizedBox(height: 16),

                    _dnsField(
                      textCtrl: controller.secondaryCtrl,
                      label: "DNS الاحتياطي",
                      hint: "1.1.1.1",
                      icon: Icons.alt_route_rounded,
                    ),

                    const SizedBox(height: 40),

                    /// زر الحفظ
                    _buildSaveButton(),
                  ],
                );
              }),
            ),

            // الفوتر
            const AppMiniFooter(title: Text("DNS Configuration v4.5")),
          ],
        ),
      ),
    );
  }

  /* ================= ويجيت السويتش المطور ================= */
  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: SwitchListTile(
        activeColor: const Color(0xFF1E3A8A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  /* ================= حقل إدخال DNS المطور ================= */
  // تم تغيير اسم البارامتر إلى textCtrl لتجنب التعارض مع كلمة controller الخاصة بـ GetView
  Widget _dnsField({
    required TextEditingController textCtrl,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: textCtrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(fontSize: 13, color: Colors.blueGrey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  /* ================= زر الحفظ ================= */
  // لم نعد بحاجة لتمرير المتحكم كبارامتر، لأنه متاح مباشرة بفضل GetView
  Widget _buildSaveButton() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
            colors: [Color(0xff1E3A8A), Color(0xff3B82F6)]),
        boxShadow: [
          BoxShadow(
              color: const Color(0xff1E3A8A).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
        label: const Text("حفظ الإعدادات الجديدة",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: () {
          // استخدام المتحكم مباشرة
          controller.saveDnsSettings();
        },
      ),
    );
  }
}