import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/shared/layouts/app_mini_footer.dart';
import '../../../controllers/cards/cards/add_single_card_controller.dart';
import '../../widgets/shared/layouts/sub_page_header.dart';
import '../../widgets/shared/layouts/modern_input.dart';

class AddSingleCardPage extends GetView<AddSingleCardController> {
  const AddSingleCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            const PremiumHeader(
              title: "إضافة كرت جديد",
              subtitle: "إنشاء حساب مستخدم جديد في الشبكة",
              icon: Icons.add_card_rounded,
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 15,
                        color: Colors.black.withOpacity(0.03),
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel("بيانات الكرت"),
                      const SizedBox(height: 10),
                      
                      ModernInput(
                        label: "اسم المستخدم",
                        icon: Icons.person_outline_rounded,
                        controller: controller.usernameCtrl,
                      ),
                      ModernInput(
                        label: "كلمة المرور",
                        icon: Icons.lock_outline_rounded,
                        controller: controller.passwordCtrl,
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(),
                      ),
                      _buildFieldLabel("اختيار حساب الادارة"),
                      const SizedBox(height: 10),
                      
                      // مراقبة حالة تحميل العملاء
                      Obx(() => controller.isCustomersLoading.value 
                        ? const Center(child: LinearProgressIndicator())
                        : _buildCustomerDropdown()),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(),
                      ),
                      _buildFieldLabel("اختيار الباقة"),
                      const SizedBox(height: 10),
                      
                      // استخدام Obx لمراقبة قائمة الباقات وحالة التحميل
                      Obx(() => controller.isProfilesLoading.value 
                        ? const Center(child: LinearProgressIndicator())
                        : _buildPackageDropdown()),
                    
                      const SizedBox(height: 35),
                      
                      // زر الحفظ مع مراقبة حالة التحميل
                      Obx(() => _buildSaveButton()),
                    ],
                  ),
                ),
              ),
            ),
            
           AppMiniFooter(
              title: Text("إنشاء حساب مستخدم جديد في الشبكة",
                style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blueGrey.shade400),),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildCustomerDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          // 🔹 التعديل الجوهري هنا: نتحقق هل الاسم المختار موجود في القائمة الحالية؟
          // إذا لم يكن موجوداً، نمرر null لتجنب الانهيار.
          value: controller.customers.any((c) => c.name == controller.selectedCustomer.value?.name)
              ? controller.selectedCustomer.value?.name
              : null, 
          isExpanded: true,
          icon: const Icon(Icons.person_search_rounded, color: Color(0xFF1E3A8A)),
          hint: const Text("اختر العميل"),
          items: controller.customers.map((c) => DropdownMenuItem(
            value: c.name,
            child: Text(c.name, 
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          )).toList(),
          onChanged: (v) {
            if (v != null) {
              controller.selectedCustomer.value = controller.customers.firstWhere((c) => c.name == v);
            }
          },
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1E3A8A),
      ),
    );
  }

  Widget _buildPackageDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedProfile.value?.name,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1E3A8A)),
          hint: const Text("اختر الباقة"),
          items: controller.profiles.map((p) => DropdownMenuItem(
            value: p.name,
            child: Text(p.name, 
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          )).toList(),
          onChanged: (v) {
            controller.selectedProfile.value = controller.profiles.firstWhere((p) => p.name == v);
          },
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return InkWell(
      onTap: controller.isLoading.value ? null : () => controller.saveCard(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: controller.isLoading.value 
              ? [Colors.grey, Colors.blueGrey]
              : [const Color(0xFF0F172A), const Color(0xFF1E3A8A)]
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Center(
          child: controller.isLoading.value 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text(
                "حفظ الكرت",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
        ),
      ),
    );
  }

  
}