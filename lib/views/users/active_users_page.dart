import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/core/string_extensions.dart';
import '/controllers/users/active_users_controller.dart';
import '/models/users_model.dart';
import '../widgets/shared/layouts/sub_page_header.dart';


class ActiveUsersPage extends GetView<ActiveUsersController> {
  const ActiveUsersPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8FAFC),
        body: Column(
          children: [
            Obx(() => PremiumHeader(
              title: "الجلسات النشطة",
              subtitle: "المتصلين حالياً بالكروت: ${controller.actives.length}",
              icon: Icons.bolt_rounded,
            )),
            
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
                if (controller.actives.isEmpty) return const Center(child: Text("لا توجد جلسات نشطة"));

                return RefreshIndicator(
                  onRefresh: controller.fetchActiveSessions,
                  child: 
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 80),
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  itemCount: controller.actives.length,
                  itemBuilder: (context, i) => _buildUserCard(controller.actives[i]),
                ));
              }),

            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(ActiveUserModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.green.shade50),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xffF0FDF4), 
              child: Icon(Icons.person, color: Colors.green)
            ),
            // عرض الـ Label بجانب الـ Username
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    a.label, 
                    style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.normal),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(a.username, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(a.address, style: const TextStyle(fontSize: 14)),
                Text(a.macAddress, style:const  TextStyle(fontSize: 14)),

              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showActionSheet(a),
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat(Icons.access_time, "الارتباط", a.uptime.formatUptime),
                // عرض إجمالي الرصيد بدلاً من الوقت المتبقي
                _miniStat(Icons.cloud_upload_outlined, "الرفع", a.upload.formatBytes),
                _miniStat(Icons.cloud_download_outlined, "التحميل", a.download.formatBytes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- نافذة الخيارات المنبثقة وحوار التسمية (تبقى كما هي في المنطق) ---
  void _showActionSheet(ActiveUserModel a) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(a.username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            _actionItem("إعادة تسمية الجهاز", Icons.edit_outlined, Colors.blue, () {
              Get.back();
              _showRenameDialog(a);
            }),
            _actionItem("قطع الاتصال (فصل)", Icons.link_off, Colors.orange, () {
              Get.back();
              controller.disconnect(a);
            }),
            _actionItem("حظر المستخدم نهائياً", Icons.block, Colors.red, () {
              Get.back();
              controller.block(a);
            }),
            _actionItem("تحويل لخدمة مجانية", Icons.star_border, Colors.purple, () {
              Get.back();
              controller.makeFree(a);
            }),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(ActiveUserModel a) {
    final ctrl = TextEditingController(text: a.label == "Unknown" ? "" : a.label);
    Get.defaultDialog(
      title: "تسمية الجهاز",
      content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "الاسم الجديد (Label)")),
      textConfirm: "حفظ",
      onConfirm: () {
        Get.back();
        controller.rename(a, ctrl.text);
      },
    );
  }

  Widget _actionItem(String t, IconData i, Color c, VoidCallback onTap) => ListTile(
    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(i, color: c, size: 20)),
    title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    onTap: onTap,
  );

  Widget _miniStat(IconData i, String l, String v) => Column(
    children: [
      Icon(i, size: 14, color: Colors.grey),
      const SizedBox(height: 4),
      Text(l, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    ],
  );
}