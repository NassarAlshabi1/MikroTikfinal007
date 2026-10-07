import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import 'package:mikronet/controllers/helpers/widgets.dart';
import 'package:mikronet/controllers/prints/batches/add_batch_controller.dart';
import 'package:mikronet/core/app_theme.dart';
import 'package:mikronet/models/print_model.dart';

/// شاشة إنشاء دفعة البطاقات، مصممة على نمط MkCards الداكن RTL.
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
  bool showCustomerOnCard = false;

  BatchesFormController get form => widget.controller;

  @override
  void initState() {
    super.initState();
    // الشاشة المرجعية لا تعرض اسم الدفعة، لذلك نولد اسماً افتراضياً قابلاً
    // للتعديل من خلال منطق الحفظ الحالي.
    if (form.batchName.text.trim().isEmpty) {
      form.batchName.text = 'دفعة ${DateTime.now().millisecondsSinceEpoch}';
    }
    if (form.numOfCards.text.trim().isEmpty) form.numOfCards.text = '765';
    if (form.usernameLength.text.trim().isEmpty || form.usernameLength.text.trim() == '7') {
      form.usernameLength.text = '10';
    }
    if (form.passwordLength.text.trim().isEmpty || form.passwordLength.text.trim() == '5') {
      form.passwordLength.text = '10';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: GetBuilder<BatchesFormController>(
          init: form,
          builder: (controller) {
            return SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildModeTabs(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                      child: Column(
                        children: [
                          _buildProfileRow(controller),
                          const SizedBox(height: 10),
                          _buildTemplateRow(controller),
                          const SizedBox(height: 10),
                          _buildCustomerRow(controller),
                          const SizedBox(height: 14),
                          _buildCustomerSwitch(),
                          const SizedBox(height: 10),
                          _buildPasswordType(controller),
                          const SizedBox(height: 10),
                          _buildLengthAndCount(controller),
                          const SizedBox(height: 10),
                          _buildPagesAndCards(controller),
                          const SizedBox(height: 10),
                          _buildRangeRow(),
                          const SizedBox(height: 10),
                          _buildPrefixSuffix(controller),
                          const SizedBox(height: 10),
                          _buildGenerateMode(controller),
                          const SizedBox(height: 13),
                          _buildAddButton(controller),
                          const SizedBox(height: 15),
                          _buildTemplatePreview(controller),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomNavigationBar(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 9),
      child: Row(
        children: [
          _topIcon(Icons.more_vert_rounded, onTap: () {}),
          const SizedBox(width: 16),
          _topIcon(Icons.wb_sunny_outlined, onTap: () {}),
          const Spacer(),
          const Text(
            'MkCards',
            style: TextStyle(color: AppColors.info, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 17),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4A382A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFB79A60)),
            ),
            child: const Text('جيبي', style: TextStyle(color: Color(0xFFF6E5B5), fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          const Icon(Icons.circle, color: Color(0xFF65D27B), size: 13),
          const Spacer(),
          _topIcon(Icons.arrow_forward_rounded, onTap: Get.back),
        ],
      ),
    );
  }

  Widget _topIcon(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, color: AppColors.text, size: 27),
      ),
    );
  }

  Widget _buildModeTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(child: _modeTab('استيراد دفعة', Icons.file_upload_outlined, false)),
          const SizedBox(width: 8),
          Expanded(child: _modeTab('إنشاء دفعة', Icons.note_add_outlined, true)),
        ],
      ),
    );
  }

  Widget _modeTab(String title, IconData icon, bool active) {
    return Container(
      height: 61,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF174C6B) : const Color(0xFF101B2E),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: active ? const Color(0xFF2D9DCA) : const Color(0xFF162A42)),
        boxShadow: active ? [BoxShadow(color: AppColors.info.withOpacity(.13), blurRadius: 8)] : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? AppColors.text : AppColors.textMuted, size: 26),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: active ? AppColors.text : AppColors.textMuted, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProfileRow(BatchesFormController controller) {
    return _selectRow(
      label: 'اختر باقة البوزرمينجر',
      icon: Icons.manage_search_rounded,
      child: MySelectedMenu(
        items: controller.allProfiles.map((p) => {'id': p.id, 'name': p.name}).toList(),
        mainValue: controller.selectedProfile.value,
        onSave: (value) {
          controller.selectedProfile.value = value.toString();
          controller.update();
        },
        hintText: 'اختر الباقة',
        emptyText: 'لا توجد باقات',
        selectedKeyName: 'id',
        bgColor: AppColors.soft,
        border: Border.all(color: AppColors.border),
        icon: const Icon(Icons.unfold_more_rounded, color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildTemplateRow(BatchesFormController controller) {
    return _selectRow(
      label: 'قالب الطباعة',
      icon: Icons.description_outlined,
      child: MySelectedMenu(
        items: controller.allTemplates.map((t) => {'id': t.id, 'name': t.name}).toList(),
        mainValue: controller.selectedTemplate.value == 0 ? null : controller.selectedTemplate.value.toString(),
        onSave: (value) {
          controller.selectedTemplate.value = int.tryParse(value.toString()) ?? 0;
          controller.update();
        },
        hintText: 'اختر قالباً',
        emptyText: controller.templatesLoadError.isEmpty ? 'لا توجد قوالب' : 'تعذر جلب القوالب',
        selectedKeyName: 'id',
        bgColor: AppColors.soft,
        border: Border.all(color: AppColors.border),
        icon: const Icon(Icons.unfold_more_rounded, color: AppColors.textMuted),
      ),
      trailing: _plusButton(() => controller.reloadTemplates()),
    );
  }

  Widget _buildCustomerRow(BatchesFormController controller) {
    return _selectRow(
      label: 'اختر نقطة البيع',
      icon: Icons.storefront_outlined,
      child: MySelectedMenu(
        items: controller.allCustomers.map((c) => {'id': c.name, 'name': c.name}).toList(),
        mainValue: controller.selectedCustomer.value,
        onSave: (value) {
          controller.selectedCustomer.value = value.toString();
          controller.update();
        },
        hintText: 'بدون نقطة بيع',
        emptyText: 'بدون نقطة بيع',
        selectedKeyName: 'id',
        bgColor: AppColors.soft,
        border: Border.all(color: AppColors.border),
        icon: const Icon(Icons.unfold_more_rounded, color: AppColors.textMuted),
      ),
      trailing: _plusButton(() => _showHint('إضافة نقطة بيع جديدة متاحة من شاشة الموزعين')),
    );
  }

  Widget _selectRow({required String label, required IconData icon, required Widget child, Widget? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 82,
            padding: const EdgeInsets.fromLTRB(12, 5, 10, 5),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(label, style: const TextStyle(color: AppColors.text, fontSize: 12)),
                Expanded(
                  child: Row(
                    children: [
                      Icon(icon, color: AppColors.info, size: 26),
                      const SizedBox(width: 8),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing],
      ],
    );
  }

  Widget _plusButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: 68,
        height: 82,
        decoration: BoxDecoration(
          color: const Color(0xFF102337),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFF1A6384)),
        ),
        child: const Icon(Icons.add_rounded, color: AppColors.info, size: 31),
      ),
    );
  }

  Widget _buildCustomerSwitch() {
    return InkWell(
      onTap: () => setState(() => showCustomerOnCard = !showCustomerOnCard),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Row(
          children: [
            _checkBox(showCustomerOnCard),
            const Spacer(),
            const Text('إظهار نقطة البيع على الكرت', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordType(BatchesFormController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('اختر صنف الكرت', style: TextStyle(color: AppColors.text, fontSize: 12)),
          const SizedBox(height: 7),
          Row(
            children: controller.passwordTypes.map((item) {
              final id = item['id'] as String;
              final selected = controller.selectedPasswordType == id;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    controller.selectedPasswordType = id;
                    controller.update();
                  },
                  borderRadius: BorderRadius.circular(11),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF1E7FAA) : AppColors.soft,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: selected ? AppColors.info : AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Icon(item['icon'] as IconData, color: selected ? Colors.white : AppColors.textMuted, size: 19),
                        const SizedBox(height: 3),
                        Text(item['label'].toString().replaceAll('\n', ' '), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? Colors.white : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLengthAndCount(BatchesFormController controller) {
    return Row(
      children: [
        Expanded(child: _textField(controller.usernameLength, 'اختر نمط الاسم', suffix: _namePatternLabel(controller.selectedNamePattern), onTap: () => _chooseNamePattern(controller))),
        const SizedBox(width: 10),
        Expanded(child: _textField(controller.passwordLength, 'عدد الأرقام بالكرت', numeric: true)),
      ],
    );
  }

  Widget _buildPrefixSuffix(BatchesFormController controller) {
    return Row(
      children: [
        Expanded(child: _textField(controller.prefix, 'بادئة اختيارية', suffix: 'Prefix')),
        const SizedBox(width: 10),
        Expanded(child: _textField(controller.suffix, 'لاحقة اختيارية', suffix: 'Suffix')),
      ],
    );
  }

  Widget _buildPagesAndCards(BatchesFormController controller) {
    PrintTemplatesModel? template;
    for (final candidate in controller.allTemplates) {
      if (candidate.id == controller.selectedTemplate.value) {
        template = candidate;
        break;
      }
    }
    final perPage = template == null ? 51 : template.numOfRows * template.numOfColumns;
    final count = int.tryParse(controller.numOfCards.text) ?? 0;
    final pages = perPage == 0 ? 0 : (count / perPage).ceil();
    return Row(
      children: [
        Expanded(child: _readOnlyInfo('عدد الصفحات', '$pages', Icons.menu_book_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _textField(controller.numOfCards, 'عدد الكروت', numeric: true, helper: 'اجعل تقلل عدد الصفحات فارغ للتغيير')),
      ],
    );
  }

  Widget _buildRangeRow() {
    return Row(
      children: [
        Expanded(child: _readOnlyInfo('بداية الكرت', '1', Icons.keyboard_double_arrow_right_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _readOnlyInfo('نهاية الكرت', '1', Icons.keyboard_double_arrow_left_rounded)),
      ],
    );
  }

  Widget _buildGenerateMode(BatchesFormController controller) {
    return InkWell(
      onTap: () => _showHint('يتم استبعاد الحروف والرموز غير الصالحة عند التوليد'),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.border)),
        child: const Row(
          children: [
            Icon(Icons.block_rounded, color: AppColors.textMuted, size: 26),
            SizedBox(width: 10),
            Expanded(child: Text('استبعاد حرف/رقم من توليد الأرقام', style: TextStyle(color: AppColors.text, fontSize: 15))),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BatchesFormController controller) {
    return InkWell(
      onTap: controller.handleGenerate,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        height: 67,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF32B4F1),
          borderRadius: BorderRadius.circular(19),
          boxShadow: [BoxShadow(color: const Color(0xFF32B4F1).withOpacity(.22), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('إضافة +', style: TextStyle(color: const Color(0xFF082238), fontWeight: FontWeight.w900, fontSize: 18)),
            SizedBox(width: 10),
            Icon(Icons.note_add_outlined, color: Color(0xFF082238), size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatePreview(BatchesFormController controller) {
    Uint8List image = Uint8List(0);
    for (final item in controller.allTemplates) {
      if (item.id == controller.selectedTemplate.value) {
        image = item.image;
        break;
      }
    }
    if (image.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 128,
        width: double.infinity,
        color: Colors.white,
        child: Image.memory(image, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
      ),
    );
  }

  Widget _settingsCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(13, 4, 12, 4),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(color: AppColors.text, fontSize: 12)),
          Expanded(child: Row(children: [Icon(icon, color: AppColors.info, size: 25), const SizedBox(width: 9), Expanded(child: child)])),
        ],
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label, {bool numeric = false, String? suffix, String? helper, VoidCallback? onTap}) {
    return Container(
      height: helper == null ? 82 : 96,
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 4),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: const TextStyle(color: AppColors.text, fontSize: 12)),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: onTap != null,
              onTap: onTap,
              onChanged: (_) => form.update(),
              textAlign: TextAlign.right,
              keyboardType: numeric ? TextInputType.number : TextInputType.text,
              style: const TextStyle(color: AppColors.text, fontSize: 16),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: suffix,
                hintStyle: const TextStyle(color: AppColors.textMuted),
                suffixIcon: suffix == null ? null : const Icon(Icons.search_rounded, color: AppColors.info, size: 22),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (helper != null) Text(helper, style: const TextStyle(color: AppColors.textMuted, fontSize: 8), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _readOnlyInfo(String title, String value, IconData icon) {
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(color: AppColors.text, fontSize: 12)),
          Expanded(child: Row(children: [Icon(icon, color: AppColors.textMuted, size: 25), const SizedBox(width: 8), Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.text, fontSize: 18))) ])),
        ],
      ),
    );
  }

  Widget _checkBox(bool checked) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: checked ? AppColors.info : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: checked ? AppColors.info : AppColors.textMuted, width: 2)),
      child: checked ? const Icon(Icons.check_rounded, color: Colors.white, size: 25) : null,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 72,
      decoration: const BoxDecoration(color: Color(0xFF07101E), border: Border(top: BorderSide(color: Color(0xFF162840)))),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(Icons.play_arrow_outlined, color: AppColors.textMuted, size: 33),
          Icon(Icons.circle_outlined, color: AppColors.textMuted, size: 34),
          Icon(Icons.square_outlined, color: AppColors.textMuted, size: 31),
        ],
      ),
    );
  }

  String _namePatternLabel(String value) {
    switch (value) {
      case 'letters':
        return 'حروف فقط';
      case 'mixed':
        return 'حروف وأرقام';
      default:
        return 'الأرقام فقط';
    }
  }

  void _chooseNamePattern(BatchesFormController controller) {
    final options = <Map<String, String>>[
      {'id': 'numbers', 'label': 'الأرقام فقط'},
      {'id': 'letters', 'label': 'حروف فقط'},
      {'id': 'mixed', 'label': 'حروف وأرقام'},
    ];
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              final value = option['id']!;
              return ListTile(
                title: Text(option['label']!, textAlign: TextAlign.right),
                trailing: Radio<String>(value: value, groupValue: controller.selectedNamePattern, onChanged: (v) { if (v != null) { controller.selectedNamePattern = v; controller.update(); Get.back(); } }),
                onTap: () { controller.selectedNamePattern = value; controller.update(); Get.back(); },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showHint(String message) {
    showMsgDialog(message: message, type: MsgType.info);
  }
}
