import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';

// استيراد المتحكم والموديل
import 'package:mikronet/features/cards/controllers/cards/card_sessions_controller.dart';
// استيراد الويدجت الجاهزة
import 'package:mikronet/core/ui/widgets/sub_page_header.dart';
import 'package:mikronet/features/cards/views/widgets/session_info_card.dart';
import 'package:mikronet/core/utils/string_extensions.dart';
class CardSessionsPage extends GetView<CardSessionsController> {
  final String username;

  const CardSessionsPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    // حقن المتحكم وتمرير اسم المستخدم (cardCode) إليه
    // نستخدم Get.put هنا لضمان تمرير البرامتر 'username' للمشيد

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            // 1. الهيدر الموحد
            PremiumHeader(
              title: "سجل الجلسات",
              subtitle: "رقم الكرت: $username",
              showBackButton: true,
            ),
            
            Expanded(
              child: Obx(() {
                // 2. حالة التحميل
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                // 3. حالة القائمة فارغة
                if (controller.sessionsList.isEmpty) {
                  return _buildEmptyState();
                }

                // 4. عرض قائمة الجلسات الحقيقية
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.sessionsList.length,
                  itemBuilder: (context, index) {
                    final session = controller.sessionsList[index];
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (index == 0) _buildSectionTitle("السجلات الأخيرة"),
                        
                        SessionInfoCard(
                          from: session.fromTime.formatDate,
                          to: session.toTime.formatDate,
                          ip: session.ip,
                          mac: session.macAddress,
                          // ملاحظة: الموديل الحالي لا يحتوي على Upload/Download
                          // سنعرض الـ Uptime مكانها أو نتركها كقيم افتراضية
                          upload: session.upload.formatBytes, 
                          download:session.download.formatBytes, 
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, right: 5),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSubtle, 
          fontWeight: FontWeight.w900, 
          fontSize: 15
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 60, color: AppColors.soft),
          SizedBox(height: 11),
          Text(
            "لا توجد جلسات مسجلة لهذا الكرت",
            style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}