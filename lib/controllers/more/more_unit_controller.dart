import 'package:get/get.dart';
import 'package:mikronet/api/router_api.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import 'package:mikronet/core/app_pages.dart';

class MoreUnitController extends GetxController {
  
  // دالة الانتقال لصفحة النسخ الاحتياطي والاستعادة (بيانات التطبيق)
  void goToBackupAndRestore() {
    Get.toNamed(AppRoutes.backup);
  }

  // النسخ الاحتياطي الحقيقي لراوتر MikroTik
  void goToRouterBackup() {
    Get.toNamed(AppRoutes.routerBackup);
  }

  // أدوات الصيانة (التشخيص، IP، جدار الحماية، Queue...)
  void goToMaintenance() {
    Get.toNamed(AppRoutes.maintenance);
  }

  // إدارة Hotspot
  void goToHotspot() {
    Get.toNamed(AppRoutes.hotspot);
  }

  // تكامل Telegram (ضبط البوت + تفعيل المميزات)
  void goToTelegram() {
    Get.toNamed(AppRoutes.telegram);
  }

  // الموزعون والمحاسبة
  void goToDistributors() {
    Get.toNamed(AppRoutes.distributors);
  }

  // مراقبة الشبكة المتقدمة
  void goToMonitor() {
    Get.toNamed(AppRoutes.monitor);
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