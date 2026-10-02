import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/controllers/helpers/widgets.dart';
// import 'package:mikronet/controllers/print/batches_controller.dart';
import 'package:mikronet/controllers/prints/batches/add_batch_controller.dart';
// import 'package:mikronet/views/helpers/dialogs.dart';

// استيراد الويجيت الموحدة
import '../../widgets/shared/layouts/sub_page_header.dart';
import '../../widgets/shared/layouts/app_mini_footer.dart';
import '../../widgets/shared/typography/section_title.dart';

class AddBatchView extends StatefulWidget {
  final BatchesFormController controller;
  final int? editIndex;
  final dynamic batch;

  const AddBatchView({
    super.key,
    required this.controller,
    this.editIndex,
    this.batch,
  });

  @override
  State<AddBatchView> createState() => _AddBatchViewState();
}

class _AddBatchViewState extends State<AddBatchView> {
  
  @override
  void initState() {
    super.initState();
    if (widget.batch != null) {
      // يمكنك تهيئة القيم هنا في حالة التعديل لاحقاً
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: GetBuilder<BatchesFormController>(
          init: BatchesFormController(),
          builder: (controller) {
            return Column(
              children: [
                PremiumHeader(
                  title:
                      widget.editIndex == null ? "إنشاء دفعة كروت" : "تعديل الدفعة",
                  subtitle: "توليد وإدارة رموز الشبكة",
                  icon: Icons.layers_rounded,
                ),
            
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Column(
                      children: [
                        const SectionTitle(title: "إعدادات الدفعة الجديدة"),
                        _buildFormCard(controller),
                      ],
                    ),
                  ),
                ),
            
                const AppMiniFooter(title: Text("Micronet Card Engine")),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildFormCard(BatchesFormController controller) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel("المعلومات الأساسية",controller),
          const SizedBox(height: 15),
          _buildModernInput(
              controller.batchName, "اسم الدفعة (مثال: دفعة الشتاء)", Icons.badge_outlined,controller),
          _buildModernInput(
              controller.numOfCards, "عدد الكروت المطلوب توليدها", Icons.pin_outlined,controller,
              isNumber: true),
          const Divider(height: 40),
          _buildFieldLabel("إعدادات الربط والتصميم",controller),
          const SizedBox(height: 15),
          
          // تم إضافة حقل اختيار العميل هنا
          _buildCustomerDropdown(controller),
          const SizedBox(height: 12),
          
          _buildProfileDropdown(controller),
          const SizedBox(height: 12),
          _buildTemplateDropdown(controller),
          const Divider(height: 40),
          
          _buildFieldLabel("نمط كلمة المرور",controller),
          const SizedBox(height: 12),
          _buildGenerationTypeSelector(controller),
          const Divider(height: 40),
          
          _buildFieldLabel("طول الرموز",controller),
          const SizedBox(height: 15),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: Text("طول اسم المستخدم")),
              SizedBox(width: 12),
              Expanded(child: Text("طول كلمة المرور")),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                  child: _buildModernInput(
                      controller.usernameLength, "طول اسم المستخدم", Icons.person,controller)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildModernInput(
                      controller.passwordLength, "طول كلمة المرور", Icons.password,controller)),
            ],
          ),
          const Divider(height: 40),
          // // 
          // Text(controller.dataInsert.toString()),
          // const Divider(height: 40),
          // 
          _buildFieldLabel("تخصيص الرموز (اختياري)",controller),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                  child: _buildModernInput(
                      controller.prefix, "بادئة (Prefix)", Icons.login_rounded,controller)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildModernInput(
                      controller.suffix, "لاحقة (Suffix)", Icons.logout_rounded,controller)),
            ],
          ),
          const SizedBox(height: 35),
          _buildActionButtons(controller),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text,BatchesFormController controller) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E3A8A)));
  }

  Widget _buildModernInput(
      TextEditingController ctrl, String hint, IconData icon,BatchesFormController controller,
      {bool isNumber = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          controller.update();
        } ,
      ),
    );
  }

  Widget _buildDropdownRow(
    BatchesFormController controller,
    {
    required double screenWidth,
    double padding=10,
    required Widget child,
    required String label
  }){
    return
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            width: (screenWidth / 3) - padding,
            child: Text(label),
          ),
          SizedBox(
            width: (screenWidth / 3 * 2) - padding,
            child: child
          )
        ],
      );
  }

  // --- دالة ويدجت حقل اختيار العميل الجديدة ---
  Widget _buildCustomerDropdown(BatchesFormController controller) => 
  _buildDropdownRow(controller,
    screenWidth: Navigator.of(context).context.width , 
    padding: 45,
    label: "اختر العميل",
    child: MySelectedMenu(
      // استخدام اسم العميل كمعرف (id) لسهولة إرساله للميكروتك
      items: controller.allCustomers.map((c)=>{"id":c.name ,"name":c.name}).toList(),
      onSave: (val) {
        controller.selectedCustomer.value=val.toString();
        controller.update();
      },
      hintText: "اختر العميل",
      selectedKeyName: "id",
      bgColor: const Color(0xFFF1F5F9),
      border: Border.all(color: Colors.grey.shade300),
    ),
  );

  Widget _buildProfileDropdown(BatchesFormController controller) => 
  _buildDropdownRow(controller,
    screenWidth: Navigator.of(context).context.width , 
    padding: 45,
    label: "اختر باقة",
    child: MySelectedMenu(
      items: controller.allProfiles.map((p)=>{"id":p.id ,"name":p.name}).toList(),
      onSave: (val) {
        controller.selectedProfile.value=val.toString();
        controller.update();
      },
      hintText: "اختر باقة",
      selectedKeyName: "id",
      bgColor: const Color(0xFFF1F5F9),
      border: Border.all(color: Colors.grey.shade300),
    ),
  );

  Widget _buildTemplateDropdown(BatchesFormController controller) => 
  _buildDropdownRow(controller,
    screenWidth: Navigator.of(context).context.width , 
    padding: 45,
    label: "اختر قالب",
    child: MySelectedMenu(
      items: controller.allTemplates.map((t)=>{"id":t.id ,"name":t.name}).toList(),
      onSave: (val) {
        controller.selectedTemplate.value=int.parse(val);
        controller.update();
      },
      hintText: "اختر قالب" ,
      selectedKeyName: "id",
      bgColor: const Color(0xFFF1F5F9),
      border: Border.all(color: Colors.grey.shade300),
    ),
  );
  
  Widget _buildGenerationTypeSelector(BatchesFormController controller) {
    return Row(
      children: controller.passwordTypes.map((opt) {
        bool isSelected = controller.selectedPasswordType == opt['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              controller.selectedPasswordType=opt['id'];
              controller.update();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(opt['icon'],
                      color:
                          isSelected ? Colors.white : const Color(0xFF64748B),
                      size: 20),
                  const SizedBox(height: 4),
                  Text(opt['label'],textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(BatchesFormController controller) {
    return Row(
      children: [
        Expanded(
            flex: 2,
            child: _customButton(
                "إنشاء وتوليد",
                const [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                Icons.bolt_rounded,
                controller.handleGenerate,
                controller
              )),
        const SizedBox(width: 12),
        Expanded(
            child: _customButton(
                "معاينة",
                const [Color(0xFF10B981), Color(0xFF059669)],
                Icons.visibility_rounded,
                controller.handlePreview,
                controller
              )),
      ],
    );
  }

  Widget _customButton(
      String text, List<Color> colors, IconData icon, VoidCallback tap,BatchesFormController controller) {
    return InkWell(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                  color: colors.last.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13))
        ]),
      ),
    );
  }
}