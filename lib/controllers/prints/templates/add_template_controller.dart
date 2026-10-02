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
      final name = profileName.text.trim();
      if (name.isEmpty) {
        showMsgDialog(message: "اكتب اسم القالب أولًا", type: MsgType.error);
        return;
      }

      // تأكيد تحميل الصورة قبل الحفظ (وإلا حُفظ قالب بلا صورة/تالف)
      await ensureImageLoaded();

      Map temp = getLayoutData(49); // 49 كقيمة افتراضية كما بالكود الأصلي
      PrintTemplatesModel model = PrintTemplatesModel.fromDataForm(temp);
      final int r = await PrintTemplatesApi.addOneTemplate(model.toDatabase());
      if (r <= 0) {
        showMsgDialog(message: "لم يتم حفظ القالب — تحقق من المساحة المتاحة", type: MsgType.error);
        return;
      }

      await showMsgDialog(message: "تمت الاضافة بنجاح",type: MsgType.success);
      Get.back(); // العودة للخلف بعد النجاح
    } catch (e) {
      showMsgDialog(message: "تعذّر حفظ القالب: ${e.toString()}",type: MsgType.error);
    }
  }
}