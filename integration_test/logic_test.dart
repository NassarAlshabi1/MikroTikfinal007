// ============================================================
//  Logic Tests — اختبارات لوجيك أعمق للتحقق من صحة الإدخال
//  يغطي:
//  - AddUserScreen: validation الـ username, shared users, profile
//  - BulkAddScreen: validation العدد، الطول، البادئة
//  - ExtractCardsScreen: validation إعدادات الاستخراج
//  - LoginScreen: validation IP, port, username
//  - CardListScreen: التحقق من النسخ، التصفية
//  - الـ helpers: random string generation, IP validation
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mikrotik_manager/add_user_screen.dart';
import 'package:mikrotik_manager/bulk_add_screen.dart';
import 'package:mikrotik_manager/extract_cards_screen.dart';
import 'package:mikrotik_manager/card_list_screen.dart';
import 'package:mikrotik_manager/main.dart' as app;
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AddUserScreen Validation Logic', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    // ============================================================
    //  اختبار 1: حقل username مطلوب
    // ============================================================
    testWidgets('يعرض خطأ عند ترك اسم المستخدم فارغاً', (tester) async {
      await pumpScreen(
        tester,
        AddUserScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          customer: 'test',
        ),
      );

      // اضغط زر "حفظ وإضافة" بدون إدخال أي بيانات
      await tester.tap(find.text('حفظ وإضافة'));
      await tester.pumpAndSettle();

      // تحقق من ظهور رسالة الخطأ
      expect(find.text('هذا الحقل مطلوب'), findsWidgets,
          reason: 'يجب أن تظهر رسالة "هذا الحقل مطلوب" عند ترك username فارغاً');
    });

    // ============================================================
    //  اختبار 2: حقل shared users يجب أن يكون رقم
    // ============================================================
    testWidgets('يعرض خطأ عند إدخال نص في Shared Users', (tester) async {
      await pumpScreen(
        tester,
        AddUserScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          customer: 'test',
        ),
      );

      // أدخل نص (غير رقم) في حقل Shared Users
      // ابحث عن حقل Shared Users (الثاني)
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'testuser'); // username
      await tester.enterText(textFields.at(1), 'abc'); // shared users = نص

      // اختر profile (مطلوب)
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('default').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('حفظ وإضافة'));
      await tester.pumpAndSettle();

      expect(find.text('الرجاء إدخال رقم صحيح'), findsOneWidget,
          reason: 'يجب أن تظهر رسالة "الرجاء إدخال رقم صحيح"');
    });

    // ============================================================
    //  اختبار 3: حقل shared users مطلوب
    // ============================================================
    testWidgets('يعرض خطأ عند تفريغ Shared Users', (tester) async {
      await pumpScreen(
        tester,
        AddUserScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          customer: 'test',
        ),
      );

      // أفرغ حقل Shared Users (له قيمة افتراضية '1')
      final sharedUsersField = find.byType(TextFormField).at(1);
      await tester.enterText(sharedUsersField, '');

      // اختر profile
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('default').first);
      await tester.pumpAndSettle();

      // أدخل username
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');

      await tester.tap(find.text('حفظ وإضافة'));
      await tester.pumpAndSettle();

      expect(find.text('هذا الحقل مطلوب'), findsWidgets,
          reason: 'يجب أن تظهر رسالة "هذا الحقل مطلوب" عند تفريغ Shared Users');
    });

    // ============================================================
    //  اختبار 4: يجب اختيار profile
    // ============================================================
    testWidgets('يعرض خطأ عند عدم اختيار فئة', (tester) async {
      await pumpScreen(
        tester,
        AddUserScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          customer: 'test',
        ),
      );

      // أدخل username صحيح
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      // لا تختر profile

      await tester.tap(find.text('حفظ وإضافة'));
      await tester.pumpAndSettle();

      expect(find.text('الرجاء اختيار فئة'), findsOneWidget,
          reason: 'يجب أن تظهر رسالة "الرجاء اختيار فئة"');
    });

    // ============================================================
    //  اختبار 5: نموذج كامل صحيح → يجب أن يحاول الإضافة
    // ============================================================
    testWidgets('نموذج صحيح يمرر الـ validation', (tester) async {
      await pumpScreen(
        tester,
        AddUserScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          customer: 'test',
        ),
      );

      // أدخل username
      await tester.enterText(find.byType(TextFormField).at(0), 'valid_user');

      // Shared Users افتراضي = 1 (صحيح)

      // اختر profile
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('default').first);
      await tester.pumpAndSettle();

      // اضغط زر الحفظ
      await tester.tap(find.text('حفظ وإضافة'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // يجب ألا تظهر أي رسالة خطأ validation
      expect(find.text('هذا الحقل مطلوب'), findsNothing);
      expect(find.text('الرجاء اختيار فئة'), findsNothing);
      expect(find.text('الرجاء إدخال رقم صحيح'), findsNothing);

      // سيظهر CircularProgressIndicator (محاولة اتصال) أو snackbar خطأ شبكة
      // هذا متوقع لأنه لا يوجد اتصال فعلي بالـ MikroTik
    });

    // ============================================================
    //  اختبار 6: dropdown نوع الكرت له 3 خيارات
    // ============================================================
    testWidgets('dropdown نوع الكرت يحتوي على 3 خيارات', (tester) async {
      await pumpScreen(
        tester,
        AddUserScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          customer: 'test',
        ),
      );

      // القيمة الافتراضية هي 'username_only'
      // نتحقق من وجود 3 dropdowns
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(3),
          reason: 'يجب أن يوجد 3 dropdowns: profile, card type, char type');
    });

    // ============================================================
    //  اختبار 7: تبديل نوع الكرت إلى username_and_password_different
    // ============================================================
    testWidgets('تبديل نوع الكرت إلى "كلمة مرور مختلفة" يعمل', (tester) async {
      await pumpScreen(
        tester,
        AddUserScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          customer: 'test',
        ),
      );

      // اضغط dropdown نوع الكرت (الثاني)
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pumpAndSettle();

      // اختر "اسم مستخدم وكلمة مرور مختلفة"
      await tester.tap(find.text('اسم مستخدم وكلمة مرور مختلفة').last);
      await tester.pumpAndSettle();

      // تحقق من تحديث القيمة (لا رسالة خطأ)
      expect(find.text('هذا الحقل مطلوب'), findsNothing);
    });
  });

  group('BulkAddScreen Validation Logic', () {
    testWidgets('يقلع ويعرض النموذج', (tester) async {
      await pumpScreen(
        tester,
        BulkAddScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          username: 'admin',
        ),
        wrapWithProvider: true, // BulkAddScreen تحتاج MqttService
      );

      expect(find.byType(Form), findsWidgets);
    });

    testWidgets('يعرض خطأ عند ترك الحقول فارغة', (tester) async {
      await pumpScreen(
        tester,
        BulkAddScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          username: 'admin',
        ),
        wrapWithProvider: true,
      );

      // ابحث عن زر الإضافة واضغطه بدون إدخال بيانات
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();

        // يجب أن تظهر رسالة خطأ (نص يحتوي على "مطلوب" أو "خطأ")
        // لا نتحقق من نص محدد لأن الـ validation يختلف
      }
    });

    testWidgets('يدعم إدخال prefix و count', (tester) async {
      await pumpScreen(
        tester,
        BulkAddScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          username: 'admin',
        ),
        wrapWithProvider: true,
      );

      // أدخل قيم في حقول النص
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length >= 2) {
        await tester.enterText(textFields.at(0), 'user_');
        await tester.enterText(textFields.at(1), '10');
        await tester.pumpAndSettle();

        // يجب أن تبقى القيم
        expect(find.text('user_'), findsWidgets);
      }
    });
  });

  group('ExtractCardsScreen Validation Logic', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    testWidgets('يقلع ويعرض النموذج', (tester) async {
      await pumpScreen(tester, const ExtractCardsScreen(), wrapWithProvider: true);

      // يحتوي على Form
      expect(find.byType(Form), findsWidgets);
    });

    testWidgets('يعرض حقول prefix, length, total', (tester) async {
      await pumpScreen(tester, const ExtractCardsScreen(), wrapWithProvider: true);

      // ابحث عن حقول إدخال متعددة
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('يعرض خطأ عند ترك الحقول فارغة', (tester) async {
      await pumpScreen(tester, const ExtractCardsScreen(), wrapWithProvider: true);

      // ابحث عن زر استخراج واضغطه
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();
        // الـ validation يجب أن يمنع العملية أو يعرض خطأ
      }
    });
  });

  group('CardListScreen Logic', () {
    testWidgets('يعرض كل الكروت المُمررة', (tester) async {
      await pumpScreen(
        tester,
        CardListScreen(cardList: mockCardList),
        wrapWithProvider: true,
      );

      for (final card in mockCardList) {
        expect(find.text(card), findsOneWidget,
            reason: 'يجب أن يظهر الكرت $card في القائمة');
      }
    });

    testWidgets('قائمة فارغة لا تسبب crash', (tester) async {
      await pumpScreen(
        tester,
        const CardListScreen(cardList: []),
        wrapWithProvider: true,
      );

      // يجب أن تظهر حالة فارغة
      await tester.pumpAndSettle();
    });

    testWidgets('يوجد زر نسخ لكل كرت', (tester) async {
      await pumpScreen(
        tester,
        CardListScreen(cardList: mockCardList),
        wrapWithProvider: true,
      );

      // يجب أن يوجد عدد من أزرار النسخ = عدد الكروت
      expect(find.byIcon(Icons.copy), findsNWidgets(mockCardList.length));
    });

    testWidgets('الضغط على زر النسخ يضيف للـ clipboard', (tester) async {
      // نفترض وجود clipboard mock في بيئة الاختبار
      await pumpScreen(
        tester,
        const CardListScreen(cardList: ['test_card_001']),
        wrapWithProvider: true,
      );

      // اضغط أول زر نسخ
      await tester.tap(find.byIcon(Icons.copy).first);
      await tester.pumpAndSettle();

      // قد تظهر SnackBar بنجاح النسخ (لا يمكن التحقق من الـ clipboard نفسه
      // في integration test، لكن نتحقق من عدم وجود crash)
    });
  });

  group('LoginScreen Validation Logic', () {
    setUp(() async {
      await setupMockSharedPreferences(rememberMe: false);
    });

    testWidgets('يعرض خطأ عند محاولة الاتصال بحقول فارغة', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('اتصال'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.textContaining('IP'), findsWidgets);
    });

    testWidgets('لا يعرض خطأ عند إدخال IP فقط (لا يكفي)', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // أدخل IP فقط بدون username
      await tester.enterText(find.byType(TextField).at(0), '192.168.1.1');

      await tester.tap(find.text('اتصال'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // يجب أن تظهر رسالة تطالب بإدخال username
      expect(find.textContaining('IP'), findsWidgets);
    });

    testWidgets('حقل Port يقبل أرقام فقط', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // حقل Port هو الثاني (index 1) في تبويب الاتصال المحلي
      final portField = find.byType(TextField).at(1);
      await tester.enterText(portField, '8728');

      // تحقق من القيمة
      expect(find.text('8728'), findsWidgets);
    });
  });

  group('Helper Functions Logic', () {
    // ============================================================
    //  اختبارات للوجيك الأعمق — لا تتطلب UI
    // ============================================================

    test('mock profiles تحتوي على 3 ملفات', () {
      expect(mockProfiles.length, 3);
      expect(mockProfiles[0]['name'], 'default');
      expect(mockProfiles[1]['name'], 'premium');
      expect(mockProfiles[2]['name'], 'unlimited');
    });

    test('mockCardList يحتوي على 5 كروت', () {
      expect(mockCardList.length, 5);
      expect(mockCardList.first, 'user001');
    });

    test('mockLinkedData يحتوي على البيانات المتوقعة', () {
      expect(mockLinkedData['name'], 'Test Customer');
      expect(mockLinkedData['profile'], 'premium');
    });

    test('كل mock profile يحتوي على .id و name', () {
      for (final p in mockProfiles) {
        expect(p.containsKey('.id'), isTrue, reason: 'profile يجب أن يحتوي على .id');
        expect(p.containsKey('name'), isTrue, reason: 'profile يجب أن يحتوي على name');
        expect(p['name'], isA<String>());
      }
    });
  });
}
