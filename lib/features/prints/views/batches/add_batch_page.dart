import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:mikronet/core/ui/widgets/selected_menu.dart';
import 'package:mikronet/features/prints/controllers/batches/add_batch_controller.dart';
import 'package:mikronet/app/routes/app_routes.dart';

// استيراد الويجيت الموحدة
import 'package:mikronet/core/ui/widgets/sub_page_header.dart';
import 'package:mikronet/core/ui/widgets/app_mini_footer.dart';
import 'package:mikronet/core/ui/widgets/section_title.dart';

/// شاشة إنشاء/توليد دفعة كروت — نفس تقسيم شاشة ABOTALAL:
/// بطاقة "خيارات الباقة" ثم بطاقة "مواصفات الكرت والتوليد" ثم زر إضافة كبير.
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
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: GetBuilder<BatchesFormController>(
          init: widget.controller,
          builder: (controller) {
            return Column(
              children: [
                PremiumHeader(
                  title: "إضافة وتوليد كروت يوزرمانجر",
                  subtitle: widget.editIndex == null ? "إنشاء دفعة جديدة" : "تعديل الدفعة",
                  icon: Icons.auto_awesome_motion_rounded,
                ),
                _buildTabs(),
                Expanded(
                  child: selectedTab == 0
                      ? _buildCreateTab(controller)
                      : _buildImportTab(),
                ),
                const AppMiniFooter(title: Text("Micronet Card Engine")),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------- تبويبات الصفحة (إنشاء دفعة / استيراد دفعة) ----------
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _tabItem("إنشاء دفعة", 0),
          _tabItem("استيراد دفعة", 1),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final active = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.info : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                index == 0 ? Icons.add_card_rounded : Icons.file_upload_outlined,
                size: 18,
                color: active ? AppColors.info : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: active ? AppColors.info : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportTab() {
    // الاستيراد من الراوتر يحدث من شاشة الدفعات (batches_list)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_download_rounded, size: 56, color: AppColors.info),
            const SizedBox(height: 14),
            const Text("استيراد دفعة موجودة على الراوتر",
                style: TextStyle(color: AppColors.textBright, fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 6),
            const Text("ستُعرض دفعات الراوتر المخزّنة لتستوردها وتطبعها",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.batches),
              icon: const Icon(Icons.layers_rounded, size: 18),
              label: const Text("فتح دفعات الطباعة"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab(BatchesFormController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======== بطاقة خيارات الباقة ========
          const SectionTitle(title: "خيارات الباقة"),
          const SizedBox(height: 8),
          _groupCard(children: [
            _labeledField(
              label: "باقات اليوزرمانجر",
              trailing: IconButton(
                tooltip: "إضافة باقة",
                onPressed: () => Get.toNamed(AppRoutes.addProfile),
                icon: const Icon(Icons.add_circle_rounded, color: AppColors.info, size: 28),
              ),
              child: MySelectedMenu(
                items: controller.allProfiles.map((p) => {"id": p.id, "name": p.name}).toList(),
                onSave: (val) {
                  controller.selectedProfile.value = val.toString();
                  controller.update();
                },
                hintText: "اختر باقة",
                selectedKeyName: "id",
                bgColor: AppColors.overlay,
                border: Border.all(color: AppColors.border),
              ),
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: "قالب الطباعة",
              trailing: TextButton(
                onPressed: () => Get.toNamed(AppRoutes.templates),
                child: const Text("تغيير القالب",
                    style: TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              child: _templateDropdown(controller),
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: "نقطة البيع (العميل)",
              trailing: const Icon(Icons.storefront_rounded, color: AppColors.textMuted, size: 20),
              child: MySelectedMenu(
                items: controller.allCustomers.map((c) => {"id": c.name, "name": c.name}).toList(),
                onSave: (val) {
                  controller.selectedCustomer.value = val.toString();
                  controller.update();
                },
                hintText: "اختر العميل",
                selectedKeyName: "id",
                bgColor: AppColors.overlay,
                border: Border.all(color: AppColors.border),
              ),
            ),
            const SizedBox(height: 14),
            _buildModernInput(controller.batchName, "اسم الدفعة (مثال: دفعة الشتاء)",
                Icons.badge_outlined, controller),
          ]),
          const SizedBox(height: 16),

          // ======== بطاقة مواصفات الكرت ========
          const SectionTitle(title: "مواصفات الكرت والتوليد"),
          const SizedBox(height: 8),
          _groupCard(children: [
            _labeledField(
              label: "صنف الكرت",
              trailing: const Icon(Icons.password_rounded, color: AppColors.textMuted, size: 20),
              child: _cardTypeDropdown(controller),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _labeledField(
                    label: "نمط الاسم",
                    child: _patternDropdown(controller),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _labeledField(
                    label: "عدد",
                    child: _numberInput(controller.usernameLength, "9"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _labeledField(
                    label: "عدد الصفحات",
                    child: _numberInput(controller.numOfPages, "1",
                        onChanged: (_) => controller.syncCardsFromPages()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _labeledField(
                    label: "عدد الكروت",
                    child: _numberInput(controller.numOfCards, "51",
                        onChanged: (_) => controller.syncPagesFromCards()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: "نهاية الكرت",
              child: _textInput(controller.suffix, "نهاية اختيارية (مثال: 99)"),
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: "بداية الكرت",
              child: _textInput(controller.prefix, "بداية اختيارية"),
            ),
            const SizedBox(height: 6),
            // خيار استبعاد حرف/رقم (مثل ABOTALAL)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("استبعاد حرف/رقم",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(width: 8),
                Checkbox(
                  value: controller.excludeCharEnabled,
                  onChanged: (v) {
                    controller.excludeCharEnabled = v ?? false;
                    controller.update();
                  },
                  activeColor: AppColors.info,
                ),
              ],
            ),
            if (controller.excludeCharEnabled)
              _textInput(controller.excludedCharsCtrl,
                  "رقم واحد أو حرف واحد (مثال: 0 أو O أو 1)"),
            const SizedBox(height: 6),
            _labeledField(
              label: "طول كلمة المرور",
              child: _numberInput(controller.passwordLength, "6"),
            ),
          ]),
          const SizedBox(height: 20),

          // ======== زر الإضافة الرئيسي ========
          _mainAddButton(controller),
          const SizedBox(height: 12),
          _previewButton(controller),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---------- مكوّنات مساعدة ----------
  Widget _groupCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child, Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _inputShell(Widget child) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _textInput(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: AppColors.overlay,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      style: const TextStyle(color: AppColors.textBright, fontSize: 13, fontWeight: FontWeight.bold),
    );
  }

  Widget _numberInput(TextEditingController ctrl, String hint,
      {ValueChanged<String>? onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      onChanged: (v) {
        onChanged?.call(v);
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: AppColors.overlay,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      style: const TextStyle(color: AppColors.textBright, fontSize: 13, fontWeight: FontWeight.bold),
    );
  }

  Widget _cardTypeDropdown(BatchesFormController controller) {
    const labels = {
      "none": "كلمة سر فارغة",
      "same": "اسم المستخدم = كلمة السر",
      "diff": "أرقام مختلفة",
      "mixed": "أرقام وحروف مدمجة",
    };
    return _inputShell(DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: controller.selectedPasswordType,
        isExpanded: true,
        icon: const Icon(Icons.unfold_more_rounded, color: AppColors.textMuted, size: 20),
        dropdownColor: AppColors.card,
        style: const TextStyle(color: AppColors.textBright, fontSize: 13, fontWeight: FontWeight.bold),
        items: controller.passwordTypes
            .map((o) => DropdownMenuItem<String>(
                  value: o["id"],
                  child: Text(labels[o["id"]] ?? o["label"]),
                ))
            .toList(),
        onChanged: (v) {
          controller.selectedPasswordType = v ?? "none";
          controller.update();
        },
      ),
    ));
  }

  Widget _patternDropdown(BatchesFormController controller) {
    return _inputShell(DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: controller.selectedUsernamePattern,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted, size: 20),
        dropdownColor: AppColors.card,
        style: const TextStyle(color: AppColors.textBright, fontSize: 13, fontWeight: FontWeight.bold),
        items: controller.usernamePatterns
            .map((o) => DropdownMenuItem<String>(
                  value: o["id"],
                  child: Text(o["label"]),
                ))
            .toList(),
        onChanged: (v) {
          controller.selectedUsernamePattern = v ?? "numbers";
          controller.update();
        },
      ),
    ));
  }

  Widget _templateDropdown(BatchesFormController controller) {
    return Row(
      children: [
        Expanded(
          child: MySelectedMenu(
            items: controller.allTemplates.map((t) => {"id": t.id, "name": t.name}).toList(),
            onSave: (val) {
              controller.selectedTemplate.value = int.parse(val);
              controller.update();
            },
            hintText: "اختر قالب",
            emptyText: controller.templatesLoadError.isNotEmpty
                ? "تعذّر جلب القوالب"
                : "لا توجد قوالب — أنشئ قالبًا من قسم الطباعة",
            selectedKeyName: "id",
            bgColor: AppColors.overlay,
            border: Border.all(color: AppColors.border),
          ),
        ),
        IconButton(
          tooltip: "تحديث القوالب",
          onPressed: controller.reloadTemplates,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
        ),
      ],
    );
  }

  Widget _buildModernInput(TextEditingController ctrl, String hint, IconData icon,
      BatchesFormController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        onChanged: (value) => controller.update(),
        style: const TextStyle(color: AppColors.textBright, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _mainAddButton(BatchesFormController controller) {
    return InkWell(
      onTap: controller.handleGenerate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.info, AppColors.sky]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: AppColors.info.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text("إضافة وتوليد الكروت",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _previewButton(BatchesFormController controller) {
    return InkWell(
      onTap: controller.handlePreview,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_rounded, color: AppColors.textMuted, size: 18),
            SizedBox(width: 8),
            Text("معاينة الكروت قبل الإنشاء",
                style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
