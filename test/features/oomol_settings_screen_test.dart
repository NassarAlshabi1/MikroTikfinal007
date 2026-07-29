// ============================================================
//  اختبارات شاشة إعدادات OOMOL Cloud
//  تطبّق flutter-testing skill: widget tests + form validation
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mikrotik_manager/ai/oomol_settings_screen.dart';
import 'package:mikrotik_manager/services/secure_credentials_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SecureCredentialsStorageContainer.instance = InMemorySecureCredentialsStorage();
  });

  tearDown(() {
    SecureCredentialsStorageContainer.resetToProduction();
  });

  Widget buildApp() {
    return const MaterialApp(
      home: OomolSettingsScreen(),
    );
  }

  group('☁️ OomolSettingsScreen', () {
    testWidgets('يُبنى بدون أخطاء', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      expect(find.byType(OomolSettingsScreen), findsOneWidget);
    });

    testWidgets('يعرض العنوان', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      expect(find.text('☁️ إعدادات OOMOL Cloud'), findsOneWidget);
    });

    testWidgets('يعرض قسم API Key', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      expect(find.text('🔑 API Key'), findsOneWidget);
    });

    testWidgets('يعرض قسم Package', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      expect(find.text('📦 Package'), findsOneWidget);
    });

    testWidgets('يعرض زر "اختبار الاتصال"', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      expect(find.widgetWithText(FilledButton, 'اختبار الاتصال'), findsOneWidget);
    });

    testWidgets('يعرض حقل API key مع obscure افتراضي', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      // TextField موجود
      expect(find.byType(TextField), findsNWidgets(3)); // apiKey + packageName + version
      // زر إظهار/إخفاء
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('يتبدل obscure عند الضغط على أيقونة العين', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      // اضغط على الأيقونة
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();
      // الآن يجب أن تكون visibility (مفعّلة)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('يعرض حقل Package Name', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      // تحقق من وجود label "Package Name"
      expect(find.text('Package Name'), findsOneWidget);
    });

    testWidgets('يعرض زر "حفظ" في AppBar', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      expect(find.byTooltip('حفظ'), findsOneWidget);
    });

    testWidgets('يعرض أيقونة cloud في header', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });

    testWidgets('يحفظ API key عند الضغط على زر الحفظ', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // أدخل API key في الحقل الأول
      await tester.enterText(find.byType(TextField).first, 'api-test-key-12345');

      // اضغط زر الحفظ
      await tester.tap(find.byTooltip('حفظ'));
      await tester.pump();

      // تحقق من الحفظ في secure storage
      final stored = await SecureCredentialsStorageContainer.instance.getOomolApiKey();
      expect(stored, 'api-test-key-12345');
    });
  });
}
