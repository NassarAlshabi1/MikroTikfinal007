import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart';

class ReportsUnitController extends GetxController{
  void gotToSystemStatus()=>Get.toNamed(AppRoutes.systemStatus);
  void gotToSalesReport()=>Get.toNamed(AppRoutes.salesReport);

  void goToMonitor()=>Get.toNamed(AppRoutes.monitor);

  void goToMaintenance()=>Get.toNamed(AppRoutes.maintenance);
}