import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/features/diagnostics/presentation/diagnostics_hub_screen.dart';
import 'package:mikrotik_manager/network_doctor_screen.dart';
import 'package:mikrotik_manager/providers/mikrotik_qos_provider.dart';
import 'package:mikrotik_manager/screens/ai_diagnostic_dashboard_screen.dart';

void main() {
  group('Diagnostics hub', () {
    testWidgets('groups diagnostic destinations and marks the QoS preview',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DiagnosticsHubScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('مركز التشخيص'), findsOneWidget);
      expect(find.text('فحص اتصال الشبكة'), findsOneWidget);
      expect(find.textContaining('انسخ أو شارك التقرير'), findsOneWidget);
      expect(find.text('تشخيص MikroTik بالذكاء الاصطناعي'), findsOneWidget);

      final scrollable = find.byType(Scrollable).first;
      final analysisHeading = find.text('التحليل والسجل');
      await tester.scrollUntilVisible(
        analysisHeading,
        200,
        scrollable: scrollable,
      );
      expect(analysisHeading, findsOneWidget);

      final qosPreview = find.text('معاينة لوحة QoS');
      await tester.scrollUntilVisible(
        qosPreview,
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(qosPreview, findsOneWidget);
      expect(find.text('تجريبي'), findsOneWidget);
      expect(
        find.textContaining('لا يقرأ QoS من الراوتر ولا يطبّق أوامر عليه'),
        findsOneWidget,
      );
    });

    testWidgets('opens the phone network check from the common hub',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DiagnosticsHubScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('فحص اتصال الشبكة'));
      await tester.pumpAndSettle();

      expect(find.byType(NetworkDoctorScreen), findsOneWidget);
      expect(find.text('الملخص'), findsOneWidget);
      expect(find.text('الفحوصات المكتملة'), findsOneWidget);
      expect(
        find.textContaining('لم تُشغّل الفحوصات بعد'),
        findsOneWidget,
      );

      await tester.tap(find.text('الفحوصات'));
      await tester.pumpAndSettle();
      expect(find.text('اتصال الراوتر'), findsOneWidget);

      await tester.tap(find.text('التوصيات والأدوات'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('شغّل الفحوصات أولاً لعرض توصيات'),
        findsOneWidget,
      );
    });

    testWidgets('keeps the legacy QoS dashboard explicitly experimental',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AiDiagnosticDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('هذه لوحة تجريبية ببيانات محلية ثابتة'),
        findsOneWidget,
      );
      expect(find.text('تشغيل العرض التجريبي'), findsOneWidget);
      expect(find.text('درجة صحة الشبكة'), findsNothing);
    });

    test('QoS preview never claims that commands were sent to the router',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(qosProvider.notifier).loadConfig();
      final result = await container.read(qosProvider.notifier).applyConfig();

      expect(result, startsWith('محاكاة تجريبية:'));
      expect(result, contains('لم تُرسل إلى الراوتر'));
    });
  });
}
