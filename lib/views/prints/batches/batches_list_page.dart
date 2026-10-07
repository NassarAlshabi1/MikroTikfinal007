import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../controllers/prints/batches/batches_list_controller.dart';
import '../../../controllers/prints/batches/add_batch_controller.dart';
import 'add_batch_page.dart';

class BatchesView extends GetView<BatchesListController> {
  const BatchesView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BatchesListController>()) {
      Get.put(BatchesListController());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF070F1E),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0EA5E9),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.playlist_add_rounded),
          label: const Text("إنشاء دفعة"),
          onPressed: () async {
            await Get.to(
              () => AddBatchView(controller: BatchesFormController()),
            );
            await controller.getAllBatches2();
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 1. شريط التطبيق العلوي (MkCards مع الأيقونات والنقطة الخضراء)
              _buildTopAppBar(),

              // 2. المحتوى الرئيسي
              Expanded(
                child: GetBuilder<BatchesListController>(
                  builder: (ctrl) {
                    if (ctrl.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF38E5FF)),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 96),
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
  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF070F1E),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _topIconBtn(Icons.language_rounded, () {}),
              const SizedBox(width: 8),
              _topIconBtn(Icons.wb_sunny_outlined, () {}),
              const SizedBox(width: 8),
              _topIconBtn(Icons.logout_rounded, () {}),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "MkCards",
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          _topIconBtn(Icons.arrow_forward_rounded, () => Get.back()),
        ],
      ),
    );
  }

  Widget _topIconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E293B), width: 1),
        ),
        child: Icon(icon, color: const Color(0xFF38BDF8), size: 18),
      ),
    );
  }

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
                title: "الدفوعات",
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
        color: const Color(0xFF0D1726),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2E44), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3B4C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF38E5FF), size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
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
        ],
      ),
    );
  }

  /* ================= 3. قسم آخر الدفعات مع الجدول والصفحات ================= */
  Widget _buildRecentBatchesSection(BatchesListController ctrl) {
    final displayItems = ctrl.currentPageBatches.map((batch) {
      return {
        'id': batch.id,
        'count': ctrl.cardCountForBatch(batch),
        'date': DateFormat('HH:mm yyyy-MM-dd').format(batch.createdAt),
        'profile': batch.cardsProfile.trim().isEmpty
            ? 'غير محددة'
            : batch.cardsProfile.trim(),
        'status': ctrl.statusForBatch(batch),
        'statusColor': ctrl.statusColorForBatch(batch),
      };
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1726),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2E44), width: 1),
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
                        color: const Color(0xFF0F3B4C),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.history_rounded, color: Color(0xFF38E5FF), size: 16),
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
              color: Color(0xFF131D2E),
              border: Border.symmetric(horizontal: BorderSide(color: Color(0xFF1E2E44), width: 1)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "الحالة",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "الباقة",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    "التاريخ",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "العدد",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "الدف...",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          if (ctrl.loadError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ctrl.loadError,
                      style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 12),
                    ),
                  ),
                  IconButton(
                    tooltip: "إعادة المحاولة",
                    onPressed: ctrl.getAllBatches2,
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
                  ),
                ],
              ),
            ),
          if (displayItems.isEmpty && ctrl.loadError.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, color: Color(0xFF64748B), size: 32),
                  SizedBox(height: 8),
                  Text(
                    "لا توجد دفعات محفوظة لهذا الراوتر بعد",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "أنشئ دفعة جديدة لتظهر بياناتها هنا",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ),

          // صفوف مبنية من سجلات الدفعات الفعلية فقط.
          ...displayItems.map((item) {
            return InkWell(
              onTap: () => ctrl.getBatchCards(item['id'] as int),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF131D2E), width: 1)),
                ),
                child: Row(
                  children: [
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
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['profile'].toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        item['date'].toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['count'].toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['id'].toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // لا نظهر تنقل الصفحات إلا إذا وُجدت أكثر من صفحة فعلية.
          if (displayItems.isNotEmpty && ctrl.totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          color: const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E2E44), width: 1),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
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
          color: isActive ? const Color(0xFF38E5FF) : const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? const Color(0xFF38E5FF) : const Color(0xFF1E2E44), width: 1),
        ),
        child: Text(
          "$number",
          style: TextStyle(
            color: isActive ? const Color(0xFF070F1E) : Colors.white,
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
        color: const Color(0xFF0D1726),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2E44), width: 1),
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
                        color: const Color(0xFF0F3B4C),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.grid_view_rounded, color: Color(0xFF38E5FF), size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // عناصر الباقات الفعلية من الدفعات المحفوظة.
          if (ctrl.profilesSummary.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 20),
              child: Text(
                "لا توجد باقات ضمن الدفعات المحفوظة",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            )
          else
            ...ctrl.profilesSummary.map((prof) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E2E44), width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.chevron_left_rounded, color: Color(0xFF94A3B8), size: 20),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              prof['name'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "الدفعات: ${prof['batches']} | الكروت المولدة: ${prof['cards']}",
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F3B4C),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.grid_view_rounded, color: Color(0xFF38E5FF), size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
