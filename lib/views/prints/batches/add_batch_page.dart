import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mikronet/controllers/prints/batches/add_batch_controller.dart';
import 'package:mikronet/core/app_pages.dart';
import 'package:mikronet/core/app_theme.dart';
import '../../widgets/shared/layouts/sub_page_header.dart';

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
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: GetBuilder<BatchesFormController>(
          init: widget.controller,
          builder: (controller) {
            final width = MediaQuery.sizeOf(context).width;
            final maxContentWidth = width > 720 ? 680.0 : double.infinity;

            return Column(
              children: [
                PremiumHeader(
                  title: widget.editIndex == null ? 'إنشاء دفعة كروت' : 'تعديل الدفعة',
                  subtitle: 'توليد كروت حقيقية وربطها بالراوتر',
                  icon: Icons.layers_rounded,
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: ListView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                        children: [
                          _buildRouterIdentity(controller),
                          const SizedBox(height: 12),
                          _buildBatchBasics(controller),
                          const SizedBox(height: 12),
                          _buildRouterSettings(controller),
                          const SizedBox(height: 12),
                          _buildPasswordSettings(controller),
                          const SizedBox(height: 12),
                          _buildNameSettings(controller),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildActionBar(controller),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRouterIdentity(BatchesFormController controller) {
    final serial = controller.routerSerial.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C707C), Color(0xFF118A9A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.13), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.router_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('دفعة مرتبطة بهذا الراوتر', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  serial.isEmpty ? 'جارٍ قراءة هوية الراوتر…' : 'الرقم التسلسلي: $serial',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_user_rounded, color: Color(0xFFBBF7D0), size: 20),
        ],
      ),
    );
  }

  Widget _buildBatchBasics(BatchesFormController controller) {
    return _sectionCard(
      icon: Icons.edit_note_rounded,
      title: 'بيانات الدفعة',
      subtitle: 'اسم واضح وعدد الكروت المراد توليدها',
      children: [
        _textField(
          controller: controller.batchName,
          label: 'اسم الدفعة',
          hint: 'اكتب اسمًا يسهل تمييزه لاحقًا',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 10),
        _textField(
          controller: controller.numOfCards,
          label: 'عدد الكروت',
          hint: 'أدخل العدد المطلوب',
          icon: Icons.pin_outlined,
          number: true,
        ),
      ],
    );
  }

  Widget _buildRouterSettings(BatchesFormController controller) {
    final selectedCustomer = controller.allCustomers.any((customer) => customer.name == controller.selectedCustomer.value)
        ? controller.selectedCustomer.value
        : null;
    final selectedProfile = controller.allProfiles.any((profile) => profile.id.toString() == controller.selectedProfile.value)
        ? controller.selectedProfile.value
        : null;
    final selectedTemplate = controller.allTemplates.any((template) => template.id == controller.selectedTemplate.value)
        ? controller.selectedTemplate.value
        : null;

    return _sectionCard(
      icon: Icons.settings_input_component_rounded,
      title: 'إعدادات الربط والطباعة',
      subtitle: 'الاختيارات تُحمّل من الراوتر والقوالب المحفوظة',
      children: [
        if (controller.allCustomers.isEmpty)
          _emptyDropdownNote(
            title: 'العميل',
            message: 'لا توجد قائمة عملاء متاحة. سيُستخدم حساب User Manager الافتراضي.',
            icon: Icons.person_outline_rounded,
          )
        else
          _dropdownField<String>(
            label: 'العميل',
            icon: Icons.person_outline_rounded,
            hint: 'اختر العميل',
            value: selectedCustomer,
            items: controller.allCustomers
                .map((customer) => DropdownMenuItem<String>(
                      value: customer.name,
                      child: Text(customer.name, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              controller.selectedCustomer.value = value;
              controller.update();
            },
          ),
        const SizedBox(height: 10),
        if (controller.allProfiles.isEmpty)
          _emptyDropdownNote(
            title: 'الباقة',
            message: 'لا توجد باقات محمّلة. أنشئ باقة أو أعد تحميلها أولًا.',
            icon: Icons.layers_outlined,
            actionLabel: 'فتح الباقات',
            onAction: () async {
              await Get.toNamed(AppRoutes.packages);
              await controller.getallProfiles();
            },
          )
        else
          _dropdownField<String>(
            label: 'باقة User Manager',
            icon: Icons.layers_outlined,
            hint: 'اختر الباقة',
            value: selectedProfile,
            items: controller.allProfiles
                .map((profile) => DropdownMenuItem<String>(
                      value: profile.id.toString(),
                      child: Text(profile.name, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              controller.selectedProfile.value = value;
              controller.update();
            },
          ),
        const SizedBox(height: 10),
        if (controller.allTemplates.isEmpty)
          _emptyDropdownNote(
            title: 'قالب الطباعة',
            message: controller.templatesLoadError.isNotEmpty
                ? 'تعذّر تحميل القوالب. أعد المحاولة أو أنشئ قالبًا جديدًا.'
                : 'لا توجد قوالب محفوظة للاختيار.',
            icon: Icons.palette_outlined,
            actionLabel: 'إدارة القوالب',
            onAction: () async {
              await Get.toNamed(AppRoutes.templates);
              await controller.reloadTemplates();
            },
          )
        else
          Row(
            children: [
              Expanded(
                child: _dropdownField<int>(
                  label: 'قالب الطباعة',
                  icon: Icons.palette_outlined,
                  hint: 'اختر القالب',
                  value: selectedTemplate,
                  items: controller.allTemplates
                      .map((template) => DropdownMenuItem<int>(
                            value: template.id,
                            child: Text(template.name, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) controller.selectTemplate(value);
                  },
                ),
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                tooltip: 'تحديث القوالب',
                onPressed: controller.reloadTemplates,
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.info,
              ),
            ],
          ),
        if (controller.skippedTemplates > 0) ...[
          const SizedBox(height: 7),
          _inlineNotice('تم استبعاد ${controller.skippedTemplates} قالب غير صالح.', AppColors.warning),
        ],
      ],
    );
  }

  Widget _buildPasswordSettings(BatchesFormController controller) {
    final template = controller.allTemplates.firstWhereOrNull((item) => item.id == controller.selectedTemplate.value);
    final requiresPassword = template?.withPassword ?? false;
    final options = <_PasswordOption>[
      const _PasswordOption('none', 'بدون كلمة مرور', 'القالب لا يطبع كلمة مرور', Icons.remove_circle_outline_rounded),
      const _PasswordOption('diff', 'كلمات مختلفة', 'إنشاء كلمة مرور فريدة لكل كرت', Icons.pin_rounded),
      const _PasswordOption('same', 'مثل اسم المستخدم', 'استخدم اسم المستخدم ككلمة مرور', Icons.sync_alt_rounded),
    ];

    return _sectionCard(
      icon: Icons.password_rounded,
      title: 'نمط كلمة المرور',
      subtitle: requiresPassword
          ? 'القالب المختار يتضمن خانة لكلمة المرور؛ اختر كلمات مرور مختلفة.'
          : 'اختر النمط المناسب للقالب.',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 520 ? 3 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: columns == 1 ? 66 : 91,
              ),
              itemBuilder: (context, index) {
                final option = options[index];
                final selected = controller.selectedPasswordType == option.id;
                final disabled = requiresPassword ? option.id != 'diff' : option.id == 'diff';
                return _passwordOption(
                  option,
                  selected: selected,
                  disabled: disabled,
                  onTap: disabled
                      ? null
                      : () {
                          controller.selectedPasswordType = option.id;
                          controller.update();
                        },
                );
              },
            );
          },
        ),
        if (controller.selectedPasswordType == 'diff') ...[
          const SizedBox(height: 12),
          _textField(
            controller: controller.passwordLength,
            label: 'طول كلمة المرور',
            hint: 'مثال: 5',
            icon: Icons.password_rounded,
            number: true,
          ),
        ],
      ],
    );
  }

  Widget _passwordOption(
    _PasswordOption option, {
    required bool selected,
    required bool disabled,
    required VoidCallback? onTap,
  }) {
    final color = disabled ? AppColors.textMuted : (selected ? AppColors.info : AppColors.textMuted);
    return Material(
      color: selected ? AppColors.info.withOpacity(0.12) : AppColors.soft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.info.withOpacity(0.65) : AppColors.border),
          ),
          child: Row(
            children: [
              Icon(option.icon, color: color, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: disabled ? AppColors.textMuted : AppColors.text, fontSize: 11.5, fontWeight: FontWeight.w800)),
                    if (MediaQuery.sizeOf(context).width > 520) ...[
                      const SizedBox(height: 2),
                      Text(option.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5)),
                    ],
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.info, size: 17),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameSettings(BatchesFormController controller) {
    return _sectionCard(
      icon: Icons.text_fields_rounded,
      title: 'تخصيص أسماء الكروت',
      subtitle: 'البادئة واللاحقة اختيارية، وطول اسم المستخدم مطلوب.',
      children: [
        _textField(
          controller: controller.usernameLength,
          label: 'طول اسم المستخدم',
          hint: 'مثال: 7',
          icon: Icons.person_outline_rounded,
          number: true,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _textField(
                controller: controller.prefix,
                label: 'بادئة (اختياري)',
                hint: 'مثال: net-',
                icon: Icons.first_page_rounded,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _textField(
                controller: controller.suffix,
                label: 'لاحقة (اختياري)',
                hint: 'مثال: -24',
                icon: Icons.last_page_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: AppColors.info.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.info, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool number = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
      textInputAction: TextInputAction.next,
      onChanged: (_) => widget.controller.update(),
      style: const TextStyle(color: AppColors.text, fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: AppColors.soft,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.info, width: 1.2),
        ),
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required IconData icon,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
      dropdownColor: AppColors.card,
      style: const TextStyle(color: AppColors.text, fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: AppColors.soft,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.info, width: 1.2),
        ),
      ),
      hint: Text(hint, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _emptyDropdownNote({
    required String title,
    required String message,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.warning, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.text, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(message, style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5, height: 1.35)),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 6),
            TextButton(onPressed: onAction, child: Text(actionLabel, style: const TextStyle(fontSize: 10))),
          ],
        ],
      ),
    );
  }

  Widget _inlineNotice(String text, Color color) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 10))),
      ],
    );
  }

  Widget _actionBar(BatchesFormController controller) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.page,
          border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.9))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                onPressed: controller.handleGenerate,
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('إنشاء وتوليد'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: const Color(0xFF07111E),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: controller.handlePreview,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('معاينة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const _PasswordOption(this.id, this.title, this.description, this.icon);
}
