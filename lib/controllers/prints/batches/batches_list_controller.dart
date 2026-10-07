import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/views/prints/batches/batch_cards_page.dart';
import 'package:mikronet/views/prints/templates/pdf_view.dart';
import '../../../api/router_api.dart';
import '../../dialog_helper.dart';
import '/views/helpers/dialogs.dart';
import '/api/print_api.dart';
import '/models/print_model.dart';

class BatchesListController extends GetxController {
  List<PrintBatchesModel> allBatches = [];
  bool isLoading = false;
  bool isDeleteLoading = false;
  var routerSerial = "";

  // إحصائيات محسوبة من الدفعات المحفوظة، ولا تُعرض بيانات افتراضية.
  int routersCount = 0;
  int profilesCount = 0;
  int batchesCount = 0;
  int generatedCardsCount = 0;
  String loadError = "";

  // الباقات وملخصها
  List<Map<String, dynamic>> profilesSummary = [];

  // الصفحات
  int currentPage = 1;
  final int itemsPerPage = 10;
  int totalPages = 1;

  @override
  void onInit() {
    super.onInit();
    getAllBatches2();
  }

  Future<void> getRouterSerial() async {
    var res = await RouterApi.getRouterSerial();
    if (!res.status) {
      await showMsgDialog(message: res.message, type: MsgType.error);
      Get.back();
    }
    routerSerial = res.data.toString();
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      currentPage = page;
      update();
    }
  }

  void nextPage() {
    if (currentPage < totalPages) {
      currentPage++;
      update();
    }
  }

  void prevPage() {
    if (currentPage > 1) {
      currentPage--;
      update();
    }
  }

  List<PrintBatchesModel> get currentPageBatches {
    if (allBatches.isEmpty) return [];
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage > allBatches.length)
        ? allBatches.length
        : start + itemsPerPage;
    if (start >= allBatches.length) return [];
    return allBatches.sublist(start, end);
  }

  int cardCountForBatch(PrintBatchesModel batch) {
    return batch.generatedCards.isNotEmpty
        ? batch.generatedCards.length
        : batch.cards.length;
  }

  int uploadedCardCountForBatch(PrintBatchesModel batch) {
    return batch.cards.where((card) {
      if (card is! Map) return false;
      final value = card['is_add'];
      return value == true || value?.toString() == '1';
    }).length;
  }

  String statusForBatch(PrintBatchesModel batch) {
    final total = cardCountForBatch(batch);
    final uploaded = uploadedCardCountForBatch(batch);
    if (total == 0) return "لا توجد كروت";
    if (uploaded >= total) return "مكتملة";
    if (uploaded > 0) return "مكتملة جزئيًا";
    return "بانتظار الإضافة";
  }

  Color statusColorForBatch(PrintBatchesModel batch) {
    final total = cardCountForBatch(batch);
    final uploaded = uploadedCardCountForBatch(batch);
    if (total > 0 && uploaded >= total) return const Color(0xFF22C55E);
    if (uploaded > 0) return const Color(0xFFF59E0B);
    return const Color(0xFF94A3B8);
  }

  Future<void> deleteBatch(PrintBatchesModel batch, int deleteOption) async {
    isDeleteLoading = true;
    update();
    try {
      String response = "";
      if (deleteOption == 1) {
        response = (await PrintBatchesApi.deleteFromServer(batch.id)) == "done" ? "1" : "0";
      } else if (deleteOption == 2) {
        response = (await PrintBatchesApi.deleteFromLocal(batch.id)) > 0 ? "2" : "0";
      } else if (deleteOption == 3) {
        response = (await PrintBatchesApi.deleteBatch(batch.id)) == "done" ? "3" : "0";
      }
      if (response == "1") {
        try {
          await PrintBatchesApi.setBatchCardsAddedStatus(
            batch.id,
            isAdded: false,
          );
        } catch (_) {}
        for (final card in batch.cards) {
          if (card is Map) card['is_add'] = 0;
        }
        _computeStats();
        Get.back();
        update();
      } else if (response == "2" || response == "3") {
        allBatches.removeWhere((item) => item.id == batch.id);
        _computeStats();
        Get.back();
        update();
      }
    } catch (e) {
      showErrorDialog(content: e.toString());
    } finally {
      isDeleteLoading = false;
      update();
    }
  }

  Future<void> editBatch(PrintBatchesModel batch, String name, DateTime date) async {
    try {
      if (name.trim().isNotEmpty) {
        int r = await PrintBatchesApi.batchEdit(
          batch.id, 
          {
            'name': name.trim(),
            'created_at': date.microsecondsSinceEpoch,
          }
        );
        if (r > 0) {
          batch.name = name.trim();
          batch.createdAt = date;
          Get.back();
          update();
        }
      }
    } catch (e) {
      showErrorDialog(content: e.toString());
    }
  }

  Future<void> getBatchCards(int id) async {
    try {
      await getAllBatches2();
      var r = allBatches.firstWhere((b) => b.id == id);
      var cards = List.generate(r.cards.length, (i) {
        return GeneratedCardsModel.fromDatabase(r.cards[i]);
      });
      await Get.to(GeneratedCardsView(cards));
      await getAllBatches2();
    } catch (e) {
      showErrorDialog(content: e.toString());
    }
  }

  Future<void> getBatchPreview(int batchId) async {
    try {
      var batch = allBatches.firstWhere((b) => b.id == batchId);
      var response = await PrintTemplatesApi.getTemplateData(batch.templateId);
      PrintTemplatesModel template = PrintTemplatesModel.fromDatabase(response);
      
      var cards = List.generate(batch.cards.length, (i) {
        return GeneratedCardsModel.fromDatabase(batch.cards[i]);
      });
      List usernames = cards.map((c) => c.username).toList();
      List passwords = cards.map((c) => c.password).toList();
      Get.to(PdfView(
        usernames: usernames, 
        passwords: passwords, 
        template: template,
        saveFile: false,
      ));
    } catch (e) {
      showErrorDialog(content: e.toString());
    }
  }

  Future<void> getAllBatches2() async {
    isLoading = true;
    loadError = "";
    update();
    try {
      final serialResponse = await RouterApi.getRouterSerial();
      final serial = serialResponse.data?.trim() ?? "";
      if (!serialResponse.status || serial.isEmpty) {
        throw Exception(
          serialResponse.message.isNotEmpty
              ? serialResponse.message
              : "تعذّر قراءة الرقم التسلسلي للراوتر",
        );
      }

      routerSerial = serial;
      final result = await PrintBatchesApi.getAllBatchesByRouter(serial);
      final batches = <PrintBatchesModel>[];
      for (final row in result) {
        if (row is! Map) {
          throw const FormatException("صيغة سجل دفعة غير صالحة");
        }
        batches.add(PrintBatchesModel.fromDatabase(row));
      }
      batches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      allBatches = batches;
    } catch (e) {
      allBatches = [];
      currentPage = 1;
      loadError = "تعذّر تحميل دفعات الكروت: $e";
    } finally {
      _computeStats();
      isLoading = false;
      update();
    }
  }

  void _computeStats() {
    batchesCount = allBatches.length;
    generatedCardsCount = 0;

    final routerSerials = <String>{};
    final profiles = <String, Map<String, dynamic>>{};

    for (final batch in allBatches) {
      final serial = batch.routerSerial.trim();
      if (serial.isNotEmpty) routerSerials.add(serial);

      final profile = batch.cardsProfile.trim().isEmpty
          ? "غير محددة"
          : batch.cardsProfile.trim();
      final cardCount = cardCountForBatch(batch);
      generatedCardsCount += cardCount;

      final summary = profiles.putIfAbsent(
        profile,
        () => {'name': profile, 'batches': 0, 'cards': 0},
      );
      summary['batches'] = (summary['batches'] as int) + 1;
      summary['cards'] = (summary['cards'] as int) + cardCount;
    }

    routersCount = routerSerials.length;
    profilesCount = profiles.length;
    profilesSummary = profiles.values.toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    totalPages = (allBatches.length / itemsPerPage).ceil();
    if (totalPages < 1) totalPages = 1;
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
  }
}
