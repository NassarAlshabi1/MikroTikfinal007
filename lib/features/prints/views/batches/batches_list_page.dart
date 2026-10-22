import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:mikronet/core/ui/widgets/sub_page_header.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:mikronet/features/prints/controllers/batches/batches_list_controller.dart';
import 'package:mikronet/app/routes/app_routes.dart';

class BatchesView extends GetView<BatchesListController> {
  const BatchesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.page,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.toNamed(AppRoutes.addBatch),
          backgroundColor: AppColors.info,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_card_rounded),
          label: const Text("إنشاء دفعة"),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 1. شريط التطبيق العلوي (MkCards مع الأيقونات والنقطة الخضراء)
              PremiumHeader(title: "دفعات الطباعة", subtitle: "إدارة دفعات الكروت المطبوعة", goBack: Get.back),

              // 2. المحتوى الرئيسي
              Expanded(
                child: GetBuilder<BatchesListController>(
                  builder: (ctrl) {
                    if (ctrl.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.cyan),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // بطاقات الإحصائيات العلوية (2 في 2)
                          _buildTopKpiGrid(ctrl),
                          const SizedBox(height: 16),

                          // قسم آخر الدفعات
                          _buildRecentBatchesSection(ctrl),
                          const SizedBox(height: 16),

                          // قسم الباقات
                          _buildProfilesSection(ctrl),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ================= 1. شريط التطبيق العلوي ================= */

  /* ================= 2. بطاقات الإحصائيات العلوية (2 في 2) ================= */
  Widget _buildTopKpiGrid(BatchesListController ctrl) {
    return Column(
      children: [
        Row(
          children: [
            // الباقات
            Expanded(
              child: _overviewCard(
                title: "الباقات",
                value: "${ctrl.profilesCount}",
                icon: Icons.grid_view_rounded,
              ),
            ),
            const SizedBox(width: 10),
            // الراوترات
            Expanded(
              child: _overviewCard(
                title: "الراوترات",
                value: "${ctrl.routersCount}",
                icon: Icons.router_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // الكروت المولدة
            Expanded(
              child: _overviewCard(
                title: "الكروت المولدة",
                value: "${ctrl.generatedCardsCount}",
                icon: Icons.style_rounded,
              ),
            ),
            const SizedBox(width: 10),
            // الدفعات
            Expanded(
              child: _overviewCard(
                title: "الدفعات",
                value: "${ctrl.batchesCount}",
                icon: Icons.history_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _overviewCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.panel, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.deepCyan,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.cyan, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }

  /* ================= 3. قسم آخر الدفعات مع الجدول والصفحات ================= */
  Widget _buildRecentBatchesSection(BatchesListController ctrl) {
    final displayItems = ctrl.currentPageBatches.map((batch) {
      final date = DateFormat('HH:mm yyyy-MM-dd').format(batch.createdAt);
      return <String, dynamic>{
        'id': batch.id,
        'count': batch.cards.length,
        'date': date,
        'profile': batch.cardsProfile.isNotEmpty ? batch.cardsProfile : '—',
        'status': 'محفوظة',
        'statusColor': AppColors.success,
      };
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.panel, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox.shrink(),
                Row(
                  children: [
                    const Text(
                      "آخر الدفعات",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.deepCyan,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.history_rounded, color: AppColors.cyan, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // رأس جدول الدفعات
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.cardDark,
              border: Border.symmetric(horizontal: BorderSide(color: AppColors.panel, width: 1)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "الحالة",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "الباقة",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    "التاريخ",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "العدد",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "الدف...",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          if (displayItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  ctrl.loadError.isNotEmpty
                      ? "تعذّر تحميل الدفعات: ${ctrl.loadError}"
                      : "لا توجد دفعات محفوظة لهذا الراوتر بعد. اضغط + لإنشاء دفعة.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            )
          else ...[
          // صفوف جدول الدفعات
          ...displayItems.map((item) {
            return InkWell(
              onTap: () {
                if (ctrl.allBatches.isNotEmpty) {
                  ctrl.getBatchCards(item['id'] as int);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.cardDark, width: 1)),
                ),
                child: Row(
                  children: [
                    // الحالة مع النقطة الملونة
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: item['statusColor'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item['status'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // الباقة
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['profile'].toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                    // التاريخ
                    Expanded(
                      flex: 4,
                      child: Text(
                        item['date'].toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textPale, fontSize: 10),
                      ),
                    ),
                    // العدد
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['count'].toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                    // رقم الدفعة
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['id'].toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          ],

          // شريط أزرار التنقل بين الصفحات (Pagination)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pageBtn(
                  label: "السابق >",
                  onTap: () => ctrl.prevPage(),
                  isActive: false,
                ),
                const SizedBox(width: 6),
                for (int i = ctrl.totalPages; i >= 1; i--) ...[
                  _pageNumberBtn(
                    number: i,
                    isActive: ctrl.currentPage == i,
                    onTap: () => ctrl.setPage(i),
                  ),
                  const SizedBox(width: 6),
                ],
                _pageBtn(
                  label: "< التالي",
                  onTap: () => ctrl.nextPage(),
                  isActive: false,
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageBtn({required String label, required VoidCallback onTap, required bool isActive}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.panel, width: 1),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _pageNumberBtn({required int number, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.cyan : AppColors.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? AppColors.cyan : AppColors.panel, width: 1),
        ),
        child: Text(
          "$number",
          style: TextStyle(
            color: isActive ? AppColors.ink : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /* ================= 4. قسم الباقات ================= */
  Widget _buildProfilesSection(BatchesListController ctrl) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.panel, width: 1),
      ),
      child: Column(
        children: [
          // عنوان قسم الباقات
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox.shrink(),
                Row(
                  children: [
                    const Text(
                      "الباقات",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.deepCyan,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.grid_view_rounded, color: AppColors.cyan, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (ctrl.profilesSummary.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 16),
              child: Text(
                "ستظهر الباقات هنا بعد إنشاء دفعات مرتبطة بها.",
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else ...[
          // عناصر الباقات
          ...ctrl.profilesSummary.map((prof) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.panel, width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            prof['name'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "الدفعات: ${prof['batches']} | الكروت المولدة: ${prof['cards']}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.deepCyan,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.grid_view_rounded, color: AppColors.cyan, size: 18),
                      ),
                    ],
                  ),
                  ),
                ],
              ),
            );
          }),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
