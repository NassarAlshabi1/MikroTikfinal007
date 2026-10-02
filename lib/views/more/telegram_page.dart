import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/app_theme.dart';
import '../../controllers/more/telegram_controller.dart';
import '../widgets/shared/layouts/sub_page_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';

/// شاشة **التكامل مع التليجرام** — بوابة لضبط البوت وتفعيل المميزات.
class TelegramPage extends StatelessWidget {
  const TelegramPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            const PremiumHeader(
              title: "التكامل مع التليجرام",
              subtitle: "إعداد البوت واختيار المميزات التي تريد تفعيلها",
              icon: Icons.send_rounded,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                children: [
                  _TelegramStatusCard(),
                  const SizedBox(height: 14),
                  _EntryCard(
                    icon: Icons.smart_toy_rounded,
                    title: "ضبط البوت",
                    subtitle: "إضافة أو تعديل Token و Chat ID",
                    color: AppColors.telegram,
                    onTap: () => Get.toNamed('/telegram/setup'),
                  ),
                  _EntryCard(
                    icon: Icons.tune_rounded,
                    title: "تفعيل المميزات",
                    subtitle: "تحديد إشعارات وميزات التليجرام",
                    color: AppColors.primary,
                    onTap: () => Get.toNamed('/telegram/features'),
                  ),
                  const SizedBox(height: 10),
                  const _HelpNote(),
                ],
              ),
            ),
            const AppMiniFooter(title: Text("MikroNet · Telegram")),
          ],
        ),
      ),
    );
  }
}

/// كرت الحالة العلوي: هل الإشعارات جاهزة؟ وكم ميزة مفعّلة؟
class _TelegramStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<TelegramSetupController>()
        ? Get.find<TelegramSetupController>()
        : Get.put(TelegramSetupController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: CircularProgressIndicator(),
          ),
        );
      }

      final ready = controller.enabled.value &&
          controller.tokenCtrl.text.trim().isNotEmpty &&
          controller.chatCtrl.text.trim().isNotEmpty;

      final color = ready ? AppColors.success : AppColors.warning;
      final title = ready ? "الإشعارات تعمل" : "الإشعارات متوقفة";
      final note = ready
          ? "سيُرسل التقرير أثناء فتح التطبيق كل ${controller.intervalCtrl.text.trim()} دقيقة"
          : "افتح «ضبط البوت» وأدخل Token و Chat ID ثم فعّل الإشعارات";

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                ready ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    note,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _EntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpNote extends StatelessWidget {
  const _HelpNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: AppColors.info, size: 18),
              SizedBox(width: 8),
              Text(
                "كيف أحصل على Token و Chat ID؟",
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "1) افتح @BotFather في تيليجرام وأنشئ بوتًا جديدًا ثم انسخ الـToken.\n"
            "2) افتح @userinfobot لتعرف معرّف محادثتك (Chat ID).\n"
            "3) أرسل /start للبوت مرة واحدة حتى يسمح بإرسال الرسائل إليك.",
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.7),
          ),
        ],
      ),
    );
  }
}
