import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/features/hotspot/services/hotspot_logic.dart';

/// اختبارات **الميزات المنقولة من تطبيق MikroNet Voucher**:
///
/// 1. تسعير الكروت وتسجيل المبيعات تلقائيًا عند توليد قسائم Hotspot
///    (`VoucherSpec.price` + `VoucherSalesRecorder`).
/// 2. ظهور السعر على الكرت المطبوع وفي تصدير CSV.
///
/// كلها منطق نقي بلا أي اتصال شبكة أو قاعدة بيانات.
void main() {
  group('VoucherSpec.price — تسعير الكروت', () {
    test('shouldRecordSale: لا مبيعات بلا سعر', () {
      expect(const VoucherSpec(count: 10).shouldRecordSale, isFalse);
      expect(const VoucherSpec(count: 10, price: 0).shouldRecordSale, isFalse);
      expect(const VoucherSpec(count: 10, price: 5).shouldRecordSale, isTrue);
    });

    test('السعر سالب أو مبالغ فيه ← خطأ تحقق', () {
      expect(
        const VoucherSpec(count: 1, price: -0.5).validate()
            .where((issue) => issue.contains('سعر')),
        isNotEmpty,
      );
      expect(
        const VoucherSpec(count: 1, price: 1000001).validate()
            .where((issue) => issue.contains('سعر')),
        isNotEmpty,
      );
    });

    test('سعر كسري مقبول', () {
      expect(
        const VoucherSpec(count: 1, price: 2.5).validate()
            .where((issue) => issue.contains('سعر')),
        isEmpty,
      );
    });
  });

  group('VoucherSalesRecorder — بناء صفوف المبيعات', () {
    final vouchers = List.generate(
      5,
      (i) => HotspotVoucher(username: 'user$i', password: 'pass$i'),
    );

    test('صف لكل كرت أُضيف فعلًا بنفس السعر والباقة', () {
      const spec = VoucherSpec(count: 5, profile: '1gb-10ly', price: 10);
      final rows = VoucherSalesRecorder.buildRows(
        vouchers: vouchers,
        spec: spec,
        routerSerial: 'ABC123',
        now: DateTime(2026, 10, 18, 14, 30),
      );

      expect(rows.length, 5);
      for (var i = 0; i < rows.length; i++) {
        expect(rows[i]['card_username'], 'user$i');
        expect(rows[i]['profile_name'], '1gb-10ly');
        expect(rows[i]['price'], 10);
        expect(rows[i]['source'], 'hotspot');
        expect(rows[i]['router_serial'], 'ABC123');
        expect(rows[i]['sale_date'], '2026-10-18');
      }
      // نفس الطابع الزمني للدفعة كلها
      expect(
        rows.map((row) => row['timestamp']).toSet().length,
        1,
      );
      expect(
        rows.first['timestamp'],
        DateTime(2026, 10, 18, 14, 30).millisecondsSinceEpoch,
      );
    });

    test('الفاشل إضافته لا يُسجّل في المبيعات', () {
      const spec = VoucherSpec(count: 5, profile: 'p', price: 3);
      final rows = VoucherSalesRecorder.buildRows(
        vouchers: vouchers,
        spec: spec,
        failedNames: const {'user1', 'user3'},
      );

      expect(rows.length, 3);
      final names = rows.map((row) => row['card_username']).toSet();
      expect(names.containsAll(['user0', 'user2', 'user4']), isTrue);
      expect(names.contains('user1'), isFalse);
      expect(names.contains('user3'), isFalse);
    });

    test('بلا سعر ← لا صفوف إطلاقًا (كروت مجانية)', () {
      const spec = VoucherSpec(count: 5, profile: 'p', price: 0);
      final rows = VoucherSalesRecorder.buildRows(vouchers: vouchers, spec: spec);
      expect(rows, isEmpty);
    });

    test('عمود router_serial فارغ آمن عند غياب المعرّف', () {
      const spec = VoucherSpec(count: 1, profile: 'p', price: 1);
      final rows = VoucherSalesRecorder.buildRows(
        vouchers: vouchers.take(1).toList(),
        spec: spec,
      );
      expect(rows.first['router_serial'], '');
    });
  });

  group('سعر الكرت في الطباعة والتصدير', () {
    test('priceLabel: صحيح وكسري وبلا سعر', () {
      expect(const VoucherPrintItem(username: 'u', password: 'p', price: 10).priceLabel,
          'السعر: 10');
      expect(const VoucherPrintItem(username: 'u', password: 'p', price: 2.5).priceLabel,
          'السعر: 2.50');
      expect(const VoucherPrintItem(username: 'u', password: 'p').priceLabel, '');
      expect(
          const VoucherPrintItem(username: 'u', password: 'p', price: 0).priceLabel, '');
    });

    test('CSV يتضمن عمود السعر', () {
      final csv = VoucherExporter.toCsv(const [
        VoucherPrintItem(
          username: '1001',
          password: '9182',
          profile: 'default',
          validity: '1d',
          price: 10,
        ),
        VoucherPrintItem(username: '1002', password: '1827'),
      ]);

      final lines = csv.split('\r\n').where((line) => line.isNotEmpty).toList();
      expect(lines.first, 'username,password,profile,validity,data_limit,price,note');
      expect(lines[1], '1001,9182,default,1d,,10,');
      // الكرت بلا سعر ← خانة فارغة
      expect(lines[2], '1002,1827,,,,,');
    });

    test('سعر كسري يُصدَّر بنقطة عشرية بلا فاصلة تُفسد الأعمدة', () {
      final csv = VoucherExporter.toCsv(const [
        VoucherPrintItem(username: 'u1', password: 'p1', price: 2.5),
      ]);
      expect(csv, contains(',2.50,'));
    });
  });
}
