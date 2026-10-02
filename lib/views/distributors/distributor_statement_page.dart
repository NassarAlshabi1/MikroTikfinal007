import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/distributors/distributor_statement_controller.dart';
import '../../models/distributor_model.dart';
import '../widgets/shared/layouts/gradient_button.dart';
import '../widgets/shared/layouts/sub_page_header.dart';
import '../widgets/shared/typography/section_title.dart';

class DistributorStatementPage extends GetView<DistributorStatementController> {
  const DistributorStatementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            PremiumHeader(
              title: controller.distributor.name,
              subtitle: "كشف الحساب والحركات المالية",
              icon: Icons.receipt_long_rounded,
              goBack: Get.back,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  children: [
                    Obx(() => _summaryCard()),
                    const SectionTitle(title: "تسجيل حركة جديدة"),
                    Row(
                      children: [
                        Expanded(
                          child: _typeButton(
                            "بيع كروت",
                            Icons.point_of_sale_rounded,
                            const Color(0xFF2563EB),
                            () => controller.openAddTransactionDialog(DistributorTxType.sale),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _typeButton(
                            "دفعة",
                            Icons.payments_rounded,
                            const Color(0xFF10B981),
                            () => controller.openAddTransactionDialog(DistributorTxType.payment),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _typeButton(
                            "مرتجع",
                            Icons.assignment_return_rounded,
                            const Color(0xFFF59E0B),
                            () => controller.openAddTransactionDialog(DistributorTxType.refund),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GradientButton(
                      label: "تصدير كشف الحساب PDF",
                      icon: Icons.picture_as_pdf_rounded,
                      height: 48,
                      colors: const [Color(0xFF7C3AED), Color(0xFFA855F7)],
                      onPressed: controller.exportPdf,
                    ),
                    const SectionTitle(title: "الحركات"),
                    Obx(() {
                      if (controller.isLoading.value) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (controller.transactions.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            "لا توجد حركات مسجلة لهذا الموزع بعد.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        );
                      }
                      return Column(
                        children: controller.transactions
                            .map((transaction) => _transactionTile(transaction))
                            .toList(),
                      );
                    }),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final summary = controller.summary.value;
    if (summary == null) {
      return const SizedBox(height: 10);
    }

    final balance = summary.balance;
    final isDebit = balance >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "الرصيد الحالي",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isDebit ? const Color(0xFFF59E0B) : const Color(0xFF10B981))
                      .withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  summary.balanceLabel,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              balance.abs().toStringAsFixed(2),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26),
            ),
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            children: [
              _stat("المبيعات", summary.totalSales),
              _stat("الأرباح", summary.profit),
              _stat("الدفعات", summary.totalPayments),
              _stat("الكروت", summary.cardsCount.toDouble()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, double value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(0),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _typeButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transactionTile(DistributorTransactionModel transaction) {
    final isSale = transaction.type == DistributorTxType.sale;
    final color = isSale
        ? const Color(0xFF2563EB)
        : transaction.type == DistributorTxType.payment
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSale
                  ? Icons.point_of_sale_rounded
                  : transaction.type == DistributorTxType.payment
                      ? Icons.payments_rounded
                      : Icons.assignment_return_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${transaction.type.arabicLabel}${transaction.cardsCount > 0 ? " • ${transaction.cardsCount} كرت" : ""}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 3),
                Text(
                  "${transaction.txDate}${transaction.note.isEmpty ? "" : " • ${transaction.note}"}",
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.amount.toStringAsFixed(2),
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14),
              ),
              if (isSale && transaction.profit != 0)
                Text(
                  "ربح ${transaction.profit.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
            ],
          ),
          IconButton(
            onPressed: () => controller.deleteTransaction(transaction),
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }
}
