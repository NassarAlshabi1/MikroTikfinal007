import 'package:get/get.dart';
import 'package:mikronet/core/models/app_response.dart';
import 'package:mikronet/core/mikrotik/router_api.dart';
import 'package:mikronet/core/storage/db_api.dart';
import 'package:mikronet/core/ui/dialogs/dialog_helper.dart';
import 'package:mikronet/features/cards/data/profiles_api.dart';
import 'package:mikronet/features/distributors/data/distributors_api.dart';
import 'package:mikronet/features/distributors/models/distributor_model.dart';
import 'package:mikronet/features/prints/data/print_api.dart';

class TransferableBatch {
  final int id;
  final String name;
  final String profileName;
  final String customer;
  final int cardsCount;
  final double unitPrice;

  const TransferableBatch({
    required this.id,
    required this.name,
    required this.profileName,
    required this.customer,
    required this.cardsCount,
    required this.unitPrice,
  });
}

class DistributorStockTransferController extends GetxController {
  DistributorStockTransferController(this.distributor);

  final DistributorModel distributor;
  final RxList<TransferableBatch> batches = <TransferableBatch>[].obs;
  final RxBool isLoading = true.obs;
  final RxInt transferringBatchId = 0.obs;
  String loadError = '';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    loadError = '';
    try {
      final serialResponse = await RouterApi.getRouterSerial();
      final serial = serialResponse.data?.toString() ?? '';
      if (!serialResponse.status || serial.isEmpty) {
        throw Exception('تعذّر تحديد الراوتر المتصل');
      }

      final existing = await DBApi.select('distributor_stock_transfers');
      final transferredIds = existing
          .whereType<Map>()
          .where((row) => (row['router_serial'] ?? '').toString() == serial)
          .map((row) => int.tryParse(row['batch_id']?.toString() ?? '') ?? 0)
          .toSet();

      final profilesResponse = await ProfilesApi.getProfiles();
      if (!profilesResponse.status || profilesResponse.data == null) {
        throw Exception('تعذّر تحميل باقات User Manager وأسعارها');
      }
      final profiles = profilesResponse.data!;
      final sourceBatches = await PrintBatchesApi.getAllBatchesByRouter(serial);
      final result = <TransferableBatch>[];

      for (final raw in sourceBatches.whereType<Map>()) {
        final batchId = int.tryParse(raw['id']?.toString() ?? '') ?? 0;
        if (batchId <= 0 || transferredIds.contains(batchId)) continue;
        final cardRows = (raw['cards'] as List? ?? const []).whereType<Map>().toList();
        final usernames = cardRows
            .map((card) => (card['username'] ?? '').toString())
            .where((name) => name.isNotEmpty)
            .toSet();
        if (cardRows.isEmpty || usernames.length != cardRows.length) continue;

        final profileName = (raw['cards_profile'] ?? '').toString();
        final customer = (raw['customer'] ?? '').toString();
        final matches = profiles.where((profile) =>
            profile.name == profileName &&
            (customer.isEmpty || profile.customer == customer)).toList();
        if (matches.length != 1) continue;
        final price = double.tryParse(matches.first.price.trim());
        if (price == null || price < 0) continue;

        result.add(TransferableBatch(
          id: batchId,
          name: (raw['name'] ?? 'دفعة $batchId').toString(),
          profileName: profileName,
          customer: customer,
          cardsCount: cardRows.length,
          unitPrice: price,
        ));
      }

      batches.assignAll(result);
    } catch (e) {
      loadError = e.toString().replaceFirst('Exception: ', '');
      batches.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> transfer(TransferableBatch batch) async {
    if (transferringBatchId.value != 0) return;
    transferringBatchId.value = batch.id;
    try {
      final AppResponse<int> response = await DistributorsApi.transferBatchToDistributor(
        distributorId: distributor.id,
        batchId: batch.id,
      );
      await showMsgDialog(
        message: response.message,
        type: response.status ? MsgType.success : MsgType.error,
      );
      if (response.status) await load();
    } catch (e) {
      await showMsgDialog(message: e.toString(), type: MsgType.error);
    } finally {
      transferringBatchId.value = 0;
    }
  }
}
