import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart'; // استيراد المسارات

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