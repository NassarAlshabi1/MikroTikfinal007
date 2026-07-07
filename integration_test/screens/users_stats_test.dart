// ============================================================
//  اختبارات شاشات المستخدمين والإحصائيات
//  - ActiveUsersScreen
//  - CardsStatisticsScreen
//  - CardListScreen
//  - StatsScreen
//  - AddUserScreen
//  - BulkAddScreen
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mikrotik_manager/active_users_screen.dart';
import 'package:mikrotik_manager/cards_statistics_screen.dart';
import 'package:mikrotik_manager/card_list_screen.dart';
import 'package:mikrotik_manager/stats_screen.dart';
import 'package:mikrotik_manager/add_user_screen.dart';
import 'package:mikrotik_manager/bulk_add_screen.dart';
import '../test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ActiveUsersScreen Tests', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    testWidgets('يقلع ويعرض الـ AppBar + زر التحديث', (tester) async {
      await pumpScreen(tester, const ActiveUsersScreen());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('يعرض حالة فارغة أو تحميل أو قائمة بدون crash',
        (tester) async {
      await pumpScreen(tester, const ActiveUsersScreen());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // إما CircularProgressIndicator أو ListView أو رسالة
      final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      final hasList = find.byType(ListView).evaluate().isNotEmpty;
      final hasText = find.byType(Text).evaluate().isNotEmpty;

      expect(hasLoading || hasList || hasText, isTrue,
          reason: 'يجب أن تعرض الشاشة شيء ما');
    });
  });

  group('CardsStatisticsScreen Tests', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    testWidgets('يقلع ويعرض الـ AppBar', (tester) async {
      await pumpScreen(tester, const CardsStatisticsScreen());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('يعرض حالة تحميل ثم محتوى بدون crash', (tester) async {
      await pumpScreen(tester, const CardsStatisticsScreen());

      // انتظر بداية التحميل
      await tester.pump();
      expect(find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.byType(Scaffold).evaluate().isNotEmpty, isTrue);

      // انتظر اكتمال
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });
  });

  group('CardListScreen Tests', () {
    testWidgets('يعرض قائمة الكروت', (tester) async {
      await pumpScreen(
        tester,
        CardListScreen(
          cardList: mockCardList,
          isNetworkLinked: false,
        ),
      );

      // تحقق من ظهور أول كرت
      expect(find.text('user001'), findsOneWidget);
      expect(find.text('user002'), findsOneWidget);
      expect(find.text('user003'), findsOneWidget);
    });

    testWidgets('يعرض زر النسخ لكل كرت', (tester) async {
      await pumpScreen(
        tester,
        CardListScreen(cardList: mockCardList),
        wrapWithProvider: true,
      );

      // يجب أن يوجد على الأقل زر نسخ واحد (Icons.copy)
      expect(find.byIcon(Icons.copy), findsWidgets);
    });

    testWidgets('يعرض حالة "مرتبط بشبكة" عند تمرير linkedData',
        (tester) async {
      await pumpScreen(
        tester,
        CardListScreen(
          cardList: mockCardList,
          isNetworkLinked: true,
          linkedData: mockLinkedData,
        ),
        wrapWithProvider: true,
      );

      // تحقق من ظهور اسم العميل المرتبط
      expect(find.text('Test Customer'), findsWidgets);
    });

    testWidgets('قائمة فارغة لا تسبب crash', (tester) async {
      await pumpScreen(
        tester,
        const CardListScreen(cardList: []),
      );

      await tester.pumpAndSettle();
      // لا نتوقع crash
    });
  });

  group('StatsScreen Tests', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    testWidgets('يقلع ويعرض الـ Scaffold', (tester) async {
      await pumpScreen(tester, const StatsScreen());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('يعرض حالة تحميل أو محتوى بدون crash', (tester) async {
      await pumpScreen(tester, const StatsScreen());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      final hasScaffold = find.byType(Scaffold).evaluate().isNotEmpty;
      expect(hasScaffold, isTrue);
    });
  });

  group('AddUserScreen Tests', () {
    testWidgets('يقلع ويعرض نموذج إضافة مستخدم', (tester) async {
      await pumpScreen(
        tester,
        AddUserScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          customer: 'Test Customer',
        ),
      );

      // تحقق من وجود حقول إدخال
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('يعرض زر إضافة المستخدم', (tester) async {
      await pumpScreen(
        tester,
        AddUserScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: false,
          customer: 'Test',
        ),
      );

      // ابحث عن زر (ElevatedButton)
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('يعرض dropdown للملف الشخصي', (tester) async {
      await pumpScreen(
        tester,
        AddUserScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          customer: 'Test',
        ),
      );

      // قد يكون DropdownButtonFormField
      final hasDropdown =
          find.byType(DropdownButtonFormField).evaluate().isNotEmpty ||
              find.byType(DropdownButton<dynamic>).evaluate().isNotEmpty;
      expect(hasDropdown, isTrue,
          reason: 'يجب أن يوجد dropdown لاختيار الملف الشخصي');
    });
  });

  group('BulkAddScreen Tests', () {
    testWidgets('يقلع ويعرض نموذج الإضافة بالجملة', (tester) async {
      await pumpScreen(
        tester,
        BulkAddScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          username: 'admin',
        ),
        wrapWithProvider: true,
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('يعرض زر بدء الإضافة بالجملة', (tester) async {
      await pumpScreen(
        tester,
        BulkAddScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: false,
          username: 'admin',
        ),
        wrapWithProvider: true,
      );

      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });
}
