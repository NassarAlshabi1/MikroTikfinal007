import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';

import 'package:mikronet/features/sites/controllers/blocked_sites_controller.dart'; 
import 'package:mikronet/features/sites/models/sites_model.dart';

// تأكد من مسارات الويدجت المشتركة
import 'package:mikronet/core/ui/widgets/sub_page_header.dart';
import 'package:mikronet/core/ui/widgets/app_mini_footer.dart';
import 'package:mikronet/core/ui/widgets/section_title.dart';

class BlockedSitesPage extends GetView<BlockedSitesController> {
  const BlockedSitesPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.soft,

        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: FloatingActionButton.extended(
            onPressed: () => _showAddSiteDialog(context),
            backgroundColor: AppColors.primary,
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: const CircleAvatar(
          backgroundColor: AppColors.dangerOverlay,
          child: Icon(Icons.public_off_rounded, color: Colors.red, size: 20),
        ),
        title: Text(
          site.blockValue, 
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.text,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            site.name, 
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                fillColor: AppColors.soft,
                prefixIcon: const Icon(Icons.label_outline_rounded, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 11),
            
            // الحقل الثاني: القيمة المراد حظرها (إجباري)
            TextField(
              controller: controller.valueCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: controller.inputHint, 
                filled: true,
                fillColor: AppColors.soft,
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
              backgroundColor: AppColors.primary,
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
              size: 70, color: Colors.green.withValues(alpha: 0.4)),
          const SizedBox(height: 11),
          Text(
            "لا توجد قيود في ${controller.pageTitle} حالياً",
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}