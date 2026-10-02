import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/shared/layouts/main_gate_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../../controllers/reports/system_status_report_controller.dart';
import '../../core/string_extensions.dart';

// 1. التغيير هنا: الوراثة من GetView
class SystemStatusReportPage extends GetView<SystemStatusReportController> {
  const SystemStatusReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // الهيدر
            const MainGateHeader(
              title: "حالة النظام",
              subtitle: "مراقبة حية لأداء راوتر المايكروتيك",
              icon: Icons.monitor_heart_rounded,
            ),

            Expanded(
              child: Obx(() {
                // نستخدم controller مباشرة لأن GetView توفره لنا
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  );
                }

                if (controller.systemState.value == null) {
                  return _buildErrorState(); // لم نعد بحاجة لتمرير المتحكم كبارامتر
                }

                final state = controller.systemState.value!;
                
                return RefreshIndicator(
                  onRefresh: controller.fetchSystemStatus,
                  color: const Color(0xFF1E3A8A),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    children: [
                      // 1. كارت المعالج (CPU)
                      _buildCpuCard(state.cpu),
                      const SizedBox(height: 15),

                      // 2. كارت الذاكرة (Memory)
                      _buildMemoryCard(state.totalMemory.formatBytes, state.freeMemory.formatBytes),
                      const SizedBox(height: 15),

                      // 3. كارت التخزين والقرص (Disk)
                      _buildDiskCard(state.totalDiskSpace, state.freeDiskSpace),
                      const SizedBox(height: 15),

                      // 4. كروت المعلومات الإضافية
                      Row(
                        children: [
                          Expanded(child: _buildInfoCard("وقت التشغيل", state.uptime.formatUptime, Icons.timer_rounded, const Color(0xFFF59E0B))),
                          const SizedBox(width: 15),
                          Expanded(child: _buildInfoCard("إصدار النظام", state.version, Icons.info_outline_rounded, const Color(0xFF0EA5E9))),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),

            // زر التحديث اليدوي في الأسفل
            _buildActionButtons(), // لم نعد بحاجة لتمرير المتحكم كبارامتر

            // الفوتر
            const AppMiniFooter(title: Text( "تقارير وحالة النظام")),
          ],
        ),
      ),
    );
  }

  // --- كارت المعالج (CPU) ---
  Widget _buildCpuCard(String cpuLoad) {
    int load = int.tryParse(cpuLoad) ?? 0;
    Color statusColor = load > 80 ? Colors.redAccent : (load > 50 ? Colors.orange : const Color(0xFF10B981));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.memory_rounded, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Text("استهلاك المعالج", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 10),
              Text(load > 80 ? "الضغط مرتفع جداً" : "أداء النظام مستقر", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: load / 100,
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: statusColor,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text("$cpuLoad%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }

  // --- كارت الذاكرة (Memory) ---
  Widget _buildMemoryCard(String totalMem, String freeMem) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], 
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.sd_storage_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text("الذاكرة (RAM)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoStat("الذاكرة الحرة", freeMem),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)), 
              _infoStat("إجمالي الذاكرة", totalMem),
            ],
          ),
        ],
      ),
    );
  }

  // --- كارت القرص والتخزين ---
  Widget _buildDiskCard(String totalDisk, String freeDisk) {
    double total = double.tryParse(totalDisk.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    double free = double.tryParse(freeDisk.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    double used = total > 0 ? total - free : 0;
    int percent = total > 0 ? ((used / total) * 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.storage_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text("مساحة القرص (Disk)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Text("$percent%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: total > 0 ? used / total : 0,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoStat("المستخدمة", used.toStringAsFixed(1).formatBytes),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)), 
              _infoStat("الإجمالية", total.toStringAsFixed(1).formatBytes),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  // --- كروت المعلومات الصغيرة ---
  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  // --- شاشة الخطأ ---
  // تم إزالة البارامتر، الدالة الآن تستخدم controller الموروث مباشرة
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey),
          const SizedBox(height: 15),
          const Text("لم نتمكن من جلب بيانات النظام", style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: controller.fetchSystemStatus, // استخدام مباشر
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("إعادة المحاولة"),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
          )
        ],
      ),
    );
  }

  // --- منطقة زر التحديث أسفل الشاشة ---
  // تم إزالة البارامتر، الدالة الآن تستخدم controller الموروث مباشرة
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => controller.fetchSystemStatus(), // استخدام مباشر
          icon: const Icon(Icons.sync_rounded, color: Colors.white),
          label: const Text("تحديث حالة النظام", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A), 
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}