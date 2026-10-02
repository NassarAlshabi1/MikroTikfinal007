import 'package:get/get.dart';
import 'package:mikronet/core/app_pages.dart';

class ReportsUnitController extends GetxController{
  void gotToSystemStatus()=>Get.toNamed(AppRoutes.systemStatus);
  void gotToSalesReport()=>Get.toNamed(AppRoutes.salesReport);
}