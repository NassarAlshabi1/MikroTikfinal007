import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:mikronet/features/backup/controllers/backup_restore_controller.dart';
import 'package:mikronet/core/ui/widgets/app_mini_footer.dart';
import 'package:mikronet/core/ui/widgets/sub_page_header.dart';
import 'package:mikronet/core/ui/widgets/modern_input.dart';

class BackupRestorePage extends GetView<BackupRestoreController> {
  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            const PremiumHeader(
              title: "النسخ الاحتياطي والاستعادة",
              subtitle: "حفظ واسترجاع بياناتك بكل أمان وسهولة",
              icon: Icons.backup_rounded,
            ),
            
            Expanded(
              child: Container(
                margin:const EdgeInsets.symmetric(horizontal: 14,vertical: 25),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                   color: AppColors.soft,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 15,
                        color: Colors.black.withValues(alpha: 0.03),
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel("بيانات النسخة الاحتياطية"),
                      const SizedBox(height: 10),
                      
                      ModernInput(
                        label: "اسم النسخة", 
                        icon: Icons.save_as_outlined, 
                        controller: controller.nameCtrl,
                      ),
                      const Spacer(),
                      // const SizedBox(height: 200),
                      // const Spacer(),
                      // _sectionLabel("البيانات المراد حفظها / استعادتها"),
                      // const SizedBox(height: 10),

                      // // مربعات الاختيار بتصميم عصري
                      // Obx(() => Column(
                      //   children: [
                      //     _buildCustomCheckbox(
                      //       title: "بيانات الدخول (Logins)",
                      //       icon: Icons.router_rounded,
                      //       value: controller.isLoginsChecked.value,
                      //       onChanged: (val) => controller.isLoginsChecked.value = val,
                      //     ),
                      //     _buildCustomCheckbox(
                      //       title: "القوالب (Templates)",
                      //       icon: Icons.design_services_rounded,
                      //       value: controller.isTemplatesChecked.value,
                      //       onChanged: (val) => controller.isTemplatesChecked.value = val,
                      //     ),
                      //     _buildCustomCheckbox(
                      //       title: "الدفعات والكروت (Batches)",
                      //       icon: Icons.receipt_long_rounded,
                      //       value: controller.isBatchesChecked.value,
                      //       onChanged: (val) => controller.isBatchesChecked.value = val,
                      //     ),
                      //   ],
                      // )),

                      const SizedBox(height: 14),
                      
                      // زر النسخ الاحتياطي
                      _buildActionBtn(
                        title: "إنشاء نسخة احتياطية",
                        icon: Icons.cloud_upload_rounded,
                        color: AppColors.primary, // أزرق داكن
                        onTap: controller.createBackup,
                      ),
                      
                      const SizedBox(height: 11),

                      // خط فاصل مع كلمة "أو"
                      const Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text("أو", style: TextStyle(color: AppColors.textSubtle, fontWeight: FontWeight.bold)),
                          ),
                          Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),
                      
                      const SizedBox(height: 11),

                      // زر الاستعادة
                      _buildActionBtn(
                        title: "استعادة من ملف",
                        icon: Icons.settings_backup_restore_rounded,
                        color: AppColors.tealDark, // لون أخضر مزرق لتمييزه
                        onTap: controller.restoreBackup,
                      ),
                    ],
                  ),
                ),
              ),
            
            
            const AppMiniFooter(
              title: Text(
                "النسخ الاحتياطي يضمن عدم فقدان كروتك وبياناتك",
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSubtle),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // تصميم زر الإجراء (Action Button)
  Widget _buildActionBtn({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }


  Widget _sectionLabel(String title) => Container(
    alignment: Alignment.centerRight,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10))),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.primary)),
      ],
    ),
  );
}