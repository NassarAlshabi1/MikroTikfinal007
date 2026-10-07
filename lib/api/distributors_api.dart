import '/api/database_api.dart';
import '/models/distributor_model.dart';
import '/models/response.dart';

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

      final summaries = <DistributorSummary>[];
      for (final distributor in distributorsRes.data!) {
        final own = transactions.where((t) => t.distributorId == distributor.id).toList();
        final sales = own.where((t) => t.type == DistributorTxType.sale).toList();

        summaries.add(
          DistributorSummary(
            distributor: distributor,
            salesCount: sales.length,
            cardsCount: sales.fold(0, (sum, t) => sum + t.cardsCount),
            totalSales: sales.fold(0.0, (sum, t) => sum + t.amount),
            totalCost: sales.fold(0.0, (sum, t) => sum + t.cost),
            totalPayments: own
                .where((t) => t.type == DistributorTxType.payment)
                .fold(0.0, (sum, t) => sum + t.amount),
            totalRefunds: own
                .where((t) => t.type == DistributorTxType.refund)
                .fold(0.0, (sum, t) => sum + t.amount),
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

    double sales = 0, cost = 0, payments = 0, balance = 0;
    for (final summary in response.data!) {
      sales += summary.totalSales;
      cost += summary.totalCost;
      payments += summary.totalPayments;
      balance += summary.balance;
    }

    return AppResponse(
      status: true,
      message: "done",
      data: {
        "sales": sales,
        "profit": sales - cost,
        "payments": payments,
        "balance": balance,
      },
    );
  }
}
