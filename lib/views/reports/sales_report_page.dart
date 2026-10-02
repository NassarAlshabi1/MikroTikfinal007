import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/shared/layouts/main_gate_header.dart';
// import '../widgets/shared/layouts/app_mini_footer.dart';
 import '/controllers/reports/sales_report_controller.dart'; // مسار المتحكم الذي أنشأناه

class SalesReportPage extends GetView<SalesReportController> {
  const SalesReportPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // الهيدر المشترك
            const MainGateHeader( // استبدلها بالويدجت الخاصة بك
              title: "تقرير المبيعات",
              subtitle: "إحصائيات الإيرادات وحركة الكروت المباعة",
              icon: Icons.point_of_sale_rounded,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                children: [
                  // 1. حقول اختيار التاريخ
                  _buildDateSelectors(context, controller),
                  const SizedBox(height: 20),

                  // 2. الكارد الكبير للملخص
                  Obx(() => _buildSummaryCard(controller)),
                  const SizedBox(height: 20),

                  // 3. قائمة الكروت المباعة (الكروت الصغيرة)
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)));
                    }
                    if (controller.salesList.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text("لا توجد مبيعات في هذه الفترة", style: TextStyle(color: Colors.grey)),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.salesList.length,
                      itemBuilder: (context, index) {
                        final item = controller.salesList[index];
                        return _buildSmallCard(item);
                      },
                    );
                  }),
                ],
              ),
            ),

            // منطقة الأزرار في الفوتر
            _buildActionButtons(controller),
            
            // الفوتر المشترك
           // const AppMiniFooter(title: Text( "إدارة تقارير النظام")), // استبدلها بالويدجت الخاصة بك
          ],
        ),
      ),
    );
  }

  // --- ويدجت حقول التواريخ ---
  Widget _buildDateSelectors(BuildContext context, SalesReportController controller) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => controller.pickFromDate(context),
            child: _dateContainer("من تاريخ", controller.fromDate),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: InkWell(
            onTap: () => controller.pickToDate(context),
            child: _dateContainer("إلى تاريخ", controller.toDate),
          ),
        ),
      ],
    );
  }

  Widget _dateContainer(String label, Rx<DateTime?> dateRx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range_rounded, color: Color(0xFF1E3A8A), size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Obx(() => Text(
                dateRx.value != null ? "${dateRx.value!.year}-${dateRx.value!.month}-${dateRx.value!.day}" : "اختر التاريخ",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              )),
            ],
          ),
        ],
      ),
    );
  }

  // --- ويدجت الكارد الكبير (الملخص) ---
  Widget _buildSummaryCard(SalesReportController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], // تدرج أزرق مشابه لهوية التطبيق
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ملخص المبيعات الإجمالي", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem("إجمالي الكروت", "${controller.totalCards.value} كرت", Icons.style_rounded),
              _summaryItem("إجمالي المبلغ", "${controller.totalRevenue.value} ريال", Icons.account_balance_wallet_rounded),
            ],
          ),
          
          if (controller.summaryByProfile.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(color: Colors.white24, height: 1),
            ),
            const Text("تفصيل حسب الفئة:", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            // إنشاء تفاصيل الفئات ديناميكياً
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: controller.summaryByProfile.entries.map((entry) {
                String profile = entry.key;
                int count = entry.value['count'];
                double total = entry.value['total'];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("فئة $profile", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text("$count كرت = $total ريال", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ]
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // --- ويدجت الكروت الصغيرة ---
  Widget _buildSmallCard(item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF1E3A8A), size: 20),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.card, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(item.date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${item.price} ريال", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text("باقة ${item.profile}", style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- منطقة الأزرار أسفل الصفحة ---
  Widget _buildActionButtons(SalesReportController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => controller.fetchReport(),
              icon: const Icon(Icons.sync_rounded, color: Colors.white),
              label: const Text("توليد التقرير", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A), // اللون الأزرق الرئيسي
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: () => controller.printReport(),
              icon: const Icon(Icons.print_rounded, color: Color(0xFF1E3A8A)),
              label: const Text("طباعة", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}