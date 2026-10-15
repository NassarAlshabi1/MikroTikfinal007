import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';

import 'package:mikronet/features/backup/data/router_backup_api.dart';
import 'package:mikronet/features/backup/controllers/router_backup_controller.dart';
import 'package:mikronet/core/ui/widgets/gradient_button.dart';
import 'package:mikronet/core/ui/widgets/modern_input.dart';
import 'package:mikronet/core/ui/widgets/sub_page_header.dart';
import 'package:mikronet/core/ui/widgets/section_title.dart';

/// صفحة النسخ الاحتياطي الحقيقي لراوتر MikroTik.
class RouterBackupPage extends GetView<RouterBackupController> {
  const RouterBackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            PremiumHeader(
              title: "نسخ الراوتر الاحتياطي",
              subtitle: "حفظ إعدادات المايكروتك واستعادتها من الهاتف",
              icon: Icons.backup_rounded,
              goBack: Get.back,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                physics: const BouncingScrollPhysics(),
                children: [
                  const SectionTitle(title: "إنشاء نسخة جديدة"),
                  ModernInput(
                    label: "اسم النسخة",
                    icon: Icons.drive_file_rename_outline_rounded,
                    controller: controller.nameCtrl,
                  ),
                  Obx(
                    () => GradientButton(
                      label: "نسخة إعدادات كاملة (‎.backup)",
                      icon: Icons.save_rounded,
                      height: 48,
                      onPressed: controller.isBusy.value ? null : controller.createBackup,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => GradientButton(
                      label: "تصدير نصي للإعدادات (‎.rsc)",
                      icon: Icons.description_rounded,
                      height: 48,
                      colors: const [AppColors.tealDark, AppColors.green],
                      onPressed: controller.isBusy.value ? null : controller.createExport,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => GradientButton(
                      label: "رفع ملف نسخة من الهاتف إلى الراوتر (FTP)",
                      icon: Icons.upload_file_rounded,
                      height: 48,
                      colors: const [AppColors.violet, Color(0xFFA855F7)],
                      onPressed: controller.isBusy.value ? null : controller.uploadFromPhone,
                    ),
                  ),

                  const SizedBox(height: 10),
                  const SectionTitle(title: "الملفات على الراوتر"),
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: Text(
                            controller.statusMessage.value,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: "تحديث",
                          onPressed: controller.loadFiles,
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (controller.files.isEmpty) {
                      return _emptyState();
                    }

                    return Column(
                      children: controller.files
                          .map((file) => _fileCard(file, controller))
                          .toList(),
                    );
                  }),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, size: 42, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text(
            "لا توجد ملفات نسخ أو تصدير على الراوتر.\nأنشئ نسخة جديدة من الأعلى.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _fileCard(RouterFileModel file, RouterBackupController controller) {
    final isBackup = file.isBackup;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isBackup ? AppColors.blue : AppColors.green)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isBackup ? Icons.settings_backup_restore_rounded : Icons.text_snippet_rounded,
                  color: isBackup ? AppColors.blue : AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${file.readableSize} • ${file.lastModified}",
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: "تنزيل",
                  icon: Icons.download_rounded,
                  color: AppColors.blue,
                  onTap: controller.isBusy.value ? null : () => controller.downloadFile(file),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  label: "استعادة",
                  icon: Icons.restore_rounded,
                  color: AppColors.warning,
                  onTap: controller.isBusy.value ? null : () => controller.restoreFile(file),
                ),
              ),
              const SizedBox(width: 8),
              _actionButton(
                label: "",
                icon: Icons.delete_outline_rounded,
                color: AppColors.danger,
                onTap: controller.isBusy.value ? null : () => controller.deleteFile(file),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
