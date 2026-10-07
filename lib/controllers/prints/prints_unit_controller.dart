import 'package:get/get.dart';

import '../../core/app_pages.dart';

class PrintsUnitController extends GetxController{
  void gotToBtches()=>Get.toNamed(AppRoutes.batches);
  void gotToTemplates()=>Get.toNamed(AppRoutes.templates);
  
}