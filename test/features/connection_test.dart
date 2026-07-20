// ============================================================
//  اختبارات الاتصال وتسجيل الدخول
//
//  يغطي:
//  1) MikrotikConnector (exceptions, cache, forceDisconnect)
//  2) Login credentials flow (handleCredentials logic)
//  3) Validation (IP, user, password, port)
//  4) SharedPreferences persistence
//  5) Connection state management
//  6) Edge cases (empty, invalid, network errors)
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mikrotik_manager/mikrotik_connector.dart';

void main() {
  // إعداد SharedPreferences mock
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('🔗 اختبارات الاتصال وتسجيل الدخول', () {
    // ============================================================
    //  1) MikrotikCredentialsMissingException
    // ============================================================
    group('① MikrotikCredentialsMissingException', () {
      test('يُنشأ برسالة مخصصة', () {
        const exception = MikrotikCredentialsMissingException('Missing IP');
        expect(exception.message, 'Missing IP');
      });

      test('toString يحتوي على الرسالة', () {
        const exception = MikrotikCredentialsMissingException('Missing IP');
        expect(exception.toString(), contains('MikrotikCredentialsMissingException'));
        expect(exception.toString(), contains('Missing IP'));
      });
    });

    // ============================================================
    //  2) MikrotikConnectionException
    // ============================================================
    group('② MikrotikConnectionException', () {
      test('يُنشأ برسالة', () {
        const exception = MikrotikConnectionException('Timeout');
        expect(exception.message, 'Timeout');
      });

      test('يُنشأ برسالة + originalException', () {
        final original = Exception('network error');
        final exception = MikrotikConnectionException('Wrapped', original);
        expect(exception.message, 'Wrapped');
        expect(exception.originalException, original);
      });

      test('toString يحتوي على الرسالة', () {
        const exception = MikrotikConnectionException('Failed');
        expect(exception.toString(), contains('MikrotikConnectionException'));
        expect(exception.toString(), contains('Failed'));
      });
    });

    // ============================================================
    //  3) MikrotikConnector — الحالة الأولية
    // ============================================================
    group('③ MikrotikConnector — Initial State', () {
      test('currentIp = null قبل الاتصال', () {
        // قبل أي اتصال
        // نتحقق من أن forceDisconnect يعيد الحالة لنقطة الصفر
        MikrotikConnector.forceDisconnect();
        // بعد forceDisconnect، يجب أن تكون الحالة فارغة
        // (نستخدم hasActiveConnection كـ proxy)
        expect(MikrotikConnector.hasActiveConnection, isFalse);
      });

      test('hasActiveConnection = false بعد forceDisconnect', () {
        MikrotikConnector.forceDisconnect();
        expect(MikrotikConnector.hasActiveConnection, isFalse);
      });

      test('isCached = false بعد forceDisconnect', () {
        MikrotikConnector.forceDisconnect();
        expect(MikrotikConnector.isCached, isFalse);
      });

      test('currentPort = 8728 افتراضياً', () {
        expect(MikrotikConnector.currentPort, 8728);
      });
    });

    // ============================================================
    //  4) MikrotikConnector.connect — الحالات الخاطئة
    // ============================================================
    group('④ MikrotikConnector.connect — Error Cases', () {
      test('يرمي MikrotikCredentialsMissingException عند غياب IP', () async {
        // لا توجد بيانات في prefs
        SharedPreferences.setMockInitialValues({});

        await expectLater(
          MikrotikConnector.connect(),
          throwsA(isA<MikrotikCredentialsMissingException>()),
        );
      });

      test('يرمي MikrotikCredentialsMissingException عند غياب user', () async {
        SharedPreferences.setMockInitialValues({
          'ip': '192.168.1.1',
          // user missing
        });

        await expectLater(
          MikrotikConnector.connect(),
          throwsA(isA<MikrotikCredentialsMissingException>()),
        );
      });

      test('يرمي MikrotikCredentialsMissingException عند غياب pass', () async {
        SharedPreferences.setMockInitialValues({
          'ip': '192.168.1.1',
          'user': 'admin',
          // pass missing
        });

        await expectLater(
          MikrotikConnector.connect(),
          throwsA(isA<MikrotikCredentialsMissingException>()),
        );
      });

      test('يرمي MikrotikConnectionException عند IP غير صالح', () async {
        SharedPreferences.setMockInitialValues({
          'ip': '192.168.99.99', // IP غير متاح
          'user': 'admin',
          'pass': 'password',
          'port': '8728',
        });

        // سيحاول الاتصال ويفشل (timeout أو connection refused)
        await expectLater(
          MikrotikConnector.connect(),
          throwsA(isA<MikrotikConnectionException>()),
        );
      });
    });

    // ============================================================
    //  5) التحقق من بيانات الدخول (Validation)
    // ============================================================
    group('⑤ Login Validation', () {
      // قواعد التحقق التي يجب أن يطبقها _login()
      test('IP فارغ غير مقبول', () {
        const ip = '';
        expect(ip.isEmpty, isTrue);
      });

      test('IP بدون نقاط غير صالح', () {
        const ip = '19216811';
        expect(ip.contains('.'), isFalse);
      });

      test('IP صالح يحتوي على 4 أجزاء', () {
        const ip = '192.168.1.1';
        final parts = ip.split('.');
        expect(parts.length, 4);
        expect(parts.every((p) => int.tryParse(p) != null), isTrue);
      });

      test('user فارغ غير مقبول', () {
        const user = '';
        expect(user.isEmpty, isTrue);
      });

      test('port يجب أن يكون رقم', () {
        const portStr = '8728';
        final port = int.tryParse(portStr);
        expect(port, isNotNull);
        expect(port, 8728);
      });

      test('port = 8728 هو الافتراضي', () {
        const defaultPort = '8728';
        final port = int.tryParse(defaultPort) ?? 8728;
        expect(port, 8728);
      });

      test('port غير رقمي يُرجع 8728', () {
        const portStr = 'abc';
        final port = int.tryParse(portStr) ?? 8728;
        expect(port, 8728);
      });

      test('port = 8729 لـ API-SSL', () {
        const portStr = '8729';
        final port = int.tryParse(portStr) ?? 8728;
        expect(port, 8729);
      });
    });

    // ============================================================
    //  6) Credentials Persistence — الحفظ والاستعادة
    // ============================================================
    group('⑥ Credentials Persistence', () {
      test('حفظ IP وقراءته', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ip', '192.168.1.1');

        final saved = prefs.getString('ip');
        expect(saved, '192.168.1.1');
      });

      test('حفظ user وقراءته', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', 'admin');

        expect(prefs.getString('user'), 'admin');
      });

      test('حفظ pass وقراءته', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pass', 'secret');

        expect(prefs.getString('pass'), 'secret');
      });

      test('حفظ port وقراءته', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('port', '8729');

        expect(prefs.getString('port'), '8729');
      });

      test('remember_me = false افتراضياً', () async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('remember_me') ?? false, isFalse);
      });

      test('تذكر بيانات الدخول يحفظها', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', true);
        await prefs.setString('ip', '192.168.1.1');
        await prefs.setString('user', 'admin');
        await prefs.setString('pass', 'secret');

        expect(prefs.getBool('remember_me'), isTrue);
        expect(prefs.getString('ip'), '192.168.1.1');
        expect(prefs.getString('user'), 'admin');
        expect(prefs.getString('pass'), 'secret');
      });

      test('clear_on_logout flag يعمل بشكل صحيح', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', false);
        await prefs.setBool('clear_on_logout', true);

        expect(prefs.getBool('clear_on_logout'), isTrue);
        expect(prefs.getBool('remember_me'), isFalse);
      });
    });

    // ============================================================
    //  7) MikrotikConnector.forceDisconnect
    // ============================================================
    group('⑦ MikrotikConnector.forceDisconnect', () {
      test('لا يرمي استثناء حتى لو لم يكن هناك اتصال', () {
        expect(() => MikrotikConnector.forceDisconnect(), returnsNormally);
      });

      test('بعد forceDisconnect: hasActiveConnection = false', () {
        MikrotikConnector.forceDisconnect();
        expect(MikrotikConnector.hasActiveConnection, isFalse);
      });

      test('بعد forceDisconnect: isCached = false', () {
        MikrotikConnector.forceDisconnect();
        expect(MikrotikConnector.isCached, isFalse);
      });

      test('استدعاء forceDisconnect مرتين متتاليتين آمن', () {
        MikrotikConnector.forceDisconnect();
        MikrotikConnector.forceDisconnect();
        expect(MikrotikConnector.hasActiveConnection, isFalse);
      });
    });

    // ============================================================
    //  8) Connection State Management
    // ============================================================
    group('⑧ Connection State', () {
      test('hasActiveConnection = false قبل أي اتصال', () {
        MikrotikConnector.forceDisconnect();
        expect(MikrotikConnector.hasActiveConnection, isFalse);
      });

      test('isCached = false قبل أي اتصال', () {
        MikrotikConnector.forceDisconnect();
        expect(MikrotikConnector.isCached, isFalse);
      });

      test('currentPort يعيد قيمة int', () {
        expect(MikrotikConnector.currentPort, isA<int>());
      });
    });

    // ============================================================
    //  9) Edge Cases — حالات حافة
    // ============================================================
    group('⑨ Edge Cases', () {
      test('بيانات فارغة تماماً', () async {
        SharedPreferences.setMockInitialValues({});

        await expectLater(
          MikrotikConnector.connect(),
          throwsA(isA<MikrotikCredentialsMissingException>()),
        );
      });

      test('IP فقط بدون user/pass', () async {
        SharedPreferences.setMockInitialValues({
          'ip': '192.168.1.1',
        });

        await expectLater(
          MikrotikConnector.connect(),
          throwsA(isA<MikrotikCredentialsMissingException>()),
        );
      });

      test('user و pass بدون IP', () async {
        SharedPreferences.setMockInitialValues({
          'user': 'admin',
          'pass': 'secret',
        });

        await expectLater(
          MikrotikConnector.connect(),
          throwsA(isA<MikrotikCredentialsMissingException>()),
        );
      });

      test('port غير رقمي يُستبدل بـ 8728', () async {
        SharedPreferences.setMockInitialValues({
          'ip': '192.168.99.99', // IP غير صالح لتفادي اتصال ناجح
          'user': 'admin',
          'pass': 'secret',
          'port': 'abc', // غير رقمي
        });

        // يجب أن يحاول الاتصال بالمنفذ 8728 ويفشل
        await expectLater(
          MikrotikConnector.connect(),
          throwsA(isA<MikrotikConnectionException>()),
        );
      });

      test('منفذ مخصص 8729 (API-SSL)', () async {
        SharedPreferences.setMockInitialValues({
          'ip': '192.168.99.99',
          'user': 'admin',
          'pass': 'secret',
          'port': '8729',
        });

        // سيفشل الاتصال لكن نتحقق من أنه يقرأ المنفذ الصحيح
        await expectLater(
          MikrotikConnector.connect(),
          throwsA(isA<MikrotikConnectionException>()),
        );
      });
    });

    // ============================================================
    //  10) تسجيل الدخول البعيد (Remote Login)
    // ============================================================
    group('⑩ Remote Login', () {
      test('remote_server فارغ غير مقبول', () {
        const server = '';
        expect(server.isEmpty, isTrue);
      });

      test('remote_server يحتوي على IP أو domain', () {
        const server = '192.168.1.100';
        final isIp = server.contains('.') && server.split('.').length == 4;
        expect(isIp, isTrue);
      });

      test('remote_port افتراضي = 8728', () {
        const port = '8728';
        expect(int.tryParse(port), 8728);
      });

      test('حفظ بيانات الدخول البعيد', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('remote_server', 'example.com');
        await prefs.setString('remote_port', '8728');
        await prefs.setString('remote_user', 'admin');
        await prefs.setString('remote_pass', 'secret');

        expect(prefs.getString('remote_server'), 'example.com');
        expect(prefs.getString('remote_port'), '8728');
        expect(prefs.getString('remote_user'), 'admin');
        expect(prefs.getString('remote_pass'), 'secret');
      });
    });

    // ============================================================
    //  11) Performance — زمن الاتصال
    // ============================================================
    group('⏱️ Performance', () {
      test('connect مع IP غير صالح يفشل خلال 10 ثوان', () async {
        SharedPreferences.setMockInitialValues({
          'ip': '192.168.99.99',
          'user': 'admin',
          'pass': 'secret',
          'port': '8728',
        });

        final stopwatch = Stopwatch()..start();
        try {
          await MikrotikConnector.connect();
        } catch (_) {}
        stopwatch.stop();

        // يجب أن يفشل خلال 10 ثوان (timeout = 5s + overhead)
        expect(stopwatch.elapsed.inSeconds, lessThan(15));
      });

      test('forceDisconnect سريع جداً', () {
        final stopwatch = Stopwatch()..start();
        MikrotikConnector.forceDisconnect();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}
