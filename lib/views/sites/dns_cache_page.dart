import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/controllers/sites/dns_cache_controller.dart'; 
import '/models/sites_model.dart'; 

import '../widgets/shared/layouts/sub_page_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../widgets/shared/typography/section_title.dart';

class DnsCachePage extends GetView<DnsCacheController> {
  const DnsCachePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1B2740),

        floatingActionButton: Obx(() {
          if (controller.dnsCacheList.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: FloatingActionButton.extended(
              onPressed: controller.confirmClearCache,
              backgroundColor: const Color(0xFFEF4444),
              elevation: 8,
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
              label: const Text(
                "مسح التخزين المؤقت للراوتر",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          );
        }),

        body: Column(
          children: [
            // الهيدر الموحد
            const PremiumHeader(
              title: "سجلات DNS",
              subtitle: "مراقبة وإدارة التخزين المؤقت لـ MikroTik",
              icon: Icons.dns_rounded,
            ),

            const SectionTitle(title: "إحصائيات السجلات الحالية"),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    // بطاقة الإحصائية
                    Obx(() => _buildStatCard(controller.dnsCacheList.length)),

                    const SizedBox(height: 10),
                    const SectionTitle(title: "قائمة عناوين الـ DNS"),

                    Expanded(
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
                        }

                        if (controller.dnsCacheList.isEmpty) {
                          return _buildEmptyState();
                        }

                        return RefreshIndicator(
                          onRefresh: controller.fetchDnsCache,
                          color: const Color(0xFF3B82F6),
                          backgroundColor: const Color(0xFF16213A),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 90, top: 6),
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            itemCount: controller.dnsCacheList.length,
                            itemBuilder: (context, i) {
                              final site = controller.dnsCacheList[i];
                              return _buildDnsItemCard(site);
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            const AppMiniFooter(title: Text("DNS Monitor Engine")),
          ],
        ),
      ),
    );
  }

  /* ================= بطاقة الإحصائيات ================= */
  Widget _buildStatCard(int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff1E3A8A), Color(0xff3B82F6)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1E3A8A).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF16213A).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.speed_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "إجمالي السجلات في الذاكرة",
                style: TextStyle(color: Color(0xB3E8EEF9), fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                "$count سجل مخزن",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white),
            tooltip: "تحديث السجلات",
            onPressed: controller.fetchDnsCache,
          ),
        ],
      ),
    );
  }

  /* ================= كرت سجل DNS الفردي ================= */
  Widget _buildDnsItemCard(DNSCacheModel site) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF243352)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xff1E3A8A).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.language_rounded, color: Color(0xFF60A5FA), size: 22),
        ),
        title: Text(
          site.name.isNotEmpty ? site.name : "Unknown Host",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFFE8EEF9),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              site.data.isNotEmpty ? site.data : "0.0.0.0", 
              style: const TextStyle(
                color: Color(0xFF94A3B8), 
                fontSize: 12, 
                letterSpacing: 0.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.category_outlined, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Text(
                  site.type.isNotEmpty ? site.type : "A",
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.history_toggle_off_rounded, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Text(
                  site.ttl.isNotEmpty ? site.ttl : "00:00:00",
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
          tooltip: "حذف السجل",
          onPressed: () => controller.confirmDeleteSite(site),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 56, color: Colors.blue.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text(
            "ذاكرة DNS المؤقتة فارغة تماماً",
            style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: controller.fetchDnsCache,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text("تحديث السجلات"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: const Color(0xFF60A5FA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
