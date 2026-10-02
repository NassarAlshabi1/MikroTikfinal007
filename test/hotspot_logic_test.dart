import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/services/hotspot_logic.dart';

/// اختبارات منطق **Hotspot** — حمولات RouterOS حقيقية بلا أي اتصال شبكة.
///
/// أمثلة `/ip/hotspot/user/print`:
/// ```
///          name: 1020304050
///      password: 9182
///       profile: default
///  limit-uptime: 1d
///   uptime-used: 3h20m
/// limit-bytes-total: 1073741824
///      bytes-in: 52428800
/// ```
/// وأمثلة `/ip/hotspot/active/print`:
/// ```
///        user: 1020304050
///     address: 10.5.50.12
/// mac-address: AA:BB:CC:DD:EE:FF
///      uptime: 1h12m
///   login-by: http
/// ```
void main() {
  group('HotspotUser.parse — الحقول والحالات', () {
    test('مستخدم كامل الحدود: الحسابات والنِسب صحيحة', () {
      final user = HotspotUser.parse({
        '.id': '*1',
        'name': '1020304050',
        'password': '9182',
        'profile': 'default',
        'mac-address': 'AA:BB:CC:DD:EE:FF',
        'comment': 'قسيمة 1',
        'disabled': 'false',
        'limit-uptime': '1d',
        'uptime-used': '12h',
        'limit-bytes-total': '1073741824',
        'bytes-in': '52428800',
        'bytes-out': '10485760',
      });

      expect(user.name, '1020304050');
      expect(user.password, '9182');
      expect(user.profile, 'default');
      expect(user.limitUptime, const Duration(hours: 24));
      expect(user.usedUptime, const Duration(hours: 12));
      expect(user.uptimePercent, 50);
      expect(user.remainingLabel, '12h');
      expect(user.limitBytes, 1073741824);
      expect(user.usedBytes, 52428800 + 10485760);
      expect(user.isExhausted, isFalse);
      expect(user.stateLabel, 'فعال');
    });

    test('كرت استهلك مدته كاملة ← منتهي', () {
      final user = HotspotUser.parse({
        '.id': '*2',
        'name': 'expired',
        'limit-uptime': '12h',
        'uptime-used': '12h',
      });

      expect(user.isUptimeExhausted, isTrue);
      expect(user.isExhausted, isTrue);
      expect(user.stateLabel, 'منتهي');
      expect(user.remainingLabel, '0s');
    });

    test('كرت تجاوز المدة (1w2d3h4m5s ضد 1w) ← منتهي والنسبة > 100', () {
      final user = HotspotUser.parse({
        '.id': '*3',
        'name': 'over',
        'limit-uptime': '1w',
        'uptime-used': '1w2d3h4m5s',
      });

      expect(user.isUptimeExhausted, isTrue);
      expect(user.uptimePercent, greaterThan(100));
    });

    test('قارب على الانتهاء (استهلك 85% وحد التنبيه 20%)', () {
      final user = HotspotUser.parse({
        '.id': '*4',
        'name': 'almost',
        'limit-uptime': '10h',
        'uptime-used': '8h30m',
      });

      expect(user.isNearExpiry(), isTrue);
      expect(user.stateLabel, 'قارب على الانتهاء');
      expect(user.isNearExpiry(thresholdPercent: 10), isFalse);
    });

    test('استهلك رصيد البيانات فقط ← منتهي بالبيانات', () {
      final user = HotspotUser.parse({
        '.id': '*5',
        'name': 'bytes',
        'limit-uptime': '30d',
        'uptime-used': '1h',
        'limit-bytes-total': '100M',
        'bytes-in': '104857600',
        'bytes-out': '0',
      });

      expect(user.limitBytes, 104857600);
      expect(user.isBytesExhausted, isTrue);
      expect(user.isUptimeExhausted, isFalse);
      expect(user.isExhausted, isTrue);
    });

    test('مستخدم معطّل ← الحالة معطّل مهما كانت الحدود', () {
      final user = HotspotUser.parse({
        '.id': '*6',
        'name': 'off',
        'disabled': 'true',
        'limit-uptime': '1d',
        'uptime-used': '1m',
      });

      expect(user.disabled, isTrue);
      expect(user.stateLabel, 'معطّل');
    });

    test('بلا حدود إطلاقًا: لا يُحسب منتهيًا والنِسب صفر', () {
      final user = HotspotUser.parse({'.id': '*7', 'name': 'free'});

      expect(user.hasUptimeLimit, isFalse);
      expect(user.hasBytesLimit, isFalse);
      expect(user.isExhausted, isFalse);
      expect(user.uptimePercent, 0);
      expect(user.bytesPercent, 0);
      expect(user.limitLabel, 'بلا حد زمني');
      expect(user.remainingLabel, '—');
    });

    test('أحجام بوحدات RouterOS تُقرأ صحيحة', () {
      expect(ExpiredBytesParser.parse('1G'), 1024 * 1024 * 1024);
      expect(ExpiredBytesParser.parse('500M'), 500 * 1024 * 1024);
      expect(ExpiredBytesParser.parse('1024'), 1024);
      expect(ExpiredBytesParser.parse(''), isNull);
      expect(HotspotUser.readableBytes(1536), '1.5 KB');
      expect(HotspotUser.readableBytes(2 * 1024 * 1024), '2.0 MB');
    });

    test('مدة غير مفهومة لا تُخمَّن ← لا حدود', () {
      final user = HotspotUser.parse({
        '.id': '*8',
        'name': 'weird',
        'limit-uptime': 'غير معروف',
        'uptime-used': '1h30',
      });

      expect(user.limitUptime, isNull);
      expect(user.hasUptimeLimit, isFalse);
      expect(user.isExhausted, isFalse);
    });
  });

  group('HotspotActiveSession.parse', () {
    test('جلسة كاملة: المدة والاستهلاك ونوع الدخول بالعربية', () {
      final session = HotspotActiveSession.parse({
        '.id': '*A',
        'user': '1020304050',
        'address': '10.5.50.12',
        'mac-address': 'AA:BB:CC:DD:EE:FF',
        'uptime': '1h12m',
        'idle-time': '30s',
        'bytes-in': '1048576',
        'bytes-out': '2097152',
        'login-by': 'http',
        'server': 'hotspot1',
      });

      expect(session.user, '1020304050');
      expect(session.address, '10.5.50.12');
      expect(session.uptime, const Duration(hours: 1, minutes: 12));
      expect(session.uptimeLabel, '1h12m');
      expect(session.usedBytes, 3145728);
      expect(session.usedLabel, '3.0 MB');
      expect(session.loginByLabel, 'صفحة HTTP');
      expect(session.idleLabel, '30s');
    });

    test('أنواع دخول مختلفة تُترجم', () {
      expect(HotspotActiveSession.parse({'user': 'a', 'login-by': 'mac'}).loginByLabel, 'تلقائي بـ MAC');
      expect(HotspotActiveSession.parse({'user': 'a', 'login-by': 'https'}).loginByLabel, 'صفحة HTTPS');
      expect(HotspotActiveSession.parse({'user': 'a', 'login-by': 'cookie'}).loginByLabel, 'كوكي');
      expect(
        HotspotActiveSession.parse({'user': 'a', 'login-by': 'trial'}).loginByLabel,
        'تجريبي',
      );
      expect(HotspotActiveSession.parse({'user': 'a'}).loginByLabel, 'غير محدد');
    });

    test('لا خمول ← «لا خمول»', () {
      final session = HotspotActiveSession.parse({'user': 'a', 'idle-time': '0s'});
      expect(session.idleLabel, 'لا خمول');
    });
  });

  group('الباقات والخوادم', () {
    test('باقة كاملة الحقول', () {
      final profile = HotspotProfile.parse({
        'name': '1M',
        'shared-users': '2',
        'rate-limit': '1M/1M',
        'session-timeout': '8h',
        'idle-timeout': '10m',
      });

      expect(profile.name, '1M');
      expect(profile.sharedUsers, '2');
      expect(profile.rateLabel, '1M/1M');
      expect(profile.sessionTimeout, '8h');
    });

    test('باقة بلا تحديد سرعة ← «بلا تحديد سرعة»', () {
      expect(HotspotProfile.parse({'name': 'free'}).rateLabel, 'بلا تحديد سرعة');
    });

    test('خادم: مجلد صفحة الدخول الافتراضي hotspot', () {
      final server = HotspotServer.parse({
        'name': 'hs1',
        'interface': 'bridge-hotspot',
        'profile': 'default',
      });

      expect(server.name, 'hs1');
      expect(server.effectiveHtmlDirectory, 'hotspot');
      expect(server.disabled, isFalse);
    });

    test('مجلد مخصّص يُحترم', () {
      final server = HotspotServer.parse({'name': 'hs1', 'html-directory': 'login-page'});
      expect(server.effectiveHtmlDirectory, 'login-page');
    });
  });

  group('توليد القسائم', () {
    test('العدد والأطوال ونوع الأحرف صحيحة', () {
      final vouchers = HotspotVoucherGenerator.generate(
        const VoucherSpec(
          count: 25,
          usernameLength: 8,
          passwordLength: 6,
          charset: VoucherCharset.digits,
        ),
        seed: 42,
      );

      expect(vouchers.length, 25);
      expect(vouchers.every((v) => v.username.length == 8), isTrue);
      expect(vouchers.every((v) => v.password.length == 6), isTrue);
      expect(vouchers.every((v) => RegExp(r'^\d+$').hasMatch(v.username)), isTrue);
    });

    test('الأسماء فريدة دائمًا', () {
      final vouchers = HotspotVoucherGenerator.generate(
        const VoucherSpec(count: 100, usernameLength: 4),
        seed: 7,
      );

      expect(vouchers.map((v) => v.username).toSet().length, 100);
    });

    test('الأحرف الملتبسة مُستثناة (0/O و 1/I/l)', () {
      final vouchers = HotspotVoucherGenerator.generate(
        const VoucherSpec(
          count: 60,
          usernameLength: 10,
          passwordLength: 10,
          charset: VoucherCharset.alnumUpper,
        ),
        seed: 99,
      );

      for (final voucher in vouchers) {
        for (final char in HotspotVoucherGenerator.ambiguousChars.split('')) {
          expect(voucher.username.contains(char), isFalse, reason: 'الاسم ${voucher.username}');
          expect(voucher.password.contains(char), isFalse, reason: 'الكلمة ${voucher.password}');
        }
      }
    });

    test('البادئة تُضاف لكل الأسماء', () {
      final vouchers = HotspotVoucherGenerator.generate(
        const VoucherSpec(count: 5, prefix: 'm-', usernameLength: 6),
        seed: 3,
      );

      expect(vouchers.every((v) => v.username.startsWith('m-')), isTrue);
      expect(vouchers.every((v) => v.username.length == 8), isTrue);
    });

    test('نفس البذرة ← نفس النتيجة (قابلية التكرار)', () {
      final first = HotspotVoucherGenerator.generate(
        const VoucherSpec(count: 10, usernameLength: 6),
        seed: 1234,
      );
      final second = HotspotVoucherGenerator.generate(
        const VoucherSpec(count: 10, usernameLength: 6),
        seed: 1234,
      );

      expect(
        first.map((v) => "${v.username}:${v.password}").join(','),
        second.map((v) => "${v.username}:${v.password}").join(','),
      );
    });
  });

  group('تحقق مواصفات القسائم (VoucherSpec.validate)', () {
    test('مواصفات صحيحة ← بلا مشاكل', () {
      final issues = const VoucherSpec(
        count: 10,
        limitUptime: '1w2d',
        limitBytes: '2G',
      ).validate();

      expect(issues, isEmpty);
    });

    test('عدد غير صالح', () {
      expect(const VoucherSpec(count: 0).validate(), isNotEmpty);
      expect(const VoucherSpec(count: 5000).validate(), isNotEmpty);
    });

    test('أطوال غير صالحة', () {
      expect(const VoucherSpec(count: 1, usernameLength: 2).validate(), isNotEmpty);
      expect(const VoucherSpec(count: 1, passwordLength: 40).validate(), isNotEmpty);
    });

    test('بادئة بأحرف غير مسموحة', () {
      expect(const VoucherSpec(count: 1, prefix: 'م-').validate(), isNotEmpty);
    });

    test('صيغة مدة أو بيانات غير مفهومة', () {
      expect(const VoucherSpec(count: 1, limitUptime: '1h30').validate(), isNotEmpty);
      expect(const VoucherSpec(count: 1, limitBytes: 'كثير').validate(), isNotEmpty);
    });
  });

  group('تصدير القسائم', () {
    const items = [
      VoucherPrintItem(
        username: '1001',
        password: '9182',
        profile: 'default',
        validity: '1d',
        dataLimit: '1G',
      ),
    ];

    test('CSV بعناوين وأسطر صحيحة', () {
      final csv = VoucherExporter.toCsv(items);
      final lines = csv.split('\r\n').where((line) => line.isNotEmpty).toList();

      expect(lines.first, 'username,password,profile,validity,data_limit,note');
      expect(lines.length, 2);
      expect(lines[1], '1001,9182,default,1d,1G,');
    });

    test('تهريب الفواصل وعلامات الاقتباس', () {
      final csv = VoucherExporter.toCsv(const [
        VoucherPrintItem(username: 'a,b', password: 'x"y', note: 'ملاحظة، مع فاصلة'),
      ]);

      expect(csv, contains('"a,b"'));
      expect(csv, contains('"x""y"'));
      expect(csv, contains('"ملاحظة، مع فاصلة"'));
    });

    test('أوامر RouterOS جاهزة للاستخدام اليدوي', () {
      final commands = VoucherExporter.toRouterOsCommands(items, server: 'hs1');
      expect(commands, contains('/ip/hotspot/user/add'));
      expect(commands, contains('name=1001'));
      expect(commands, contains('password=9182'));
      expect(commands, contains('limit-uptime=1d'));
      expect(commands, contains('server=hs1'));
    });
  });

  group('التحقق من صفحة الدخول', () {
    const validLogin = '''
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
</head><body>
<form name="login" action="\$(link-login-only)" method="post">
  <input name="username"><input name="password" type="password">
</form></body></html>''';

    test('صفحة صالحة كاملة ← بلا أخطاء', () {
      final files = [
        const HotspotLoginFile(fileName: 'login.html', content: validLogin),
        const HotspotLoginFile(fileName: 'error.html', content: '<html></html>'),
      ];

      final issues = HotspotLoginPageValidator.validate(files);
      expect(HotspotLoginPageValidator.canUpload(files), isTrue);
      expect(issues.any((issue) => issue.severity == LoginIssueSeverity.error), isFalse);
    });

    test('login.html مفقود ← خطأ مُفشِل', () {
      final files = [
        const HotspotLoginFile(fileName: 'error.html', content: '<html></html>'),
      ];

      final issues = HotspotLoginPageValidator.validate(files);
      expect(HotspotLoginPageValidator.canUpload(files), isFalse);
      expect(issues.first.severity, LoginIssueSeverity.error);
      expect(issues.first.message, contains('login.html'));
    });

    test('بدون \$(link-login-only) ← خطأ', () {
      final files = [
        const HotspotLoginFile(
          fileName: 'login.html',
          content: '<html><form><input name="username"></form></html>',
        ),
      ];

      final issues = HotspotLoginPageValidator.validate(files);
      expect(HotspotLoginPageValidator.canUpload(files), isFalse);
      expect(issues.any((i) => i.message.contains('link-login-only')), isTrue);
    });

    test('بدون viewport ← تحذير (وليس خطأ)', () {
      final files = [
        const HotspotLoginFile(
          fileName: 'login.html',
          content: '<html><form action="\$(link-login-only)">'
              '<input name="username"><input name="password"></form></html>',
        ),
      ];

      final issues = HotspotLoginPageValidator.validate(files);
      expect(issues.any((i) => i.severity == LoginIssueSeverity.warning), isTrue);
      expect(HotspotLoginPageValidator.canUpload(files), isTrue);
    });

    test('ملفات موصى بها ناقصة ← ملاحظة', () {
      final files = [
        const HotspotLoginFile(fileName: 'login.html', content: validLogin),
      ];

      final issues = HotspotLoginPageValidator.validate(files);
      expect(issues.any((i) => i.severity == LoginIssueSeverity.info), isTrue);
    });

    test('ملف كبير جدًا ← تحذير', () {
      final files = [
        HotspotLoginFile(
          fileName: 'login.html',
          content: validLogin,
          bytes: List.filled(600 * 1024, 120),
        ),
        HotspotLoginFile(fileName: 'bg.png', bytes: List.filled(1024, 1)),
      ];

      final issues = HotspotLoginPageValidator.validate(files);
      expect(issues.any((i) => i.message.contains('كبير')), isTrue);
      expect(HotspotLoginPageValidator.canUpload(files), isTrue);
    });

    test('لا ملفات ← خطأ واضح', () {
      final issues = HotspotLoginPageValidator.validate(const []);
      expect(issues.first.severity, LoginIssueSeverity.error);
    });
  });
}
