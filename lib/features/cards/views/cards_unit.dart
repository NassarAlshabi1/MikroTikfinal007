import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';
// استيراد المتحكم
import 'package:mikronet/features/cards/controllers/cards_unit_controller.dart'; 

// استيراد الـ Widgets المشتركة
import 'package:mikronet/core/ui/widgets/main_gate_header.dart';
import 'package:mikronet/core/ui/widgets/app_mini_footer.dart';
import 'package:mikronet/core/ui/widgets/main_action_card.dart';
import 'package:mikronet/core/ui/widgets/section_title.dart';

class CardsUnitPage extends GetView<CardsUnitController> {
  const CardsUnitPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            // الهيدر المطور المشترك
            const MainGateHeader(
              title: "إدارة الكروت",
              subtitle: "تحكم كامل في الكروت، الخدمات، والأسعار",
              icon: Icons.credit_card_rounded,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                physics: const BouncingScrollPhysics(),
                children: [
                  const SectionTitle(title: "إدارة الكروت والخدمات"),
                  
                  // كرت الكروت والخدمات
                  MainActionCard(
                    title: "الكروت والخدمات",
                    subtitle: "إضافة • تعديل • حذف الكروت",
                    icon: Icons.style_rounded,
                    color: AppColors.indigo,
                    onTap: controller.goToCardsList, // استخدام دالة المتحكم
                  ),

                  // كرت إضافة كرت واحد
                  MainActionCard(
                    title: "إضافة كرت واحد",
                    subtitle: "إنشاء كرت اشتراك يدوي سريع",
                    icon: Icons.add_moderator_rounded,
                    color: AppColors.sky,
                    onTap: controller.goToAddSingleCard, // استخدام دالة المتحكم
                  ),

                  const SizedBox(height: 11),

                  // حذف المستخدمين المنتهين (فحص ذكي للمدة)
                  MainActionCard(
                    title: "المستخدمون المنتهون",
                    subtitle: "فحص ذكي: من استهلك مدته كاملة فقط",
                    icon: Icons.auto_delete_rounded,
                    color: AppColors.danger,
                    onTap: controller.goToExpiredUsers,
                  ),

                  const SizedBox(height: 11),

                  // إدارة Hotspot (قسائم الإنترنت)
                  MainActionCard(
                    title: "Hotspot",
                    subtitle: "قسائم الإنترنت • الجلسات • صفحة الدخول",
                    icon: Icons.wifi_rounded,
                    color: AppColors.teal,
                    onTap: controller.goToHotspot,
                  ),

                  const SizedBox(height: 11),

                  const SectionTitle(title: "الاشتراكات والأسعار"),

                  // كرت الباقات والسرعات
                  MainActionCard(
                    title: "الباقات والسرعات",
                    subtitle: "الأسعار • المدد • تحديد السرعات",
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.warning,
                    onTap: controller.goToPackages, // استخدام دالة المتحكم
                  ),
                ],
              ),
            ),

            const AppMiniFooter(
              title: Text("إدارة الكروت",
                style: TextStyle(fontWeight: FontWeight.bold,color: AppColors.textSubtle),),
              ),
          ],
        ),
      ),
    );
  }
}