import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/api/version7_api.dart';
import 'package:mikronet/models/cards_model.dart';

void main() {
  group('CardModel - Parsing and Search Indexing', () {
    test('إنشاء كرت وتحويل بيانات RouterOS v6 بشكل سليم', () {
      final card = CardModel.fromMikrotik({
        '.id': '*1A',
        'username': 'user100',
        'password': 'pass100password',
        'actual-profile': '10GB_Monthly',
        'uptime-used': '2h15m',
        'customer': 'admin',
      });

      expect(card.id, '*1A');
      expect(card.username, 'user100');
      expect(card.password, 'pass100password');
      expect(card.profile, '10GB_Monthly');
      expect(card.status, 'active');
      expect(card.customer, 'admin');
      expect(card.searchKey.contains('user100'), isTrue);
      expect(card.searchKey.contains('10gb_monthly'), isTrue);
      expect(card.searchKey.contains('pass100'), isTrue);
    });

    test('كرت غير مستخدم (جديد)', () {
      final card = CardModel.fromMikrotik({
        '.id': '*2B',
        'username': 'newcard01',
        'password': '9988',
        'actual-profile': '5GB',
        'uptime-used': '',
        'customer': 'admin',
      });

      expect(card.status, 'normal');
    });

    test('كرت منتهي (تم استخدامه ولكن أزيل البروفايل الفعال)', () {
      final card = CardModel.fromMikrotik({
        '.id': '*3C',
        'username': 'expiredcard',
        'password': '1234',
        'uptime-used': '5h',
        'customer': 'admin',
      });

      expect(card.status, 'expired');
    });

    test('غياب الباقة أو العميل لا يتحول إلى قيمة وهمية', () {
      final card = CardModel.fromMikrotik({
        '.id': '*4D',
        'username': 'withoutprofile',
        'uptime-used': '',
      });
      final customer = CustomerModel.fromMikrotik({});

      expect(card.profile, isEmpty);
      expect(card.customer, isEmpty);
      expect(card.searchKey.contains('unknown'), isFalse);
      expect(customer.name, isEmpty);
    });

    test('بيانات RouterOS v7 الناقصة لا تُستبدل باسم أو باقة افتراضية', () {
      final card = CardsApi7.fromMikrotik7({
        '.id': '*5E',
        'profile': <String, dynamic>{},
      });

      expect(card.username, isEmpty);
      expect(card.profile, isEmpty);
      expect(card.customer, isEmpty);
      expect(card.status, 'normal');
    });

    test('سرعة البحث والفلترة مع 10,000 كرت في زمن قياسي', () {
      final cards = List.generate(10000, (i) {
        return CardModel(
          id: '*$i',
          username: 'user_$i',
          password: 'pwd_$i',
          profile: (i % 3 == 0) ? 'Gold_50GB' : (i % 2 == 0 ? 'Silver_10GB' : 'Bronze_1GB'),
          status: (i % 3 == 0) ? 'active' : (i % 2 == 0 ? 'normal' : 'expired'),
          customer: 'admin',
        );
      });

      // 1. حساب الإحصائيات في دورة واحدة O(N)
      final stopwatch = Stopwatch()..start();
      int cNew = 0, cActive = 0, cExpired = 0;
      for (final c in cards) {
        if (c.status == 'active') {
          cActive++;
        } else if (c.status == 'normal') {
          cNew++;
        } else {
          cExpired++;
        }
      }
      stopwatch.stop();

      expect(cards.length, 10000);
      expect(cNew + cActive + cExpired, 10000);
      expect(stopwatch.elapsedMilliseconds, lessThan(50)); // أقل من 50 ميلي ثانية

      // 2. البحث السريع باستخدام searchKey
      stopwatch.reset();
      stopwatch.start();
      const query = 'gold_50gb';
      final filtered = cards.where((c) => c.searchKey.contains(query)).toList();
      stopwatch.stop();

      expect(filtered.isNotEmpty, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(30)); // بحث فوري في 10,000 كرت
    });
  });
}
