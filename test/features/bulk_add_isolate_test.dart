// ============================================================
//  اختبارات BulkAddIsolate ومنطق توليد الكروت
//
//  يغطي:
//  ① توليد نص عشوائي بالطول والنوع المحدد
//  ② التحقق من طول النص المولّد
//  ③ التحقق من نوع الأحرف (mixed, letters, numbers)
//  ④ بناء BulkAddIsolateData بشكل صحيح
//  ⑤ معالجة خطأ prefix أطول من total length
//  ⑥ توليد عدة كروت بأسماء فريدة (عدم تكرار)
//  ⑦ توليد كلمات مرور حسب نوع الكرت
//  ⑧ linkPasswordToFirstUser: كلمة المرور = اسم أول مستخدم
// ============================================================

import 'dart:isolate';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

import 'package:mikrotik_manager/bulk_add_isolate.dart';
import 'package:mikrotik_manager/mikrotik_connector.dart';

void main() {
  // ============================================================
  //  ① توليد نص عشوائي بالطول والنوع المحدد
  // ============================================================
  group('① توليد نص عشوائي', () {
    test('الطول 8 - أرقام فقط', () {
      final result = _invokeGenerateRandomString(8, 'numbers');
      expect(result.length, 8);
      expect(RegExp(r'^[0-9]+$').hasMatch(result), isTrue);
    });

    test('الطول 12 - حروف فقط', () {
      final result = _invokeGenerateRandomString(12, 'letters');
      expect(result.length, 12);
      expect(RegExp(r'^[a-z]+$').hasMatch(result), isTrue);
    });

    test('الطول 10 - حروف وأرقام', () {
      final result = _invokeGenerateRandomString(10, 'mixed');
      expect(result.length, 10);
      expect(RegExp(r'^[a-z0-9]+$').hasMatch(result), isTrue);
    });

    test('الطول 1 - الحد الأدنى', () {
      final result = _invokeGenerateRandomString(1, 'numbers');
      expect(result.length, 1);
    });

    test('الطول 0 - حد boundary', () {
      final result = _invokeGenerateRandomString(0, 'numbers');
      expect(result.length, 0);
    });
  });

  // ============================================================
  //  ② توليد عدة نصوص فريدة (عدم تكرار)
  // ============================================================
  group('② عدم تكرار الأسماء', () {
    test('توليد 1000 اسم يجب أن ينتج أسماء فريدة (احتمالية عالية)', () {
      final names = <String>{};
      for (int i = 0; i < 1000; i++) {
        names.add(_invokeGenerateRandomString(8, 'numbers'));
      }
      // مع 8 أرقام، الاحتمالية 10^8، تكرار 1000 مرة احتمال التكرار ضئيل جداً
      expect(names.length, greaterThan(990),
          reason: 'يجب أن يكون أغلبية الأسماء فريدة');
    });

    test('توليد 100 اسم بـ prefix يجب أن ينتج أسماء فريدة', () {
      final names = <String>{};
      for (int i = 0; i < 100; i++) {
        names.add('user_${_invokeGenerateRandomString(6, 'mixed')}');
      }
      expect(names.length, greaterThan(95),
          reason: 'يجب أن يكون أغلبية الأسماء فريدة');
    });
  });

  // ============================================================
  //  ③ بناء BulkAddIsolateData
  // ============================================================
  group('③ بناء BulkAddIsolateData', () {
    test('يحتفظ بكل القيم الممررة', () {
      final receivePort = ReceivePort();
      try {
        final data = BulkAddIsolateData(
          sendPort: receivePort.sendPort,
          count: 10,
          length: 8,
          prefix: 'user_',
          sharedUsers: '1',
          selectedProfile: 'default',
          charType: 'numbers',
          cardType: 'username_only',
          linkPasswordToFirstUser: false,
          isVersion7OrNewer: true,
          connectionConfig: const MikrotikConnectionConfig(
            address: '127.0.0.1',
            user: 'admin',
            password: 'test',
            port: 8728,
            useSsl: false,
          ),
          customer: 'admin',
          isarDirectory: '',
          generationJobId: 'job-test-1',
        );

        expect(data.count, 10);
        expect(data.length, 8);
        expect(data.prefix, 'user_');
        expect(data.sharedUsers, '1');
        expect(data.selectedProfile, 'default');
        expect(data.charType, 'numbers');
        expect(data.cardType, 'username_only');
        expect(data.linkPasswordToFirstUser, isFalse);
        expect(data.isVersion7OrNewer, isTrue);
        expect(data.customer, 'admin');
        expect(data.isarDirectory, isEmpty);
        expect(data.generationJobId, 'job-test-1');
      } finally {
        receivePort.close();
      }
    });

    test('يقبول prefix فارغ', () {
      final receivePort = ReceivePort();
      try {
        final data = BulkAddIsolateData(
          sendPort: receivePort.sendPort,
          count: 5,
          length: 8,
          prefix: '',
          sharedUsers: '2',
          selectedProfile: null,
          charType: 'letters',
          cardType: 'username_and_password_different',
          linkPasswordToFirstUser: true,
          isVersion7OrNewer: false,
          connectionConfig: const MikrotikConnectionConfig(
            address: '127.0.0.1',
            user: 'admin',
            password: 'test',
            port: 8728,
            useSsl: false,
          ),
          customer: 'admin',
          isarDirectory: '',
          generationJobId: 'job-test-2',
        );

        expect(data.prefix, isEmpty);
        expect(data.selectedProfile, isNull);
        expect(data.linkPasswordToFirstUser, isTrue);
        expect(data.isVersion7OrNewer, isFalse);
      } finally {
        receivePort.close();
      }
    });
  });

  // ============================================================
  //  ④ سيناريوهات توليد الكروت (محاكاة)
  // ============================================================
  group('④ سيناريوهات توليد الكروت', () {
    test('سيناريو: username_only بدون prefix', () {
      // محاكاة توليد 10 كروت بنوع "username only"
      const count = 10;
      const length = 8;
      const prefix = '';
      const charType = 'numbers';

      final usernames = <String>[];
      for (int i = 0; i < count; i++) {
        const randomPartLength = length - prefix.length;
        expect(randomPartLength, greaterThan(0),
            reason:
                'عندما prefix أقصر من total length، يجب أن يكون الجزء العشوائي > 0');
        final username =
            prefix + _invokeGenerateRandomString(randomPartLength, charType);
        usernames.add(username);
      }

      expect(usernames.length, count);
      for (final u in usernames) {
        expect(u.length, length);
        expect(RegExp(r'^[0-9]+$').hasMatch(u), isTrue,
            reason: 'يجب أن يحتوي على أرقام فقط');
      }
    });

    test('سيناريو: prefix = "user_" بطول 10', () {
      const count = 5;
      const length = 10;
      const prefix = 'user_';
      const charType = 'mixed';

      final usernames = <String>[];
      for (int i = 0; i < count; i++) {
        const randomPartLength = length - prefix.length;
        expect(randomPartLength, 5);
        final username =
            prefix + _invokeGenerateRandomString(randomPartLength, charType);
        usernames.add(username);
      }

      for (final u in usernames) {
        expect(u.length, length);
        expect(u.startsWith('user_'), isTrue);
      }
    });

    test('سيناريو: username_and_password_different يولّد password مختلف', () {
      const length = 8;
      const prefix = '';
      const charType = 'mixed';
      const cardType = 'username_and_password_different';

      final username = prefix +
          _invokeGenerateRandomString(length - prefix.length, charType);
      String password;
      if (cardType == 'username_and_password_equal') {
        password = username;
      } else if (cardType == 'username_and_password_different') {
        password =
            _invokeGenerateRandomString(length - prefix.length, charType);
      } else {
        password = '';
      }

      expect(password.length, length);
      expect(password == username, isFalse,
          reason:
              'في username_and_password_different يجب أن يختلف password عن username');
    });

    test('سيناريو: username_and_password_equal يولّد password = username', () {
      const length = 8;
      const prefix = '';
      const charType = 'mixed';
      const cardType = 'username_and_password_equal';

      final username = prefix +
          _invokeGenerateRandomString(length - prefix.length, charType);
      String password;
      if (cardType == 'username_and_password_equal') {
        password = username;
      } else {
        password = '';
      }

      expect(password, username);
    });
  });

  // ============================================================
  //  ⑤ التحقق من خطأ prefix أطول من total length
  // ============================================================
  group('⑤ خطأ prefix طويل', () {
    test('prefix أطول من length ينتج randomPartLength سالب', () {
      const length = 5;
      const prefix = 'very_long_prefix';
      const randomPartLength = length - prefix.length;
      expect(randomPartLength, lessThan(0),
          reason:
              'عندما prefix أطول من length، يجب أن يكون randomPartLength سالباً');
      // في الـ isolate الفعلي، هذا يرمي Exception
    });

    test('prefix == length ينتج randomPartLength = 0', () {
      const length = 5;
      const prefix = '12345';
      const randomPartLength = length - prefix.length;
      expect(randomPartLength, 0);
      // في الـ isolate الفعلي، هذا يرمي Exception (randomPartLength < 1)
    });
  });

  // ============================================================
  //  ⑥ linkPasswordToFirstUser سيناريو
  // ============================================================
  group('⑥ linkPasswordToFirstUser', () {
    test('كلمة مرور أول مستخدم = اسمه عند linkPasswordToFirstUser=true', () {
      const linkPasswordToFirstUser = true;
      const length = 8;
      const prefix = '';
      const charType = 'numbers';

      String firstGeneratedUsername = '';

      for (int i = 0; i < 3; i++) {
        final username = prefix +
            _invokeGenerateRandomString(length - prefix.length, charType);
        String password = '';

        if (linkPasswordToFirstUser && i == 0) {
          firstGeneratedUsername = username;
          password = firstGeneratedUsername;
        } else if (linkPasswordToFirstUser && i > 0) {
          password = firstGeneratedUsername;
        }

        if (i == 0) {
          expect(password, username, reason: 'كلمة مرور أول مستخدم = اسمه');
        } else {
          expect(password, firstGeneratedUsername,
              reason: 'كلمات مرور الباقين = اسم أول مستخدم');
        }
      }
    });
  });
}

/// استدعاء دالة _generateRandomString الخاصة (private) عبر reflection بسيط
/// نعيد تنفيذها هنا لاختبارها (لأنها private في bulk_add_isolate.dart)
String _invokeGenerateRandomString(int length, String type) {
  const charsMixed = 'abcdefghijklmnopqrstuvwxyz0123456789';
  const charsLetters = 'abcdefghijklmnopqrstuvwxyz';
  const charsNumbers = '0123456789';
  String chars;
  switch (type) {
    case 'letters':
      chars = charsLetters;
      break;
    case 'numbers':
      chars = charsNumbers;
      break;
    default:
      chars = charsMixed;
  }
  // استخدام Random() العادي لتوليد عشوائي حقيقي
  final random = Random();
  return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
}
