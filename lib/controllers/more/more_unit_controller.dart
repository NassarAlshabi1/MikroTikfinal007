import 'package:get/get.dart';
import 'package:mikronet/api/router_api.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import 'package:mikronet/core/app_pages.dart';

class MoreUnitController extends GetxController {
  
  // دالة الانتقال لصفحة النسخ الاحتياطي والاستعادة
  void goToBackupAndRestore() {
    Get.toNamed(AppRoutes.backup);
  }

  // دالة إعادة تشغيل النظام (الراوتر)
  void rebootSystem() {
    showConfirmDialog(message: "هل انت متاكد من اعادة تشغيل النظام", onConfirm: _executeReboot);
  }
  void _executeReboot()async{
    showLoadingDialog();
    var res =await RouterApi.rebootSystem();
    showMsgDialog(message: res.message,type:res.status? MsgType.success:MsgType.error);
    if(res.status){
      Get.offAllNamed(AppRoutes.login);
    }
  }
}