import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/features/maintenance/controllers/cable_test_controller.dart';
import 'package:mikronet/features/maintenance/controllers/diagnostics_controller.dart';
import 'package:mikronet/features/maintenance/controllers/maintenance_hub_controller.dart';
import 'package:mikronet/features/maintenance/controllers/tool_list_controller.dart';
import 'package:mikronet/features/maintenance/models/maintenance_tools.dart';
import 'package:mikronet/features/maintenance/views/cable_test_page.dart';
import 'package:mikronet/features/maintenance/views/diagnostics_page.dart';
import 'package:mikronet/features/maintenance/views/maintenance_hub_page.dart';
import 'package:mikronet/features/maintenance/views/tool_list_page.dart';

class MaintenanceRoutes {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.maintenance,
      page: () => const MaintenanceHubPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => MaintenanceHubController())),
    ),
    GetPage(
      name: AppRoutes.maintenanceTool,
      page: () => const ToolListPage(),
      binding: BindingsBuilder(() => Get.lazyPut(
        () => ToolListController(Get.arguments as MaintenanceTool),
      )),
    ),
    GetPage(
      name: AppRoutes.maintenanceDiagnostics,
      page: () => const DiagnosticsPage(),
      binding: BindingsBuilder(() => Get.lazyPut(
        () => DiagnosticsController(
          Get.arguments is DiagnosticTool ? Get.arguments as DiagnosticTool : null,
        ),
      )),
    ),
    GetPage(
      name: AppRoutes.maintenanceCableTest,
      page: () => const CableTestPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => CableTestController())),
    ),
  ];
}
