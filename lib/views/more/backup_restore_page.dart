import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/controllers/more/backup_restore_controller.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../widgets/shared/layouts/sub_page_header.dart';
import '../widgets/shared/layouts/modern_input.dart';

class BackupRestorePage extends GetView<BackupRestoreController> {
  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(BackupRestoreController()); // تهيئة المتحكم

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            const PremiumHeader(
              title: "النسخ الاحتياطي والاستعادة",
              subtitle: "حفظ واسترجاع بياناتك بكل أمان وسهولة",
              icon: Icons.backup_rounded,
            ),
            
            Expanded(
              child: Container(
                margin:const EdgeInsets.symmetric(horizontal: 20,vertical: 25),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                   color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 15,
                        color: Colors.black.withOpacity(0.03),
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

                      const SizedBox(height: 30),
                      
                      // زر النسخ الاحتياطي
                      _buildActionBtn(
                        title: "إنشاء نسخة احتياطية",
                        icon: Icons.cloud_upload_rounded,
                        color: const Color(0xFF1E3A8A), // أزرق داكن
                        onTap: controller.createBackup,
                      ),
                      
                      const SizedBox(height: 15),

                      // خط فاصل مع كلمة "أو"
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.blueGrey.shade200)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("أو", style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold)),
                          ),
                          Expanded(child: Divider(color: Colors.blueGrey.shade200)),
                        ],
                      ),
                      
                      const SizedBox(height: 15),

                      // زر الاستعادة
                      _buildActionBtn(
                        title: "استعادة من ملف",
                        icon: Icons.settings_backup_restore_rounded,
                        color: const Color(0xFF0F766E), // لون أخضر مزرق لتمييزه
                        onTap: controller.restoreBackup,
                      ),
                    ],
                  ),
                ),
              ),
            
            
            AppMiniFooter(
              title: Text(
                "النسخ الاحتياطي يضمن عدم فقدان كروتك وبياناتك",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade400),
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
              color: color.withOpacity(0.3),
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

  // تصميم الـ Checkbox المخصص
  Widget _buildCustomCheckbox({
    required String title,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF1E3A8A).withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: value ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
            width: value ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: value ? const Color(0xFF1E3A8A) : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(width: 15),
            Icon(icon, color: Colors.blueGrey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: value ? FontWeight.bold : FontWeight.w600,
                  color: value ? const Color(0xFF1E3A8A) : Colors.blueGrey.shade700,
                  fontSize: 14,
                ),
              ),
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
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(10))),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1E3A8A))),
      ],
    ),
  );
}