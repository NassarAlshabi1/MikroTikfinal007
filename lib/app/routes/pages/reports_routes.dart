import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/features/reports/controllers/monitor_controller.dart';
import 'package:mikronet/features/reports/controllers/reports_unit_controller.dart';
import 'package:mikronet/features/reports/controllers/sales_report_controller.dart';
import 'package:mikronet/features/reports/controllers/system_status_report_controller.dart';
import 'package:mikronet/features/reports/views/monitor_page.dart';
import 'package:mikronet/features/reports/views/reports_unit.dart';
import 'package:mikronet/features/reports/views/sales_report_page.dart';
import 'package:mikronet/features/reports/views/system_status_report_page.dart';

class ReportsRoutes {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.reports, 
      page: () => const ReportsUnitPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => ReportsUnitController())),
    ),
    GetPage(
      name: AppRoutes.salesReport, 
      page: () => const SalesReportPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => SalesReportController())),
    ),
    GetPage(
      name: AppRoutes.systemStatus, 
      page: () => const SystemStatusReportPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => SystemStatusReportController())),
    ),
    GetPage(
      name: AppRoutes.monitor,
      page: () => const MonitorPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => MonitorController())),
    ),
  ];
}
