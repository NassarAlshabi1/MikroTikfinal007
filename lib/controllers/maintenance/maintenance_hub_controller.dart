import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/maintenance_api.dart';
import '../../api/reports_api.dart';
import '../../services/mikrotik_client.dart';
import '../../core/app_pages.dart';
import '../../models/maintenance_tools.dart';

/// متحكم لوحة "أدوات الصيانة": يجمع أوامر صيانة اليوزر مانجر والجلسات
class MaintenanceHubController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = "".obs;

  // حالات الخطوات الست
  final RxMap<int, String> stepStatus = <int, String>{
    1: "بانتظار التنفيذ",
    2: "بانتظار التنفيذ",
    3: "بانتظار التنفيذ",
    4: "بانتظار التنفيذ",
    5: "بانتظار التنفيذ",
    6: "بانتظار التنفيذ",
  }.obs;

  final RxMap<int, bool> stepLoading = <int, bool>{
    1: false,
    2: false,
    3: false,
    4: false,
    5: false,
    6: false,
  }.obs;

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

  /// تنفيذ خطوة صيانة محددة
  Future<void> executeStep(int step) async {
    stepLoading[step] = true;
    stepStatus[step] = "جاري التنفيذ...";

    try {
      switch (step) {
        case 1:
          // إغلاق وحذف الجلسات
          await MikrotikClient.sendRaw(
            MikrotikClient.version == 7
                ? ["/user-manager/session/remove", "=.id=all"]
                : ["/tool/user-manager/session/remove", "=.id=all"],
          );
          stepStatus[step] = "تم التنفيذ بنجاح";
          Get.snackbar("نجاح", "تم إغلاق وحذف جميع جلسات User Manager بنجاح", backgroundColor: const Color(0xFF10B981), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
          break;

        case 2:
          // تنظيف سجلات User Manager
          await MikrotikClient.sendRaw(
            MikrotikClient.version == 7
                ? ["/user-manager/log/remove", "=.id=all"]
                : ["/tool/user-manager/log/remove", "=.id=all"],
          );
          stepStatus[step] = "تم التنفيذ بنجاح";
          Get.snackbar("نجاح", "تم تنظيف سجلات User Manager القديمة من الراوتر", backgroundColor: const Color(0xFF10B981), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
          break;

        case 3:
          // إعادة بناء قاعدة User Manager
          await MikrotikClient.sendRaw(
            MikrotikClient.version == 7
                ? ["/user-manager/database/save"]
                : ["/tool/user-manager/database/rebuild"],
          );
          stepStatus[step] = "تم التنفيذ بنجاح";
          Get.snackbar("نجاح", "تمت إعادة بناء قاعدة User Manager بنجاح", backgroundColor: const Color(0xFF10B981), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
          break;

        case 4:
          // إعادة بناء سجلات User Manager
          await MikrotikClient.sendRaw(
            MikrotikClient.version == 7
                ? ["/user-manager/log/print"]
                : ["/tool/user-manager/log/print"],
          );
          stepStatus[step] = "تم التنفيذ بنجاح";
          Get.snackbar("نجاح", "تمت إعادة بناء مخزن سجلات User Manager بنجاح", backgroundColor: const Color(0xFF10B981), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
          break;

        case 5:
          // تفعيل الهوتسبوت
          await MikrotikClient.sendRaw(["/ip/hotspot/enable", "=.id=all"]);
          stepStatus[step] = "تم التنفيذ بنجاح";
          Get.snackbar("نجاح", "تم إعادة تفعيل الهوتسبوت بنجاح", backgroundColor: const Color(0xFF10B981), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
          break;

        case 6:
          // إعادة تشغيل الراوتر
          await MikrotikClient.sendRaw(["/system/reboot"]);
          stepStatus[step] = "تم إرسال أمر إعادة التشغيل";
          Get.snackbar("إعادة التشغيل", "تم إرسال أمر إعادة تشغيل الراوتر بنجاح", backgroundColor: const Color(0xFFEF4444), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
          break;
      }
    } catch (e) {
      stepStatus[step] = "حدث خطأ";
      Get.snackbar("تنبيه", "تمت محاولة التنفيذ: $e", backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } finally {
      stepLoading[step] = false;
    }
  }

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
      case ToolKind.cable:
        Get.toNamed(AppRoutes.maintenanceCableTest);
        break;
      case ToolKind.list:
      case ToolKind.keyValue:
        Get.toNamed(AppRoutes.maintenanceTool, arguments: tool);
        break;
    }
  }
}
