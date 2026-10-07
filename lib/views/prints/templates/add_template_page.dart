import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/core/app_theme.dart';
import '../../../controllers/prints/templates/add_template_controller.dart';
import '../../widgets/shared/layouts/gradient_button.dart';
import '../../widgets/shared/layouts/sub_page_header.dart';
import 'template_shared_widgets.dart';

class AddTemplatePage extends GetView<AddTemplateController> {
  const AddTemplatePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AddTemplateController>()) {
      Get.put(AddTemplateController());
    }

    final width = MediaQuery.sizeOf(context).width;
    final contentWidth = width > 820 ? 760.0 : double.infinity;
    final controlsWidth = width > 820 ? 760.0 : width;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            const PremiumHeader(
              title: 'إنشاء تصميم كرت',
              subtitle: 'اختر الخلفية واضبط مواضع النص قبل حفظ القالب',
              icon: Icons.palette_rounded,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: GetBuilder<AddTemplateController>(
                    init: controller,
                    builder: (ctrl) => ListView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                      children: [
                        _nameField(ctrl),
                        const SizedBox(height: 12),
                        _editorHint(),
                        const SizedBox(height: 9),
                        buildCanvasArea(ctrl),
                        const SizedBox(height: 12),
                        buildSettingsArea(ctrl, controlsWidth),
                        const SizedBox(height: 14),
                        GradientButton(
                          height: 52,
                          onPressed: ctrl.saveAction,
                          icon: Icons.add_circle_outline_rounded,
                          label: 'حفظ التصميم',
                          colors: const [Color(0xFF0369A1), Color(0xFF0EA5E9)],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nameField(AddTemplateController ctrl) {
    return TextField(
      controller: ctrl.profileName,
      onChanged: (_) => ctrl.update(),
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppColors.text, fontSize: 13),
      decoration: InputDecoration(
        labelText: 'اسم التصميم',
        hintText: 'اكتب اسمًا واضحًا للقالب',
        prefixIcon: const Icon(Icons.text_fields_rounded),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.info),
        ),
      ),
    );
  }

  Widget _editorHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.touch_app_rounded, color: AppColors.info, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text('اسحب اسم المستخدم وكلمة المرور داخل المعاينة لضبط مكان الطباعة.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
