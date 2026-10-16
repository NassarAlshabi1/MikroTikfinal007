import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:mikronet/features/users/controllers/users_unit_controller.dart';

// استيراد الـ Widgets الموحدة
import 'package:mikronet/core/ui/widgets/main_gate_header.dart';
import 'package:mikronet/core/ui/widgets/app_mini_footer.dart';
import 'package:mikronet/core/ui/widgets/main_action_card.dart';
import 'package:mikronet/core/ui/widgets/section_title.dart';


class UsersUnitPage extends GetView<UsersUnitController> {
  const UsersUnitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                    color: AppColors.green,
                    onTap: controller.goToActiveUsers
                  ),


                  const SizedBox(height: 11),

                  const SectionTitle(title: "التحكم والأمان"),
                  
                  MainActionCard(
                    title: "إدارة الأجهزة المحفوظة",
                    subtitle: "التحكم في MAC Address وحظر الأجهزة",
                    icon: Icons.important_devices_rounded,
                    color: AppColors.indigo,
                    onTap: controller.goToSavedUsers,
                  ),
                ],
              ),
            ),

            // 4. الفوتر مع تمرير اسم القسم المطلوب (حل المشكلة)
            const AppMiniFooter(
              title: Text("مراقبة الجلسات النشطة والتحكم بالأجهزة",
                style: TextStyle(fontWeight: FontWeight.bold,color: AppColors.textSubtle),),
              ),
          ],
        ),
      ),
    );
  }
}
