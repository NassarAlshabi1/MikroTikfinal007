import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/core/app_pages.dart';
import 'package:mikronet/core/app_theme.dart';
import 'package:mikronet/controllers/helpers/confirm_dialog.dart';
import '../../../controllers/prints/templates/templates_list_controller.dart';
import '/models/print_model.dart';
import '../../widgets/shared/layouts/sub_page_header.dart';

class TemplatesListPage extends GetView<TemplatesListController> {
  const TemplatesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            const PremiumHeader(
              title: 'تصميم الكروت',
              subtitle: 'مكتبة قوالب الطباعة المحفوظة',
              icon: Icons.palette_rounded,
            ),
            Expanded(
              child: GetBuilder<TemplatesListController>(
                init: controller,
                builder: (ctrl) {
                  if (ctrl.isLoading) return _loadingState();
                  if (ctrl.loadError.isNotEmpty) return _errorState(ctrl);
                  if (ctrl.allTemplates.isEmpty) return _emptyState();

                  final width = MediaQuery.sizeOf(context).width;
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: width > 820 ? 760 : double.infinity),
                      child: RefreshIndicator(
                        onRefresh: ctrl.getAll,
                        color: AppColors.info,
                        backgroundColor: AppColors.card,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
                          children: [
                            _librarySummary(ctrl),
                            if (ctrl.skippedTemplates > 0) ...[
                              const SizedBox(height: 10),
                              _notice('تم استبعاد ${ctrl.skippedTemplates} سجل قالب غير صالح.', AppColors.warning),
                            ],
                            const SizedBox(height: 13),
                            for (final template in ctrl.allTemplates)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 13),
                                child: _templateCard(context, ctrl, template),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Get.toNamed(AppRoutes.addTemplate);
            await controller.getAll();
          },
          backgroundColor: AppColors.info,
          foregroundColor: const Color(0xFF07111E),
          icon: const Icon(Icons.add_rounded),
          label: const Text('إنشاء تصميم'),
        ),
      ),
    );
  }

  Widget _loadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.info),
          SizedBox(height: 12),
          Text('جارٍ تحميل التصاميم المحفوظة…',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _errorState(TemplatesListController ctrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 42),
            const SizedBox(height: 12),
            const Text('تعذّر تحميل التصاميم',
                style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(ctrl.loadError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.5)),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: ctrl.getAll,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          width: 460,
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(color: AppColors.info.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.style_outlined, color: AppColors.info, size: 31),
              ),
              const SizedBox(height: 13),
              const Text('مكتبة التصاميم فارغة',
                  style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 6),
              const Text('أنشئ قالب طباعة جديدًا لتستخدمه عند توليد دفعة كروت.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.45)),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.addTemplate),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إنشاء أول تصميم'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _librarySummary(TemplatesListController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _iconBadge(Icons.collections_bookmark_rounded, AppColors.info),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('قوالب الطباعة', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 13)),
                SizedBox(height: 3),
                Text('قوالبك المحفوظة محليًا وجاهزة للدفعات',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 9.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.info.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
            child: Text('${ctrl.allTemplates.length}',
                style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _templateCard(BuildContext context, TemplatesListController ctrl, PrintTemplatesModel template) {
    final cardsPerPage = template.numOfRows * template.numOfColumns;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.16), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _templatePreview(template),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(template.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 8),
                      _pill(
                        template.withPassword ? 'مع كلمة مرور' : 'بدون كلمة مرور',
                        template.withPassword ? AppColors.purple : AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _detailPill(Icons.grid_view_rounded, '${template.numOfRows} × ${template.numOfColumns}'),
                      _detailPill(Icons.credit_card_rounded, '$cardsPerPage كرت في الصفحة'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ctrl.preview(template.id),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('معاينة التصميم'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.info,
                            side: BorderSide(color: AppColors.info.withOpacity(0.5)),
                            minimumSize: const Size.fromHeight(43),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      IconButton.filledTonal(
                        tooltip: 'تعديل التصميم',
                        onPressed: () async {
                          await Get.toNamed(AppRoutes.editTemplate, arguments: template);
                          await ctrl.getAll();
                        },
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.info,
                          backgroundColor: AppColors.info.withOpacity(0.12),
                          minimumSize: const Size(43, 43),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 19),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        tooltip: 'حذف التصميم',
                        onPressed: () => _confirmDelete(template),
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          backgroundColor: AppColors.danger.withOpacity(0.11),
                          minimumSize: const Size(43, 43),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _templatePreview(PrintTemplatesModel template) {
    return Container(
      height: 142,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF123A5A), Color(0xFF1D4ED8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        image: template.image.isNotEmpty
            ? DecorationImage(image: MemoryImage(template.image), fit: BoxFit.cover)
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.03), Colors.black.withOpacity(0.6)],
              ),
            ),
          ),
          if (template.image.isEmpty)
            const Center(child: Icon(Icons.style_rounded, color: Colors.white70, size: 40)),
          Positioned(
            right: 12,
            bottom: 10,
            child: Row(
              children: [
                const Icon(Icons.image_search_rounded, color: Colors.white70, size: 15),
                const SizedBox(width: 5),
                Text(template.image.isEmpty ? 'لا توجد صورة خلفية' : 'معاينة صورة القالب',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(13)),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _detailPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 14),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }

  Widget _notice(String message, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 17),
          const SizedBox(width: 7),
          Expanded(child: Text(message, style: TextStyle(color: color, fontSize: 10.5))),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(PrintTemplatesModel template) async {
    final confirmed = await confirmAction('حذف تصميم «${template.name}» نهائيًا من مكتبة القوالب؟');
    if (confirmed) await controller.delete(template.id);
  }
}
