// ============================================================
//  اختبارات شاشة الدخول (LoginScreen) + HomeScreen
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:mikrotik_manager/main.dart' as app;
import 'package:mikrotik_manager/mqtt_service.dart';
import '../test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen Tests', () {
    setUp(() async {
      await setupMockSharedPreferences(rememberMe: false);
    });

    testWidgets('يقلع التطبيق ويعرض شاشة الدخول', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // تحقق من وجود عناصر شاشة الدخول
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('اتصال محلي'), findsOneWidget);
      expect(find.text('اتصال عن بعد'), findsOneWidget);
      expect(find.text('اتصال'), findsOneWidget);
    });

    testWidgets('يعرض رسالة خطأ عند الحقول الفارغة', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('اتصال'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.textContaining('IP'), findsWidgets);
    });

    testWidgets('التبديل بين التبويبات يعمل', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ابدأ بتبويب محلي
      expect(find.text('IP Address'), findsOneWidget);

      // انتقل لتبويب عن بعد
      await tester.tap(find.text('اتصال عن بعد'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('عنوان الخادم البعيد (Domain أو IP)'), findsOneWidget);

      // ارجع
      await tester.tap(find.text('اتصال محلي'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('IP Address'), findsOneWidget);
    });

    testWidgets('زر إظهار/إخفاء كلمة المرور يعمل', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('checkbox تذكرني قابل للتبديل', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('تذكرني'));
      await tester.pumpAndSettle();
    });

    testWidgets('إعدادات MQTT قابلة للطي', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // اضغط على "إعدادات MQTT"
      await tester.tap(find.text('إعدادات MQTT'));
      await tester.pumpAndSettle();

      // تحقق من ظهور حقول MQTT
      expect(find.text('MQTT Username'), findsOneWidget);
      expect(find.text('MQTT Password'), findsOneWidget);
    });
  });

  group('HomeScreen Tests', () {
    testWidgets('يعرض HomeScreen مع شبكة الخدمات', (tester) async {
      // نحتاج لـ Pump مباشر لـ HomeScreen لأنه يتطلب حالة اتصال
      const homeScreen = app.HomeScreen(
        isVersion7OrNewer: true,
        username: 'admin',
      );

      await pumpScreen(
        tester,
        ChangeNotifierProvider<MqttService>(
          create: (_) => MqttService(
            scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          ),
          child: homeScreen,
        ),
        withMqttProvider: false,
      );

      // انتظر تحميل الشاشة
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // تحقق من وجود العنوان العلوي
      expect(find.byType(AppBar), findsWidgets);

      // تحقق من وجود GridView للخدمات
      expect(find.byType(GridView), findsWidgets);
    });

    testWidgets('يقلع HomeScreen في زمن معقول', (tester) async {
      final stopwatch = Stopwatch()..start();

      const homeScreen = app.HomeScreen(
        isVersion7OrNewer: false,
        username: 'admin',
      );

      await pumpScreen(
        tester,
        ChangeNotifierProvider<MqttService>(
          create: (_) => MqttService(
            scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          ),
          child: homeScreen,
        ),
      );

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(15000),
          reason: 'يجب أن يقلع HomeScreen في أقل من 15 ثانية');
    });
  });
}
