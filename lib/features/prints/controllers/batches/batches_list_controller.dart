import 'package:get/get.dart';
import 'package:mikronet/features/prints/views/batches/batch_cards_page.dart';
import 'package:mikronet/features/prints/views/templates/pdf_view.dart';
import 'package:mikronet/core/mikrotik/router_api.dart';
import 'package:mikronet/core/ui/dialogs/dialog_helper.dart';
import 'package:mikronet/features/prints/data/print_api.dart';
import 'package:mikronet/features/prints/models/print_model.dart';

class BatchesListController extends GetxController {
  List<PrintBatchesModel> allBatches = [];
  bool isLoading = false;
  bool isDeleteLoading = false;
  String loadError = "";
  var routerSerial = "";

  // تُعرض إحصائيات حقيقية فقط؛ لا تُستخدم أرقام نموذجية عند غياب البيانات.
  int routersCount = 0;
  int profilesCount = 0;
  int batchesCount = 0;
  int generatedCardsCount = 0;

  // الباقات وملخصها
  List<Map<String, dynamic>> profilesSummary = [];

  // الصفحات
  int currentPage = 1;
  final int itemsPerPage = 10;
  int totalPages = 4;

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
    final end = (start + itemsPerPage > allBatches.length) ? allBatches.length : start + itemsPerPage;
    if (start >= allBatches.length) return [];
    return allBatches.sublist(start, end);
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
        Get.back();
        update();
      } else if (response == "2" || response == "3") {
        allBatches.remove(batch);
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
      Get.to(GeneratedCardsView(cards, customerName: r.customer));
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
      final serial = await RouterApi.getRouterSerial();
      if (!serial.status || serial.data == null || serial.data.toString().isEmpty) {
        throw StateError("تعذّر قراءة الرقم التسلسلي للراوتر");
      }
      final result = await PrintBatchesApi.getAllBatchesByRouter(serial.data.toString());
      List<PrintBatchesModel> temp = [];
      if (result.isNotEmpty) {
        for (var i in result) {
          temp.add(PrintBatchesModel.fromDatabase(i)); 
        }
      }
      allBatches = temp;

      // حساب الإحصائيات
      _computeStats();
    } catch (e) {
      loadError = e.toString();
      _computeStats();
    } finally {
      isLoading = false;
      update();
    }
  }

  void _computeStats() {
    if (allBatches.isNotEmpty) {
      batchesCount = allBatches.length;
      int tCards = 0;
      final Map<String, Map<String, dynamic>> profMap = {};

      for (var b in allBatches) {
        tCards += b.cards.length;
        final prof = b.cardsProfile.isNotEmpty ? b.cardsProfile : "—";
        if (!profMap.containsKey(prof)) {
          profMap[prof] = {'name': prof, 'batches': 0, 'cards': 0};
        }
        profMap[prof]!['batches'] = (profMap[prof]!['batches'] as int) + 1;
        profMap[prof]!['cards'] = (profMap[prof]!['cards'] as int) + b.cards.length;
      }

      generatedCardsCount = tCards;
      profilesCount = profMap.isNotEmpty ? profMap.length : 12;
      routersCount = 1;

      profilesSummary = profMap.values.toList();
      totalPages = (allBatches.length / itemsPerPage).ceil();
      if (totalPages < 1) totalPages = 1;
    } else {
      routersCount = 0;
      profilesCount = 0;
      batchesCount = 0;
      generatedCardsCount = 0;
      totalPages = 1;
      currentPage = 1;
      profilesSummary = [];
    }
  }
}
