import 'package:flutter_test/flutter_test.dart';
import 'package:mikronet/services/mikrotik_duration.dart';

void main() {
  group('MikrotikDuration.parse - صيغة الرموز', () {
    test('1w2d3h4m5s', () {
      final result = MikrotikDuration.parse('1w2d3h4m5s');
      expect(result, isNotNull);
      expect(
        result,
        const Duration(days: 9, hours: 3, minutes: 4, seconds: 5),
      );
    });

    test('قيم مفردة', () {
      expect(MikrotikDuration.parse('1w'), const Duration(days: 7));
      expect(MikrotikDuration.parse('2d'), const Duration(days: 2));
      expect(MikrotikDuration.parse('4h'), const Duration(hours: 4));
      expect(MikrotikDuration.parse('30m'), const Duration(minutes: 30));
      expect(MikrotikDuration.parse('45s'), const Duration(seconds: 45));
    });

    test('ترتيب مقلوب وفراغات', () {
      expect(
        MikrotikDuration.parse('5s4m3h2d1w'),
        const Duration(days: 9, hours: 3, minutes: 4, seconds: 5),
      );
      expect(
        MikrotikDuration.parse('1d 2h 3m'),
        const Duration(days: 1, hours: 2, minutes: 3),
      );
    });

    test('صفر', () {
      expect(MikrotikDuration.parse('0s'), Duration.zero);
      expect(MikrotikDuration.parse('0'), Duration.zero);
      expect(MikrotikDuration.parse('00:00:00'), Duration.zero);
    });

    test('ثوانٍ صحيحة', () {
      expect(MikrotikDuration.parse('3600'), const Duration(hours: 1));
    });
  });

  group('MikrotikDuration.parse - صيغة الساعة', () {
    test('ساعة:دقيقة:ثانية', () {
      expect(MikrotikDuration.parse('03:04:05'), const Duration(hours: 3, minutes: 4, seconds: 5));
    });

    test('مع بادئة أسابيع/أيام', () {
      expect(
        MikrotikDuration.parse('1w2d03:04:05'),
        const Duration(days: 9, hours: 3, minutes: 4, seconds: 5),
      );
      expect(
        MikrotikDuration.parse('2d12:00:00'),
        const Duration(days: 2, hours: 12),
      );
    });

    test('يوم:ساعة:دقيقة:ثانية', () {
      expect(
        MikrotikDuration.parse('1:02:03:04'),
        const Duration(days: 1, hours: 2, minutes: 3, seconds: 4),
      );
    });

    test('الجزءان مُلتبسان ← يُرفض بأمان', () {
      expect(MikrotikDuration.parse('03:04'), isNull);
    });
  });

  group('MikrotikDuration.parse - مدخلات غير صالحة', () {
    test('فراغ أو نص غير مفهوم', () {
      expect(MikrotikDuration.parse(null), isNull);
      expect(MikrotikDuration.parse(''), isNull);
      expect(MikrotikDuration.parse('   '), isNull);
      expect(MikrotikDuration.parse('abc'), isNull);
      expect(MikrotikDuration.parse('12x'), isNull);
      expect(MikrotikDuration.parse('1h30'), isNull); // بقايا غير مفهومة
      expect(MikrotikDuration.parse('1w2d++3h'), isNull);
      expect(MikrotikDuration.parse('--'), isNull);
    });
  });

  group('MikrotikDuration.format', () {
    test('تنسيق مختصر', () {
      expect(MikrotikDuration.format(const Duration(seconds: 0)), '0s');
      expect(MikrotikDuration.format(const Duration(seconds: 45)), '45s');
      expect(MikrotikDuration.format(const Duration(minutes: 30)), '30m');
      expect(
        MikrotikDuration.format(const Duration(days: 9, hours: 3, minutes: 4, seconds: 5)),
        '1w2d3h4m5s',
      );
      expect(MikrotikDuration.format(const Duration(days: 1, hours: 2)), '1d2h');
    });

    test('ذهاب وإياب (parse ↔ format)', () {
      for (final value in ['1w2d3h4m5s', '2d12h', '5m30s', '45s', '3w']) {
        final duration = MikrotikDuration.parse(value);
        expect(duration, isNotNull, reason: value);
        expect(MikrotikDuration.format(duration!), value);
      }
    });
  });

  group('UptimeUsage - المعيار الذكي للحذف', () {
    test('استهلك مدته كاملة ← مؤهل للحذف', () {
      final usage = UptimeUsage(
        used: MikrotikDuration.parse('1w2d3h4m5s')!,
        limit: MikrotikDuration.parse('1w2d3h4m5s')!,
      );
      expect(usage.isExhausted, isTrue);
      expect(usage.percent, 100);
      expect(usage.remaining, Duration.zero);
    });

    test('تجاوز المدة ← مؤهل للحذف', () {
      final usage = UptimeUsage(
        used: MikrotikDuration.parse('2w')!,
        limit: MikrotikDuration.parse('1w')!,
      );
      expect(usage.isExhausted, isTrue);
      expect(usage.percent, 200);
    });

    test('لم يكمل مدته ← غير مؤهل (فارق ثانية واحدة)', () {
      final usage = UptimeUsage(
        used: MikrotikDuration.parse('6d23h59m59s')!,
        limit: MikrotikDuration.parse('1w')!,
      );
      expect(usage.isExhausted, isFalse);
      expect(usage.remaining, const Duration(seconds: 1));
    });

    test('بدون حد (0 أو فارغ) ← لا يُحذف أبدًا', () {
      expect(
        UptimeUsage(used: const Duration(days: 10), limit: Duration.zero).isExhausted,
        isFalse,
      );
    });

    test('مستخدمون بلا استهلاك', () {
      final usage = UptimeUsage(
        used: MikrotikDuration.parse('0s')!,
        limit: MikrotikDuration.parse('1d')!,
      );
      expect(usage.isExhausted, isFalse);
      expect(usage.percent, 0);
    });
  });
}
