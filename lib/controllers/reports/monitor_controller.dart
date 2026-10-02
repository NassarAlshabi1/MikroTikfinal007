import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/reports_api.dart';
import '../../api/router_monitor_api.dart';

/// مراقبة متقدمة للراوتر: الحساسات (الحرارة/الفولت) والمنافذ وحركة البيانات.
class MonitorController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  final RxMap<String, String> health = <String, String>{}.obs;
  final RxList<RouterInterfaceModel> interfaces = <RouterInterfaceModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLiveRefreshing = false.obs;
  final RxString errorMessage = "".obs;

  // بيانات الموارد العامة
  final RxString cpu = "0%".obs;
  final RxString freeMemory = "-".obs;
  final RxString uptime = "-".obs;
  final RxString version = "-".obs;

  Timer? _liveTimer;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    loadAll();
    _liveTimer = Timer.periodic(const Duration(seconds: 6), (_) => refreshTraffic());
  }

  @override
  void onClose() {
    _liveTimer?.cancel();
    tabController.dispose();
    super.onClose();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    errorMessage.value = "";

    await Future.wait([_loadResources(), _loadHealth(), _loadInterfaces()]);

    isLoading.value = false;
  }

  Future<void> _loadResources() async {
    try {
      final response = await ReportsApi.getSystemState();
      if (response.status && response.data != null) {
        cpu.value = "${response.data!.cpu}%";
        freeMemory.value = response.data!.freeMemory;
        uptime.value = response.data!.uptime;
        version.value = response.data!.version;
      }
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<void> _loadHealth() async {
    final response = await RouterMonitorApi.getHealth();
    if (response.status && response.data != null) {
      health.assignAll(response.data!);
    } else if (response.message.isNotEmpty) {
      // بعض الموديلات لا تدعم /system/health
      health.clear();
    }
  }

  Future<void> _loadInterfaces() async {
    final response = await RouterMonitorApi.getInterfaces();
    if (response.status && response.data != null) {
      interfaces.assignAll(response.data!);
    } else {
      errorMessage.value = response.message;
    }
  }

  /// قراءة لحظية لحركة المنافذ العاملة (أول 8 منافذ لتخفيف الحمل).
  Future<void> refreshTraffic() async {
    if (isLiveRefreshing.value || interfaces.isEmpty) return;
    isLiveRefreshing.value = true;

    final targets = interfaces
        .where((element) => element.running && !element.disabled)
        .take(8)
        .toList();

    for (final target in targets) {
      final response = await RouterMonitorApi.getInterfaceTraffic(target.name);
      if (response.status && response.data != null) {
        target.rxBitsPerSecond = response.data!["rx"] ?? 0;
        target.txBitsPerSecond = response.data!["tx"] ?? 0;
      }
    }

    if (targets.isNotEmpty) interfaces.refresh();
    isLiveRefreshing.value = false;
  }

  /// أهم قيمة حرارية متاحة (تختلف أسماء الحساسات حسب الموديل).
  String? get temperatureValue {
    for (final key in health.keys) {
      if (key.toLowerCase().contains("temperature")) {
        return health[key];
      }
    }
    return null;
  }

  bool get hasHealth => health.isNotEmpty;
}
