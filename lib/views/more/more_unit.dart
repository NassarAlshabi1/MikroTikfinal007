import 'package:flutter/material.dart';
import 'package:get/get.dart';

// استيراد المتحكم الذي أنشأناه
// استيراد الويدجتس المشتركة بناءً على هيكلة مشروعك
import '../../controllers/more/more_unit_controller.dart';
import '../widgets/shared/layouts/main_gate_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../widgets/shared/cards/main_action_card.dart';
import '../widgets/shared/typography/section_title.dart';

class MoreUnitPage extends GetView<MoreUnitController> {
  const MoreUnitPage({super.key});

  @override
  Widget build(BuildContext context) {
   
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  // عنوان القسم
                  const SectionTitle(title: "إدارة النظام"),
                  
                  // الزر الأول: النسخ الاحتياطي
                  MainActionCard(
                    title: "النسخ الاحتياطي والاستعادة",
                    subtitle: "حفظ نسخة من إعدادات المايكروتك أو استرجاعها",
                    icon: Icons.save_rounded,
                    color: const Color(0xFF3B82F6), // لون أزرق مناسب للحفظ والأمان
                    onTap: controller.goToBackupAndRestore, // استدعاء الدالة من المتحكم
                  ),

                  // مسافة بين البطاقات
                  const SizedBox(height: 15),

                  // الزر الثاني: إعادة التشغيل
                  MainActionCard(
                    title: "إعادة تشغيل النظام",
                    subtitle: "عمل Reboot للراوتر وتحديث حالة الخدمات",
                    icon: Icons.restart_alt_rounded,
                    color: const Color(0xFFF59E0B), // لون برتقالي تحذيري
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