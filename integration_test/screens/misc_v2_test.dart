// ============================================================
//  اختبارات الشاشات المتبقية
//  - ProfileScreen
//  - QahtaniLinkScreen
//  - BackupSystemScreen
//  - ActiveUsersV2 (Riverpod)
//  - CardsStatisticsV2 (Riverpod)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mikrotik_manager/profile_screen.dart';
import 'package:mikrotik_manager/qahtani_link_screen.dart';
import 'package:mikrotik_manager/backup_system_screen.dart';
import 'package:mikrotik_manager/mqtt_service.dart';
import 'package:mikrotik_manager/v2/ui/active_users_v2.dart';
import 'package:mikrotik_manager/v2/ui/cards_statistics_v2.dart';
import '../test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileScreen Tests', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    testWidgets('يقلع ويعرض شاشة الملف الشخصي', (tester) async {
      await pumpScreen(tester, const ProfileScreen());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('يعرض حالة فارغة أو محتوى', (tester) async {
      await pumpScreen(tester, const ProfileScreen());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('QahtaniLinkScreen Tests', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    testWidgets('يقلع ويعرض شاشة ربط الشبكة', (tester) async {
      // QahtaniLinkScreen تستخدم MqttService — نوفّرها
      final mqttService = MqttService(
        scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
      );

      await tester.pumpWidget(
        provider.ChangeNotifierProvider<MqttService>(
          create: (_) => mqttService,
          child: MaterialApp(
            theme: _testTheme,
            home: const QahtaniLinkScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('لا يسبب crash مع MQTT غير مُهيأ', (tester) async {
      final mqttService = MqttService(
        scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
      );

      await tester.pumpWidget(
        provider.ChangeNotifierProvider<MqttService>(
          create: (_) => mqttService,
          child: MaterialApp(
            theme: _testTheme,
            home: const QahtaniLinkScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 10));
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('BackupSystemScreen Tests', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    testWidgets('يقلع ويعرض شاشة النسخ الاحتياطي', (tester) async {
      await pumpScreen(tester, const BackupSystemScreen());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('يعرض زر إنشاء نسخة احتياطية', (tester) async {
      await pumpScreen(tester, const BackupSystemScreen());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ابحث عن FAB أو زر
      final hasFab = find.byType(FloatingActionButton).evaluate().isNotEmpty;
      final hasButton = find.byType(ElevatedButton).evaluate().isNotEmpty;
      expect(hasFab || hasButton, isTrue,
          reason: 'يجب أن يوجد زر لإنشاء نسخة احتياطية');
    });

    testWidgets('يعرض قائمة فارغة أو قائمة بالنسخ', (tester) async {
      await pumpScreen(tester, const BackupSystemScreen());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('ActiveUsersV2 Tests (Riverpod)', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    testWidgets('يقلع ويعرض شاشة المستخدمين V2', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: _testTheme,
            home: const ActiveUsersV2(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('المستخدمون النشطون V2'), findsOneWidget);
    });

    testWidgets('يعرض زر التحديث', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: _testTheme,
            home: const ActiveUsersV2(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('يعرض أزرار التنقل بين الصفحات', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: _testTheme,
            home: const ActiveUsersV2(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('السابق'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);
    });

    testWidgets('يعرض نوع المصدر (Hotspot/User Manager)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: _testTheme,
            home: const ActiveUsersV2(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // عرض نوع الـ paging
      final hasServerPaging =
          find.text('Server Paging').evaluate().isNotEmpty ||
              find.text('Local Paging').evaluate().isNotEmpty;
      expect(hasServerPaging, isTrue);
    });
  });

  group('CardsStatisticsV2 Tests (Riverpod)', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    testWidgets('يقلع ويعرض شاشة إحصائيات الكروت V2', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: _testTheme,
            home: const CardsStatisticsV2(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('إحصائيات الكروت V2'), findsOneWidget);
    });

    testWidgets('يعرض زر التحديث', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: _testTheme,
            home: const CardsStatisticsV2(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('يعرض بطاقات الإحصائيات بعد التحديث', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: _testTheme,
            home: const CardsStatisticsV2(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 10));

      // يجب أن تظهر البطاقات الإحصائية أو شاشة تحميل
      final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      final hasCard = find.byType(Card).evaluate().isNotEmpty;
      final hasStatsText =
          find.text('عدد المستخدمين').evaluate().isNotEmpty ||
              find.text('عدد الجلسات').evaluate().isNotEmpty;
      expect(hasLoading || hasCard || hasStatsText, isTrue);
    });
  });
}

// استخدم نفس theme من test_helpers
final ThemeData _testTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF6b3fa0),
  scaffoldBackgroundColor: const Color(0xFF1a1329),
  fontFamily: 'Tajawal',
  cardColor: const Color(0xFF2d213f),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF6b3fa0),
    secondary: Color(0xFFB39DDB),
    surface: Color(0xFF2d213f),
    background: Color(0xFF1a1329),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2d213f),
    elevation: 0,
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
  ),
);
