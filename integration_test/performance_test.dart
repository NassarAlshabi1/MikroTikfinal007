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
import 'package:shared_preferences/shared_preferences.dart';

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
const int _thresholdPass = 2000; // < 2s ممتاز
const int _thresholdWarn = 5000; // 2-5s مقبول
// > 5s بطيء (FAIL)

/// تقرير كل الاختبارات
final List<ScreenPerfResult> _results = [];

/// يقيس زمن بناء شاشة معينة
Future<ScreenPerfResult> measureScreen(
  WidgetTester tester,
  String screenName,
  Widget screen, {
  Duration settleTimeout = const Duration(seconds: 10),
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

    final settleStopwatch = Stopwatch()..start();
    await tester.pumpAndSettle(settleTimeout);
    settleStopwatch.stop();
    settleMs = settleStopwatch.elapsedMilliseconds;
  } catch (e) {
    if (buildMs == null) buildMs = buildStopwatch.elapsedMilliseconds;
    if (settleMs == null) settleMs = 0;
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
      await tester.pumpAndSettle(const Duration(seconds: 10));
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
        app.HomeScreen(isVersion7OrNewer: true, username: 'admin'),
        wrapWithProvider: true,
      );
      _results.add(result);
      expect(result.status, isNot(equals('FAIL')),
          reason: 'HomeScreen build failed');
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
          tester, 'ExtractCardsScreen', const ExtractCardsScreen());
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
    print('\n');
    print('=' * 80);
    print('  📊 PERFORMANCE TEST REPORT');
    print('=' * 80);
    print('${'Screen'.padRight(30)} | ${'Build'.padLeft(8)} | ${'Settle'.padLeft(8)} | ${'Total'.padLeft(8)} | Status');
    print('-' * 80);

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
      print('${r.screenName.padRight(30)} | '
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
        print('    └─ Error: ${r.error}');
      }
    }

    print('-' * 80);
    print('${'TOTAL'.padRight(30)} | '
        '${totalBuildMs.toString().padLeft(6)}ms | '
        '${totalSettleMs.toString().padLeft(6)}ms | '
        '${totalMs.toString().padLeft(6)}ms |');
    print('-' * 80);
    print('Summary: ✅ $passCount PASS | ⚠️ $warnCount WARN | ❌ $failCount FAIL');
    print('Average build time per screen: ${(totalMs / _results.length).round()}ms');
    print('Thresholds: PASS < ${_thresholdPass}ms | WARN < ${_thresholdWarn}ms | FAIL >= ${_thresholdWarn}ms');
    print('=' * 80);

    // JSON report for CI parsing
    print('\n=== JSON REPORT ===');
    print(jsonEncode({
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
    print('=== END JSON REPORT ===\n');
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
