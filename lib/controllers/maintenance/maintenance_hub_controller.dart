import 'package:get/get.dart';

import '../../api/maintenance_api.dart';
import '../../api/reports_api.dart';
import '../../core/app_pages.dart';
import '../../models/maintenance_tools.dart';

/// متحكم لوحة "أدوات الصيانة": يجمع الأقسام ويقرأ عدّادات الراوتر.
class MaintenanceHubController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxString errorMessage = "".obs;

  /// cpu / ram / uptime / version
  final RxMap<String, String> resources = <String, String>{}.obs;

  /// مفتاح = أمر RouterOS، قيمة = عدد العناصر (-1 تعني خطأ)
  final RxMap<String, int> counts = <String, int>{}.obs;

  List<MaintenanceSection> get sections => MaintenanceCatalog.sections;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = "";

    await Future.wait([_loadResources(), _loadCounts()]);

    isLoading.value = false;
  }

  Future<void> _loadResources() async {
    try {
      final response = await ReportsApi.getSystemState();
      if (response.status && response.data != null) {
        final system = response.data!;
        resources.assignAll({
          "cpu": "${system.cpu}%",
          "memory": system.freeMemory,
          "uptime": system.uptime,
          "version": system.version,
        });
      }
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<void> _loadCounts() async {
    final commands = <String>{
      for (final section in sections) ...section.countCommands,
      // عدّادات إضافية للبطاقات المفيدة
      "/ip/firewall/filter/print",
      "/ip/firewall/nat/print",
      "/ip/firewall/address-list/print",
      "/queue/simple/print",
      "/ip/arp/print",
      "/ip/address/print",
      "/ip/dhcp-server/lease/print",
      "/ip/firewall/connection/print",
      "/ip/neighbor/print",
      "/interface/print",
    };

    for (final command in commands) {
      final count = await MaintenanceApi.countOnly(command);
      counts[command] = count;
    }
  }

  /// عدّاد قسم = مجموع عدّادات أوامره.
  int sectionCount(MaintenanceSection section) {
    if (section.countCommands.isEmpty) return -1;
    var total = 0;
    for (final command in section.countCommands) {
      final value = counts[command] ?? -1;
      if (value < 0) return -1;
      total += value;
    }
    return total;
  }

  /// عدّاد أداة مفردة.
  int toolCount(MaintenanceTool tool) {
    final command = tool.menu?.command;
    if (command == null) return -1;
    return counts[command] ?? -1;
  }

  void openTool(MaintenanceTool tool) {
    switch (tool.kind) {
      case ToolKind.diagnostics:
        Get.toNamed(AppRoutes.maintenanceDiagnostics, arguments: tool.diagnostic);
        break;
      case ToolKind.list:
      case ToolKind.keyValue:
        Get.toNamed(AppRoutes.maintenanceTool, arguments: tool);
        break;
    }
  }
}
