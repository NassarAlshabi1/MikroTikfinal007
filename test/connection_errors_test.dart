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

    test('خطأ فارغ ← رسالة عامة واضحة', () {
      expect(ConnectionErrors.describe(''), contains('غير معروف'));
      expect(ConnectionErrors.describe(null), contains('غير معروف'));
    });
  });
}
