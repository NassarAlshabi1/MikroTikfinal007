import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/app_theme.dart';
import '../../controllers/more/telegram_controller.dart';
import '../widgets/shared/layouts/sub_page_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../widgets/shared/typography/section_title.dart';

/// شاشة **ضبط البوت**: Token و Chat ID والفاصل الزمني.
class TelegramSetupPage extends GetView<TelegramSetupController> {
  const TelegramSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            const PremiumHeader(
              title: "ضبط البوت",
              subtitle: "Token و Chat ID",
              icon: Icons.smart_toy_rounded,
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  children: [
                    const SectionTitle(title: "بيانات الربط"),
                    _field(
                      ctrl: controller.tokenCtrl,
                      label: "توكن البوت (Bot Token)",
                      hint: "123456789:AA...",
                      icon: Icons.key_rounded,
                    ),
                    _field(
                      ctrl: controller.chatCtrl,
                      label: "معرّف المحادثة (Chat ID)",
                      hint: "123456789",
                      icon: Icons.chat_rounded,
                    ),
                    _field(
                      ctrl: controller.intervalCtrl,
                      label: "الفاصل بين التقارير (دقائق)",
                      hint: "60",
                      icon: Icons.schedule_rounded,
                      isNumber: true,
                    ),
                    const SizedBox(height: 4),
                    _switchRow(
                      title: "تشغيل الإشعارات",
                      subtitle: "إرسال التقارير إلى تيليجرام أثناء فتح التطبيق",
                      value: controller.enabled.value,
                      onChanged: (v) => controller.enabled.value = v,
                    ),
                    const SizedBox(height: 14),
                    _button(
                      label: "اختبار الاتصال بالبوت",
                      icon: Icons.wifi_tethering_rounded,
                      color: AppColors.info,
                      onTap: controller.isBusy.value ? null : controller.testConnection,
                    ),
                    const SizedBox(height: 10),
                    _button(
                      label: "إرسال رسالة تجريبية",
                      icon: Icons.send_rounded,
                      color: AppColors.telegram,
                      onTap: controller.isBusy.value ? null : controller.sendTest,
                    ),
                    const SizedBox(height: 10),
                    _button(
                      label: "حفظ الإعدادات",
                      icon: Icons.save_rounded,
                      color: AppColors.success,
                      onTap: controller.isBusy.value ? null : controller.save,
                    ),
                    const SizedBox(height: 14),
                    const _BotHint(),
                  ],
                );
              }),
            ),
            const AppMiniFooter(title: Text("MikroNet · Telegram")),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: AppColors.text, fontSize: 13.5),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            value ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
            color: value ? AppColors.success : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10.5)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _button({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: disabled
                ? [AppColors.soft, AppColors.soft]
                : [color.withOpacity(0.85), color],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotHint extends StatelessWidget {
  const _BotHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        "• التوكن يُحفظ مشفّرًا داخل الجهاز ولا يُرسل لأي طرف ثالث.\n"
        "• إن لم تصل الرسائل: أرسل /start للبوت أولًا، وتأكد أن Chat ID صحيح.\n"
        "• الإرسال يعمل أثناء فتح التطبيق؛ الإرسال والتطبيق مغلق يحتاج خدمة خلفية.",
        style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.7),
      ),
    );
  }
}
