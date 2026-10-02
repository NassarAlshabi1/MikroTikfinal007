import 'package:flutter/material.dart';
import 'package:get/get.dart';

// استيراد المتحكم والموديل
import '../../../controllers/cards/cards/card_info_controller.dart';
import '/models/cards_model.dart';

// استيراد الويدجت الجاهزة
import '/views/widgets/shared/layouts/sub_page_header.dart';
import '/views/widgets/shared/layouts/modern_input.dart';
import '/views/widgets/widgetsCard/status_badge.dart';

class CardInfoPage extends GetView<CardInfoController> {
  final CardModel card;
  
  const CardInfoPage({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
   

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if(didPop) return;
        controller.goBack();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: Column(
            children: [
              // 1. الهيدر الموحد
               PremiumHeader(
                title: "تفاصيل الكرت",
                subtitle: "تفاصيل الكرت وتعديل البيانات",
                showBackButton: true,
                goBack: controller.goBack,
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel("بيانات الكرت"),
                      
                      // 2. استخدام حقول الإدخال المربوطة بالمتحكم مباشرة
                      ModernInput(
                        label: "اسم المستخدم", 
                        icon: Icons.person_outline, 
                        controller: controller.userCtrl
                      ),
                      ModernInput(
                        label: "كلمة المرور", 
                        icon: Icons.lock_outline, 
                        controller: controller.passCtrl
                      ),
                      ModernInput(
                        label: "الباقة الحالية", 
                        icon: Icons.inventory_2_outlined, 
                        controller: controller.packageCtrl, 
                        isReadOnly: true
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // 3. قسم الحالة (مربوط بـ Obx للتحديث التلقائي)
                      _buildStatusSection(),
                      
                      const SizedBox(height: 30),
                      
                      // 4. أزرار التحكم
                      _buildSaveButton(),
                      const SizedBox(height: 15),
                      _buildDeleteButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ================= STATUS SECTION ================= */
  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "حالة الكرت", 
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))
              ),
              // استخدام Obx لمراقبة تغير الحالة في المتحكم
              Obx(() => StatusBadge(status: controller.status.value)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statusBtn(
                  "تجديد الكرت", 
                  Colors.green, 
                  () => controller.changeStatus("نشطة")
                )
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statusBtn(
                  "تعطيل مؤقت", 
                  Colors.redAccent, 
                  () => controller.changeStatus("منتهية")
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* ================= HELPERS & WIDGETS ================= */
  Widget _buildSectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12, right: 5),
    child: Text(
      label, 
      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 15)
    ),
  );

  Widget _statusBtn(String t, Color c, VoidCallback o) => OutlinedButton(
    onPressed: o,
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: c.withOpacity(0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    ),
    child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 13)),
  );

  Widget _buildSaveButton() => InkWell(
    onTap: () => controller.saveChanges(),
    child: Container(
      height: 58, width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3), 
            blurRadius: 12, 
            offset: const Offset(0, 6)
          )
        ],
      ),
      child: const Center(
        child: Text(
          "حفظ كافة التعديلات", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
        )
      ),
    ),
  );

  Widget _buildDeleteButton() =>InkWell(
    onTap: () =>  controller.showDeleteConfirm(),
    child: Container(
      height: 58, width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color.fromARGB(255, 42, 15, 15), Color.fromARGB(255, 107, 27, 17)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 138, 30, 30).withOpacity(0.3), 
            blurRadius: 12, 
            offset: const Offset(0, 6)
          )
        ],
      ),
      child:  Center(
        child: TextButton.icon(
      onPressed: null,
      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 20),
      label: const Text(
        "حذف هذا الكرت نهائياً", 
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
      ),
      style: TextButton.styleFrom(padding: const EdgeInsets.all(15)),
    ),
      ),
    ),
  
  );
  
}