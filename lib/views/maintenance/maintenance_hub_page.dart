import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/maintenance/maintenance_hub_controller.dart';
import '../../models/maintenance_tools.dart';
import '../widgets/shared/layouts/sub_page_header.dart';

/// لوحة "أدوات الصيانة" — تجمع أدوات التشخيص ومراقبة الأداء وإعدادات الشبكة
/// وجدار الحماية وإدارة النطاق الترددي.
class MaintenanceHubPage extends GetView<MaintenanceHubController> {
  const MaintenanceHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            PremiumHeader(
              title: "لوحة تحكم الميكروتيك",
              subtitle: "جميع أدوات الصيانة والتشخيص بالجهاز",
              icon: Icons.build_circle_rounded,
              goBack: Get.back,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    children: [
                      _resourcesBar(),
                      ...controller.sections.map((section) => _sectionCard(section)),
                      const SizedBox(height: 30),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============== شريط الموارد السريع ===============
  Widget _resourcesBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _resourceItem("المعالج", controller.resources["cpu"] ?? "-"),
          _resourceItem("ذاكرة حرة", controller.resources["memory"] ?? "-"),
          _resourceItem("مدة التشغيل", controller.resources["uptime"] ?? "-"),
          _resourceItem("الإصدار", controller.resources["version"] ?? "-"),
        ],
      ),
    );
  }

  Widget _resourceItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // =============== بطاقة قسم ===============
  Widget _sectionCard(MaintenanceSection section) {
    final count = controller.sectionCount(section);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 4, height: 26, decoration: BoxDecoration(color: section.color, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 10),
              Icon(section.icon, color: section.color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              if (count >= 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: section.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$count",
                    style: TextStyle(color: section.color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: section.tools.map((tool) => _toolTile(tool)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _toolTile(MaintenanceTool tool) {
    final count = controller.toolCount(tool);

    return Material(
      color: tool.color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => controller.openTool(tool),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tool.icon, color: tool.color, size: 26),
              const SizedBox(height: 8),
              Text(
                tool.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (count >= 0) ...[
                const SizedBox(height: 4),
                Text(
                  "$count عنصر",
                  style: TextStyle(fontSize: 10, color: tool.color, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
