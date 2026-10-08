import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/api/cards_api.dart';
import 'package:mikronet/api/database_api.dart';
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
  final RxString lastSyncTime = 'لم تتم المزامنة بعد'.obs;
  final RxString cardStatsUpdatedAt = 'غير متاح'.obs;
  final RxString totalCardsCount = '—'.obs;
  final RxString soldCardsCount = '—'.obs;
  final RxString remainingCardsCount = '—'.obs;
  final RxString expiredCardsCount = '—'.obs;
  final RxString salesTodayCount = '—'.obs;
  final RxString salesMonthCount = '—'.obs;
  final RxString cardsStatsError = ''.obs;
  final RxString salesStatsError = ''.obs;
  final RxBool isOnline = false.obs;
  final RxBool hasCheckedConnection = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isStaleData = false.obs;
  final RxBool areCardStatsStale = false.obs;
  final RxBool hasCachedSnapshot = false.obs;

  late AnimationController pulseController;
  Timer? dataRefreshTimer;
  bool _isFetching = false;
  DateTime? _cardStatsUpdatedAtValue;

  @override
  void onInit() {
    super.onInit();
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    routerAddress.value = MikrotikClient.address.trim();
    unawaited(_initializeDashboard());
    dataRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _refreshPeriodicRouterState();
    });
  }

  @override
  void onClose() {
    dataRefreshTimer?.cancel();
    pulseController.dispose();
    super.onClose();
  }

  Future<void> _initializeDashboard() async {
    await _loadCachedSnapshot();
    await fetchRealData();
  }

  Future<void> fetchRealData() => _fetchRealData(refreshCardStats: true);

  Future<void> _refreshPeriodicRouterState() =>
      _fetchRealData(refreshCardStats: false);

  Future<void> _fetchRealData({required bool refreshCardStats}) async {
    if (_isFetching) return;
    _isFetching = true;
    isRefreshing.value = true;
    routerAddress.value = MikrotikClient.address.trim();
    if (!hasCachedSnapshot.value && lastSyncTime.value == 'لم تتم المزامنة بعد') {
      isLoading.value = true;
    }
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

      if (totalRam != null && freeRam != null && totalRam > 0) {
        final usedRam = (totalRam - freeRam).clamp(0, totalRam).toDouble();
        ramPercent.value = '${((usedRam / totalRam) * 100).round()}%';
        ramDetails.value =
            '${usedRam.toStringAsFixed(0).formatBytes} / ${totalRam.toStringAsFixed(0).formatBytes}';
      } else {
        ramPercent.value = '—';
        ramDetails.value = 'غير متاح';
      }

      if (totalDisk != null && freeDisk != null && totalDisk > 0) {
        final usedDisk = (totalDisk - freeDisk).clamp(0, totalDisk).toDouble();
        diskSpacePercent.value = '${((usedDisk / totalDisk) * 100).round()}%';
        diskSpaceDetails.value =
            '${usedDisk.toStringAsFixed(0).formatBytes} / ${totalDisk.toStringAsFixed(0).formatBytes}';
      } else {
        diskSpacePercent.value = '—';
        diskSpaceDetails.value = 'غير متاح';
      }

      final successfulUpdate = DateTime.now();
      isOnline.value = true;
      hasCheckedConnection.value = true;
      isStaleData.value = false;
      lastSyncTime.value = _formatTimestamp(successfulUpdate);

      try {
        final serialResponse = await RouterApi.getRouterSerial();
        routerSerial.value = serialResponse.status &&
                serialResponse.data?.trim().isNotEmpty == true
            ? serialResponse.data!.trim()
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

      // إحصاءات الراوتر وسجل المبيعات المحلي مصدران مستقلان؛ فشل أحدهما لا
      // يحوّل قراءة الصفر إلى قيمة افتراضية ولا يخفي نجاح الاتصال بالراوتر.
      await _loadDashboardStats(refreshCardStats: refreshCardStats);

      hasCachedSnapshot.value = true;
      try {
        await _saveCachedSnapshot(successfulUpdate);
      } catch (_) {
        // فشل التخزين المحلي لا يغيّر نتيجة القراءة الحقيقية من الراوتر.
      }
    } catch (e) {
      isOnline.value = false;
      hasCheckedConnection.value = true;
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      isStaleData.value = hasCachedSnapshot.value ||
          lastSyncTime.value != 'لم تتم المزامنة بعد';
      // نحتفظ بآخر قراءة صحيحة بدل تصفير المقاييس عند انقطاع الشبكة.
    } finally {
      _isFetching = false;
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> _loadDashboardStats({required bool refreshCardStats}) async {
    if (refreshCardStats) {
      try {
        final response = await CardsApi.getAllCards();
        if (!response.status || response.data == null) {
          throw Exception(!response.status && response.message.isNotEmpty
              ? response.message
              : 'لم يرجع الراوتر قائمة كروت صالحة');
        }

        final cards = response.data!
            .where((card) => card.username.trim().isNotEmpty)
            .toList(growable: false);
        totalCardsCount.value = '${cards.length}';
        remainingCardsCount.value =
            '${cards.where((card) => card.status == 'normal').length}';
        expiredCardsCount.value =
            '${cards.where((card) => card.status == 'expired').length}';
        cardsStatsError.value = '';
        areCardStatsStale.value = false;
        _cardStatsUpdatedAtValue = DateTime.now();
        cardStatsUpdatedAt.value = _formatTimestamp(_cardStatsUpdatedAtValue!);
      } catch (e) {
        cardsStatsError.value = _cleanError(e);
        areCardStatsStale.value = true;
      }
    } else if (totalCardsCount.value != '—') {
      // لا نجلب آلاف حسابات User Manager مع كل فحص دوري قصير؛ نظل صريحين
      // بأن هذه الأعداد من آخر تحديث يدوي/فتح للوحة.
      areCardStatsStale.value = true;
    }

    try {
      final serial = routerSerial.value.trim();
      if (serial.isEmpty || serial == 'غير متاح') {
        throw Exception('تعذّر ربط سجل المبيعات بالراوتر الحالي لغياب الرقم التسلسلي');
      }
      final routerScope = "router_serial='${_escapeSql(serial)}'";
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1));
      final monthStart = DateTime(now.year, now.month);
      final nextMonthStart = DateTime(now.year, now.month + 1);

      final allSales = await _countSales(where: routerScope);
      final todaySales = await _countSales(
        where: '$routerScope AND timestamp >= ${todayStart.millisecondsSinceEpoch} '
            'AND timestamp < ${tomorrowStart.millisecondsSinceEpoch}',
      );
      final monthSales = await _countSales(
        where: '$routerScope AND timestamp >= ${monthStart.millisecondsSinceEpoch} '
            'AND timestamp < ${nextMonthStart.millisecondsSinceEpoch}',
      );

      soldCardsCount.value = '$allSales';
      salesTodayCount.value = '$todaySales';
      salesMonthCount.value = '$monthSales';
      salesStatsError.value = '';
    } catch (e) {
      salesStatsError.value = _cleanError(e);
    }
  }

  Future<int> _countSales({String? where}) async {
    final rows = await DBApi.select('sales_records', where, 'COUNT(*) AS total');
    if (rows.isEmpty) {
      throw const FormatException('لم تُرجع قاعدة البيانات عدد سجلات المبيعات');
    }
    final value = rows.first['total'];
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw const FormatException('قيمة عدد سجلات المبيعات غير صالحة');
    }
    return parsed;
  }

  String get _snapshotKey {
    final address = MikrotikClient.address.trim().toLowerCase();
    if (address.isEmpty) return '';
    final encodedAddress = base64Url.encode(utf8.encode(address));
    return 'home_dashboard_$encodedAddress';
  }

  Future<void> _loadCachedSnapshot() async {
    final key = _snapshotKey;
    if (key.isEmpty) return;

    try {
      final rows = await DBApi.select(
        'app_settings',
        "key='${_escapeSql(key)}'",
        'value',
      );
      if (rows.isEmpty) return;

      final decoded = jsonDecode(rows.first['value'].toString());
      if (decoded is! Map) return;

      cpuPercent.value = _snapshotString(decoded, 'cpuPercent');
      ramPercent.value = _snapshotString(decoded, 'ramPercent');
      ramDetails.value = _snapshotString(decoded, 'ramDetails');
      activeUsersCount.value = _snapshotString(decoded, 'activeUsersCount');
      uptime.value = _snapshotString(decoded, 'uptime');
      diskSpacePercent.value = _snapshotString(decoded, 'diskSpacePercent');
      diskSpaceDetails.value = _snapshotString(decoded, 'diskSpaceDetails');
      systemVersion.value = _snapshotString(decoded, 'systemVersion');
      routerSerial.value = _snapshotString(decoded, 'routerSerial', fallback: '');
      totalCardsCount.value = _snapshotString(decoded, 'totalCardsCount');
      soldCardsCount.value = _snapshotString(decoded, 'soldCardsCount');
      remainingCardsCount.value = _snapshotString(decoded, 'remainingCardsCount');
      expiredCardsCount.value = _snapshotString(decoded, 'expiredCardsCount');
      salesTodayCount.value = _snapshotString(decoded, 'salesTodayCount');
      salesMonthCount.value = _snapshotString(decoded, 'salesMonthCount');

      final cardStatsEpoch = int.tryParse(decoded['cardsUpdatedAt']?.toString() ?? '');
      if (cardStatsEpoch != null && cardStatsEpoch > 0) {
        _cardStatsUpdatedAtValue =
            DateTime.fromMillisecondsSinceEpoch(cardStatsEpoch);
        cardStatsUpdatedAt.value = _formatTimestamp(_cardStatsUpdatedAtValue!);
      }

      final epoch = int.tryParse(decoded['updatedAt']?.toString() ?? '');
      if (epoch != null && epoch > 0) {
        lastSyncTime.value = _formatTimestamp(
          DateTime.fromMillisecondsSinceEpoch(epoch),
        );
        hasCachedSnapshot.value = true;
        isStaleData.value = true;
        areCardStatsStale.value = true;
      }
    } catch (_) {
      // السجل المحلي تالف أو قديم: تبقى المقاييس غير المتاحة على شرطة واضحة.
    }
  }

  Future<void> _saveCachedSnapshot(DateTime updatedAt) async {
    final key = _snapshotKey;
    if (key.isEmpty) return;

    final snapshot = <String, dynamic>{
      'cpuPercent': cpuPercent.value,
      'ramPercent': ramPercent.value,
      'ramDetails': ramDetails.value,
      'activeUsersCount': activeUsersCount.value,
      'uptime': uptime.value,
      'diskSpacePercent': diskSpacePercent.value,
      'diskSpaceDetails': diskSpaceDetails.value,
      'systemVersion': systemVersion.value,
      'routerSerial': routerSerial.value,
      'totalCardsCount': totalCardsCount.value,
      'soldCardsCount': soldCardsCount.value,
      'remainingCardsCount': remainingCardsCount.value,
      'expiredCardsCount': expiredCardsCount.value,
      'salesTodayCount': salesTodayCount.value,
      'salesMonthCount': salesMonthCount.value,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'cardsUpdatedAt': _cardStatsUpdatedAtValue?.millisecondsSinceEpoch,
    };
    final value = jsonEncode(snapshot);
    final rows = await DBApi.select(
      'app_settings',
      "key='${_escapeSql(key)}'",
      'key',
    );

    if (rows.isEmpty) {
      await DBApi.insert('app_settings', {'key': key, 'value': value});
    } else {
      await DBApi.update(
        'app_settings',
        {'value': value},
        "key='${_escapeSql(key)}'",
      );
    }
  }

  String _snapshotString(Map<dynamic, dynamic> data, String key,
      {String fallback = '—'}) {
    final value = data[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _escapeSql(String value) => value.replaceAll("'", "''");

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  double? _readNumber(String value) {
    final input = value.trim();
    if (input.isEmpty) return null;
    return double.tryParse(input);
  }

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
