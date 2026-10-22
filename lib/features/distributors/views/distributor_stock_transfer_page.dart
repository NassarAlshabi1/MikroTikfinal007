import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:mikronet/core/ui/widgets/gradient_button.dart';
import 'package:mikronet/core/ui/widgets/section_title.dart';
import 'package:mikronet/core/ui/widgets/sub_page_header.dart';
import 'package:mikronet/features/distributors/controllers/distributor_stock_transfer_controller.dart';

class DistributorStockTransferPage extends GetView<DistributorStockTransferController> {
  const DistributorStockTransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: Column(
          children: [
            PremiumHeader(
              title: 'تحويل مخزون',
              subtitle: 'إسناد دفعة كاملة إلى ${controller.distributor.name}',
              icon: Icons.inventory_2_rounded,
              goBack: Get.back,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.loadError.isNotEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        const SizedBox(height: 80),
                        Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(controller.loadError, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton(onPressed: controller.load, child: const Text('إعادة المحاولة')),
                      ],
                    );
                  }
                  if (controller.batches.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: const [
                        SizedBox(height: 75),
                        Icon(Icons.inventory_2_outlined, size: 52, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'لا توجد دفعات متاحة للتحويل على الراوتر الحالي.\nتظهر هنا الدفعات غير المحوّلة فقط.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, height: 1.6),
                        ),
                      ],
                    );
                  }
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(14),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
                        ),
                        child: const Text(
                          'بعد التحويل، يُحتسب الكرت مباعًا عند رصد أول استخدام له في User Manager. '
                          'تتحدث الأرقام عند فتح الكشف أو سحبه للتحديث؛ لا تحذف كرتًا غير مستخدم من الراوتر وهو ضمن مخزون البقالة.',
                          style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textMuted),
                        ),
                      ),
                      const SectionTitle(title: 'اختر دفعة للتحويل'),
                      const SizedBox(height: 8),
                      ...controller.batches.map(_batchCard),
                      const SizedBox(height: 20),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _batchCard(TransferableBatch batch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(batch.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 6),
          Text(
            'الباقة: ${batch.profileName} • ${batch.cardsCount} كرت',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'سعر الباقة وقت التحويل: ${batch.unitPrice.toStringAsFixed(2)} للكرت',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final busy = controller.transferringBatchId.value == batch.id;
            return GradientButton(
              height: 44,
              label: busy ? 'جارٍ التحقق والتحويل...' : 'تحويل الدفعة كاملة',
              icon: busy ? Icons.hourglass_top_rounded : Icons.move_to_inbox_rounded,
              onPressed: busy ? null : () => _confirmTransfer(batch),
              colors: const [AppColors.blue, AppColors.headerBottom],
            );
          }),
        ],
      ),
    );
  }

  Future<void> _confirmTransfer(TransferableBatch batch) async {
    final confirmed = await Get.dialog<bool>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد تحويل المخزون'),
          content: Text(
            'سيتم إسناد جميع كروت «${batch.name}» وعددها ${batch.cardsCount} إلى '
            '«${controller.distributor.name}». لا يلزم إدخال عدد أو مبلغ يدويًا؛ '
            'سيُحفظ سعر الباقة الحالي (${batch.unitPrice.toStringAsFixed(2)}) كسعر تاريخي لهذه الدفعة، '
            'ولا يمكن تحويل الدفعة نفسها إلى نقطة بيع أخرى.',
          ),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Get.back(result: true), child: const Text('تأكيد التحويل')),
          ],
        ),
      ),
    );
    if (confirmed == true) await controller.transfer(batch);
  }
}
