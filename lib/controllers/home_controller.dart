import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/api/router_api.dart';
import 'package:mikronet/api/users/active_users_api.dart';
import 'package:mikronet/core/app_pages.dart';
import 'package:mikronet/core/string_extensions.dart';
import 'package:mikronet/services/mikrotik_client.dart';
import '/api/reports_api.dart';
import '/controllers/dialog_helper.dart';

class HomeController extends GetxController with GetSingleTickerProviderStateMixin {
  final RxString cpuPercent = '—'.obs;
  final RxString ramPercent = '—'.obs;
  final RxString ramDetails = '—'.obs;
  final RxString activeUsersCount = '—'.obs;
  final RxString uptime = '—'.obs;
  final RxString diskSpacePercent = '—'.obs;
  final RxString diskSpaceDetails = '—'.obs;
  final RxString systemVersion = '—'.obs;
  final RxString routerAddress = ''.obs;
  final RxString routerSerial = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isOnline = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;

  late AnimationController pulseController;
  Timer? dataRefreshTimer;
  bool _isFetching = false;

  @override
  void onInit() {
    super.onInit();
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    fetchRealData();
    dataRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      fetchRealData();
    });
  }

  @override
  void onClose() {
    dataRefreshTimer?.cancel();
    pulseController.dispose();
    super.onClose();
  }

  Future<void> fetchRealData() async {
    if (_isFetching) return;
    _isFetching = true;
    isRefreshing.value = true;
    if (!isOnline.value) isLoading.value = true;
    errorMessage.value = '';

    try {
      final systemResponse = await ReportsApi.getSystemState();
      if (!systemResponse.status || systemResponse.data == null) {
        throw Exception(systemResponse.message.isEmpty
            ? 'تعذّر قراءة حالة الراوتر'
            : systemResponse.message);
      }

      final system = systemResponse.data!;
      final totalRam = _readNumber(system.totalMemory);
      final freeRam = _readNumber(system.freeMemory);
      final totalDisk = _readNumber(system.totalDiskSpace);
      final freeDisk = _readNumber(system.freeDiskSpace);

      cpuPercent.value = _percentage(system.cpu);
      uptime.value = system.uptime.trim().isEmpty
          ? '—'
          : system.uptime.formatUptime.replaceAll('\n', '، ');
      systemVersion.value = system.version.trim().isEmpty ? '—' : system.version.trim();
      routerAddress.value = MikrotikClient.address.trim();

      if (totalRam > 0) {
        final usedRam = (totalRam - freeRam).clamp(0, totalRam).toDouble();
        ramPercent.value = '${((usedRam / totalRam) * 100).round()}%';
        ramDetails.value = '${usedRam.toStringAsFixed(0).formatBytes} / ${totalRam.toStringAsFixed(0).formatBytes}';
      } else {
        ramPercent.value = '—';
        ramDetails.value = 'غير متاح';
      }

      if (totalDisk > 0) {
        final usedDisk = (totalDisk - freeDisk).clamp(0, totalDisk).toDouble();
        diskSpacePercent.value = '${((usedDisk / totalDisk) * 100).round()}%';
        diskSpaceDetails.value = '${usedDisk.toStringAsFixed(0).formatBytes} / ${totalDisk.toStringAsFixed(0).formatBytes}';
      } else {
        diskSpacePercent.value = '—';
        diskSpaceDetails.value = 'غير متاح';
      }

      try {
        final serialResponse = await RouterApi.getRouterSerial();
        routerSerial.value = serialResponse.status
            ? (serialResponse.data?.trim().isNotEmpty == true
                ? serialResponse.data!.trim()
                : 'غير متاح')
            : 'غير متاح';
      } catch (_) {
        routerSerial.value = 'غير متاح';
      }

      try {
        final activeResponse = await ActiveUsersApi.getAllActive();
        activeUsersCount.value = activeResponse.status && activeResponse.data != null
            ? '${activeResponse.data!.length}'
            : '—';
      } catch (_) {
        activeUsersCount.value = '—';
      }

      isOnline.value = true;
    } catch (e) {
      isOnline.value = false;
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      cpuPercent.value = '—';
      ramPercent.value = '—';
      ramDetails.value = 'غير متاح';
      activeUsersCount.value = '—';
      uptime.value = '—';
      diskSpacePercent.value = '—';
      diskSpaceDetails.value = 'غير متاح';
      systemVersion.value = '—';
      routerSerial.value = '';
    } finally {
      _isFetching = false;
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  double _readNumber(String value) =>
      double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  String _percentage(String value) {
    final parsed = double.tryParse(value.replaceAll('%', '').trim());
    return parsed == null ? '—' : '${parsed.round()}%';
  }

  // إجراءات التنقل الحالية في التطبيق.
  void generateSingleCard() => Get.toNamed(AppRoutes.addSingleCard);
  void manageActiveUsers() => Get.toNamed(AppRoutes.users);
  void viewUptimeDetails() => Get.toNamed(AppRoutes.systemStatus);
  void checkDiskSpace() => Get.toNamed(AppRoutes.systemStatus);
  void goToCards() => Get.toNamed(AppRoutes.cards);
  void goToUsers() => Get.toNamed(AppRoutes.users);
  void goToPrint() => Get.toNamed(AppRoutes.print);
  void goToSites() => Get.toNamed(AppRoutes.sites);
  void goToReports() => Get.toNamed(AppRoutes.reports);
  void goToMoreSettings() => Get.toNamed(AppRoutes.more);
  void goToDistributors() => Get.toNamed(AppRoutes.distributors);
  void goToMaintenance() => Get.toNamed(AppRoutes.maintenance);
  void goToMonitor() => Get.toNamed(AppRoutes.monitor);

  Future<void> logout() async {
    final confirmed = await showConfirmDialog(
      message: 'هل تريد الخروج من لوحة التحكم؟',
      onConfirm: () {},
    );
    if (confirmed) await Get.offAllNamed(AppRoutes.login);
  }
}
