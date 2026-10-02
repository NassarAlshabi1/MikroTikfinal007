import 'package:get/get.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import '/api/print_api.dart';
import '/models/print_model.dart';
import 'base_template_controller.dart';

class AddTemplateController extends BaseTemplateController {
  
  @override
  void onInit() {
    super.onInit();
    initialSettings();
  }

  void initialSettings() {
    profileName.text = "";
    setDefaultImage();
    setItemDimensions();
    x.value = itemWidth + 10;
    y.value = itemHeight + 10;
    x2.value = itemWidth + 11;
    y2.value = itemHeight + 11;
    update();
  }
  
  @override
  Future<void> saveAction() async {
    try {
      Map temp = getLayoutData(49); // 49 كقيمة افتراضية كما بالكود الأصلي
      PrintTemplatesModel model = PrintTemplatesModel.fromDataForm(temp);
      await PrintTemplatesApi.addOneTemplate(model.toDatabase());
      
      // تحديث قائمة القوالب المحفوظة
     //Get.back();
      await showMsgDialog(message: "تمت الاضافة بنجاح",type: MsgType.success);
       Get.back(); // العودة للخلف بعد النجاح
    } catch (e) {
      showMsgDialog(message: e.toString(),type: MsgType.error);

    }
  }
}