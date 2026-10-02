import 'package:get/get.dart';
import '../../core/app_pages.dart'; // استيراد المسارات

class UsersUnitController extends GetxController {

  void goBack() {
    Get.back();
  }

  void goToActiveUsers() {
    Get.toNamed(AppRoutes.activeUsers);
  }

  void goToHostUsers() {
    Get.toNamed(AppRoutes.hostUsers);
  }
  void goToSavedUsers() {
    Get.toNamed(AppRoutes.savedUsers);
  }
}