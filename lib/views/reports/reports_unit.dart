import 'package:flutter/material.dart';
import 'package:get/get.dart'; // استيراد مكتبة GetX للتنقل

// استيراد الويدجتس المشتركة بناءً على هيكلة مشروعك
import '../../controllers/reports/reports_unit_controller.dart';
import '../widgets/shared/layouts/main_gate_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../widgets/shared/cards/main_action_card.dart';
import '../widgets/shared/typography/section_title.dart';

class ReportsUnitPage extends GetView<ReportsUnitController> {
  const ReportsUnitPage({super.key});

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
              title: "التقارير",
              subtitle: "مراقبة شاملة للمبيعات وحالة الشبكة",
              icon: Icons.analytics_rounded,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                physics: const BouncingScrollPhysics(),
                children: [
                  // عنوان القسم
                  const SectionTitle(title: "التقارير والإحصائيات"),
                  
                  // الزر الأول: تقرير المبيعات
                  MainActionCard(
                    title: "تقرير مبيعات",
                    subtitle: "إحصائيات الكروت المباعة وإيرادات الشبكة",
                    icon: Icons.point_of_sale_rounded,
                    color: const Color(0xFF10B981), // لون أخضر مناسب للمبيعات والأموال
                    onTap: controller.gotToSalesReport,
                  ),

                  // مسافة بين البطاقات
                  const SizedBox(height: 11),

                  // الزر الثاني: تقرير حالة النظام
                  MainActionCard(
                    title: "تقرير حالة النظام",
                    subtitle: "مراقبة أداء المايكروتيك واستهلاك الموارد",
                    icon: Icons.monitor_heart_rounded,
                    color: const Color(0xFF8B5CF6), // لون بنفسجي مميز لحالة النظام
                    onTap: controller.gotToSystemStatus, // التنقل باستخدام GetX
                  ),

                  // مراقبة الشبكة المتقدمة (حرارة + منافذ + حركة)
                  MainActionCard(
                    title: "مراقبة الشبكة",
                    subtitle: "حرارة الراوتر، المنافذ، وحركة البيانات لحظيًا",
                    icon: Icons.monitor_heart_rounded,
                    color: const Color(0xFF7C3AED),
                    onTap: controller.goToMonitor,
                  ),

                  // أدوات الصيانة والتشخيص
                  MainActionCard(
                    title: "أدوات الصيانة",
                    subtitle: "التشخيص، إعدادات IP، جدار الحماية، وإدارة النطاق الترددي",
                    icon: Icons.build_circle_rounded,
                    color: const Color(0xFF0EA5E9),
                    onTap: controller.goToMaintenance,
                  ),
                ],
              ),
            ),

            // الفوتر
            const AppMiniFooter(title: Text("إدارة التقارير")),
          ],
        ),
      ),
    );
  }
}