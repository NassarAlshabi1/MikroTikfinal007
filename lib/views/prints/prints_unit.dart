import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/controllers/prints/prints_unit_controller.dart';

// استيراد المكونات المشتركة
import '/views/widgets/shared/layouts/main_gate_header.dart';
import '/views/widgets/shared/layouts/app_mini_footer.dart';
import '/views/widgets/shared/cards/main_action_card.dart';
import '/views/widgets/shared/typography/section_title.dart';

class PrintsUnitPage extends GetView<PrintsUnitController> {
  const PrintsUnitPage({super.key});

  

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // 1. الهيدر الموحد بالفخامة الجديدة
            const MainGateHeader(
              title: "إدارة عمليات الطباعة",
              subtitle: "تصميم القوالب وإدارة دفعات الكروت",
              icon: Icons.print_rounded,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  const SectionTitle(title: "إدارة الطباعة"),
                  
                  // 2. بطاقات الأوامر الموحدة
                  MainActionCard(
                    title: "دفعات الكروت",
                    subtitle: "إنشاء • توليد • متابعة الدفعات",
                    icon: Icons.layers_rounded,
                    color: const Color(0xFF2563EB),
                    onTap: controller.gotToBtches,
                  ),

                  MainActionCard(
                    title: "قوالب الطباعة",
                    subtitle: "تصميم • تعديل • حفظ القوالب",
                    icon: Icons.style_rounded, // أيقونة متناسقة مع التصميم
                    color: const Color(0xFF1E3A8A),
                    onTap: controller.gotToTemplates,
                  ),

                  const SizedBox(height: 25),

                  // const SectionTitle(title: "معلومات الطباعة"),
                  
                  // // 3. بطاقة المعلومات بتصميم Glassmorphism مبسط
                  // _buildInfoCard(
                  //   icon: Icons.info_outline,
                  //   text: "يمكنك إنشاء دفعة كروت أولاً، ثم ربطها بقالب طباعة جاهز من استوديو التصميم.",
                  // ),
                ],
              ),
            ),

            // 4. الفوتر الموحد مع تمرير اسم القسم
             AppMiniFooter(title: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 5),
      
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline, color: Color(0xFF64748B), size: 20),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              "يمكنك إنشاء دفعة كروت أولاً، ثم ربطها بقالب طباعة جاهز من استوديو التصميم.",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    )),
          ],
        ),
      ),
    );
  }

  /* ================= INFO CARD (Custom for this view) ================= */
  Widget _buildInfoCard({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
