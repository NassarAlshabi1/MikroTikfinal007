import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/distributors/distributors_list_controller.dart';
import '../../models/distributor_model.dart';
import '../widgets/shared/layouts/floating_button.dart';
import '../widgets/shared/layouts/sub_page_header.dart';
import '../widgets/shared/typography/section_title.dart';

class DistributorsListPage extends GetView<DistributorsListController> {
  const DistributorsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        floatingActionButton: FloatingButton(
          text: "إضافة موزع",
          iconBtn: Icons.person_add_alt_1_rounded,
          onPressed: controller.goToAdd,
        ),
        body: Column(
          children: [
            PremiumHeader(
              title: "الموزعون والمحاسبة",
              subtitle: "متابعة المبيعات والأرصدة والأرباح",
              icon: Icons.groups_rounded,
              goBack: Get.back,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  children: [
                    Obx(() => _totalsCard()),
                    const SectionTitle(title: "قائمة الموزعين"),
                    Obx(() {
                      if (controller.isLoading.value) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (controller.summaries.isEmpty) {
                        return _emptyState();
                      }
                      return Column(
                        children: controller.summaries
                            .map((summary) => _distributorCard(summary))
                            .toList(),
                      );
                    }),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalsCard() {
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
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                "الإجماليات العامة",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat("إجمالي المبيعات", controller.totalSales),
              _stat("إجمالي الأرباح", controller.totalProfit),
              _stat("صافي الأرصدة", controller.totalBalance),
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
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.groups_2_outlined, size: 44, color: Color(0xFF94A3B8)),
          SizedBox(height: 10),
          Text(
            "لا يوجد موزعون بعد.\nأضف أول موزع أو نقطة بيع لمتابعة حساباته.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _distributorCard(DistributorSummary summary) {
    final balance = summary.balance;
    final isDebit = balance >= 0;
    final badgeColor = isDebit ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => controller.goToStatement(summary.distributor),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.distributor.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            summary.distributor.phone.isEmpty
                                ? "بدون رقم هاتف"
                                : summary.distributor.phone,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${summary.balanceLabel} ${balance.abs().toStringAsFixed(0)}",
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniStat("المبيعات", summary.totalSales),
                    _miniStat("الأرباح", summary.profit),
                    _miniStat("الدفعات", summary.totalPayments),
                    _miniStat("الكروت", summary.cardsCount.toDouble()),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    IconButton(
                      tooltip: "تعديل",
                      onPressed: () => controller.goToEdit(summary.distributor),
                      icon: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF1E3A8A)),
                    ),
                    IconButton(
                      tooltip: "حذف",
                      onPressed: () => controller.deleteDistributor(summary.distributor),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                    ),
                    const Spacer(),
                    const Text(
                      "عرض كشف الحساب",
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                    const Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: Color(0xFF64748B)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, double value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          const SizedBox(height: 3),
          Text(
            value.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
