import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/distributors_api.dart';
import '../../controllers/dialog_helper.dart';
import '../../models/distributor_model.dart';
import '../../services/distributor_pdf.dart';
import '../helpers/confirm_dialog.dart';

class DistributorStatementController extends GetxController {
  DistributorStatementController(this.distributor);

  final DistributorModel distributor;

  final RxList<DistributorTransactionModel> transactions = <DistributorTransactionModel>[].obs;
  final Rx<DistributorSummary?> summary = Rx<DistributorSummary?>(null);
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;

    final summaryResponse = await DistributorsApi.getSummary(distributor.id);
    final transactionsResponse = await DistributorsApi.getTransactions(distributor.id);

    isLoading.value = false;

    if (summaryResponse.status) summary.value = summaryResponse.data;
    if (transactionsResponse.status && transactionsResponse.data != null) {
      transactions.assignAll(transactionsResponse.data!);
    }
  }

  Future<void> openAddTransactionDialog(DistributorTxType type) async {
    final cardsCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final confirmed = await Get.dialog<bool>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(type.arabicLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type == DistributorTxType.sale)
                  TextField(
                    controller: cardsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "عدد الكروت"),
                  ),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "المبلغ الإجمالي"),
                ),
                if (type == DistributorTxType.sale)
                  TextField(
                    controller: costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "التكلفة الإجمالية (اختياري)"),
                  ),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: "ملاحظة"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
              child: const Text("حفظ", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      await showMsgDialog(message: "يرجى إدخال مبلغ صحيح", type: MsgType.warning);
      return;
    }

    final response = await DistributorsApi.addTransaction(
      distributorId: distributor.id,
      type: type,
      amount: amount,
      cost: double.tryParse(costCtrl.text.trim()) ?? 0,
      cardsCount: int.tryParse(cardsCtrl.text.trim()) ?? 0,
      note: noteCtrl.text.trim(),
    );

    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );

    if (response.status) load();
  }

  Future<void> deleteTransaction(DistributorTransactionModel transaction) async {
    final confirmed = await confirmAction(
      "حذف هذه الحركة (${transaction.type.arabicLabel} - ${transaction.amount})؟",
    );
    if (!confirmed) return;

    final response = await DistributorsApi.deleteTransaction(transaction.id);
    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
    if (response.status) load();
  }

  /// تصدير كشف الحساب PDF ومشاركته.
  Future<void> exportPdf() async {
    final currentSummary = summary.value;
    if (currentSummary == null) {
      await showMsgDialog(message: "لا توجد بيانات للتصدير", type: MsgType.warning);
      return;
    }

    showLoadingDialog();
    try {
      await DistributorPdf.exportStatement(
        summary: currentSummary,
        transactions: transactions,
      );
      hideDialog();
    } catch (e) {
      hideDialog();
      await showMsgDialog(message: "تعذّر إنشاء التقرير:\n$e", type: MsgType.error);
    }
  }
}
