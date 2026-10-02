import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/distributors/distributor_form_controller.dart';
import '../widgets/shared/layouts/gradient_button.dart';
import '../widgets/shared/layouts/modern_input.dart';
import '../widgets/shared/layouts/sub_page_header.dart';
import '../widgets/shared/typography/section_title.dart';

class DistributorFormPage extends GetView<DistributorFormController> {
  const DistributorFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            PremiumHeader(
              title: controller.isEdit ? "تعديل موزع" : "إضافة موزع",
              subtitle: "بيانات نقطة البيع أو الموزع",
              icon: Icons.store_mall_directory_rounded,
              goBack: Get.back,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                children: [
                  const SectionTitle(title: "البيانات الأساسية"),
                  ModernInput(
                    label: "اسم الموزع",
                    icon: Icons.person_rounded,
                    controller: controller.nameCtrl,
                  ),
                  ModernInput(
                    label: "رقم الهاتف (اختياري)",
                    icon: Icons.phone_rounded,
                    controller: controller.phoneCtrl,
                  ),
                  ModernInput(
                    label: "ملاحظات (اختياري)",
                    icon: Icons.notes_rounded,
                    controller: controller.noteCtrl,
                  ),
                  if (controller.isEdit)
                    Obx(
                      () => SwitchListTile(
                        value: controller.isActive.value,
                        activeColor: const Color(0xFF10B981),
                        title: const Text(
                          "الحساب مُفعّل",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text("أوقف التفعيل لإخفاء الموزع من قائمة النشطين"),
                        onChanged: (value) => controller.isActive.value = value,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Obx(
                    () => GradientButton(
                      label: controller.isEdit ? "حفظ التعديلات" : "إضافة الموزع",
                      icon: Icons.save_rounded,
                      height: 50,
                      onPressed: controller.isSaving.value ? null : controller.save,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
