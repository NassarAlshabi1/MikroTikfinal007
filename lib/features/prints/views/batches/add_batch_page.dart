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
class AddBatchView extends StatelessWidget {
  final BatchesFormController controller;
  const AddBatchView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: GetBuilder<BatchesFormController>(
          init: controller,
          builder: (controller) {
            return Column(
              children: [
                PremiumHeader(
                  title: "إنشاء كروت User Manager",
                  subtitle: "إنشاء مستخدمين وربطهم بباقة الراوتر",
                  icon: Icons.auto_awesome_motion_rounded,
                ),
                Expanded(child: _buildCreateTab(controller)),
                const AppMiniFooter(title: Text("Micronet Card Engine")),
              ],
            );
          },
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
          const SectionTitle(title: "إعدادات الدفعة والباقة"),
          const SizedBox(height: 8),
          _groupCard(children: [
            _labeledField(
              label: "باقات اليوزرمانجر",
              trailing: IconButton(
                tooltip: "إضافة باقة",
                onPressed: () async {
                  await Get.toNamed(AppRoutes.addProfile);
                  await controller.getallProfiles();
                },
                icon: const Icon(Icons.add_circle_rounded, color: AppColors.info, size: 28),
              ),
              child: MySelectedMenu(
                items: controller.availableProfiles.map((p) => {"id": p.id, "name": p.name}).toList(),
                onSave: (val) => controller.selectProfile(val.toString()),
                hintText: "اختر باقة User Manager",
                emptyText: controller.availableProfiles.isEmpty
                    ? "لا توجد باقات مملوكة لهذا العميل"
                    : "لا توجد باقات — أنشئ باقة أولاً",
                selectedKeyName: "id",
                bgColor: AppColors.overlay,
                border: Border.all(color: AppColors.border),
              ),
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: "قالب الطباعة",
              trailing: TextButton(
                onPressed: () async {
                  await Get.toNamed(AppRoutes.templates);
                  await controller.reloadTemplates();
                },
                child: const Text("تغيير القالب",
                    style: TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              child: _templateDropdown(controller),
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: controller.customerFieldLabel,
              trailing: const Icon(Icons.group_work_rounded, color: AppColors.textMuted, size: 20),
              child: MySelectedMenu(
                items: controller.allCustomers.map((c) => {"id": c.name, "name": c.name}).toList(),
                onSave: (val) => controller.selectCustomer(val.toString()),
                hintText: controller.customerFieldHint,
                emptyText: "لا توجد ${controller.customerFieldLabel} على الراوتر",
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
            if (controller.selectedPrintTemplate == null)
              const Text(
                "اختر قالب طباعة لتحديد حقول بيانات الدخول.",
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              )
            else if (controller.selectedPrintTemplate!.withPassword) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: controller.passwordMatchesUsername,
                title: const Text(
                  "كلمة المرور تطابق اسم المستخدم",
                  style: TextStyle(color: AppColors.textBright, fontSize: 13),
                ),
                onChanged: (value) {
                  controller.passwordMatchesUsername = value;
                  controller.update();
                },
              ),
              if (!controller.passwordMatchesUsername) ...[
                _labeledField(
                  label: "نمط كلمة المرور",
                  child: _characterPatternDropdown(controller, isPassword: true),
                ),
                const SizedBox(height: 12),
                _labeledField(
                  label: "طول كلمة المرور",
                  child: _numberInput(controller.passwordLength, "5"),
                ),
              ],
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.overlay,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  "القالب المحدد لا يطبع كلمة مرور؛ سيُنشأ اسم المستخدم فقط.",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            const SizedBox(height: 14),
            _labeledField(
              label: "نمط اسم المستخدم",
              child: _characterPatternDropdown(controller, isPassword: false),
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: "طول الجزء العشوائي من اسم المستخدم",
              child: _numberInput(controller.usernameLength, "7"),
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
                    child: _numberInput(
                        controller.numOfCards, controller.cardsPerPage.toString(),
                        onChanged: (_) => controller.syncPagesFromCards()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: "بادئة اسم المستخدم",
              child: _textInput(controller.prefix, "اختياري — مثال: NET-"),
            ),
            const SizedBox(height: 14),
            _labeledField(
              label: "لاحقة اسم المستخدم",
              child: _textInput(controller.suffix, "اختياري — مثال: -A"),
            ),
            const SizedBox(height: 6),
            // خيار استبعاد حرف/رقم (مثل ABOTALAL)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("استبعاد أحرف/أرقام",
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

  Widget _characterPatternDropdown(BatchesFormController controller, {required bool isPassword}) {
    final selected = isPassword
        ? controller.selectedPasswordPattern
        : controller.selectedUsernamePattern;
    return DropdownButtonFormField<String>(
      value: selected,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.overlay,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dropdownColor: AppColors.card,
      style: const TextStyle(color: AppColors.textBright, fontSize: 13),
      items: BatchesFormController.characterPatternLabels.entries
          .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        if (isPassword) {
          controller.selectedPasswordPattern = value;
        } else {
          controller.selectedUsernamePattern = value;
        }
        controller.update();
      },
    );
  }

  Widget _templateDropdown(BatchesFormController controller) {
    return Row(
      children: [
        Expanded(
          child: MySelectedMenu(
            items: controller.compatibleTemplates.map((t) => {
              "id": t.id,
              "name": t.linkedProfileName.isEmpty
                  ? "${t.name} (عام)"
                  : "${t.name} (${t.linkedProfileName})",
            }).toList(),
              onSave: (val) {
              controller.selectTemplate(int.parse(val.toString()));
            },
            hintText: "اختر قالب",
            emptyText: controller.templatesLoadError.isNotEmpty
                ? "تعذّر جلب القوالب"
                : controller.allTemplates.isEmpty
                    ? "لا توجد قوالب — أنشئ قالبًا من قسم الطباعة"
                    : "لا يوجد قالب عام أو مرتبط بهذه الباقة؛ عدّل ارتباط القالب أولًا",
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
