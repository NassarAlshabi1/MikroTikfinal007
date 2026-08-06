// ============================================================
//  اختبارات وحدة لـ MikrotikLogAnalyzer
//  تتحقق من دقة تصنيف الأحداث وحساب الإحصائيات
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/ai/mikrotik_log_analyzer.dart';

void main() {
  group('MikrotikLogAnalyzer', () {
    // ============================================================
    //  analyze() — التحليل الشامل
    // ============================================================
    group('analyze()', () {
      test('يحلل نص فارغ بدون أخطاء', () {
        final result = MikrotikLogAnalyzer.analyze('');
        expect(result.totalLines, 0);
        expect(result.events, isEmpty);
        expect(result.healthScore, 100);
      });

      test('يحلل سطر واحد بسيط', () {
        final result = MikrotikLogAnalyzer.analyze('system rebooted');
        expect(result.totalLines, 1);
        expect(result.events.length, 1);
        expect(result.events.first.severity, LogSeverity.warning);
        expect(result.events.first.category, LogCategory.system);
      });

      test('يحلل نص متعدد الأسطر', () {
        const logs = '''
jan/15/2024 14:30:45 system rebooted
jan/15/2024 14:31:00 login failure for user admin from 192.168.1.100
jan/15/2024 14:32:00 interface ether1 link down
jan/15/2024 14:33:00 interface ether1 link up
''';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.totalLines, 4);
        expect(result.events.length, 4);
      });
    });

    // ============================================================
    //  تصنيف الأحداث الأمنية
    // ============================================================
    group('Security events', () {
      test('يكشف محاولات تسجيل الدخول الفاشلة', () {
        const logs = 'login failure for user admin from 10.0.0.5';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.severity, LogSeverity.critical);
        expect(result.events.first.category, LogCategory.security);
        expect(result.events.first.topic, contains('تسجيل دخول'));
        expect(result.events.first.source, '10.0.0.5');
        expect(result.events.first.recommendation, isNotNull);
        expect(result.events.first.tags, contains('brute-force'));
      });

      test('يكشف "Failed login"', () {
        const logs = 'Failed login from 192.168.1.100';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.category, LogCategory.security);
        expect(result.events.first.severity, LogSeverity.critical);
      });

      test('يكشف firewall drops', () {
        const logs = 'firewall input chain drop from 8.8.8.8';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.category, LogCategory.security);
        expect(result.events.first.severity, LogSeverity.info);
      });

      test('يكشف connection denied', () {
        const logs = 'connection from 1.2.3.4 denied on port 22';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.category, LogCategory.security);
        expect(result.events.first.severity, LogSeverity.warning);
      });
    });

    // ============================================================
    //  تصنيف أحداث النظام
    // ============================================================
    group('System events', () {
      test('يكشف reboots', () {
        const logs = 'system rebooted by admin';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.category, LogCategory.system);
        expect(result.events.first.severity, LogSeverity.warning);
      });

      test('يكشف kernel errors', () {
        const logs = 'kernel error: segfault at 0x00000000';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.category, LogCategory.system);
        expect(result.events.first.severity, LogSeverity.critical);
      });

      test('يكشف OOM', () {
        const logs = 'out of memory: killing process 1234';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.category, LogCategory.system);
        expect(result.events.first.severity, LogSeverity.critical);
        expect(result.events.first.topic, contains('نفاد'));
      });
    });

    // ============================================================
    //  تصنيف أحداث الواجهات
    // ============================================================
    group('Interface events', () {
      test('يكشف link down', () {
        const logs = 'interface ether1 link down';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.category, LogCategory.interface);
        expect(result.events.first.severity, LogSeverity.warning);
      });

      test('يكشف link up', () {
        const logs = 'interface ether2 link is up';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.category, LogCategory.interface);
        expect(result.events.first.severity, LogSeverity.info);
      });
    });

    // ============================================================
    //  تصنيف أحداث DHCP
    // ============================================================
    group('DHCP events', () {
      test('يكشف DHCP conflicts', () {
        const logs = 'dhcp conflict detected for 192.168.1.50';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.category, LogCategory.dhcp);
        expect(result.events.first.severity, LogSeverity.warning);
      });

      test('يكشف DHCP decline', () {
        const logs = 'dhcp declined 192.168.1.51 from 00:11:22:33:44:55';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.category, LogCategory.dhcp);
        expect(result.events.first.severity, LogSeverity.warning);
      });
    });

    // ============================================================
    //  تصنيف أحداث VPN
    // ============================================================
    group('VPN events', () {
      test('يكشف IPsec failures', () {
        const logs = 'ipsec peer 1.2.3.4 failed to connect';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.category, LogCategory.vpn);
        expect(result.events.first.severity, LogSeverity.warning);
      });

      test('يكشف OpenVPN errors', () {
        const logs = 'openvpn error: TLS handshake failed';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.category, LogCategory.vpn);
      });
    });

    // ============================================================
    //  تصنيف أحداث الـ hardware
    // ============================================================
    group('Hardware events', () {
      test('يكشف high temperature', () {
        const logs = 'system temperature high: 78°C';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.category, LogCategory.hardware);
        expect(result.events.first.severity, LogSeverity.critical);
      });

      test('يكشف voltage warning', () {
        const logs = 'voltage warning: 11.5V (low)';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.category, LogCategory.hardware);
      });
    });

    // ============================================================
    //  استخراج IP من السطر
    // ============================================================
    group('IP extraction', () {
      test('يستخرج IP بشكل صحيح', () {
        const logs = 'login failure for user admin from 192.168.1.100';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.source, '192.168.1.100');
      });

      test('يستخرج IP من سطر مع نص إضافي', () {
        const logs = 'packet dropped from 8.8.8.8 to interface ether1';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.source, '8.8.8.8');
      });

      test('يرجع null إن لم يوجد IP', () {
        const logs = 'system rebooted by admin';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.source, isNull);
      });
    });

    // ============================================================
    //  استخراج timestamp
    // ============================================================
    group('Timestamp extraction', () {
      test('يستخرج timestamp بصيغة MikroTik', () {
        const logs = 'jan/15/2024 14:30:45 system rebooted';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.events.first.timestamp, isNotNull);
        expect(result.events.first.timestamp!.year, 2024);
        expect(result.events.first.timestamp!.month, 1);
        expect(result.events.first.timestamp!.day, 15);
        expect(result.events.first.timestamp!.hour, 14);
        expect(result.events.first.timestamp!.minute, 30);
      });
    });

    // ============================================================
    //  الإحصائيات
    // ============================================================
    group('Statistics', () {
      test('يحسب severityCounts بشكل صحيح', () {
        const logs = '''
login failure from 1.2.3.4
system rebooted
interface ether1 link down
interface ether1 link up
''';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.severityCounts[LogSeverity.critical], 1); // login failure
        expect(result.severityCounts[LogSeverity.warning],
            2); // reboot + link down
        expect(result.severityCounts[LogSeverity.info], 1); // link up
      });

      test('يحسب categoryCounts بشكل صحيح', () {
        const logs = '''
login failure from 1.2.3.4
system rebooted
interface ether1 link down
''';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.categoryCounts[LogCategory.security], 1);
        expect(result.categoryCounts[LogCategory.system], 1);
        expect(result.categoryCounts[LogCategory.interface], 1);
      });

      test('يحسب healthScore', () {
        const logs = 'login failure from 1.2.3.4'; // 1 critical
        final result = MikrotikLogAnalyzer.analyze(logs);
        // 100 - (1 critical * 5) = 95
        expect(result.healthScore, 95);
      });

      test('healthScore لا يتجاوز 0', () {
        // 30 critical events → penalty = 150 → clamped to 0
        final logs =
            List.generate(30, (i) => 'login failure from 1.2.3.$i').join('\n');
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.healthScore, 0);
      });

      test('healthScore = 100 لـ logs فارغة', () {
        final result = MikrotikLogAnalyzer.analyze('');
        expect(result.healthScore, 100);
      });
    });

    // ============================================================
    //  أهم المشاكل
    // ============================================================
    group('Top issues', () {
      test('يجمع المشاكل المتكررة', () {
        const logs = '''
login failure from 1.2.3.4
login failure from 1.2.3.5
login failure from 1.2.3.6
interface ether1 link down
''';
        final result = MikrotikLogAnalyzer.analyze(logs);
        // مشكلة "تسجيل دخول فاشلة" تكررت 3 مرات
        expect(result.topIssues, isNotEmpty);
        expect(result.topIssues.first, contains('تسجيل دخول'));
        expect(result.topIssues.first, contains('3'));
      });

      test('يأخذ أعلى 5 مشاكل فقط', () {
        // إنشاء 10 مشاكل مختلفة
        final logs = '${List.generate(10, (i) => 'login failure from 1.2.3.$i')
                .join('\n')}\n${List.generate(10, (i) => 'interface ether$i link down').join('\n')}';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.topIssues.length, lessThanOrEqualTo(5));
      });
    });

    // ============================================================
    //  toAiContext
    // ============================================================
    group('toAiContext()', () {
      test('ينتج نصاً منظماً للـ AI', () {
        const logs = 'login failure from 1.2.3.4';
        final result = MikrotikLogAnalyzer.analyze(logs);
        final context = MikrotikLogAnalyzer.toAiContext(result);
        expect(context, contains('MIKROTIK LOG ANALYSIS'));
        expect(context, contains('Total lines: 1'));
        expect(context, contains('Critical: 1'));
        expect(context, contains('CRITICAL EVENTS'));
      });

      test('يتضمن التوصيات المحلية', () {
        const logs = 'login failure from 1.2.3.4';
        final result = MikrotikLogAnalyzer.analyze(logs);
        final context = MikrotikLogAnalyzer.toAiContext(result);
        expect(context, contains('LOCAL RECOMMENDATIONS'));
      });
    });

    // ============================================================
    //  التوصيات
    // ============================================================
    group('Recommendations', () {
      test('يقدم توصيات للأحداث الحرجة', () {
        const logs = 'login failure from 1.2.3.4';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.recommendations, isNotEmpty);
        expect(result.recommendations.first, contains('firewall'));
      });

      test('يقدم توصيات للأحداث الأدائية', () {
        const logs = 'queue overflow on ether1';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.recommendations, isNotEmpty);
        expect(result.recommendations.first, contains('queue'));
      });
    });

    // ============================================================
    //  ملخص نهائي شامل
    // ============================================================
    group('Summary report', () {
      test('ينتج ملخصاً قابلاً للعرض', () {
        const logs = '''
login failure from 1.2.3.4
system rebooted
interface ether1 link down
dhcp conflict for 192.168.1.50
temperature high: 80°C
''';
        final result = MikrotikLogAnalyzer.analyze(logs);
        expect(result.summary, contains('تقرير تحليل'));
        expect(result.summary, contains('إجمالي الأسطر: 5'));
        expect(result.summary, contains('أحداث مُحلّلة: 5'));
        expect(result.summary, contains('التوزيع حسب الخطورة'));
        expect(result.summary, contains('التوزيع حسب الفئة'));
      });
    });
  });

  // ============================================================
  //  LogSeverity / LogCategory enums
  // ============================================================
  group('LogSeverity', () {
    test('لكل severity displayName و emoji', () {
      for (final s in LogSeverity.values) {
        expect(s.displayName, isNotEmpty);
        expect(s.emoji, isNotEmpty);
      }
    });
  });

  group('LogCategory', () {
    test('لكل category displayName و emoji', () {
      for (final c in LogCategory.values) {
        expect(c.displayName, isNotEmpty);
        expect(c.emoji, isNotEmpty);
      }
    });
  });

  // ============================================================
  //  LogAnalysisResult getters
  // ============================================================
  group('LogAnalysisResult', () {
    test('hasCriticalIssues = true عند وجود critical events', () {
      const logs = 'login failure from 1.2.3.4';
      final result = MikrotikLogAnalyzer.analyze(logs);
      expect(result.hasCriticalIssues, isTrue);
    });

    test('hasCriticalIssues = false بدون critical events', () {
      const logs = 'interface ether1 link up';
      final result = MikrotikLogAnalyzer.analyze(logs);
      expect(result.hasCriticalIssues, isFalse);
    });
  });
}
