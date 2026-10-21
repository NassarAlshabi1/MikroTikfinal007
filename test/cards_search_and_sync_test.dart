import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/features/cards/models/cards_model.dart';

void main() {
  group('CardModel - Parsing and Search (MikroNet implementation)', () {
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
      // البحث في تنفيذ MikroNet يتم على username و profile مباشرة (بدون فهرس searchKey)
      expect(card.username.toLowerCase().contains('user100'), isTrue);
      expect(card.profile.toLowerCase().contains('10gb_monthly'), isTrue);
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

    test('كرت بدون بروفايل فعّال وبدون استخدام يبقى جديداً', () {
      final card = CardModel.fromMikrotik({
        '.id': '*4D',
        'username': 'freshcard',
        'password': '5678',
        'customer': 'admin',
      });

      expect(card.status, 'normal');
      expect(card.profile, 'unknown');
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

      // 2. البحث كما في تنفيذ MikroNet: username أو profile (غير حساس لحالة الأحرف)
      stopwatch.reset();
      stopwatch.start();
      const query = 'gold_50gb';
      final filtered = cards
          .where((c) =>
              c.username.toLowerCase().contains(query) ||
              c.profile.toLowerCase().contains(query))
          .toList();
      stopwatch.stop();

      expect(filtered.isNotEmpty, isTrue);
      expect(filtered.length, 3334); // كل رقم يقبل القسمة على 3
      expect(stopwatch.elapsedMilliseconds, lessThan(30)); // بحث فوري في 10,000 كرت
    });
  });
}
