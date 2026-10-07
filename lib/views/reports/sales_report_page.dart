import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/controllers/reports/sales_report_controller.dart';

class SalesReportPage extends GetView<SalesReportController> {
  const SalesReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SalesReportController>()) {
      Get.put(SalesReportController());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF070F1E),
        body: SafeArea(
          child: Column(
            children: [
              // 1. شريط التطبيق العلوي (MkCards مع الأيقونات والنقطة الخضراء)
              _buildTopAppBar(),

              // 2. المحتوى الرئيسي القابل للتمرير
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // كارد العنوان وأزرار المزامنة والتصدير
                      _buildHeaderCard(controller),
                      const SizedBox(height: 12),

                      // لوحة الفلاتر (التواريخ، الأجهزة، الباقات، نقاط البيع، الحالة)
                      _buildFiltersPanel(context, controller),
                      const SizedBox(height: 14),

                      // شبكة بطاقات الإحصائيات (2 في 3)
                      Obx(() => _buildKpiGrid(controller)),
                      const SizedBox(height: 14),

                      // جدول تفصيل الباقات والمبيعات
                      Obx(() => _buildBreakdownTable(controller)),
                      const SizedBox(height: 12),

                      // شريط الملخص السفلي
                      _buildBottomSummaryBar(controller),
                      const SizedBox(height: 16),
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
          // الأيقونات على اليسار
          Row(
            children: [
              _topIconBtn(Icons.language_rounded, () {}),
              const SizedBox(width: 8),
              _topIconBtn(Icons.wb_sunny_outlined, () {}),
              const SizedBox(width: 8),
              _topIconBtn(Icons.logout_rounded, () {}),
            ],
          ),

          // العنوان في الوسط مع النقطة الخضراء
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

          // زر الرجوع في اليمين
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

  /* ================= 2. كارد العنوان وأزرار الإجراءات ================= */
  Widget _buildHeaderCard(SalesReportController controller) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1726),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2E44), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F3B4C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calculate_rounded, color: Color(0xFF38E5FF), size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "الحسابات المالية",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    "آخر مزامنة: ${controller.lastSyncTime.value}",
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // أزرار المزامنة والتصدير والتحديث
          Row(
            children: [
              // زر مزامنة الآن (Cyan Pill)
              Expanded(
                flex: 3,
                child: Obx(() => ElevatedButton.icon(
                  onPressed: controller.isSyncing.value ? null : () => controller.syncFromRouter(silent: false),
                  icon: controller.isSyncing.value
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFF070F1E), strokeWidth: 2))
                      : const Icon(Icons.sync_rounded, color: Color(0xFF070F1E), size: 18),
                  label: const Text(
                    "مزامنة الآن",
                    style: TextStyle(color: Color(0xFF070F1E), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38E5FF),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                )),
              ),
              const SizedBox(width: 8),
              // زر تصدير CSV (Dark Button)
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: () => controller.exportCsv(),
                  icon: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                  label: const Text(
                    "تصدير CSV",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF131D2E),
                    side: const BorderSide(color: Color(0xFF38E5FF), width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // زر Refresh
              InkWell(
                onTap: () => controller.fetchReport(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131D2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1E2E44), width: 1),
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* ================= 3. لوحة الفلاتر ================= */
  Widget _buildFiltersPanel(BuildContext context, SalesReportController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1726),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2E44), width: 1),
      ),
      child: Column(
        children: [
          // 1. صفي التواريخ
          Row(
            children: [
              Expanded(
                child: _buildDateBox(
                  context,
                  controller.fromDate,
                  () => controller.pickFromDate(context),
                  () => controller.clearFromDate(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDateBox(
                  context,
                  controller.toDate,
                  () => controller.pickToDate(context),
                  () => controller.clearToDate(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. صفي الأجهزة والباقات
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildDropdown(
                  icon: Icons.router_rounded,
                  value: controller.selectedDevice.value,
                  items: controller.availableDevices,
                  onChanged: (v) {
                    if (v != null) controller.selectedDevice.value = v;
                  },
                )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(() => _buildDropdown(
                  icon: Icons.confirmation_number_rounded,
                  value: controller.selectedProfile.value,
                  items: controller.availableProfiles,
                  onChanged: (v) {
                    if (v != null) {
                      controller.selectedProfile.value = v;
                      controller.fetchReport();
                    }
                  },
                )),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. صف نقاط البيع
          Obx(() => _buildDropdown(
            icon: Icons.storefront_rounded,
            value: controller.selectedDistributor.value,
            items: controller.availableDistributors,
            onChanged: (v) {
              if (v != null) controller.selectedDistributor.value = v;
            },
          )),
          const SizedBox(height: 10),

          // 4. صف الحالة (منتهي / نشط / الكل)
          Obx(() => _buildDropdown(
            icon: Icons.filter_alt_rounded,
            value: controller.selectedStatus.value,
            items: controller.statusOptions,
            onChanged: (v) {
              if (v != null) {
                controller.selectedStatus.value = v;
                controller.fetchReport();
              }
            },
          )),
          const SizedBox(height: 10),

          // 5. صف أزرار المعاينة وتقرير الأجهزة PDF والإلغاء
          Row(
            children: [
              // زر المعاينة بالعين
              InkWell(
                onTap: () => controller.fetchReport(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38E5FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.remove_red_eye_rounded, color: Color(0xFF070F1E), size: 20),
                ),
              ),
              const SizedBox(width: 10),
              // زر تقرير اجهزة pdf
              Expanded(
                child: InkWell(
                  onTap: () => controller.generatePdfReport(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF38E5FF), width: 1.2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "تقرير اجهزة pdf",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // زر X للإلغاء
              InkWell(
                onTap: () => controller.clearAllFilters(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155), width: 1),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(BuildContext context, Rx<DateTime?> dateRx, VoidCallback onPick, VoidCallback onClear) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF131D2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38E5FF).withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onPick,
            child: Row(
              children: [
                Obx(() {
                  final d = dateRx.value;
                  final text = d != null ? "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}" : "اختر التاريخ";
                  return Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  );
                }),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
          InkWell(
            onTap: onClear,
            child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131D2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2E44), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF38E5FF), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.contains(value) ? value : items.firstOrNull,
                dropdownColor: const Color(0xFF131D2E),
                icon: const Icon(Icons.unfold_more_rounded, color: Color(0xFF94A3B8), size: 18),
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= 4. شبكة الـ KPIs (2 في 3) ================= */
  Widget _buildKpiGrid(SalesReportController controller) {
    return Column(
      children: [
        // الصف 1: إجمالي الكروت | الكروت الفعالة
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                title: "الكروت الفعالة",
                value: "${controller.activeCards.value}",
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF22C55E),
                valueColor: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                title: "إجمالي الكروت",
                value: "${controller.totalCards.value}",
                icon: Icons.confirmation_number_rounded,
                iconColor: const Color(0xFF38E5FF),
                valueColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // الصف 2: إجمالي البيع | الكروت المنتهية
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                title: "إجمالي البيع",
                value: _formatNumber(controller.totalSales.value),
                icon: Icons.point_of_sale_rounded,
                iconColor: const Color(0xFF38E5FF),
                valueColor: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                title: "الكروت المنتهية",
                value: "${controller.expiredCards.value}",
                icon: Icons.cancel_rounded,
                iconColor: const Color(0xFFEF4444),
                valueColor: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // الصف 3: الربح | إجمالي المدفوعات
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                title: "الربح",
                value: _formatNumber(controller.netProfit.value),
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF22C55E),
                valueColor: const Color(0xFF22C55E),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                title: "إجمالي المدفوعات",
                value: _formatNumber(controller.totalPayments.value),
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFFF59E0B),
                valueColor: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color valueColor,
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                style: TextStyle(
                  color: valueColor,
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

  /* ================= 5. جدول تفصيل الباقات ================= */
  Widget _buildBreakdownTable(SalesReportController controller) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1726),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2E44), width: 1),
      ),
      child: Column(
        children: [
          // رأس الجدول باللون الأزرق الفاتح / Cyan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF38E5FF),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "الباقة",
                    style: TextStyle(color: Color(0xFF070F1E), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "عدد الكروت",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF070F1E), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "الفعالة",
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Color(0xFF070F1E), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // صفوف البيانات
          ...controller.tableRows.map((row) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E2E44), width: 0.8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      row['profile']?.toString() ?? "100c",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "${row['count'] ?? 91}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "${row['active'] ?? 0}",
                      textAlign: TextAlign.left,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }),

          // صف الإجمالي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF131D2E),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    "الإجمالي",
                    style: TextStyle(color: Color(0xFF38E5FF), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "${controller.tableRows.fold<int>(0, (sum, item) => sum + (item['count'] as int? ?? 0))}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "${controller.tableRows.fold<int>(0, (sum, item) => sum + (item['active'] as int? ?? 0))}",
                    textAlign: TextAlign.left,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ================= 6. شريط الملخص السفلي ================= */
  Widget _buildBottomSummaryBar(SalesReportController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1726),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2E44), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 16),
              const SizedBox(width: 6),
              const Text("مدفوعات مسبقة: 61", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              const SizedBox(width: 12),
              Text("الكروت ${controller.expiredCards.value}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            ],
          ),
          const Row(
            children: [
              Icon(Icons.unfold_more_rounded, color: Color(0xFF94A3B8), size: 16),
              SizedBox(width: 4),
              Text("1/1 صفحة", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(double num) {
    if (num >= 1000) {
      return NumberFormat("#,##0", "en_US").format(num);
    }
    return num.toStringAsFixed(0);
  }
}
