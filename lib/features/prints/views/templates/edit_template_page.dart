import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:mikronet/core/ui/widgets/gradient_button.dart';
import 'package:mikronet/core/ui/widgets/modern_input.dart';
import 'package:mikronet/features/prints/controllers/templates/edit_template_controller.dart';

import 'package:mikronet/core/ui/widgets/sub_page_header.dart';
import 'package:mikronet/features/prints/views/templates/template_shared_widgets.dart'; 

class EditTemplatePage extends GetView<EditTemplateController> {
  const EditTemplatePage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    // يتم تمرير البيانات عبر Get.to(()=> EditTemplateView(), arguments: templateModel);
    //Get.put(EditTemplateController()); 

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            PremiumHeader(title: "تعديل القالب", subtitle: "تحديث إعدادات القالب", goBack: Get.back),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: GetBuilder<EditTemplateController>(
                  builder: (_) {
                    return Column(
                      children: [
                        ModernInput(label: 'ادخل اسم مميز', icon: Icons.text_fields_rounded, controller: controller.profileName,),
                        
                        buildCanvasArea(controller),
                        const SizedBox(height: 5),
                        buildSettingsArea(controller, screenWidth),
                        const SizedBox(height: 5),    
                        GradientButton(
                          height: 55,
                          onPressed: controller.saveAction,
                          icon: Icons.save_rounded,
                          label: "حفظ التعديلات",
                          colors: const [Color(0xff1E3C72), Color(0xff2563EB)], // لون أخضر لتمييز التعديل
                       

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