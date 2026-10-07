import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/maintenance_api.dart';
import '../../api/router_monitor_api.dart';
import '../../controllers/dialog_helper.dart';
import '../../models/maintenance_tools.dart';

/// متحكم أدوات التشخيص: Ping، اختبار النطاق، Torch، Fetch، تنقيط الحزم، السجل.
class DiagnosticsController extends GetxController with GetSingleTickerProviderStateMixin {
  DiagnosticsController(this.initialTool);

  final DiagnosticTool? initialTool;

  late TabController tabController;

  // ===== Ping =====
  final pingAddressCtrl = TextEditingController(text: "8.8.8.8");
  final pingCountCtrl = TextEditingController(text: "5");
  final RxList<Map<String, String>> pingRows = <Map<String, String>>[].obs;
  final RxString pingSummary = "".obs;
  final RxBool isPinging = false.obs;

  // ===== Traceroute =====
  final traceAddressCtrl = TextEditingController(text: "8.8.8.8");
  final RxList<Map<String, String>> traceRows = <Map<String, String>>[].obs;
  final RxBool isTracing = false.obs;

  // ===== Torch =====
  final RxList<RouterInterfaceModel> interfaces = <RouterInterfaceModel>[].obs;
  final RxString selectedInterface = "".obs;
  final RxList<Map<String, String>> torchRows = <Map<String, String>>[].obs;
  final RxBool isTorchRunning = false.obs;
  StreamSubscription<Map<String, String>>? _torchSubscription;

  // ===== Fetch =====
  final fetchUrlCtrl = TextEditingController(text: "https://");
  final fetchPathCtrl = TextEditingController(text: "mikronet_fetch.txt");
  final RxList<Map<String, String>> fetchRows = <Map<String, String>>[].obs;
  final RxBool isFetching = false.obs;

  // ===== Sniffer =====
  final snifferFileCtrl = TextEditingController(text: "mikronet_sniffer");
  final snifferLimitCtrl = TextEditingController(text: "1000");
  final RxMap<String, String> snifferStatus = <String, String>{}.obs;
  final RxBool isSnifferBusy = false.obs;

  // ===== Logs =====
  final RxList<Map<String, String>> logs = <Map<String, String>>[].obs;
  final RxBool isLoadingLogs = false.obs;
  final logSearchCtrl = TextEditingController();
  final RxString logQuery = "".obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 6, vsync: this, initialIndex: _initialIndex());
    _loadInterfaces();
    _loadSnifferStatus();
    loadLogs();
  }

  int _initialIndex() {
    switch (initialTool) {
      case DiagnosticTool.traceroute:
        return 1;
      case DiagnosticTool.torch:
        return 2;
      case DiagnosticTool.fetch:
        return 3;
      case DiagnosticTool.sniffer:
        return 4;
      case DiagnosticTool.logs:
        return 5;
      case DiagnosticTool.ping:
      default:
        return 0;
    }
  }

  // ===================== Ping =====================
  Future<void> runPing() async {
    final address = pingAddressCtrl.text.trim();
    if (address.isEmpty) {
      await showMsgDialog(message: "أدخل عنوانًا للفحص", type: MsgType.warning);
      return;
    }

    isPinging.value = true;
    pingRows.clear();
    pingSummary.value = "جاري الفحص...";

    final count = int.tryParse(pingCountCtrl.text.trim()) ?? 5;
    final response = await MaintenanceApi.ping(address: address, count: count);

    isPinging.value = false;

    if (!response.status || response.data == null) {
      pingSummary.value = response.message;
      return;
    }

    pingRows.assignAll(response.data!);
    pingSummary.value = _summarizePing(response.data!);
  }

  String _summarizePing(List<Map<String, String>> rows) {
    final times = <double>[];
    var lost = 0;

    for (final row in rows) {
      final raw = row["time"] ?? "";
      final seconds = RegExp(r'([\d.]+)s').firstMatch(raw);
      final millis = RegExp(r'([\d.]+)ms').firstMatch(raw);
      if (millis != null) {
        times.add(double.tryParse(millis.group(1)!) ?? 0);
      } else if (seconds != null) {
        times.add((double.tryParse(seconds.group(1)!) ?? 0) * 1000);
      } else {
        lost++;
      }
    }

    if (times.isEmpty) {
      return "لا يوجد رد (فقدان كامل)";
    }

    times.sort();
    final total = times.reduce((a, b) => a + b);
    return "المرسل: ${rows.length} • المستلم: ${times.length} • الفاقد: $lost\n"
        "الأدنى: ${times.first.toStringAsFixed(1)}ms • "
        "الأعلى: ${times.last.toStringAsFixed(1)}ms • "
        "المتوسط: ${(total / times.length).toStringAsFixed(1)}ms";
  }

  // ===================== Traceroute =====================
  Future<void> runTraceroute() async {
    final address = traceAddressCtrl.text.trim();
    if (address.isEmpty) {
      await showMsgDialog(message: "أدخل عنوانًا للتتبع", type: MsgType.warning);
      return;
    }

    isTracing.value = true;
    traceRows.clear();

    final response = await MaintenanceApi.traceroute(address: address);

    isTracing.value = false;

    if (response.status && response.data != null) {
      traceRows.assignAll(response.data!);
    } else {
      await showMsgDialog(message: response.message, type: MsgType.error);
    }
  }

  // ===================== Torch =====================
  Future<void> _loadInterfaces() async {
    final response = await RouterMonitorApi.getInterfaces();
    if (response.status && response.data != null) {
      interfaces.assignAll(response.data!);
      final running = response.data!.where((element) => element.running && !element.disabled);
      selectedInterface.value = running.isNotEmpty
          ? running.first.name
          : (response.data!.isNotEmpty ? response.data!.first.name : "");
    }
  }

  void startTorch() {
    final target = selectedInterface.value;
    if (target.isEmpty) {
      showMsgDialog(message: "لم يتم العثور على منافذ لتشغيل Torch", type: MsgType.warning);
      return;
    }

    torchRows.clear();
    isTorchRunning.value = true;

    _torchSubscription = MaintenanceApi.torch(interface: target).listen(
      (row) {
        torchRows.insert(0, row);
        if (torchRows.length > 120) {
          torchRows.removeRange(120, torchRows.length);
        }
      },
      onError: (Object error) {
        isTorchRunning.value = false;
      },
      onDone: () {
        isTorchRunning.value = false;
      },
    );
  }

  Future<void> stopTorch() async {
    await _torchSubscription?.cancel();
    _torchSubscription = null;
    await MaintenanceApi.stopTorch();
    isTorchRunning.value = false;
  }

  // ===================== Fetch =====================
  Future<void> runFetch() async {
    final url = fetchUrlCtrl.text.trim();
    if (!url.startsWith("http")) {
      await showMsgDialog(message: "أدخل رابطًا صحيحًا يبدأ بـ http/https", type: MsgType.warning);
      return;
    }

    isFetching.value = true;
    fetchRows.clear();

    final response = await MaintenanceApi.fetchUrl(
      url: url,
      dstPath: fetchPathCtrl.text.trim(),
    );

    isFetching.value = false;

    if (response.status && response.data != null) {
      fetchRows.assignAll(response.data!);
      await showMsgDialog(message: "تم تنفيذ Fetch بنجاح", type: MsgType.success);
    } else {
      await showMsgDialog(message: response.message, type: MsgType.error);
    }
  }

  // ===================== Sniffer =====================
  Future<void> _loadSnifferStatus() async {
    final response = await MaintenanceApi.snifferStatus();
    if (response.status && response.data != null) {
      snifferStatus.assignAll(response.data!);
    }
  }

  Future<void> startSniffer() async {
    final target = selectedInterface.value;
    if (target.isEmpty) {
      await showMsgDialog(message: "اختر منفذًا أولًا", type: MsgType.warning);
      return;
    }

    isSnifferBusy.value = true;
    final response = await MaintenanceApi.snifferStart(
      interface: target,
      fileName: snifferFileCtrl.text.trim().isEmpty ? "mikronet_sniffer" : snifferFileCtrl.text.trim(),
      memoryLimit: snifferLimitCtrl.text.trim().isEmpty ? "1000" : snifferLimitCtrl.text.trim(),
    );
    isSnifferBusy.value = false;

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
    _loadSnifferStatus();
  }

  Future<void> stopSniffer() async {
    isSnifferBusy.value = true;
    final response = await MaintenanceApi.snifferStop();
    isSnifferBusy.value = false;

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
    _loadSnifferStatus();
  }

  // ===================== Logs =====================
  Future<void> loadLogs() async {
    isLoadingLogs.value = true;
    final response = await MaintenanceApi.logs();
    isLoadingLogs.value = false;

    if (response.status && response.data != null) {
      logs.assignAll(response.data!);
    }
  }

  void setLogQuery(String query) => logQuery.value = query;

  List<Map<String, String>> get filteredLogs {
    final query = logQuery.value.trim().toLowerCase();
    if (query.isEmpty) return logs;
    return logs.where((row) {
      return row.values.any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  @override
  void onClose() {
    _torchSubscription?.cancel();
    tabController.dispose();
    pingAddressCtrl.dispose();
    pingCountCtrl.dispose();
    traceAddressCtrl.dispose();
    fetchUrlCtrl.dispose();
    fetchPathCtrl.dispose();
    snifferFileCtrl.dispose();
    snifferLimitCtrl.dispose();
    logSearchCtrl.dispose();
    super.onClose();
  }
}
