import 'package:get/get.dart';

import 'package:mikronet/app/routes/app_routes.dart';

class PrintsUnitController extends GetxController{
  void gotToBtches()=>Get.toNamed(AppRoutes.batches);
  void gotToTemplates()=>Get.toNamed(AppRoutes.templates);
  
}