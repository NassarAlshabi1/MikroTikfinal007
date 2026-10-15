import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:mikronet/features/prints/controllers/prints_unit_controller.dart';

// استيراد المكونات المشتركة
import 'package:mikronet/core/ui/widgets/main_gate_header.dart';
import 'package:mikronet/core/ui/widgets/app_mini_footer.dart';
import 'package:mikronet/core/ui/widgets/main_action_card.dart';
import 'package:mikronet/core/ui/widgets/section_title.dart';

class PrintsUnitPage extends GetView<PrintsUnitController> {
  const PrintsUnitPage({super.key});

  

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                physics: const BouncingScrollPhysics(),
                children: [
                  const SectionTitle(title: "إدارة الطباعة"),
                  
                  // 2. بطاقات الأوامر الموحدة
                  MainActionCard(
                    title: "دفعات الكروت",
                    subtitle: "إنشاء • توليد • متابعة الدفعات",
                    icon: Icons.layers_rounded,
                    color: AppColors.blue,
                    onTap: controller.gotToBtches,
                  ),

                  MainActionCard(
                    title: "قوالب الطباعة",
                    subtitle: "تصميم • تعديل • حفظ القوالب",
                    icon: Icons.style_rounded, // أيقونة متناسقة مع التصميم
                    color: AppColors.primary,
                    onTap: controller.gotToTemplates,
                  ),

                  const SizedBox(height: 16),

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
      padding: const EdgeInsets.symmetric(horizontal: 14,vertical: 5),
      
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline, color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              "يمكنك إنشاء دفعة كروت أولاً، ثم ربطها بقالب طباعة جاهز من استوديو التصميم.",
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSubtle,
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

}
