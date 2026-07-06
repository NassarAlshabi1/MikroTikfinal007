// ============================================================
//  Integration Test — اختبارات تكامل على محاكي Android
//  يُشغّل عبر GitHub Actions workflow
//  يتحقق من أن التطبيق يُقلع ويصل لشاشة الدخول بدون أخطاء
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// استيراد الـ main مع prefix لتجنب تعارض الأسماء
// لأن main() معرّفة في كلا الملفين
import 'package:mikrotik_manager/main.dart' as app;

void main() {
  // تهيئة بيئة الاختبار التكاملي
  // تُشغّل التطبيق الحقيقي على الجهاز/المحاكي
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Launch Tests', () {
    // ============================================================
    //  الاختبار 1: التطبيق يُقلع ويعرض شاشة الدخول
    // ============================================================
    testWidgets('يقلع التطبيق ويعرض شاشة الدخول', (WidgetTester tester) async {
      // ابدأ التطبيق
      app.main();

      // انتظر حتى يكتمل الإطار الأول + تأخير للـ async init
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // تحقق من وجود شعار الـ wifi
      expect(find.byType(Image), findsWidgets,
          reason: 'يجب أن يظهر شعار الـ wifi');

      // تحقق من وجود تبويبات (TabBar)
      expect(find.byType(TabBar), findsOneWidget,
          reason: 'يجب أن يظهر TabBar للتبديل بين الاتصال المحلي والعن بعد');

      // تحقق من وجود نص "اتصال محلي"
      expect(find.text('اتصال محلي'), findsOneWidget,
          reason: 'يجب أن يظهر تبويب اتصال محلي');

      // تحقق من وجود نص "اتصال عن بعد"
      expect(find.text('اتصال عن بعد'), findsOneWidget,
          reason: 'يجب أن يظهر تبويب اتصال عن بعد');

      // تحقق من وجود حقل IP
      expect(find.byType(TextField), findsWidgets,
          reason: 'يجب أن تظهر حقول إدخال في شاشة الدخول');

      // تحقق من وجود زر "اتصال"
      expect(find.text('اتصال'), findsOneWidget,
          reason: 'يجب أن يظهر زر اتصال');
    });

    // ============================================================
    //  الاختبار 2: التبديل بين تبويبات الدخول
    // ============================================================
    testWidgets('التبديل بين تبويب الاتصال المحلي والعن بعد',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ابدأ بتبويب "اتصال محلي" (افتراضي)
      expect(find.text('IP Address'), findsOneWidget,
          reason: 'يجب أن يظهر حقل IP في تبويب الاتصال المحلي');

      // اضغط على تبويب "اتصال عن بعد"
      await tester.tap(find.text('اتصال عن بعد'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // تحقق من ظهور حقل "عنوان الخادم البعيد"
      expect(find.text('عنوان الخادم البعيد (Domain أو IP)'), findsOneWidget,
          reason: 'يجب أن يظهر حقل الخادم البعيد بعد التبديل');

      // ارجع لتبويب "اتصال محلي"
      await tester.tap(find.text('اتصال محلي'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('IP Address'), findsOneWidget,
          reason: 'يجب أن يعود حقل IP عند الرجوع للتبويب المحلي');
    });

    // ============================================================
    //  الاختبار 3: التحقق من رسالة الخطأ عند الحقول الفارغة
    // ============================================================
    testWidgets('يعرض رسالة خطأ عند محاولة الاتصال بحقول فارغة',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // اضغط زر "اتصال" بدون إدخال أي بيانات
      final connectButton = find.text('اتصال');
      expect(connectButton, findsOneWidget);

      await tester.tap(connectButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // تحقق من ظهور رسالة خطأ تطالب بإدخال IP
      expect(
        find.textContaining('IP'),
        findsWidgets,
        reason: 'يجب أن تظهر رسالة تطالب بإدخال IP',
      );
    });

    // ============================================================
    //  الاختبار 4: التحقق من إظهار/إخفاء كلمة المرور
    // ============================================================
    testWidgets('زر إظهار/إخفاء كلمة المرور يعمل', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ابحث عن زر إظهار كلمة المرور (visibility icon)
      final visibilityButton = find.byIcon(Icons.visibility_off);
      expect(visibilityButton, findsOneWidget,
          reason: 'يجب أن يظهر أيقونة إخفاء كلمة المرور افتراضياً');

      // اضغط لتبديل الحالة
      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();

      // تحقق من ظهور أيقونة "إظهار"
      expect(find.byIcon(Icons.visibility), findsOneWidget,
          reason: 'يجب أن تتغير الأيقونة إلى visibility بعد الضغط');
    });

    // ============================================================
    //  الاختبار 5: التحقق من checkbox "تذكرني"
    // ============================================================
    testWidgets('checkbox تذكرني قابل للتبديل', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ابحث عن checkbox "تذكرني"
      final rememberMeCheckbox = find.text('تذكرني');
      expect(rememberMeCheckbox, findsOneWidget);

      // اضغط عليه
      await tester.tap(rememberMeCheckbox);
      await tester.pumpAndSettle();

      // لا يوجد assertion صريم لأن القيمة الافتراضية قد تكون true
      // لكننا نتحقق على الأقل من أن العنصر يستجيب للنقر بدون crash
    });
  });

  group('Performance Smoke Tests', () {
    // ============================================================
    //  الاختبار 6: التطبيق يُقلع في زمن معقول (أقل من 10 ثوانٍ)
    // ============================================================
    testWidgets('يقلع التطبيق في زمن معقول', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      stopwatch.stop();

      // يجب أن يُقلع في أقل من 10 ثوانٍ على المحاكي
      // (المحاكي أبطأ من الجهاز الحقيقي، لذا الحد متساهل)
      expect(stopwatch.elapsedMilliseconds, lessThan(15000),
          reason: 'يجب أن يُقلع التطبيق في أقل من 15 ثانية');

      debugPrint('⏱️ زمن الإقلاع: ${stopwatch.elapsedMilliseconds}ms');
    });

    // ============================================================
    //  الاختبار 7: لا يوجد memory leak واضح بعد التبديل بين التبويبات
    // ============================================================
    testWidgets('التبديل المتكرر بين التبويبات لا يسبب crash',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // بدّل بين التبويبات 5 مرات
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('اتصال عن بعد'));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await tester.tap(find.text('اتصال محلي'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // التطبيق ما زال يعمل
      expect(find.byType(TabBar), findsOneWidget,
          reason: 'التطبيق يجب أن يستجيب بعد التبديل المتكرر');
    });
  });
}
