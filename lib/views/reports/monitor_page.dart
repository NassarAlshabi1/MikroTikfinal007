import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/router_monitor_api.dart';
import '../../controllers/reports/monitor_controller.dart';
import '../widgets/shared/layouts/sub_page_header.dart';

class MonitorPage extends GetView<MonitorController> {
  const MonitorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
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
              labelColor: const Color(0xFF1E3A8A),
              unselectedLabelColor: const Color(0xFF94A3B8),
              indicatorColor: const Color(0xFF2563EB),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        Row(
          children: [
            _resourceCard("المعالج", controller.cpu.value, Icons.memory_rounded, const Color(0xFF2563EB)),
            const SizedBox(width: 10),
            _resourceCard("ذاكرة حرة", controller.freeMemory.value, Icons.sd_storage_rounded, const Color(0xFF10B981)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _resourceCard("مدة التشغيل", controller.uptime.value, Icons.timer_outlined, const Color(0xFFF59E0B)),
            const SizedBox(width: 10),
            _resourceCard("الإصدار", controller.version.value, Icons.info_outline_rounded, const Color(0xFF7C3AED)),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          "الحساسات",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 10),
        if (controller.temperatureValue != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB91C1C), Color(0xFFEF4444)],
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
                      style: TextStyle(color: Colors.white70, fontSize: 13),
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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                "لا يوفّر هذا الراوتر بيانات حساسات عبر /system/health، "
                "أو أن الإصدار لا يدعمها. (الخَطأ الشائع: بعض أجهزة RouterOS v6)",
                style: TextStyle(color: Color(0xFF64748B), height: 1.6, fontSize: 12),
              ),
            );
          }

          return Column(
            children: controller.health.entries
                .map((entry) => _healthRow(entry.key, entry.value))
                .toList(),
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _resourceCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Color(0xFF1E293B),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF1E3A8A),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "قراءة لحظية كل 6 ثوانٍ للمنافذ العاملة",
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
                        icon: const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B)),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Obx(() {
            if (controller.interfaces.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  "لم يتم العثور على منافذ، أو تعذّر قراءة /interface/print.",
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              );
            }
            return Column(
              children: controller.interfaces
                  .map((element) => _interfaceCard(element))
                  .toList(),
            );
          }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _interfaceCard(RouterInterfaceModel element) {
    final isRunning = element.running && !element.disabled;
    final color = element.disabled
        ? const Color(0xFF94A3B8)
        : isRunning
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                  color: color.withOpacity(0.12),
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
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${element.type}${element.comment.isEmpty ? "" : " • ${element.comment}"}",
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  element.statusLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _trafficStat("تنزيل", element.rxBitsPerSecond, const Color(0xFF2563EB)),
              _trafficStat("رفع", element.txBitsPerSecond, const Color(0xFFF59E0B)),
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
