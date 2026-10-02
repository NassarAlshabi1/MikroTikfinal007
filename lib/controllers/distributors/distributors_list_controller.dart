import 'package:get/get.dart';

import '../../api/distributors_api.dart';
import '../../core/app_pages.dart';
import '../../controllers/dialog_helper.dart';
import '../../models/distributor_model.dart';
import '../helpers/confirm_dialog.dart';

class DistributorsListController extends GetxController {
  final RxList<DistributorSummary> summaries = <DistributorSummary>[].obs;
  final RxMap<String, double> totals = <String, double>{}.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;

    final summariesResponse = await DistributorsApi.getSummaries();
    final totalsResponse = await DistributorsApi.getTotals();

    isLoading.value = false;

    if (summariesResponse.status && summariesResponse.data != null) {
      summaries.assignAll(summariesResponse.data!);
    }
    if (totalsResponse.status && totalsResponse.data != null) {
      totals.assignAll(totalsResponse.data!);
    }
  }

  void goToAdd() => Get.toNamed(AppRoutes.distributorForm);

  void goToEdit(DistributorModel distributor) =>
      Get.toNamed(AppRoutes.distributorForm, arguments: distributor);

  void goToStatement(DistributorModel distributor) =>
      Get.toNamed(AppRoutes.distributorStatement, arguments: distributor);

  Future<void> deleteDistributor(DistributorModel distributor) async {
    final confirmed = await confirmAction(
      "حذف الموزع «${distributor.name}» وكل حركاته المالية؟",
    );
    if (!confirmed) return;

    final response = await DistributorsApi.deleteDistributor(distributor.id);
    await showMsgDialog(
      message: response.message,
      type: response.status ? MsgType.success : MsgType.error,
    );
    load();
  }

  double get totalSales => totals["sales"] ?? 0;
  double get totalProfit => totals["profit"] ?? 0;
  double get totalBalance => totals["balance"] ?? 0;
}
