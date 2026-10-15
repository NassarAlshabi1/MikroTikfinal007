/// نوع حركة حساب الموزع.
enum DistributorTxType {
  /// بيع كروت: يزيد دين الموزع (مدين لنا).
  sale,

  /// دفعة نقدية: تخفض دين الموزع.
  payment,

  /// مرتجع كروت: يخفض دين الموزع.
  refund;

  /// تحويل القيمة المخزّنة في قاعدة البيانات إلى نوع الحركة.
  static DistributorTxType fromKey(String? key) {
    switch (key) {
      case 'payment':
        return DistributorTxType.payment;
      case 'refund':
        return DistributorTxType.refund;
      case 'sale':
      default:
        return DistributorTxType.sale;
    }
  }
}

extension DistributorTxTypeLabel on DistributorTxType {
  String get arabicLabel {
    switch (this) {
      case DistributorTxType.sale:
        return "بيع كروت";
      case DistributorTxType.payment:
        return "دفعة نقدية";
      case DistributorTxType.refund:
        return "مرتجع";
    }
  }

}

class DistributorModel {
  final int id;
  final String name;
  final String phone;
  final String note;
  final bool isActive;
  final int createdAt;

  DistributorModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.note,
    required this.isActive,
    required this.createdAt,
  });

  static DistributorModel fromDatabase(Map data) {
    return DistributorModel(
      id: _asInt(data["id"]),
      name: (data["name"] ?? "").toString(),
      phone: (data["phone"] ?? "").toString(),
      note: (data["note"] ?? "").toString(),
      isActive: _asInt(data["is_active"]) == 1,
      createdAt: _asInt(data["created_at"]),
    );
  }
}

class DistributorTransactionModel {
  final int id;
  final int distributorId;
  final DistributorTxType type;
  final double amount;
  final double cost;
  final int cardsCount;
  final String note;
  final String txDate;
  final int createdAt;

  DistributorTransactionModel({
    required this.id,
    required this.distributorId,
    required this.type,
    required this.amount,
    required this.cost,
    required this.cardsCount,
    required this.note,
    required this.txDate,
    required this.createdAt,
  });

  /// أثر الحركة على رصيد الموزع (موجب = مدين لنا).
  double get balanceEffect {
    switch (type) {
      case DistributorTxType.sale:
        return amount;
      case DistributorTxType.payment:
      case DistributorTxType.refund:
        return -amount;
    }
  }

  double get profit => type == DistributorTxType.sale ? (amount - cost) : 0;

  static DistributorTransactionModel fromDatabase(Map data) {
    return DistributorTransactionModel(
      id: _asInt(data["id"]),
      distributorId: _asInt(data["distributor_id"]),
      type: DistributorTxType.fromKey(data["type"]?.toString()),
      amount: _asDouble(data["amount"]),
      cost: _asDouble(data["cost"]),
      cardsCount: _asInt(data["cards_count"]),
      note: (data["note"] ?? "").toString(),
      txDate: (data["tx_date"] ?? "").toString(),
      createdAt: _asInt(data["created_at"]),
    );
  }
}

/// ملخص حساب موزع: المبيعات، الدفعات، الربح، والرصيد.
class DistributorSummary {
  final DistributorModel distributor;
  final int salesCount;
  final int cardsCount;
  final double totalSales;
  final double totalCost;
  final double totalPayments;
  final double totalRefunds;

  DistributorSummary({
    required this.distributor,
    required this.salesCount,
    required this.cardsCount,
    required this.totalSales,
    required this.totalCost,
    required this.totalPayments,
    required this.totalRefunds,
  });

  double get profit => totalSales - totalCost;

  /// موجب = الموزع مدين لنا، سالب = له رصيد عندنا.
  double get balance => totalSales - totalPayments - totalRefunds;

  String get balanceLabel => balance >= 0 ? "مدين" : "دائن";
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
