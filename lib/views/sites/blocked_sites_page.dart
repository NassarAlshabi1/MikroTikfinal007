import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/controllers/sites/blocked_sites_controller.dart'; 
import '/models/sites_model.dart';

// تأكد من مسارات الويدجت المشتركة
import '../widgets/shared/layouts/sub_page_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../widgets/shared/typography/section_title.dart';

class BlockedSitesPage extends GetView<BlockedSitesController> {
  const BlockedSitesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // تهيئة المتحكم في حال لم يتم حقنه مسبقاً
    Get.put(BlockedSitesController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),

        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: FloatingActionButton.extended(
            onPressed: () => _showAddSiteDialog(context),
            backgroundColor: const Color(0xFF1E3A8A),
            elevation: 8,
            icon: const Icon(Icons.add_moderator_rounded, color: Colors.white),
            label: const Text(
              "إضافة حظر",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),

        body: Column(
          children: [
            PremiumHeader(
              title: controller.pageTitle,
              subtitle: controller.pageSubtitle,
              icon: Icons.security_rounded,
            ),

            SectionTitle(title: "قائمة ${controller.pageTitle} الحالية"),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.blockedList.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 160),
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.blockedList.length,
                  itemBuilder: (context, i) {
                    final site = controller.blockedList[i];
                    return _buildSiteCard(site);
                  },
                );
              }),
            ),

            const AppMiniFooter(title: Text("Security Engine")),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteCard(BlockedSiteModel site) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade50,
          child: const Icon(Icons.public_off_rounded, color: Colors.red, size: 20),
        ),
        title: Text(
          site.blockValue, 
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            site.name, 
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          // تم التعديل هنا: تمرير الكائن (site) بدلاً من site.id
          onPressed: () => controller.removeBlock(site),
        ),
      ),
    );
  }

  /* ================= نافذة إضافة موقع جديد (محدثة) ================= */
  void _showAddSiteDialog(BuildContext context) {
    // تصفير الحقول قبل فتح النافذة لتكون فارغة دائماً
    controller.nameCtrl.clear();
    controller.valueCtrl.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(
          "إضافة ${controller.pageTitle}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الحقل الأول: الاسم (اختياري/توضيحي)
            TextField(
              controller: controller.nameCtrl,
              decoration: InputDecoration(
                hintText: "اسم القاعدة (مثال: Facebook Block)",
                filled: true,
                fillColor: Colors.grey.shade100,
                prefixIcon: const Icon(Icons.label_outline_rounded, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 15),
            
            // الحقل الثاني: القيمة المراد حظرها (إجباري)
            TextField(
              controller: controller.valueCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: controller.inputHint, 
                filled: true,
                fillColor: Colors.grey.shade100,
                prefixIcon: const Icon(Icons.block_rounded, color: Colors.redAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("تراجع", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => controller.addBlock(),
            child: const Text("حظر الآن", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined,
              size: 70, color: Colors.green.withOpacity(0.4)),
          const SizedBox(height: 15),
          Text(
            "لا توجد قيود في ${controller.pageTitle} حالياً",
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}