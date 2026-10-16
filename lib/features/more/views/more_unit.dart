import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';

// استيراد المتحكم الذي أنشأناه
// استيراد الويدجتس المشتركة بناءً على هيكلة مشروعك
import 'package:mikronet/features/more/controllers/more_unit_controller.dart';
import 'package:mikronet/core/ui/widgets/main_gate_header.dart';
import 'package:mikronet/core/ui/widgets/app_mini_footer.dart';
import 'package:mikronet/core/ui/widgets/main_action_card.dart';
import 'package:mikronet/core/ui/widgets/section_title.dart';

class MoreUnitPage extends GetView<MoreUnitController> {
  const MoreUnitPage({super.key});

  @override
  Widget build(BuildContext context) {
   
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            // الهيدر المطور
            const MainGateHeader(
              title: "إعدادات إضافية",
              subtitle: "أدوات النظام، الحماية، والتحكم المتقدم",
              icon: Icons.tune_rounded,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                physics: const BouncingScrollPhysics(),
                children: [
                  // عنوان القسم
                  const SectionTitle(title: "إدارة النظام"),
                  
                  // النسخ الاحتياطي الحقيقي لراوتر MikroTik
                  MainActionCard(
                    title: "نسخ الراوتر الاحتياطي",
                    subtitle: "إنشاء نسخة إعدادات على الراوتر وتنزيلها أو استعادتها",
                    icon: Icons.settings_backup_restore_rounded,
                    color: AppColors.primary,
                    onTap: controller.goToRouterBackup,
                  ),

                  // مسافة بين البطاقات
                  const SizedBox(height: 11),

                  // الموزعون والمحاسبة
                  MainActionCard(
                    title: "الموزعون والمحاسبة",
                    subtitle: "نقاط البيع، الأرصدة، الأرباح، وكشوف الحساب PDF",
                    icon: Icons.groups_rounded,
                    color: AppColors.green,
                    onTap: controller.goToDistributors,
                  ),

                  const SizedBox(height: 11),

                  // مراقبة الشبكة
                  MainActionCard(
                    title: "مراقبة الشبكة",
                    subtitle: "حرارة الراوتر، المنافذ، وحركة البيانات لحظيًا",
                    icon: Icons.monitor_heart_rounded,
                    color: AppColors.violet,
                    onTap: controller.goToMonitor,
                  ),

                  const SizedBox(height: 11),

                  // إدارة Hotspot
                  MainActionCard(
                    title: "Hotspot",
                    subtitle: "قسائم الإنترنت • الجلسات النشطة • رفع صفحة الدخول",
                    icon: Icons.wifi_rounded,
                    color: AppColors.teal,
                    onTap: controller.goToHotspot,
                  ),

                  const SizedBox(height: 11),

                  // تكامل Telegram
                  MainActionCard(
                    title: "التكامل مع التليجرام",
                    subtitle: "إشعارات فورية وتقارير دورية عبر بوت تيليجرام",
                    icon: Icons.send_rounded,
                    color: AppColors.telegram,
                    onTap: controller.goToTelegram,
                  ),

                  const SizedBox(height: 11),

                  // أدوات الصيانة
                  MainActionCard(
                    title: "أدوات الصيانة",
                    subtitle: "التشخيص، إعدادات IP، جدار الحماية، وإدارة النطاق الترددي",
                    icon: Icons.build_circle_rounded,
                    color: AppColors.sky,
                    onTap: controller.goToMaintenance,
                  ),

                  const SizedBox(height: 11),

                  // النسخ الاحتياطي لبيانات التطبيق
                  MainActionCard(
                    title: "نسخ بيانات التطبيق",
                    subtitle: "حفظ قوالب الكروت والراوترات المحفوظة كملف قاعدة بيانات",
                    icon: Icons.save_rounded,
                    color: AppColors.primary,
                    onTap: controller.goToBackupAndRestore,
                  ),

                  // مسافة بين البطاقات
                  const SizedBox(height: 11),

                  // الزر الثاني: إعادة التشغيل
                  MainActionCard(
                    title: "إعادة تشغيل النظام",
                    subtitle: "عمل Reboot للراوتر وتحديث حالة الخدمات",
                    icon: Icons.restart_alt_rounded,
                    color: AppColors.warning, // لون برتقالي تحذيري
                    onTap: controller.rebootSystem, // استدعاء الدالة من المتحكم
                  ),
                ],
              ),
            ),

            // الفوتر
            const AppMiniFooter(title: Text("الإعدادات الإضافية")),
          ],
        ),
      ),
    );
  }
}