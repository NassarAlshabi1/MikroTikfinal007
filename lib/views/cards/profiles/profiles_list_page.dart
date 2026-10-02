import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/cards/profiles/profiles_list_controller.dart';
import '/models/profiles_model.dart';
import '/views/widgets/shared/layouts/sub_page_header.dart';
import '../../../core/string_extensions.dart';

class ProfilesListPage extends GetView<ProfilesListController> {
  const ProfilesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // حل مشكلة الخطأ في الصورة: حقن المتحكم هنا لضمان وجوده
    //Get.lazyPut(() => PackagesController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF1E3A8A),
          onPressed: () {
            controller.goToAddProfile();
            // controller.prepareSheet();
            // _openUpsertSheet(context);
          },
          label: const Text("إضافة باقة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
        ),
        body: Column(
          children: [
            Obx(() => PremiumHeader(
              title: "إدارة باقات الشبكة",
              subtitle: "عدد الباقات المتوفرة: ${controller.packages.length}",
              icon: Icons.wifi_tethering_rounded,
            )),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: controller.packages.length,
                  itemBuilder: (context, i) {
                    final p = controller.packages[i];
                    return _buildPackageCard(context, p, i);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /* ---------------- تصميم الكرت (نفس تصميمك) ---------------- */
  Widget _buildPackageCard(BuildContext context, ProfilesModel p, int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            trailing: Text("${p.price} ريال", style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w900, fontSize: 18)),
          ),
          const Divider(indent: 20, endIndent: 20, height: 1),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoCell(Icons.event_available_rounded, "الصلاحية", p.validity.formatUptime),
                _infoCell(Icons.timer_outlined, "الوقت", p.uptime.formatUptime),
                _infoCell(Icons.data_usage_rounded, "الرصيد", p.palance.formatBytes),
              ],
            ),
          ),
          _buildActions(context, p, i),
        ],
      ),
    );
  }

  /* ---------------- نافذة الإضافة والتعديل (نفس تقسيم حقولك) ---------------- */
  // ... (الاستيرادات والجزء العلوي من الكود كما هو)

  void _openUpsertSheet(BuildContext context, {int? index}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("تفاصيل الباقة المتقدمة", textAlign: TextAlign.right, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              _field(controller.nameCtrl, "اسم الباقة", Icons.badge_outlined),
              _field(controller.priceCtrl, "سعر البيع", Icons.payments_outlined, isNum: true),
              
             // في دالة _openUpsertSheet...

            _sectionLabel("تحديد الرصيد (Data Limit)"),
            Row(children: [
              Expanded(child: _field(controller.gigasCtrl, "جيجا بايت (GB)", Icons.storage_rounded, isNum: true)),
              const SizedBox(width: 10),
              Expanded(child: _field(controller.megasCtrl, "ميجا بايت (MB)", Icons.sd_card_rounded, isNum: true)),
            ]),

            _sectionLabel("تحديد الصلاحية (بقاء الكرت)"),
            Row(children: [
              Expanded(child: _field(controller.daysCtrl, "أيام", Icons.calendar_month, isNum: true)),
              const SizedBox(width: 10),
              Expanded(child: _field(controller.hoursCtrl, "ساعات", Icons.more_time, isNum: true)),
            ]),

            _sectionLabel("تحديد الوقت (Uptime - مدة الاتصال)"),
            Row(children: [
              Expanded(child: _field(controller.uptimeDaysCtrl, "أيام", Icons.timer, isNum: true)),
              const SizedBox(width: 10),
              Expanded(child: _field(controller.uptimeHoursCtrl, "ساعات", Icons.history_toggle_off, isNum: true)),
]),
              
              _sectionLabel("تحديد السرعة"),
              _field(controller.speedCtrl, "مثال: 4M/4M", Icons.speed),
              
              const SizedBox(height: 20),
              _saveButton(index),
            ],
          ),
        ),
      ),
    );
  }
// ... (باقي الميثودات المساعدة في الواجهة)

  // --- ميثودات مساعدة (تصميمك الأصلي) ---
  Widget _sectionLabel(String title) => Container(
    alignment: Alignment.centerRight,
    margin: const EdgeInsets.only(top: 20, bottom: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
        const SizedBox(width: 8),
        Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(10))),
      ],
    ),
  );

  Widget _field(TextEditingController c, String l, IconData i, {bool isNum = false}) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: c,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i, color: const Color(0xFF1E3A8A), size: 20),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    ),
  );

  Widget _saveButton(int? index) => InkWell(
    onTap: () => controller.executeSave(index: index),
    child: Container(
      height: 60,
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)]), borderRadius: BorderRadius.circular(15)),
      child: const Center(child: Text("حفظ الإعدادات", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    ),
  );

  Widget _buildActions(BuildContext context, ProfilesModel p, int i) => Container(
    decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(onPressed: () {
          controller.goToEditProfile(p);
        }, icon: const Icon(Icons.edit_outlined), label: const Text("تعديل")),
        const VerticalDivider(),
        TextButton.icon(onPressed: () => controller.confirmDelete(i), icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text("حذف", style: TextStyle(color: Colors.red))),
      ],
    ),
  );

  Widget _infoCell(IconData icon, String label, String value) => Column(
    children: [
      Icon(icon, size: 18, color: Colors.blueGrey.shade400),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ],
  );
}