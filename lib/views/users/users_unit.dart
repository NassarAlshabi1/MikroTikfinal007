import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/controllers/users/users_unit_controller.dart';

// استيراد الـ Widgets الموحدة
import '../widgets/shared/layouts/main_gate_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../widgets/shared/cards/main_action_card.dart';
import '../widgets/shared/typography/section_title.dart';


class UsersUnitPage extends GetView<UsersUnitController> {
  const UsersUnitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // 1. الهيدر الموحد
            const MainGateHeader(
              title: "إدارة المستخدمين",
              subtitle: "مراقبة الجلسات النشطة والتحكم بالأجهزة",
              icon: Icons.manage_accounts_rounded,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  
                  const SectionTitle(title: "المراقبة المباشرة"),
                  MainActionCard(
                    title: "الأجهزة المتصلة",
                    subtitle: "عرض كل الاجهزة المتصلة بالشبكة",
                    icon: Icons.devices_rounded,
                    color: const Color.fromARGB(255, 16, 95, 185),
                    onTap: controller.goToHostUsers,
                  ),
                  MainActionCard(
                    title: "الاجهزة المتصلة بكروت",
                    subtitle: "عرض الاجهزة المتصلة بكروت",
                    icon: Icons.online_prediction_rounded,
                    color: const Color(0xFF10B981),
                    onTap: controller.goToActiveUsers
                  ),


                  const SizedBox(height: 15),

                  const SectionTitle(title: "التحكم والأمان"),
                  
                  MainActionCard(
                    title: "إدارة الأجهزة المحفوظة",
                    subtitle: "التحكم في MAC Address وحظر الأجهزة",
                    icon: Icons.important_devices_rounded,
                    color: const Color(0xFF6366F1),
                    onTap: controller.goToSavedUsers,
                  ),
                ],
              ),
            ),

            // 4. الفوتر مع تمرير اسم القسم المطلوب (حل المشكلة)
            AppMiniFooter(
              title: Text("مراقبة الجلسات النشطة والتحكم بالأجهزة",
                style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blueGrey.shade400),),
              ),
          ],
        ),
      ),
    );
  }
}
