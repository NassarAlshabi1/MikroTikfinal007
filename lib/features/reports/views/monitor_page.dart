import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';

import 'package:mikronet/features/reports/data/router_monitor_api.dart';
import 'package:mikronet/features/reports/controllers/monitor_controller.dart';
import 'package:mikronet/core/ui/widgets/sub_page_header.dart';

class MonitorPage extends GetView<MonitorController> {
  const MonitorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            PremiumHeader(
              title: "مراقبة الشبكة",
              subtitle: "الحرارة والمنافذ وحركة البيانات",
              icon: Icons.monitor_heart_rounded,
              goBack: Get.back,
            ),
            TabBar(
              controller: controller.tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.blue,
              tabs: const [
                Tab(text: "الموارد والحساسات"),
                Tab(text: "المنافذ"),
              ],
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return TabBarView(
                  controller: controller.tabController,
                  children: [
                    _resourcesTab(),
                    _interfacesTab(),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== تبويب الموارد =====================
  Widget _resourcesTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      children: [
        Row(
          children: [
            _resourceCard("المعالج", controller.cpu.value, Icons.memory_rounded, AppColors.blue),
            const SizedBox(width: 10),
            _resourceCard("ذاكرة حرة", controller.freeMemory.value, Icons.sd_storage_rounded, AppColors.green),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _resourceCard("مدة التشغيل", controller.uptime.value, Icons.timer_outlined, AppColors.warning),
            const SizedBox(width: 10),
            _resourceCard("الإصدار", controller.version.value, Icons.info_outline_rounded, AppColors.violet),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          "الحساسات",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.text),
        ),
        const SizedBox(height: 10),
        if (controller.temperatureValue != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB91C1C), AppColors.danger],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(Icons.thermostat_rounded, color: Colors.white, size: 34),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "درجة الحرارة",
                      style: TextStyle(color: Color(0xB3E8EEF9), fontSize: 13),
                    ),
                    Text(
                      controller.temperatureValue!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Obx(() {
          if (!controller.hasHealth) {
            return Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                "لا يوفّر هذا الراوتر بيانات حساسات عبر /system/health، "
                "أو أن الإصدار لا يدعمها. (الخَطأ الشائع: بعض أجهزة RouterOS v6)",
                style: TextStyle(color: AppColors.textMuted, height: 1.6, fontSize: 12),
              ),
            );
          }

          return Column(
            children: controller.health.entries
                .map((entry) => _healthRow(entry.key, entry.value))
                .toList(),
          );
        }),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _resourceCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthRow(String name, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 13, color: AppColors.textSubtle)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== تبويب المنافذ =====================
  Widget _interfacesTab() {
    return RefreshIndicator(
      onRefresh: controller.loadAll,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "قراءة لحظية كل 6 ثوانٍ للمنافذ العاملة",
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
              Obx(
                () => controller.isLiveRefreshing.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: controller.refreshTraffic,
                        icon: const Icon(Icons.bolt_rounded, color: AppColors.warning),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Obx(() {
            if (controller.interfaces.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  "لم يتم العثور على منافذ، أو تعذّر قراءة /interface/print.",
                  style: TextStyle(color: AppColors.textMuted),
                ),
              );
            }
            return Column(
              children: controller.interfaces
                  .map((element) => _interfaceCard(element))
                  .toList(),
            );
          }),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _interfaceCard(RouterInterfaceModel element) {
    final isRunning = element.running && !element.disabled;
    final color = element.disabled
        ? AppColors.textMuted
        : isRunning
            ? AppColors.green
            : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.settings_ethernet_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      element.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${element.type}${element.comment.isEmpty ? "" : " • ${element.comment}"}",
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  element.statusLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(width: 6),
              Obx(() {
                final busy = controller.togglingInterfaceId.value == element.id;
                final anyToggling = controller.togglingInterfaceId.isNotEmpty;
                return IconButton(
                  onPressed: (busy || anyToggling)
                      ? null
                      : () => controller.toggleInterface(element),
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          element.disabled
                              ? Icons.power_settings_new_rounded
                              : Icons.power_off_rounded,
                          size: 20,
                          color: element.disabled ? AppColors.green : AppColors.danger,
                        ),
                  tooltip: element.disabled
                      ? "تفعيل المنفذ"
                      : "تعطيل المنفذ (يقطع المتصلين عبره)",
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  padding: EdgeInsets.zero,
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _trafficStat("تنزيل", element.rxBitsPerSecond, AppColors.blue),
              _trafficStat("رفع", element.txBitsPerSecond, AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trafficStat(String label, double bitsPerSecond, Color color) {
    final text = bitsPerSecond <= 0
        ? "0 bps"
        : bitsPerSecond >= 1000000
            ? "${(bitsPerSecond / 1000000).toStringAsFixed(2)} Mbps"
            : "${(bitsPerSecond / 1000).toStringAsFixed(1)} Kbps";

    return Expanded(
      child: Row(
        children: [
          Icon(
            label == "تنزيل" ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            "$label: $text",
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
