import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/features/cards/models/cards_model.dart';
import 'package:mikronet/features/distributors/models/distributor_model.dart';

void main() {
  group('كشف أول استخدام لكروت User Manager v6', () {
    test('كرت جديد بمدة صفر وآخر ظهور never لا يعد مباعًا', () {
      final card = CardModel.fromMikrotik({
        '.id': '*1',
        'username': 'new-card',
        'password': 'pass',
        'actual-profile': 'Weekly',
        'uptime-used': '0s',
        'last-seen': 'never',
        'customer': 'admin',
      });

      expect(card.hasBeenUsed, isFalse);
    });

    test('مدة استخدام موجبة تثبت أن الكرت استُخدم', () {
      final card = CardModel.fromMikrotik({
        '.id': '*2',
        'username': 'used-card',
        'password': 'pass',
        'actual-profile': 'Weekly',
        'uptime-used': '1m2s',
        'last-seen': '',
        'customer': 'admin',
      });

      expect(card.hasBeenUsed, isTrue);
    });

    test('تاريخ last-seen يثبت الدخول حتى إن بقي uptime-used صفرًا', () {
      final card = CardModel.fromMikrotik({
        '.id': '*3',
        'username': 'seen-card',
        'password': 'pass',
        'actual-profile': 'Weekly',
        'uptime-used': '0s',
        'last-seen': 'oct/22/2026 10:15:30',
        'customer': 'admin',
      });

      expect(card.hasBeenUsed, isTrue);
    });
  });

  test('مخزون نقطة البيع يحسب المتبقي من المستلم ناقص المباع', () {
    const stock = DistributorStockSummary(
      deliveredCards: 120,
      soldCards: 37,
      salesAmount: 370,
    );

    expect(stock.remainingCards, 83);
  });

  test('الرصيد يضم المبيعات الآلية، والربح لا يخمّن تكلفة المخزون', () {
    final summary = DistributorSummary(
      distributor: DistributorModel(
        id: 1,
        name: 'بقالة الاختبار',
        phone: '',
        note: '',
        isActive: true,
        createdAt: 1,
      ),
      salesCount: 10,
      cardsCount: 10,
      totalSales: 500,
      totalCost: 100,
      totalPayments: 200,
      totalRefunds: 10,
      automaticSales: 300,
      deliveredCards: 12,
      soldCards: 10,
      remainingCards: 2,
    );

    expect(summary.balance, 290);
    expect(summary.profit, 100);
  });
}
