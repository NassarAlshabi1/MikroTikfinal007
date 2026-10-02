import 'package:flutter/material.dart';
import 'package:get/get.dart';
// استيراد المتحكم
import '/controllers/cards/cards_unit_controller.dart'; 

// استيراد الـ Widgets المشتركة
import '../widgets/shared/layouts/main_gate_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../widgets/shared/cards/main_action_card.dart';
import '../widgets/shared/typography/section_title.dart';

class CardsUnitPage extends GetView<CardsUnitController> {
  const CardsUnitPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  const SectionTitle(title: "إدارة الكروت والخدمات"),
                  
                  // كرت الكروت والخدمات
                  MainActionCard(
                    title: "الكروت والخدمات",
                    subtitle: "إضافة • تعديل • حذف الكروت",
                    icon: Icons.style_rounded,
                    color: const Color(0xFF6366F1),
                    onTap: controller.goToCardsList, // استخدام دالة المتحكم
                  ),

                  // كرت إضافة كرت واحد
                  MainActionCard(
                    title: "إضافة كرت واحد",
                    subtitle: "إنشاء كرت اشتراك يدوي سريع",
                    icon: Icons.add_moderator_rounded,
                    color: const Color(0xFF0EA5E9),
                    onTap: controller.goToAddSingleCard, // استخدام دالة المتحكم
                  ),

                  const SizedBox(height: 15),

                  const SectionTitle(title: "الاشتراكات والأسعار"),

                  // كرت الباقات والسرعات
                  MainActionCard(
                    title: "الباقات والسرعات",
                    subtitle: "الأسعار • المدد • تحديد السرعات",
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: controller.goToPackages, // استخدام دالة المتحكم
                  ),
                ],
              ),
            ),

            AppMiniFooter(
              title: Text("إدارة الكروت",
                style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blueGrey.shade400),),
              ),
          ],
        ),
      ),
    );
  }
}