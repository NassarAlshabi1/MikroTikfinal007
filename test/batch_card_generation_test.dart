import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/controllers/helpers/functions.dart';
import 'package:mikronet/models/print_model.dart';
import 'package:mikronet/models/profiles_model.dart';

void main() {
  group('اختبارات توليد دفعات الكروت واختيار الباقة والقالب', () {
    test('توليد أسماء مستخدمين فريدة مع بادئة ولاحقة واستبعاد الكروت الموجودة مسبقاً', () {
      final existing = ['VIP_101_NET', 'VIP_102_NET', 'USER_999'];
      final count = 100;

      final generated = generateUniqueRandomStrings(
        count: count,
        length: 6,
        prefix: 'VIP_',
        suffix: '_NET',
        users: existing,
      );

      expect(generated.length, count);
      // التأكد من عدم تكرار أي رمز
      expect(generated.toSet().length, count);

      for (final u in generated) {
        expect(u.startsWith('VIP_'), isTrue);
        expect(u.endsWith('_NET'), isTrue);
        expect(existing.contains(u), isFalse); // استبعاد الكروت المسبقة
      }
    });

    test('أنماط توليد كلمات المرور (diff, same, none)', () {
      const count = 50;
      final usernames = generateUniqueRandomStrings(count: count, length: 7);

      // 1. نمط diff: كلمات مرور مختلفة
      final diffPasswords = generateUniqueRandomStrings(count: count, length: 5);
      expect(diffPasswords.length, count);
      expect(diffPasswords.toSet().length, count);

      // 2. نمط same: مطابقة اسم المستخدم
      final samePasswords = List<String>.from(usernames);
      expect(samePasswords, equals(usernames));

      // 3. نمط none: بدون كلمة مرور
      final nonePasswords = List.generate(count, (i) => '');
      expect(nonePasswords.every((p) => p.isEmpty), isTrue);
    });

    test('ربط بطاقات الدفعة بالباقة والقالب وقواعد التحقق', () {
      final templateWithPass = PrintTemplatesModel(
        id: 1,
        name: 'قالب كروت قياسي (مع كلمة مرور)',
        image: Uint8List(0),
        withPassword: true,
        numOfRows: 10,
        numOfColumns: 4,
        usernameFontSize: 14,
        passwordFontSize: 12,
        usernameLocation: LocationData(x: 20, y: 30),
        passwordLocation: LocationData(x: 20, y: 50),
      );

      final templateNoPass = PrintTemplatesModel(
        id: 2,
        name: 'قالب قسائم هوتسبوت (بدون كلمة مرور)',
        image: Uint8List(0),
        withPassword: false,
        numOfRows: 12,
        numOfColumns: 4,
        usernameFontSize: 16,
        passwordFontSize: 0,
        usernameLocation: LocationData(x: 25, y: 35),
        passwordLocation: LocationData(x: 0, y: 0),
      );

      final profile = ProfilesModel(
        id: '1',
        name: 'باقة 20 جيجا شهرية',
        price: '1000',
        validity: '30d',
        uptime: '30d',
        palance: '20GB',
        speed: '5M/10M',
        users: '1',
        customer: 'admin',
      );

      expect(templateWithPass.withPassword, isTrue);
      expect(templateNoPass.withPassword, isFalse);
      expect(profile.name, 'باقة 20 جيجا شهرية');

      // إنشاء بطاقات الدفعة
      final usernames = generateUniqueRandomStrings(count: 40, length: 7);
      final passwords = generateUniqueRandomStrings(count: 40, length: 5);

      final cards = List.generate(40, (i) {
        return GeneratedCardsModel(
          id: i + 1,
          username: usernames[i],
          password: passwords[i],
          profileName: profile.name,
          batchId: 10,
          isAdd: false,
        );
      });

      expect(cards.length, 40);
      expect(cards.first.profileName, 'باقة 20 جيجا شهرية');
      expect(cards.first.isAdd, isFalse);

      final dbMap = cards.first.toDatabase();
      expect(dbMap['username'], usernames.first);
      expect(dbMap['password'], passwords.first);
      expect(dbMap['profile_name'], 'باقة 20 جيجا شهرية');
    });

    test('أداء توليد 1,000 كرت مع فحص التكرار في زمن فائق السرعة', () {
      final existingDatabase = List.generate(5000, (i) => 'OLD_CARD_$i');
      final stopwatch = Stopwatch()..start();

      final cards = generateUniqueRandomStrings(
        count: 1000,
        length: 8,
        prefix: 'NET_',
        suffix: '_2026',
        users: existingDatabase,
      );

      stopwatch.stop();

      expect(cards.length, 1000);
      expect(cards.toSet().length, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // أقل من 100 ميلي ثانية لتوليد 1000 كرت فريد
    });
  });
}
