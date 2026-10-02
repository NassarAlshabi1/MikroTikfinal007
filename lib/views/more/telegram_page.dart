import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/more/telegram_controller.dart';
import '../widgets/shared/layouts/gradient_button.dart';
import '../widgets/shared/layouts/modern_input.dart';
import '../widgets/shared/layouts/sub_page_header.dart';
import '../widgets/shared/typography/section_title.dart';

class TelegramPage extends GetView<TelegramController> {
  const TelegramPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            PremiumHeader(
              title: "تكامل Telegram",
              subtitle: "تقارير المبيعات وحالة الشبكة إلى Telegram",
              icon: Icons.send_rounded,
              goBack: Get.back,
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  children: [
                    _enableCard(),
                    const SectionTitle(title: "بيانات البوت"),
                    ModernInput(
                      label: "Bot Token",
                      icon: Icons.vpn_key_rounded,
                      controller: controller.tokenCtrl,
                    ),
                    ModernInput(
                      label: "Chat ID",
                      icon: Icons.tag_rounded,
                      controller: controller.chatCtrl,
                    ),
                    ModernInput(
                      label: "الفاصل الزمني بين التقارير (دقيقة)",
                      icon: Icons.timer_outlined,
                      controller: controller.intervalCtrl,
                      isNumber: true,
                    ),
                    const SectionTitle(title: "محتوى التقرير"),
                    _switchTile(
                      title: "تقرير المبيعات اليومية",
                      subtitle: "عدد الكروت وإجمالي المبيعات",
                      value: controller.sendSales.value,
                      onChanged: (value) => controller.sendSales.value = value,
                    ),
                    _switchTile(
                      title: "حالة الراوتر",
                      subtitle: "المعالج، الذاكرة، مدة التشغيل، الإصدار",
                      value: controller.sendRouter.value,
                      onChanged: (value) => controller.sendRouter.value = value,
                    ),
                    _switchTile(
                      title: "عدد المتصلين الآن",
                      subtitle: "مستخدمو الجلسات النشطة",
                      value: controller.sendUsers.value,
                      onChanged: (value) => controller.sendUsers.value = value,
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => GradientButton(
                        label: "اختبار الاتصال بالبوت",
                        icon: Icons.wifi_tethering_rounded,
                        height: 48,
                        colors: const [Color(0xFF0F766E), Color(0xFF10B981)],
                        onPressed: controller.isBusy.value ? null : controller.testConnection,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => GradientButton(
                        label: "إرسال تقرير الآن",
                        icon: Icons.send_rounded,
                        height: 48,
                        colors: const [Color(0xFF7C3AED), Color(0xFFA855F7)],
                        onPressed: controller.isBusy.value ? null : controller.sendNow,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => GradientButton(
                        label: "حفظ الإعدادات",
                        icon: Icons.save_rounded,
                        height: 48,
                        onPressed: controller.isBusy.value ? null : controller.save,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _howToCard(),
                    const SizedBox(height: 30),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _enableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SwitchListTile(
        value: controller.enabled.value,
        activeColor: const Color(0xFF10B981),
        title: const Text(
          "تشغيل الإرسال الدوري",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          "يعمل أثناء فتح التطبيق، ويرسل التقرير كل فترة محددة.",
          style: TextStyle(fontSize: 11),
        ),
        onChanged: (value) => controller.enabled.value = value,
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        dense: true,
        value: value,
        activeColor: const Color(0xFF2563EB),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        onChanged: onChanged,
      ),
    );
  }

  Widget _howToCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF1E3A8A), size: 20),
              SizedBox(width: 8),
              Text(
                "كيف أحصل على التوكن ومعرّف المحادثة؟",
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            "1) أنشئ بوتًا من @BotFather في Telegram واحصل على Bot Token.\n"
            "2) أرسل للبوت رسالة /start من حسابك.\n"
            "3) افتح رابط getUpdates الخاص بالبوت لقراءة chat.id، أو استخدم أي بوت معرفة المعرّف.\n"
            "4) الصق التوكن والمعرّف هنا ثم اضغط «اختبار الاتصال».",
            style: TextStyle(height: 1.7, fontSize: 12, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}
