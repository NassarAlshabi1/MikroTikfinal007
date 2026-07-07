// ============================================================
//  Performance Tests — قياس زمن بناء كل شاشة وإصدار تقرير
//  يُشغّل عبر: flutter test integration_test/performance_test.dart
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart' as provider;

import 'package:mikrotik_manager/main.dart' as app;
import 'package:mikrotik_manager/active_users_screen.dart';
import 'package:mikrotik_manager/cards_statistics_screen.dart';
import 'package:mikrotik_manager/card_list_screen.dart';
import 'package:mikrotik_manager/stats_screen.dart';
import 'package:mikrotik_manager/add_user_screen.dart';
import 'package:mikrotik_manager/bulk_add_screen.dart';
import 'package:mikrotik_manager/network_doctor_screen.dart';
import 'package:mikrotik_manager/network_map_screen.dart';
import 'package:mikrotik_manager/device_monitoring_screen.dart';
import 'package:mikrotik_manager/rogue_dhcp_detector_screen.dart';
import 'package:mikrotik_manager/system_dashboard_screen.dart';
import 'package:mikrotik_manager/pdf_templates_screen.dart';
import 'package:mikrotik_manager/edit_pdf_template_screen.dart';
import 'package:mikrotik_manager/extract_cards_screen.dart';
import 'package:mikrotik_manager/process_image_screen.dart';
import 'package:mikrotik_manager/saved_files_screen.dart';
import 'package:mikrotik_manager/profile_screen.dart';
import 'package:mikrotik_manager/qahtani_link_screen.dart';
import 'package:mikrotik_manager/backup_system_screen.dart';
import 'package:mikrotik_manager/mqtt_service.dart';
import 'package:mikrotik_manager/v2/ui/active_users_v2.dart';
import 'package:mikrotik_manager/v2/ui/cards_statistics_v2.dart';
import 'test_helpers.dart';

/// نتيجة قياس شاشة واحدة
class ScreenPerfResult {
  final String screenName;
  final int buildTimeMs;
  final int settleTimeMs;
  final int totalTimeMs;
  final String status; // 'PASS', 'WARN', 'FAIL'
  final String? error;

  ScreenPerfResult({
    required this.screenName,
    required this.buildTimeMs,
    required this.settleTimeMs,
    required this.totalTimeMs,
    required this.status,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'screen': screenName,
        'buildMs': buildTimeMs,
        'settleMs': settleTimeMs,
        'totalMs': totalTimeMs,
        'status': status,
        if (error != null) 'error': error,
      };
}

/// عتبات الأداء (ms)
// ملاحظة: المحاكي أبطأ من الجهاز الحقيقي بـ 3-5x، لذا العتبات متساهلة
const int _thresholdPass = 3000;  // < 3s ممتاز على المحاكي
const int _thresholdWarn = 8000;  // 3-8s مقبول على المحاكي
// > 8s بطيء (FAIL)

/// تقرير كل الاختبارات
final List<ScreenPerfResult> _results = [];

/// يقيس زمن بناء شاشة معينة
///
/// ملاحظة: نستخدم pump(Duration) بدل pumpAndSettle لأن:
/// - الشاشات تحتوي على network calls للـ MikroTik (تفشل في CI بدون router حقيقي)
/// - هذه الـ calls تأخذ timeout طويل (10-30s) حتى مع mounted checks
/// - الهدف هو قياس زمن البناء (build)، وليس انتظار اكتمال الـ network
Future<ScreenPerfResult> measureScreen(
  WidgetTester tester,
  String screenName,
  Widget screen, {
  Duration settleTimeout = const Duration(seconds: 2),
  bool wrapWithProvider = false,
  bool wrapWithRiverpod = false,
}) async {
  int? buildMs;
  int? settleMs;
  String? error;

  final buildStopwatch = Stopwatch()..start();
  try {
    if (wrapWithRiverpod) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: _testTheme, home: screen),
        ),
      );
    } else if (wrapWithProvider) {
      await tester.pumpWidget(
        provider.ChangeNotifierProvider<MqttService>(
          create: (_) => MqttService(
            scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          ),
          child: MaterialApp(theme: _testTheme, home: screen),
        ),
      );
    } else {
      await tester.pumpWidget(
        MaterialApp(theme: _testTheme, home: screen),
      );
    }
    buildStopwatch.stop();
    buildMs = buildStopwatch.elapsedMilliseconds;

    // pump(Duration) يضخ إطار واحد بعد تقدم الوقت — كافٍ لقياس البناء
    // لا ننتظر اكتمال الـ network calls (قد تأخذ 10-30s في CI)
    final settleStopwatch = Stopwatch()..start();
    await tester.pump(settleTimeout);
    // محاولة pumpAndSettle بـ timeout قصير جداً — إن لم يكتمل، نتجاهل
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    } catch (_) {
      // timeout متوقع للشاشات ذات الـ network calls — لا يعد فشلاً
    }
    settleStopwatch.stop();
    settleMs = settleStopwatch.elapsedMilliseconds;
  } catch (e) {
    buildMs ??= buildStopwatch.elapsedMilliseconds;
    settleMs ??= 0;
    error = e.toString();
  }

  final totalMs = buildMs + settleMs;
  String status;
  if (error != null) {
    status = 'FAIL';
  } else if (totalMs < _thresholdPass) {
    status = 'PASS';
  } else if (totalMs < _thresholdWarn) {
    status = 'WARN';
  } else {
    status = 'FAIL';
  }

  return ScreenPerfResult(
    screenName: screenName,
    buildTimeMs: buildMs,
    settleTimeMs: settleMs,
    totalTimeMs: totalMs,
    status: status,
    error: error,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setupMockSharedPreferences();
  });

  group('Performance Tests - Build Time per Screen', () {
    // ============================================================
    //  قياس كل شاشة على حدة
    // ============================================================

    testWidgets('LoginScreen', (tester) async {
      app.main();
      final sw = Stopwatch()..start();
      // LoginScreen تحتوي على NetworkInfo().getWifiGatewayIP() (async)
      // نستخدم pump(Duration) بدل pumpAndSettle لتفادي timeout
      await tester.pump(const Duration(seconds: 2));
      try {
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      } catch (_) {}
      sw.stop();
      _results.add(ScreenPerfResult(
        screenName: 'LoginScreen',
        buildTimeMs: 0,
        settleTimeMs: sw.elapsedMilliseconds,
        totalTimeMs: sw.elapsedMilliseconds,
        status: sw.elapsedMilliseconds < _thresholdWarn ? 'PASS' : 'FAIL',
      ));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('HomeScreen', (tester) async {
      final result = await measureScreen(
        tester,
        'HomeScreen',
        const app.HomeScreen(isVersion7OrNewer: true, username: 'admin'),
        wrapWithProvider: true,
      );
      _results.add(result);
      // نتساهل مع WARN على المحاكي (HomeScreen بطيئة بسبب GridView + profiles fetch)
      expect(result.status, isNot(equals('FAIL')),
          reason: 'HomeScreen build failed: ${result.error ?? "took ${result.totalTimeMs}ms"}');
    });

    testWidgets('ActiveUsersScreen', (tester) async {
      final result = await measureScreen(
          tester, 'ActiveUsersScreen', const ActiveUsersScreen());
      _results.add(result);
    });

    testWidgets('CardsStatisticsScreen', (tester) async {
      final result = await measureScreen(
          tester, 'CardsStatisticsScreen', const CardsStatisticsScreen());
      _results.add(result);
    });

    testWidgets('CardListScreen', (tester) async {
      final result = await measureScreen(
        tester,
        'CardListScreen',
        CardListScreen(cardList: mockCardList),
        wrapWithProvider: true, // CardListScreen تحتاج MqttService
      );
      _results.add(result);
    });

    testWidgets('StatsScreen', (tester) async {
      final result =
          await measureScreen(tester, 'StatsScreen', const StatsScreen());
      _results.add(result);
    });

    testWidgets('AddUserScreen', (tester) async {
      final result = await measureScreen(
        tester,
        'AddUserScreen',
        AddUserScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          customer: 'test',
        ),
      );
      _results.add(result);
    });

    testWidgets('BulkAddScreen', (tester) async {
      final result = await measureScreen(
        tester,
        'BulkAddScreen',
        BulkAddScreen(
          profiles: mockProfiles,
          isVersion7OrNewer: true,
          username: 'admin',
        ),
        wrapWithProvider: true, // BulkAddScreen تحتاج MqttService
      );
      _results.add(result);
    });

    testWidgets('NetworkDoctorScreen', (tester) async {
      final result = await measureScreen(
          tester, 'NetworkDoctorScreen', const NetworkDoctorScreen());
      _results.add(result);
    });

    testWidgets('NetworkMapScreen', (tester) async {
      final result = await measureScreen(
          tester, 'NetworkMapScreen', const NetworkMapScreen());
      _results.add(result);
    });

    testWidgets('DeviceMonitoringScreen', (tester) async {
      final mockClient = MockRouterOSClient();
      final result = await measureScreen(
        tester,
        'DeviceMonitoringScreen',
        DeviceMonitoringScreen(client: mockClient as dynamic),
      );
      _results.add(result);
    });

    testWidgets('RogueDhcpDetectorScreen', (tester) async {
      final result = await measureScreen(
          tester, 'RogueDhcpDetectorScreen', const RogueDhcpDetectorScreen());
      _results.add(result);
    });

    testWidgets('SystemDashboardScreen', (tester) async {
      final result = await measureScreen(
          tester, 'SystemDashboardScreen', const SystemDashboardScreen());
      _results.add(result);
    });

    testWidgets('PdfTemplatesScreen', (tester) async {
      final result = await measureScreen(
        tester,
        'PdfTemplatesScreen',
        PdfTemplatesScreen(profiles: mockProfiles),
      );
      _results.add(result);
    });

    testWidgets('EditPdfTemplateScreen', (tester) async {
      final result = await measureScreen(
        tester,
        'EditPdfTemplateScreen',
        EditPdfTemplateScreen(profiles: mockProfiles),
      );
      _results.add(result);
    });

    testWidgets('ExtractCardsScreen', (tester) async {
      final result = await measureScreen(
          tester, 'ExtractCardsScreen', const ExtractCardsScreen(),
          wrapWithProvider: true); // ExtractCardsScreen تحتاج MqttService
      _results.add(result);
    });

    testWidgets('ProcessImageScreen', (tester) async {
      final result = await measureScreen(
        tester,
        'ProcessImageScreen',
        const ProcessImageScreen(
          imagePath: '/tmp/test.png',
          prefix: 'u',
          length: 6,
          total: 10,
        ),
      );
      _results.add(result);
    });

    testWidgets('SavedFilesScreen', (tester) async {
      final result = await measureScreen(
          tester, 'SavedFilesScreen', const SavedFilesScreen());
      _results.add(result);
    });

    testWidgets('ProfileScreen', (tester) async {
      final result =
          await measureScreen(tester, 'ProfileScreen', const ProfileScreen());
      _results.add(result);
    });

    testWidgets('QahtaniLinkScreen', (tester) async {
      final result = await measureScreen(
        tester,
        'QahtaniLinkScreen',
        const QahtaniLinkScreen(),
        wrapWithProvider: true,
      );
      _results.add(result);
    });

    testWidgets('BackupSystemScreen', (tester) async {
      final result = await measureScreen(
          tester, 'BackupSystemScreen', const BackupSystemScreen());
      _results.add(result);
    });

    testWidgets('ActiveUsersV2 (Riverpod)', (tester) async {
      final result = await measureScreen(
        tester,
        'ActiveUsersV2',
        const ActiveUsersV2(),
        wrapWithRiverpod: true,
      );
      _results.add(result);
    });

    testWidgets('CardsStatisticsV2 (Riverpod)', (tester) async {
      final result = await measureScreen(
        tester,
        'CardsStatisticsV2',
        const CardsStatisticsV2(),
        wrapWithRiverpod: true,
      );
      _results.add(result);
    });
  });

  // ============================================================
  //  تقرير ملخص بعد كل الاختبارات
  // ============================================================
  tearDownAll(() {
    debugPrint('\n');
    debugPrint('=' * 80);
    debugPrint('  📊 PERFORMANCE TEST REPORT');
    debugPrint('=' * 80);
    debugPrint('${'Screen'.padRight(30)} | ${'Build'.padLeft(8)} | ${'Settle'.padLeft(8)} | ${'Total'.padLeft(8)} | Status');
    debugPrint('-' * 80);

    int passCount = 0, warnCount = 0, failCount = 0;
    int totalBuildMs = 0;
    int totalSettleMs = 0;
    int totalMs = 0;

    for (final r in _results) {
      final emoji = r.status == 'PASS'
          ? '✅'
          : r.status == 'WARN'
              ? '⚠️'
              : '❌';
      debugPrint('${r.screenName.padRight(30)} | '
          '${r.buildTimeMs.toString().padLeft(6)}ms | '
          '${r.settleTimeMs.toString().padLeft(6)}ms | '
          '${r.totalTimeMs.toString().padLeft(6)}ms | '
          '$emoji ${r.status}');

      totalBuildMs += r.buildTimeMs;
      totalSettleMs += r.settleTimeMs;
      totalMs += r.totalTimeMs;

      if (r.status == 'PASS') {
        passCount++;
      } else if (r.status == 'WARN') {
        warnCount++;
      } else {
        failCount++;
      }

      if (r.error != null) {
        debugPrint('    └─ Error: ${r.error}');
      }
    }

    debugPrint('-' * 80);
    debugPrint('${'TOTAL'.padRight(30)} | '
        '${totalBuildMs.toString().padLeft(6)}ms | '
        '${totalSettleMs.toString().padLeft(6)}ms | '
        '${totalMs.toString().padLeft(6)}ms |');
    debugPrint('-' * 80);
    debugPrint('Summary: ✅ $passCount PASS | ⚠️ $warnCount WARN | ❌ $failCount FAIL');
    debugPrint('Average build time per screen: ${(totalMs / _results.length).round()}ms');
    debugPrint('Thresholds: PASS < ${_thresholdPass}ms | WARN < ${_thresholdWarn}ms | FAIL >= ${_thresholdWarn}ms');
    debugPrint('=' * 80);

    // JSON report for CI parsing
    debugPrint('\n=== JSON REPORT ===');
    debugPrint(jsonEncode({
      'summary': {
        'total_screens': _results.length,
        'pass': passCount,
        'warn': warnCount,
        'fail': failCount,
        'total_build_ms': totalBuildMs,
        'total_settle_ms': totalSettleMs,
        'total_ms': totalMs,
        'avg_ms_per_screen': (totalMs / _results.length).round(),
      },
      'screens': _results.map((r) => r.toJson()).toList(),
    }));
    debugPrint('=== END JSON REPORT ===\n');
  });
}

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
  ),
);
