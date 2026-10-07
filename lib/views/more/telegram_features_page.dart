import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/app_theme.dart';
import '../../controllers/more/telegram_controller.dart';
import '../../services/telegram_features.dart';
import '../widgets/shared/layouts/sub_page_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';

/// شاشة **تفعيل المميزات** — سبع ميزات إشعارات مع تفعيل/تعطيل الكل
/// وزر «إرسال تجربة الميزة» لكل ميزة.
class TelegramFeaturesPage extends GetView<TelegramFeaturesController> {
  const TelegramFeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            Obx(() => PremiumHeader(
                  title: "مميزات إشعارات تيليجرام",
                  subtitle:
                      "مفعّلة ${controller.enabledCount} من ${controller.all.length}",
                  icon: Icons.tune_rounded,
                )),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  children: [
                    const _IntroNote(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _bulkButton(
                            label: "تفعيل الكل",
                            icon: Icons.check_box_rounded,
                            color: AppColors.success,
                            onTap: () => controller.setAll(true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _bulkButton(
                            label: "تعطيل الكل",
                            icon: Icons.check_box_outline_blank_rounded,
                            color: AppColors.danger,
                            onTap: () => controller.setAll(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...controller.all.map((f) => _featureCard(f)),
                    const SizedBox(height: 6),
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

  Widget _bulkButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureCard(TelegramFeature feature) {
    final enabled = controller.isEnabled(feature.id);
    final busy = controller.busyFeature.value == feature.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: enabled ? feature.color.withOpacity(0.55) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: feature.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(feature.icon, color: feature.color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  feature.title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
              // شارة الحالة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.success.withOpacity(0.18)
                      : AppColors.soft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  enabled ? "مفعل" : "متوقف",
                  style: TextStyle(
                    color: enabled ? AppColors.success : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // شارة الفترة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: feature.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  feature.badge,
                  style: TextStyle(
                    color: feature.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (_) => controller.toggle(feature.id),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                feature.subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
            ),
          ),
          if (feature.id == 'daily_summary') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: AppColors.textMuted, size: 16),
                const SizedBox(width: 6),
                const Text("ساعة الإرسال",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const Spacer(),
                DropdownButton<int>(
                  value: controller.dailyHour.value,
                  dropdownColor: AppColors.card,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(color: AppColors.text, fontSize: 12.5),
                  items: List.generate(24, (i) => i)
                      .map((h) => DropdownMenuItem<int>(
                            value: h,
                            child: Text("$h:00"),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.setDailyHour(v);
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            onTap: busy ? null : () => controller.testFeature(feature.id),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.rocket_launch_rounded,
                        color: AppColors.info, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    "إرسال تجربة الميزة",
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroNote extends StatelessWidget {
  const _IntroNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "اختر الأحداث التي تريد تلقّي إشعارات عنها عبر تيليجرام",
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
