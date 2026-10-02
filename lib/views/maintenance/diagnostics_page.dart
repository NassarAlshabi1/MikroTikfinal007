import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/maintenance/diagnostics_controller.dart';
import '../widgets/shared/layouts/gradient_button.dart';
import '../widgets/shared/layouts/sub_page_header.dart';

/// أدوات التشخيص: Ping، اختبار النطاق، Torch، Fetch، تنقيط الحزم، السجل.
class DiagnosticsPage extends GetView<DiagnosticsController> {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            PremiumHeader(
              title: "أدوات التشخيص",
              subtitle: "فحص الاتصال وتحليل الحزم وسجل النظام",
              icon: Icons.biotech_rounded,
              goBack: Get.back,
            ),
            TabBar(
              controller: controller.tabController,
              isScrollable: true,
              labelColor: const Color(0xFF1E3A8A),
              unselectedLabelColor: const Color(0xFF94A3B8),
              indicatorColor: const Color(0xFF2563EB),
              tabs: const [
                Tab(text: "Ping"),
                Tab(text: "اختبار النطاق"),
                Tab(text: "Torch"),
                Tab(text: "Fetch"),
                Tab(text: "تنقيط الحزم"),
                Tab(text: "السجل"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: controller.tabController,
                children: [
                  _pingTab(),
                  _tracerouteTab(),
                  _torchTab(),
                  _fetchTab(),
                  _snifferTab(),
                  _logsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== Ping =====================
  Widget _pingTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _inputRow(controller.pingAddressCtrl, "العنوان (IP أو النطاق)", Icons.wifi_tethering_rounded),
        _inputRow(controller.pingCountCtrl, "عدد المحاولات", Icons.tag_rounded, isNumber: true),
        Obx(
          () => GradientButton(
            label: controller.isPinging.value ? "جاري الفحص..." : "ابدأ Ping",
            icon: Icons.play_arrow_rounded,
            height: 48,
            onPressed: controller.isPinging.value ? null : controller.runPing,
          ),
        ),
        const SizedBox(height: 14),
        Obx(() {
          if (controller.pingSummary.value.isEmpty) return const SizedBox.shrink();
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              controller.pingSummary.value,
              style: const TextStyle(color: Colors.white, height: 1.7, fontSize: 12.5),
            ),
          );
        }),
        const SizedBox(height: 12),
        Obx(
          () => Column(
            children: controller.pingRows
                .map((row) => _monoRow(
                      "seq ${row["seq"] ?? "-"}",
                      "${row["time"] ?? "-"}  (${row["size"] ?? "-"})",
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ===================== Traceroute =====================
  Widget _tracerouteTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _inputRow(controller.traceAddressCtrl, "العنوان المطلوب تتبعه", Icons.route_rounded),
        Obx(
          () => GradientButton(
            label: controller.isTracing.value ? "جاري التتبع..." : "ابدأ اختبار النطاق",
            icon: Icons.play_arrow_rounded,
            height: 48,
            colors: const [Color(0xFFB45309), Color(0xFFF59E0B)],
            onPressed: controller.isTracing.value ? null : controller.runTraceroute,
          ),
        ),
        const SizedBox(height: 14),
        Obx(() {
          if (controller.traceRows.isEmpty) {
            return const Text(
              "لا توجد نتائج بعد. أدخل عنوانًا وابدأ الاختبار.",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            );
          }
          return Column(
            children: controller.traceRows.map((row) {
              final hop = row["address"] ?? row[".id"] ?? "-";
              final avg = row["avg"] ?? row["last"] ?? "-";
              final loss = row["loss"] ?? "0";
              final status = row["status"] ?? "";
              return _monoRow("#${row[".id"] ?? "-"}  $hop", "$avg  •  فقدان: $loss  $status");
            }).toList(),
          );
        }),
      ],
    );
  }

  // ===================== Torch =====================
  Widget _torchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Obx(
                () => _dropdownRow(
                  label: "المنفذ",
                  value: controller.selectedInterface.value,
                  items: controller.interfaces.map((element) => element.name).toList(),
                  onChanged: (value) {
                    if (value != null) controller.selectedInterface.value = value;
                  },
                ),
              ),
              const SizedBox(height: 10),
              Obx(
                () => GradientButton(
                  label: controller.isTorchRunning.value ? "إيقاف Torch" : "تشغيل Torch",
                  icon: controller.isTorchRunning.value ? Icons.stop_rounded : Icons.bolt_rounded,
                  height: 46,
                  colors: controller.isTorchRunning.value
                      ? const [Color(0xFF991B1B), Color(0xFFEF4444)]
                      : const [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                  onPressed: controller.isTorchRunning.value ? controller.stopTorch : controller.startTorch,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.torchRows.isEmpty) {
              return const Center(
                child: Text(
                  "لا توجد بيانات بعد. شغّل Torch لعرض الحركة الحيّة.",
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: controller.torchRows.length,
              itemBuilder: (context, index) {
                final row = controller.torchRows[index];
                final src = row["src-address"] ?? "-";
                final dst = row["dst-address"] ?? "-";
                final rx = row["rx-rate"] ?? row["rx"] ?? "-";
                final tx = row["tx-rate"] ?? row["tx"] ?? "-";
                return _monoRow("$src → $dst", "↓ $rx   ↑ $tx", dense: true);
              },
            );
          }),
        ),
      ],
    );
  }

  // ===================== Fetch =====================
  Widget _fetchTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _inputRow(controller.fetchUrlCtrl, "الرابط (URL)", Icons.link_rounded),
        _inputRow(controller.fetchPathCtrl, "اسم الملف على الراوتر", Icons.description_rounded),
        Obx(
          () => GradientButton(
            label: controller.isFetching.value ? "جاري التنزيل..." : "تنفيذ Fetch",
            icon: Icons.download_rounded,
            height: 48,
            colors: const [Color(0xFF0F766E), Color(0xFF10B981)],
            onPressed: controller.isFetching.value ? null : controller.runFetch,
          ),
        ),
        const SizedBox(height: 14),
        Obx(
          () => Column(
            children: controller.fetchRows
                .expand((row) => row.entries)
                .map((entry) => _monoRow(entry.key, entry.value))
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "ملاحظة: يجب أن يكون الراوتر متصلًا بالإنترنت، ويُحفظ الملف في ذاكرة الراوتر "
          "(يمكن عرضه من المزيد ← نسخ الراوتر الاحتياطي).",
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.7),
        ),
      ],
    );
  }

  // ===================== Sniffer =====================
  Widget _snifferTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Obx(
          () => _dropdownRow(
            label: "المنفذ",
            value: controller.selectedInterface.value,
            items: controller.interfaces.map((element) => element.name).toList(),
            onChanged: (value) {
              if (value != null) controller.selectedInterface.value = value;
            },
          ),
        ),
        const SizedBox(height: 10),
        _inputRow(controller.snifferFileCtrl, "اسم ملف الالتقاط", Icons.insert_drive_file_rounded),
        _inputRow(controller.snifferLimitCtrl, "حد الذاكرة (KB)", Icons.memory_rounded, isNumber: true),
        Obx(
          () => GradientButton(
            label: "تشغيل التقاط الحزم",
            icon: Icons.play_arrow_rounded,
            height: 46,
            colors: const [Color(0xFF9D174D), Color(0xFFDB2777)],
            onPressed: controller.isSnifferBusy.value ? null : controller.startSniffer,
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => GradientButton(
            label: "إيقاف الالتقاط",
            icon: Icons.stop_rounded,
            height: 46,
            colors: const [Color(0xFF991B1B), Color(0xFFEF4444)],
            onPressed: controller.isSnifferBusy.value ? null : controller.stopSniffer,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          "حالة الـ Sniffer على الراوتر",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.snifferStatus.isEmpty) {
            return const Text(
              "لا توجد بيانات حالة (قد لا يدعم الراوتر التقاط الحزم).",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            );
          }
          return Column(
            children: controller.snifferStatus.entries
                .map((entry) => _monoRow(entry.key, entry.value))
                .toList(),
          );
        }),
      ],
    );
  }

  // ===================== Logs =====================
  Widget _logsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: controller.logSearchCtrl,
                    onChanged: controller.setLogQuery,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: "بحث في السجل...",
                      prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: controller.loadLogs,
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E3A8A)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingLogs.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = controller.filteredLogs;
            if (rows.isEmpty) {
              return const Center(
                child: Text("لا توجد أحداث في السجل", style: TextStyle(color: Color(0xFF64748B))),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              row["message"] ?? "-",
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), height: 1.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${row["time"] ?? ""} • ${row["topics"] ?? ""}",
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // ===================== عناصر مشتركة =====================
  Widget _inputRow(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: ctrl,
        textAlign: TextAlign.right,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }

  Widget _dropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: items.contains(value) ? value : null,
          hint: Text(label),
          items: items
              .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _monoRow(String title, String value, {bool dense = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
