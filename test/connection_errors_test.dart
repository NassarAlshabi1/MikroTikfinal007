import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/services/connection_errors.dart';

/// اختبارات **أخطاء الاتصال** — منطق نقي بلا أي اتصال شبكة.
///
/// الهدف: كل خطأ شائع في تسجيل الدخول له رسالة عربية مفهومة،
/// والمنفذ يُقرأ بأمان (مع دعم الأرقام العربية) بلا تخمين.
void main() {
  group('قراءة المنفذ (ConnectionErrors.parsePort)', () {
    test('منفذ عادي صحيح', () {
      expect(ConnectionErrors.parsePort('8728'), 8728);
      expect(ConnectionErrors.parsePort('8729'), 8729);
      expect(ConnectionErrors.parsePort('1'), 1);
      expect(ConnectionErrors.parsePort('65535'), 65535);
    });

    test('تجاهل المسافات الزائدة', () {
      expect(ConnectionErrors.parsePort('  8728  '), 8728);
    });

    test('الأرقام العربية-الهندية (٠..٩) تُقبل', () {
      expect(ConnectionErrors.parsePort('٨٧٢٨'), 8728);
    });

    test('الأرقام الفارسية الممتدة (۰..۹) تُقبل', () {
      expect(ConnectionErrors.parsePort('۸۷۲۹'), 8729);
    });

    test('صيغ غير مفهومة ← null بلا تخمين', () {
      expect(ConnectionErrors.parsePort(''), isNull);
      expect(ConnectionErrors.parsePort(null), isNull);
      expect(ConnectionErrors.parsePort('abc'), isNull);
      expect(ConnectionErrors.parsePort('87 28'), isNull);
      expect(ConnectionErrors.parsePort('8728.0'), isNull);
    });

    test('خارج المدى ← null', () {
      expect(ConnectionErrors.parsePort('0'), isNull);
      expect(ConnectionErrors.parsePort('-1'), isNull);
      expect(ConnectionErrors.parsePort('65536'), isNull);
      expect(ConnectionErrors.parsePort('999999999'), isNull);
    });

    test('منافذ مخصّصة شائعة تُقبل (أي منفذ يعمل)', () {
      for (final p in [1300, 2020, 5000, 8080, 9000, 12345, 50000, 65534]) {
        expect(ConnectionErrors.parsePort('$p'), p, reason: 'المنفذ $p يجب أن يكون مقبولًا');
      }
    });
  });

  group('فصل العنوان عن المنفذ (splitHostPort) — صيغة IP:PORT', () {
    test('عنوان بلا منفذ', () {
      final r = ConnectionErrors.splitHostPort('192.168.88.1');
      expect(r.host, '192.168.88.1');
      expect(r.port, isNull);
    });

    test('عنوان مع منفذ مخصّص 1300', () {
      final r = ConnectionErrors.splitHostPort('192.168.88.1:1300');
      expect(r.host, '192.168.88.1');
      expect(r.port, 1300);
    });

    test('مسافات زائدة حول القيمة', () {
      final r = ConnectionErrors.splitHostPort('  10.0.0.1:8728  ');
      expect(r.host, '10.0.0.1');
      expect(r.port, 8728);
    });

    test('اسم مضيف (DNS) مع منفذ', () {
      final r = ConnectionErrors.splitHostPort('router.local:5000');
      expect(r.host, 'router.local');
      expect(r.port, 5000);
    });

    test('IPv6 بين قوسين مع منفذ', () {
      final r = ConnectionErrors.splitHostPort('[fe80::1]:1300');
      expect(r.host, 'fe80::1');
      expect(r.port, 1300);
    });

    test('IPv6 بلا قوسين لا يُقسَم خطأً', () {
      final r = ConnectionErrors.splitHostPort('fe80::1');
      expect(r.host, 'fe80::1');
      expect(r.port, isNull);
    });

    test('منفذ غير صالح بعد النقطتين ⇒ يُعامَل كله كعنوان (بلا تخمين)', () {
      final r = ConnectionErrors.splitHostPort('192.168.88.1:abc');
      expect(r.host, '192.168.88.1:abc');
      expect(r.port, isNull);
    });

    test('قيمة فارغة', () {
      final r = ConnectionErrors.splitHostPort('   ');
      expect(r.host, isEmpty);
      expect(r.port, isNull);
    });
  });

  group('منفذ TLS', () {
    test('8729 مشفّر والافتراضي 8728 عادي', () {
      expect(ConnectionErrors.isSecurePort(8729), isTrue);
      expect(ConnectionErrors.isSecurePort(8728), isFalse);
      expect(ConnectionErrors.defaultPort, 8728);
      expect(ConnectionErrors.securePort, 8729);
    });
  });

  group('ترجمة الأخطاء إلى رسائل عربية (ConnectionErrors.describe)', () {
    test('صلاحية الشبكة غير ممنوحة (سبب فشل نسخة الإصدار سابقًا)', () {
      final msg = ConnectionErrors.describe(
        'CreateSocketError: Failed to connect: Permission denied (errno = 13)',
      );
      expect(msg, contains('صلاحية'));
      expect(msg, contains('الشبكة'));
    });

    test('رفض الاتصال ← توجيه لتفعيل خدمة API', () {
      final msg = ConnectionErrors.describe('Failed to connect: Connection refused');
      expect(msg, contains('API'));
      expect(msg, contains('8728'));
    });

    test('انتهاء المهلة', () {
      final msg = ConnectionErrors.describe(
        'TimeoutException after 0:00:60.000000: Future not completed',
      );
      expect(msg, contains('مهلة'));
    });

    test('اسم مستخدم أو كلمة مرور خاطئة', () {
      final msg = ConnectionErrors.describe(
        'LoginError: Login error: =message=invalid user name or password',
      );
      expect(msg, contains('كلمة المرور'));
    });

    test('صلاحيات غير كافية داخل الراوتر', () {
      final msg = ConnectionErrors.describe('RouterOSTrapError: not enough permissions (9)');
      expect(msg, contains('صلاحيات'));
    });

    test('شبكة غير متاحة / لا مسار للراوتر', () {
      expect(
        ConnectionErrors.describe('OS Error: Network is unreachable, errno = 101'),
        contains('شبكة'),
      );
      expect(
        ConnectionErrors.describe('Failed host lookup: \'10.5.50.1\''),
        contains('IP'),
      );
    });

    test('فشل الاتصال المشفّر (SSL)', () {
      final msg = ConnectionErrors.describe('HandshakeException: CERTIFICATE_VERIFY_FAILED');
      expect(msg, contains('SSL'));
    });

    test('انقطاع أثناء العملية', () {
      final msg = ConnectionErrors.describe('SocketException: Broken pipe');
      expect(msg, contains('انقطع'));
    });

    test('خطأ غير معروف ← يُعرض النص الأصلي للتشخيص', () {
      final msg = ConnectionErrors.describe('WALALAA something odd');
      expect(msg, contains('WALALAA something odd'));
    });

    test('رسالة رفض الاتصال تذكر المنفذ المخصّص وخطوة الحل', () {
      final msg = ConnectionErrors.describe(
        'Failed to connect: Connection refused',
        port: 1300,
      );
      expect(msg, contains('1300'));
      expect(msg, contains('port=1300'));
    });

    test('رسالة انتهاء المهلة تذكر المنفذ', () {
      final msg = ConnectionErrors.describe('TimeoutException', port: 8080);
      expect(msg, contains('8080'));
    });

    test('خطأ فارغ ← رسالة عامة واضحة', () {
      expect(ConnectionErrors.describe(''), contains('غير معروف'));
      expect(ConnectionErrors.describe(null), contains('غير معروف'));
    });
  });
}
