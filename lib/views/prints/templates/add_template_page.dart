import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/views/widgets/shared/layouts/main_gate_header.dart';
import 'package:mikronet/views/widgets/shared/layouts/modern_input.dart';
import '../../../controllers/prints/templates/add_template_controller.dart';
import '../../widgets/shared/layouts/gradient_button.dart';
import 'template_shared_widgets.dart'; // الملف الذي يحتوي على الـ UI helpers

class AddTemplatePage extends GetView<AddTemplateController> {
  const AddTemplatePage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    // تسجيل المتحكم إذا لم تكن تستخدم الـ Bindings
    Get.put(AddTemplateController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8FAFC),
        body: Column(
          children: [
            const MainGateHeader(title: "إضافة قالب جديد", subtitle: "",),
            // circleAvatarHeader(context, "إضافة قالب جديد"), 
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: GetBuilder<AddTemplateController>(
                  builder: (_) {
                    return Column(
                      children: [
                        ModernInput(label: "أضف اسماً مميزاً", icon: Icons.text_fields_rounded, controller: controller.profileName),
                        
                        buildCanvasArea(controller),
                        const SizedBox(height: 5),
                        // إعدادات القالب
                        buildSettingsArea(controller, screenWidth),
                        const SizedBox(height: 5),    
                        GradientButton(
                          height: 55,
                          onPressed: controller.saveAction,
                          icon: Icons.add_circle_outline_outlined,
                          label: "إضافة القالب",
                          colors: const [Color(0xff1E3C72), Color(0xff2563EB)],
                        ),                     
                      ],
                    );
                  }
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}