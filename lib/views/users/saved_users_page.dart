import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/views/widgets/shared/layouts/floating_button.dart';
import '../../controllers/users/saved_users_controller.dart';
import '/models/users_model.dart';

// استيراد المكونات الموحدة v4.5
import '../widgets/shared/layouts/sub_page_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../widgets/shared/typography/section_title.dart';

class SavedUsersPage extends GetView<SavedUsersController> {
  const SavedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8FAFC),

        // زر الإضافة جهة اليسار بارتفاع متناسق
        //floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 50, left: 10),
          child: FloatingButton(
            text: "اضافة يدويا",
            onPressed: ()=> _showAddDeviceSheet(context),
            iconBtn: Icons.add_circle_outline_rounded,
            )
        ),

        body: Column(
          children: [
            // 1. الهيدر الفرعي الموحد
            const PremiumHeader(
              title: "إدارة الأجهزة",
              subtitle: "التحكم في الأجهزة المسجلة والمحظورة",
              icon: Icons.devices_other_rounded,
            ),

            // 2. الفلاتر بستايل الكبسولة الموحد
            _buildFiltersSection(),
            _searchField(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SectionTitle(title: "قائمة الأجهزة"),
            ),

            // 3. القائمة الرئيسية
            Expanded(child: _buildDevicesList()),

            // 4. الفوتر الموحد v4.5
            const AppMiniFooter(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle,color: Colors.green,size: 15,),
                      SizedBox(width: 5,),
                      Text("مجاني",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blueGrey),),
                    ],
                  ),
                 Row(
                    children: [
                      Icon(Icons.circle,color: Colors.red,size: 15,),
                      SizedBox(width: 5,),
                      Text("محظور",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blueGrey),),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.circle,color: Colors.blue,size: 15,),
                      SizedBox(width: 5,),
                      Text("عادي",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blueGrey),),
                    ],
                  ),
                ],
              )
              ),
          ],
        ),
      ),
    );
  }

  /* ================= 2. FILTERS SECTION ================= */
  Widget _buildFiltersSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _filterTab( "ALL", "الكل"),
          _filterTab( "SAVED", "محفوظة"),
          _filterTab( "UNSAVED", "غير محفوظة"),
          _filterTab( "BLOCKED", "محظورة"),
          _filterTab( "FREE", "مجانية"),
        ],
      ),
    );
  }

  Widget _filterTab(String key, String title) {
    return Obx(() {
      bool isSelected = controller.filter.value == key;
      return InkWell(
        onTap: () => controller.setFilter(key),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected ? Colors.transparent : Colors.blue.shade50),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.2),
                        blurRadius: 8)
                  ]
                : [],
          ),
          child: Text(title,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      );
    });
  }

  /* ================= 3. DEVICES LIST ================= */
  Widget _buildDevicesList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      final devices = controller.filteredDevices;
      
      if (devices.isEmpty) {
        return const Center(child: Text("لا توجد أجهزة حالياً"));
      }

      return RefreshIndicator(
        onRefresh: controller.fetchDevices,
        child: 
      ListView.builder(
        itemCount: devices.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, i) {
          final d = devices[i];
          var deviceType = 
          switch(d.type){
            UserType.bypassed => "مجاني",
            UserType.blocked => "محظور",
            _ => "عادي"
          };
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.blue.shade50),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02), blurRadius: 10)
              ],
            ),
            child: ListTile(
              //isThreeLine: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: _getStatusColor(d).withOpacity(0.1),
                child: Icon(Icons.smartphone_rounded,
                    color: _getStatusColor(d), size: 22),
              ),
              title: Text(d.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              subtitle: Text("${d.srcAddress} • ${d.macAddress}\n$deviceType",
                  style:
                      const TextStyle(fontSize: 11, color: Colors.blueGrey)),
              trailing: const Icon(Icons.more_horiz_rounded,
                  color: Colors.blueGrey),
              onTap: () => _showOptionsSheet(Get.context ?? _, d),
            ),
          );
        },
      ));
    });
  }

  Color _getStatusColor(SavedUserModel d) {
    if (d.type == UserType.blocked) return Colors.red;
    if (d.type == UserType.bypassed) return Colors.green;
    return Colors.blue;
  }

  /* ================= 4. ADD DEVICE SHEET ================= */
  void _showAddDeviceSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final ipCtrl = TextEditingController();
    final macCtrl = TextEditingController();
    UserType status = UserType.regular;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSheet) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.blueGrey.shade100,
                          borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 25),
                  const Text("إضافة جهاز جديد",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 25),
                  _modernField(nameCtrl, "اسم الجهاز", Icons.badge_outlined),
                  _modernField(ipCtrl, "IP Address", Icons.wifi_rounded),
                  _modernField(macCtrl, "MAC Address", Icons.memory_rounded),

                  // Dropdown المنسق
                  Container(
                    margin: const EdgeInsets.only(bottom: 25),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                        color: const Color(0xffF1F5F9),
                        borderRadius: BorderRadius.circular(15)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<UserType>(
                        value: status,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                              value: UserType.regular, child: Text("عادي")),
                          DropdownMenuItem(value: UserType.bypassed, child: Text("مجاني")),
                          DropdownMenuItem(
                              value: UserType.blocked, child: Text("محظور")),
                        ],
                        onChanged: (v) => setStateSheet(() => status = v!),
                      ),
                    ),
                  ),

                  // زر الحفظ الموحد
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        controller.addManualDevice(
                            name: nameCtrl.text,
                            ip: ipCtrl.text,
                            mac: macCtrl.text,
                            status: status);
                        Navigator.pop(context);
                      },
                      child: const Text("حفظ الجهاز",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /* ================= 5. OPTIONS SHEET ================= */
  /* ================= 5. OPTIONS SHEET (المحدثة بالمنطق الشرطي) ================= */
  void _showOptionsSheet(BuildContext context, SavedUserModel d) {
    final TextEditingController nameCtrl = TextEditingController(text: d.label);
    
    // تعريف الحالات بناءً على نوع الجهاز
    bool isBlocked = d.type == UserType.blocked;
    bool isBypassed = d.type == UserType.bypassed;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(_).viewInsets.bottom + 30),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.blueGrey.shade100,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            const Text("إدارة الجهاز",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 25),
            _modernField(nameCtrl, "أدخل مسمى للجهاز", Icons.edit_note_rounded),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 0),
                onPressed: () {
                  Get.back();
                  controller.executeRename(d, nameCtrl.text);
                },
                child: const Text("حفظ المسمى الجديد",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Divider(thickness: 0.8)),

            // --- منطق أزرار الحظر ---
            if (!isBlocked)
              _actionTile("حظر الجهاز", Icons.block, Colors.red, () {
                Get.back();
                controller.confirmBlock(d);
              }),
            
            if (isBlocked)
              _actionTile("فك الحظر عن الجهاز", Icons.lock_open_rounded, Colors.green, () {
                Get.back();
                controller.confirmUnblock(d);
              }),

            // --- منطق أزرار المجاني/العادي ---
            if (!isBypassed)
              _actionTile("تحويل لمجاني", Icons.card_giftcard_rounded, Colors.blue, () {
                Get.back();
                controller.confirmMakeFree(d);
              }),
            
            if (isBypassed)
              _actionTile("إعادة لمستخدم عادي", Icons.person_outline_rounded, Colors.orange, () {
                Get.back();
                // نستخدم confirmUnblock لأنها تعيد الجهاز للحالة العادية (regular)
                controller.confirmUnblock(d); 
              }),

            const Divider(height: 30),

            _actionTile("حذف الجهاز نهائياً", Icons.delete_forever_rounded, Colors.grey,
                () {
              Get.back();
              controller.confirmDelete(d);
            }),
          ],
        ),
      ),
    );
  }

  Widget _modernField(
      TextEditingController controller, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
            color: const Color(0xffF1F5F9),
            borderRadius: BorderRadius.circular(15)),
        child: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              icon: Icon(icon, color: const Color(0xff1E3A8A), size: 22)),
        ),
      ),
    );
  }

  Widget _actionTile(String t, IconData i, Color c, VoidCallback f) {
    return ListTile(
      onTap: f,
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(i, color: c, size: 22)),
      title: Text(t,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              fontSize: 14)),
      trailing: const Icon(Icons.arrow_back_ios_new_rounded,
          size: 14, color: Colors.black12),
    );
  }
  Widget _searchField() {
    return Container(
      height: 55,
      margin: const EdgeInsets.symmetric(horizontal: 18,vertical: 5),
      //padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 15, 
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: TextField(
        // ربط التغيير مباشرة بدالة البحث في المتحكم
        onChanged: controller.setSearch,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          hintText: "بحث باسم الجهاز او ip او mac",
          hintStyle: TextStyle(fontSize: 13, color: Colors.blueGrey),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF1E3A8A)),
          suffixIcon: Icon(Icons.search_off_rounded,color: Color(0x00000000),),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}