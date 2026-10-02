import 'package:get/get.dart';
import 'package:mikronet/core/app_pages.dart';

class CardsUnitController extends GetxController {
  // دالة للتنقل إلى قائمة الكروت
  void goToCardsList() {
    Get.toNamed(AppRoutes.cardsList);
  }

  // دالة للتنقل إلى إضافة كرت واحد
  void goToAddSingleCard() {
    Get.toNamed(AppRoutes.addSingleCard);
  }

  // دالة للتنقل إلى الباقات والسرعات
  void goToPackages() {
    Get.toNamed(AppRoutes.packages);
  }
}