import 'package:flutter/material.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import '/api/print_api.dart';
import '/models/print_model.dart';
import 'base_template_controller.dart';

class EditTemplateController extends BaseTemplateController {
  late PrintTemplatesModel editedTemplate;
  int editId = 0;
  EditTemplateController({required this.editedTemplate});
  @override
  void onInit() {
    super.onInit();
    // نستقبل المودل المراد تعديله عبر Get.arguments
    // if (Get.arguments != null && Get.arguments is PrintTemplatesModel) {
    //   editedTemplate = Get.arguments;
      _loadData();
    // }
  }

  void _loadData() {
    profileName.text = editedTemplate.name;
    imageBytes = editedTemplate.image;
    templateImage = MemoryImage(editedTemplate.image);
    numcolumns.value = editedTemplate.numOfColumns;
    numrows.value = editedTemplate.numOfRows;
    password = editedTemplate.withPassword;
    usernameFontSize.value = editedTemplate.usernameFontSize.toInt();
    passwordFontSize.value = editedTemplate.passwordFontSize.toInt();
    x.value = editedTemplate.usernameLocation.x;
    y.value = editedTemplate.usernameLocation.y;
    x2.value = editedTemplate.passwordLocation.x;
    y2.value = editedTemplate.passwordLocation.y;
    editId = editedTemplate.id;
    
    setItemDimensions();
    update(); // لتحديث الواجهة بالبيانات المحملة
  }

  @override
  Future<void> saveAction() async {
    try {
      Map temp = getLayoutData(editId);
      PrintTemplatesModel model = PrintTemplatesModel.fromDataForm(temp);
      await PrintTemplatesApi.templateEdit(editId, model.toDatabase());
      
     
      showMsgDialog(message: "تم التعديل بنجاح",type: MsgType.success);
      
    } catch (e) {
      showMsgDialog(message: e.toString(),type: MsgType.error);
    }
  }
}