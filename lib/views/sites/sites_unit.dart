import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/sites/sites_unit_controller.dart';

// استيراد الـ Widgets الموحدة
import '../widgets/shared/layouts/main_gate_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../widgets/shared/cards/main_action_card.dart';
import '../widgets/shared/typography/section_title.dart';

class SitesUnitPage extends GetView<SitesUnitController> {
  const SitesUnitPage({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
           
            const MainGateHeader(
              title: "إدارة المواقع",
              subtitle: "إعدادات DNS وحظر عناوين الشبكة",
              icon: Icons.public_rounded,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  
                  // ================= القسم الأول: إعدادات المخدّم =================
                  const SectionTitle(title: "إعدادات المخدّم"),
                  
                  MainActionCard(
                    title: "إعدادات DNS",
                    subtitle: "ضبط عناوين DNS وصلاحيات الوصول للشبكة",
                    icon: Icons.settings_ethernet_rounded,
                    color: const Color(0xFF10B981), // لون أخضر زمردي متميز
                    onTap: controller.goToDnsSettings, // التوجيه لصفحة الإعدادات
                  ),
                  
                  const SizedBox(height: 20),

                  // ================= القسم الثاني: السجلات المؤقتة =================
                  const SectionTitle(title: "السجلات المؤقتة"),
                  
                  MainActionCard(
                    title: "DNS Cache",
                    subtitle: "عرض وحذف السجلات المؤقتة للشبكة",
                    icon: Icons.dns_rounded,
                    color: const Color(0xFF0EA5E9), // لون أزرق سماوي
                    onTap: controller.goToDnsCache, 
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // ================= القسم الثالث: الحظر والرقابة =================
                  const SectionTitle(title: "جدار الحماية والرقابة"),
                  
                  // 1. حظر IP
                  /*MainActionCard(
                    title: "حظر العناوين (IP)",
                    subtitle: "إدارة قائمة الأجهزة الممنوعة من الاتصال",
                    icon: Icons.router_rounded,
                    color: const Color(0xFFEF4444), // لون أحمر أمني
                    onTap: controller.goToBlockedIps, 
                  ),
                  const SizedBox(height: 10),
                  */
                  // 2. حظر الدومين
                  MainActionCard(
                    title: "حظر النطاقات (Domain)",
                    subtitle: "منع الوصول لمواقع محددة عبر الـ DNS",
                    icon: Icons.public_off_rounded,
                    color: const Color(0xFFF59E0B), // لون برتقالي تحذيري
                    onTap: controller.goToBlockedDomains, 
                  ),
                  const SizedBox(height: 10),
                  
                  // 3. حظر المحتوى
                  MainActionCard(
                    title: "حظر المحتوى (Content)",
                    subtitle: "فلترة الكلمات والمحتويات في الفايرول",
                    icon: Icons.gpp_bad_rounded,
                    color: const Color(0xFF8B5CF6), // لون بنفسجي
                    onTap: controller.goToBlockedContent, 
                  ),
                  
                ],
              ),
            ),

            const AppMiniFooter(title:Text( "إدارة الشبكة والمواقع")),
          ],
        ),
      ),
    );
  }
}