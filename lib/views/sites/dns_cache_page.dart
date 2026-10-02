import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/controllers/sites/dns_cache_controller.dart'; 
import '/models/sites_model.dart'; 

// استيراد الويجيت الموحدة v4.5 لضمان تناسق الهوية
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
        backgroundColor: const Color(0xFFF1F5F9),

        // 1. الزر العائم
        /*floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: FloatingActionButton.extended(
            onPressed: controller.clearCache,
            backgroundColor: const Color(0xFF1E3A8A),
            elevation: 8,
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
            label: const Text(
              "مسح التخزين المؤقت",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      */
        body: Column(
          children: [
            // 2. الهيدر الموحد
            const PremiumHeader(
              title: "سجلات DNS",
              subtitle: "مراقبة وإدارة التخزين المؤقت لـ MikroTik",
              icon: Icons.dns_rounded,
            ),

            const SectionTitle(title: "إحصائيات السجلات الحالية"),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // بطاقة الإحصائية بتصميم v4.5 المطور
                    Obx(() => _buildStatCard(controller.dnsCacheList.length)),

                    const SizedBox(height: 10),
                    const SectionTitle(title: "قائمة عناوين الـ DNS"),

                    Expanded(
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (controller.dnsCacheList.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          // تم زيادة البادينغ السفلي لتوفير مساحة للزر العائم والفوتر
                          padding: const EdgeInsets.only(bottom: 180, top: 10),
                          physics: const BouncingScrollPhysics(),
                          itemCount: controller.dnsCacheList.length,
                          itemBuilder: (context, i) {
                            final site = controller.dnsCacheList[i];
                            return _buildDnsItemCard(site);
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // 3. الفوتر الموحد v4.5
            const AppMiniFooter(title: Text("DNS Monitor Engine")),
          ],
        ),
      ),
    );
  }

  /* ================= بطاقة الإحصائيات ================= */
  Widget _buildStatCard(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff1E3A8A), Color(0xff3B82F6)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.speed_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("إجمالي السجلات",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                "$count سجل نشط",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* =================*** التعديل هنا: كرت سجل DNS الفردي المطور ***================= */
  Widget _buildDnsItemCard(DNSCacheModel site) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        // تم زيادة البادينغ العمودي لاستيعاب السطور الإضافية في الـ subtitle
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xffF0F7FF),
            borderRadius: BorderRadius.circular(14),
          ),
          // يمكنك تغيير الأيقونة بناءً على النوع لاحقاً إذا أردت (شرطية)
          child: const Icon(Icons.language_rounded,
              color: Color(0xff1E3A8A), size: 24),
        ),
        
        // 1. العنوان (اسم النطاق)
        title: Text(
          site.name.isNotEmpty ? site.name : "Unknown Host",
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E293B)),
        ),
        
        // 2. التعديل هنا: استخدام Column لعرض البيانات، النوع، والوقت
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // سطر البيانات (IP)
            Text(
              site.data.isNotEmpty ? site.data : "0.0.0.0", 
              style: TextStyle(
                  color: Colors.blueGrey.shade600, 
                  fontSize: 12, 
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500),
            ),
            
            const SizedBox(height: 6),
            
            // سطر التفاصيل الجديدة (Type & TTL)
            Row(
              children: [
                // النوع (Type)
                Icon(Icons.category_outlined, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 3),
                Text(
                  site.type.isNotEmpty ? site.type : "N/A",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                
                const SizedBox(width: 12), // مسافة بين النوع والوقت
                
                // الوقت المتبقي (TTL)
                Icon(Icons.history_toggle_off_rounded, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 3),
                Text(
                  site.ttl.isNotEmpty ? site.ttl : "00:00:00",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        
        /*trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          onPressed: () => controller.deleteSite(site.id),
        ),*/
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded,
              size: 60, color: Colors.blue.withOpacity(0.2)),
          const SizedBox(height: 15),
          const Text("الذاكرة نظيفة تماماً",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}