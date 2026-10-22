import 'package:mikronet/core/storage/db_api.dart';
import 'package:mikronet/features/distributors/models/distributor_model.dart';
import 'package:mikronet/core/models/app_response.dart';
import 'package:mikronet/core/mikrotik/router_api.dart';
import 'package:mikronet/features/cards/data/cards_api.dart';
import 'package:mikronet/features/cards/data/profiles_api.dart';
import 'package:mikronet/features/prints/data/print_api.dart';
import 'package:mikronet/features/cards/models/cards_model.dart';

/// إدارة الموزعين ونقاط البيع والمحاسبة (تخزين محلي في SQLite).
class DistributorsApi {
  static const String _distTable = "distributors";
  static const String _txTable = "dist_transactions";

  static Future<AppResponse<List<DistributorModel>>> getAll() async {
    try {
      final rows = await DBApi.select(_distTable, null, null, "is_active DESC, name ASC");
      final result = rows.whereType<Map>().map((e) => DistributorModel.fromDatabase(e)).toList();
      return AppResponse(status: true, message: "done", data: result);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<int>> insert({
    required String name,
    String phone = "",
    String note = "",
  }) async {
    try {
      final id = await DBApi.insert(_distTable, {
        "name": name,
        "phone": phone,
        "note": note,
        "is_active": 1,
        "created_at": DateTime.now().millisecondsSinceEpoch,
      });
      return AppResponse(status: true, message: "تم إضافة الموزع", data: id);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<int>> updateDistributor({
    required int id,
    required String name,
    String phone = "",
    String note = "",
    bool isActive = true,
  }) async {
    try {
      final affected = await DBApi.update(
        _distTable,
        {
          "name": name,
          "phone": phone,
          "note": note,
          "is_active": isActive ? 1 : 0,
        },
        "id=$id",
      );
      return AppResponse(status: true, message: "تم تحديث بيانات الموزع", data: affected);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<void>> deleteDistributor(int id) async {
    try {
      final stock = await DBApi.select('distributor_stock_transfers', 'distributor_id=$id');
      if (stock.isNotEmpty) {
        return AppResponse(
          status: false,
          message: 'لا يمكن حذف نقطة بيع لها سجل مخزون؛ عطّل الحساب بدلًا من حذف تاريخه.',
        );
      }
      await DBApi.delete(_txTable, "distributor_id=$id");
      await DBApi.delete(_distTable, "id=$id");
      return AppResponse(status: true, message: "تم حذف الموزع وحركاته");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<List<DistributorTransactionModel>>> getTransactions(int distributorId) async {
    try {
      final rows = await DBApi.select(
        _txTable,
        "distributor_id=$distributorId",
        null,
        "id DESC",
      );
      final result = rows
          .whereType<Map>()
          .map((e) => DistributorTransactionModel.fromDatabase(e))
          .toList();
      return AppResponse(status: true, message: "done", data: result);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// إضافة حركة (بيع / دفعة / مرتجع).
  static Future<AppResponse<int>> addTransaction({
    required int distributorId,
    required DistributorTxType type,
    required double amount,
    double cost = 0,
    int cardsCount = 0,
    String note = "",
    String? txDate,
  }) async {
    try {
      final now = DateTime.now();
      String two(int value) => value.toString().padLeft(2, '0');
      final date = txDate ?? "${now.year}-${two(now.month)}-${two(now.day)}";

      final id = await DBApi.insert(_txTable, {
        "distributor_id": distributorId,
        "type": type.name,
        "amount": amount,
        "cost": cost,
        "cards_count": cardsCount,
        "note": note,
        "tx_date": date,
        "created_at": now.millisecondsSinceEpoch,
      });
      return AppResponse(status: true, message: "تم تسجيل الحركة", data: id);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<void>> deleteTransaction(int id) async {
    try {
      await DBApi.delete(_txTable, "id=$id");
      return AppResponse(status: true, message: "تم حذف الحركة");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// Transfer all cards in a saved batch to one point of sale. The card list is
  /// verified against the connected router and no hand-entered count is used.
  static Future<AppResponse<int>> transferBatchToDistributor({
    required int distributorId,
    required int batchId,
  }) async {
    try {
      final outletRows = await DBApi.select(_distTable, 'id=$distributorId');
      if (outletRows.isEmpty || _asInt(outletRows.first['is_active']) != 1) {
        return AppResponse(status: false, message: "نقطة البيع غير موجودة أو غير مفعّلة");
      }

      final batch = await PrintBatchesApi.getBatchData(batchId);
      if (batch.isEmpty) {
        return AppResponse(status: false, message: "الدفعة غير موجودة");
      }

      final serialResponse = await RouterApi.getRouterSerial();
      final serial = serialResponse.data?.toString() ?? '';
      if (!serialResponse.status || serial.isEmpty) {
        return AppResponse(status: false, message: "تعذّر تحديد الراوتر الحالي");
      }
      if ((batch['router_serial'] ?? '').toString() != serial) {
        return AppResponse(status: false, message: "هذه الدفعة لا تخص الراوتر المتصل حاليًا");
      }

      final cardRows = (await PrintBatchesApi.getBatchCards(batchId))
          .whereType<Map>()
          .toList();
      final usernames = cardRows
          .map((row) => (row['username'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();
      if (usernames.isEmpty || usernames.length != cardRows.length ||
          usernames.toSet().length != usernames.length) {
        return AppResponse(status: false, message: "الدفعة لا تحتوي قائمة كروت صالحة وفريدة");
      }

      final existingTransfer = await DBApi.select(
        'distributor_stock_transfers',
        "batch_id=$batchId AND router_serial=${quoteValue(serial)}",
      );
      if (existingTransfer.isNotEmpty) {
        return AppResponse(status: false, message: "سبق تحويل هذه الدفعة إلى نقطة بيع");
      }

      final profileName = (batch['cards_profile'] ?? '').toString();
      final customer = (batch['customer'] ?? '').toString();
      final profilesResponse = await ProfilesApi.getProfiles();
      if (!profilesResponse.status || profilesResponse.data == null) {
        return AppResponse(status: false, message: "تعذّر جلب أسعار باقات User Manager");
      }
      final matches = profilesResponse.data!
          .where((profile) => profile.name == profileName &&
              (customer.isEmpty || profile.customer == customer))
          .toList();
      if (matches.length != 1) {
        return AppResponse(
          status: false,
          message: matches.isEmpty
              ? "الباقة المرتبطة بالدفعة غير موجودة لهذا العميل"
              : "اسم الباقة غير فريد؛ تعذّر تحديد سعرها بأمان لهذه الدفعة القديمة",
        );
      }
      final unitPrice = double.tryParse(matches.first.price.trim());
      if (unitPrice == null || unitPrice < 0) {
        return AppResponse(status: false, message: "سعر الباقة غير صالح؛ لم يتم تحويل المخزون");
      }

      final routerCardsResponse = await CardsApi.getAllCards();
      if (!routerCardsResponse.status || routerCardsResponse.data == null) {
        return AppResponse(status: false, message: "تعذّر التحقق من الكروت على الراوتر");
      }
      final routerCards = <String, CardModel>{
        for (final card in routerCardsResponse.data!) card.username: card,
      };
      for (final username in usernames) {
        final card = routerCards[username];
        if (card == null) {
          return AppResponse(status: false, message: "الكرت $username غير موجود على الراوتر؛ لم يتم تحويل الدفعة");
        }
        if (card.hasBeenUsed) {
          return AppResponse(status: false, message: "الكرت $username مستخدم مسبقًا؛ لا يمكن تحويله كمخزون جديد");
        }
      }

      final transferId = await DBApi.insertDistributorStockTransfer(
        transfer: {
          'distributor_id': distributorId,
          'batch_id': batchId,
          'batch_name': (batch['name'] ?? '').toString(),
          'profile_name': profileName,
          'customer': customer,
          'router_serial': serial,
          'unit_price': unitPrice,
          'cards_count': usernames.length,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        usernames: usernames,
      );
      return AppResponse(status: true, message: "تم تحويل ${usernames.length} كرتًا إلى نقطة البيع", data: transferId);
    } catch (e) {
      return AppResponse(status: false, message: "تعذّر تحويل الدفعة: $e");
    }
  }

  /// Detect first use from RouterOS v6 User Manager user records. The local
  /// sold marker is write-once, so repeated syncs never double-count a card.
  static Future<AppResponse<int>> syncAssignedStockForCurrentRouter() async {
    try {
      final serialResponse = await RouterApi.getRouterSerial();
      final serial = serialResponse.data?.toString() ?? '';
      if (!serialResponse.status || serial.isEmpty) {
        return AppResponse(status: false, message: "تعذّر تحديد الراوتر");
      }
      final pending = await DBApi.select(
        'distributor_stock_items',
        "router_serial=${quoteValue(serial)} AND sold_at IS NULL",
      );
      if (pending.isEmpty) {
        return AppResponse(status: true, message: "لا توجد كروت معلّقة في المخزون", data: 0);
      }

      final cardsResponse = await CardsApi.getAllCards();
      if (!cardsResponse.status || cardsResponse.data == null) {
        return AppResponse(status: false, message: "تعذّر قراءة كروت الراوتر");
      }
      final usedUsernames = cardsResponse.data!
          .where((card) => card.hasBeenUsed)
          .map((card) => card.username)
          .toSet();
      if (usedUsernames.isEmpty) {
        return AppResponse(status: true, message: "لا توجد كروت مستخدمة جديدة", data: 0);
      }

      int markedSold = 0;
      final detectedAt = DateTime.now().millisecondsSinceEpoch;
      for (final row in pending.whereType<Map>()) {
        if (!usedUsernames.contains((row['username'] ?? '').toString())) continue;
        markedSold += await DBApi.update(
          'distributor_stock_items',
          {'sold_at': detectedAt},
          "id=${row['id']} AND sold_at IS NULL",
        );
      }
      return AppResponse(status: true, message: "تمت مزامنة حالة الكروت", data: markedSold);
    } catch (e) {
      return AppResponse(status: false, message: "تعذّرت مزامنة مخزون نقاط البيع: $e");
    }
  }

  /// Sync before deleting cards, and block deletion if an assigned unsold card
  /// would disappear from User Manager and become impossible to reconcile.
  static Future<AppResponse<bool>> prepareCardDeletion(Iterable<String> usernames) async {
    try {
      final names = usernames.where((name) => name.isNotEmpty).toSet();
      if (names.isEmpty) return AppResponse(status: true, message: 'لا توجد كروت', data: true);
      final serialResponse = await RouterApi.getRouterSerial();
      final serial = serialResponse.data?.toString() ?? '';
      final allItems = (await DBApi.select('distributor_stock_items'))
          .whereType<Map>()
          .toList();
      bool isPending(Map row) => row['sold_at'] == null &&
          names.contains((row['username'] ?? '').toString()) &&
          (serial.isEmpty || (row['router_serial'] ?? '').toString() == serial);
      if (!allItems.any(isPending)) {
        return AppResponse(status: true, message: 'يمكن حذف الكروت', data: true);
      }

      final sync = await syncAssignedStockForCurrentRouter();
      final stillPending = (await DBApi.select('distributor_stock_items'))
          .whereType<Map>()
          .any(isPending);
      if (stillPending) {
        return AppResponse(
          status: false,
          message: sync.status
              ? 'لم تُستخدم بعض هذه الكروت وهي ما زالت ضمن مخزون البقالة؛ لن نحذفها حتى لا يختل رصيد المخزون.'
              : 'تعذّرت مزامنة الراوتر، لذلك أوقفنا الحذف لحماية حساب مخزون البقالة.',
          data: false,
        );
      }
      return AppResponse(status: true, message: 'تمت مزامنة المخزون قبل الحذف', data: true);
    } catch (e) {
      return AppResponse(status: false, message: 'تعذّر تأمين مخزون نقطة البيع قبل الحذف: $e', data: false);
    }
  }

  static Future<AppResponse<bool>> prepareBatchDeletion(int batchId) async {
    try {
      final transfers = (await DBApi.select(
        'distributor_stock_transfers',
        'batch_id=$batchId',
      )).whereType<Map>().toList();
      if (transfers.isEmpty) {
        return AppResponse(status: true, message: 'الدفعة غير محوّلة لمخزون نقطة بيع', data: true);
      }
      final transferIds = transfers.map((row) => _asInt(row['id'])).toSet();
      final pending = (await DBApi.select('distributor_stock_items'))
          .whereType<Map>()
          .where((row) => transferIds.contains(_asInt(row['transfer_id'])) && row['sold_at'] == null)
          .toList();
      if (pending.isEmpty) return AppResponse(status: true, message: 'لا توجد كروت معلّقة', data: true);

      final sync = await syncAssignedStockForCurrentRouter();
      final remaining = (await DBApi.select('distributor_stock_items'))
          .whereType<Map>()
          .where((row) => transferIds.contains(_asInt(row['transfer_id'])) && row['sold_at'] == null)
          .length;
      if (remaining > 0) {
        return AppResponse(
          status: false,
          message: sync.status
              ? 'لا يمكن حذف الدفعة من الراوتر: ما زال فيها مخزون غير مستخدم مسند إلى نقطة بيع.'
              : 'تعذّرت مزامنة الراوتر؛ أوقفنا حذف الدفعة لحماية مخزون نقطة البيع.',
          data: false,
        );
      }
      return AppResponse(status: true, message: 'تمت مزامنة الدفعة قبل الحذف', data: true);
    } catch (e) {
      return AppResponse(status: false, message: 'تعذّر تأمين مخزون الدفعة قبل الحذف: $e', data: false);
    }
  }

  /// ملخص كل الموزعين (المبيعات، الدفعات، الأرباح، الأرصدة).
  static Future<AppResponse<List<DistributorSummary>>> getSummaries() async {
    try {
      final distributorsRes = await getAll();
      if (!distributorsRes.status || distributorsRes.data == null) {
        return AppResponse(status: false, message: distributorsRes.message);
      }

      final txRows = await DBApi.select(_txTable);
      final transactions = txRows
          .whereType<Map>()
          .map((e) => DistributorTransactionModel.fromDatabase(e))
          .toList();
      final stockTransfers = (await DBApi.select('distributor_stock_transfers'))
          .whereType<Map>()
          .toList();
      final stockItems = (await DBApi.select('distributor_stock_items'))
          .whereType<Map>()
          .toList();

      final summaries = <DistributorSummary>[];
      for (final distributor in distributorsRes.data!) {
        final own = transactions.where((t) => t.distributorId == distributor.id).toList();
        final sales = own.where((t) => t.type == DistributorTxType.sale).toList();
        final ownTransfers = stockTransfers
            .where((transfer) => _asInt(transfer['distributor_id']) == distributor.id)
            .toList();
        final transferIds = ownTransfers.map((transfer) => _asInt(transfer['id'])).toSet();
        final ownStockItems = stockItems
            .where((item) => transferIds.contains(_asInt(item['transfer_id'])))
            .toList();
        final soldItems = ownStockItems.where((item) => item['sold_at'] != null).toList();
        final priceByTransfer = {
          for (final transfer in ownTransfers)
            _asInt(transfer['id']): _asDouble(transfer['unit_price']),
        };
        final automaticSales = soldItems.fold<double>(
          0,
          (sum, item) => sum + (priceByTransfer[_asInt(item['transfer_id'])] ?? 0),
        );
        final deliveredCards = ownTransfers.fold<int>(
          0,
          (sum, transfer) => sum + _asInt(transfer['cards_count']),
        );
        final soldCards = soldItems.length;
        final inventorySummary = DistributorStockSummary(
          deliveredCards: deliveredCards,
          soldCards: soldCards,
          salesAmount: automaticSales,
        );
        final manualSales = sales.fold(0.0, (sum, t) => sum + t.amount);
        final manualCards = sales.fold(0, (sum, t) => sum + t.cardsCount);

        summaries.add(
          DistributorSummary(
            distributor: distributor,
            salesCount: sales.length + soldCards,
            cardsCount: manualCards + soldCards,
            totalSales: manualSales + inventorySummary.salesAmount,
            totalCost: sales.fold(0.0, (sum, t) => sum + t.cost),
            totalPayments: own
                .where((t) => t.type == DistributorTxType.payment)
                .fold(0.0, (sum, t) => sum + t.amount),
            totalRefunds: own
                .where((t) => t.type == DistributorTxType.refund)
                .fold(0.0, (sum, t) => sum + t.amount),
            automaticSales: inventorySummary.salesAmount,
            deliveredCards: inventorySummary.deliveredCards,
            soldCards: inventorySummary.soldCards,
            remainingCards: inventorySummary.remainingCards,
          ),
        );
      }

      return AppResponse(status: true, message: "done", data: summaries);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// ملخص موزع واحد.
  static Future<AppResponse<DistributorSummary>> getSummary(int distributorId) async {
    final response = await getSummaries();
    if (!response.status || response.data == null) {
      return AppResponse(status: false, message: response.message);
    }
    final match = response.data!.where((s) => s.distributor.id == distributorId).toList();
    if (match.isEmpty) {
      return AppResponse(status: false, message: "الموزع غير موجود");
    }
    return AppResponse(status: true, message: "done", data: match.first);
  }

  /// إجماليات عامة لكل الموزعين (للشاشة الرئيسية للمحاسبة).
  static Future<AppResponse<Map<String, double>>> getTotals() async {
    final response = await getSummaries();
    if (!response.status || response.data == null) {
      return AppResponse(status: false, message: response.message);
    }

    double sales = 0, profit = 0, payments = 0, balance = 0;
    for (final summary in response.data!) {
      sales += summary.totalSales;
      profit += summary.profit;
      payments += summary.totalPayments;
      balance += summary.balance;
    }

    return AppResponse(
      status: true,
      message: "done",
      data: {
        "sales": sales,
        "profit": profit,
        "payments": payments,
        "balance": balance,
        "deliveredCards": response.data!.fold<int>(0, (sum, item) => sum + item.deliveredCards).toDouble(),
        "soldCards": response.data!.fold<int>(0, (sum, item) => sum + item.soldCards).toDouble(),
        "remainingCards": response.data!.fold<int>(0, (sum, item) => sum + item.remainingCards).toDouble(),
      },
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
