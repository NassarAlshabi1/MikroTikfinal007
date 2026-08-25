// ============================================================
//  اختبارات شاشة تحليل Logs MikroTik
//  تطبّق flutter-testing skill: widget tests
//  تغطي: rendering + interactions + state changes
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mikrotik_manager/ai/log_analysis_screen.dart';
import 'package:mikrotik_manager/ai/mikrotik_log_analyzer.dart';
import 'package:mikrotik_manager/services/secure_credentials_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SecureCredentialsStorageContainer.instance =
        InMemorySecureCredentialsStorage();
  });

  tearDown(() {
    SecureCredentialsStorageContainer.resetToProduction();
  });

  Widget buildApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('🔍 LogAnalysisScreen', () {
    testWidgets('يُبنى بدون أخطاء', (tester) async {
      await tester.pumpWidget(buildApp(const LogAnalysisScreen()));
      await tester.pump();
      expect(find.byType(LogAnalysisScreen), findsOneWidget);
    });

    testWidgets('يعرض العنوان الصحيح', (tester) async {
      await tester.pumpWidget(buildApp(const LogAnalysisScreen()));
      await tester.pump();
      expect(find.text('🔍 تحليل Logs MikroTik'), findsOneWidget);
    });

    testWidgets('يعرض empty state عند عدم وجود بيانات', (tester) async {
      await tester.pumpWidget(buildApp(const LogAnalysisScreen()));
      await tester.pump();
      expect(find.text('تحليل Logs MikroTik'), findsOneWidget);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
      expect(find.text('جمع + تحليل'), findsOneWidget);
    });

    testWidgets('يعرض زر "جمع + تحليل"', (tester) async {
      await tester.pumpWidget(buildApp(const LogAnalysisScreen()));
      await tester.pump();
      expect(find.widgetWithText(FilledButton, 'جمع + تحليل'), findsOneWidget);
    });

    testWidgets('يعرض زر "نسخ النتائج" في AppBar', (tester) async {
      await tester.pumpWidget(buildApp(const LogAnalysisScreen()));
      await tester.pump();
      // IconButton للنسخ موجود
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('يعرض العناوين الأساسية في AppBar', (tester) async {
      await tester.pumpWidget(buildApp(const LogAnalysisScreen()));
      await tester.pump();
      // AppBar موجود
      expect(find.byType(AppBar), findsOneWidget);
      // عنوان AppBar
      expect(find.text('🔍 تحليل Logs MikroTik'), findsOneWidget);
      // أيقونات الإجراءات
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });
  });

  // ============================================================
  //  MikrotikLogAnalyzer — اختبارات شاملة للأنماط الإضافية
  // ============================================================
  group('MikrotikLogAnalyzer — additional patterns', () {
    test('يكشف IPsec failure مع IP', () {
      const logs = 'ipsec peer 10.0.0.5 failed to connect';
      final result = MikrotikLogAnalyzer.analyze(logs);
      expect(result.events.first.category, LogCategory.vpn);
      expect(result.events.first.source, '10.0.0.5');
    });

    test('يكشف OpenVPN error', () {
      const logs = 'openvpn error: TLS handshake failed';
      final result = MikrotikLogAnalyzer.analyze(logs);
      expect(result.events.first.category, LogCategory.vpn);
      expect(result.events.first.severity, LogSeverity.warning);
    });

    test('يكشف kernel panic', () {
      const logs = 'kernel panic: not syncing';
      final result = MikrotikLogAnalyzer.analyze(logs);
      expect(result.events.first.category, LogCategory.system);
      expect(result.events.first.severity, LogSeverity.critical);
    });

    test('يكشف out of memory', () {
      const logs = 'out of memory: killing process 1234';
      final result = MikrotikLogAnalyzer.analyze(logs);
      expect(result.events.first.topic, contains('نفاد'));
    });

    test('يكشف queue overflow', () {
      const logs = 'queue overflow on ether1';
      final result = MikrotikLogAnalyzer.analyze(logs);
      expect(result.events.first.category, LogCategory.queue);
    });

    test('يكشف DNS failure', () {
      const logs = 'dns query failed for example.com';
      final result = MikrotikLogAnalyzer.analyze(logs);
      expect(result.events.first.category, LogCategory.dns);
    });

    test('يكشف firewall drop', () {
      const logs = 'firewall input chain drop from 8.8.8.8';
      final result = MikrotikLogAnalyzer.analyze(logs);
      expect(result.events.first.category, LogCategory.security);
    });

    test('يكشف connection denied', () {
      const logs = 'connection from 1.2.3.4 denied on port 22';
      final result = MikrotikLogAnalyzer.analyze(logs);
      expect(result.events.first.category, LogCategory.security);
      expect(result.events.first.severity, LogSeverity.warning);
    });

    test('يكشف BGP flapping', () {
      const logs = 'bgp peer 192.168.1.1 down - session lost';
      final result = MikrotikLogAnalyzer.analyze(logs);
      expect(result.events.first.category, LogCategory.routing);
    });

    test('يكشف temperature high', () {
      const logs = 'system temperature high: 78°C';
      final result = MikrotikLogAnalyzer.analyze(logs);
      expect(result.events.first.category, LogCategory.hardware);
      expect(result.events.first.severity, LogSeverity.critical);
    });
  });

  // ============================================================
  //  LogSeverity و LogCategory
  // ============================================================
  group('LogSeverity', () {
    test('displayName لكل مستوى', () {
      expect(LogSeverity.critical.displayName, 'حرج');
      expect(LogSeverity.warning.displayName, 'تحذير');
      expect(LogSeverity.info.displayName, 'معلومة');
      expect(LogSeverity.debug.displayName, 'تتبع');
    });

    test('emoji لكل مستوى', () {
      expect(LogSeverity.critical.emoji, isNotEmpty);
      expect(LogSeverity.warning.emoji, isNotEmpty);
    });
  });

  group('LogCategory', () {
    test('displayName لكل فئة', () {
      expect(LogCategory.security.displayName, 'أمن');
      expect(LogCategory.system.displayName, 'نظام');
      expect(LogCategory.dhcp.displayName, 'DHCP');
    });

    test('emoji لكل فئة', () {
      for (final cat in LogCategory.values) {
        expect(cat.emoji, isNotEmpty);
      }
    });
  });
}
