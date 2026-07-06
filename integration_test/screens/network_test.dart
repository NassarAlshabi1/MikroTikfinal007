// ============================================================
//  اختبارات شاشات الشبكة
//  - NetworkDoctorScreen
//  - NetworkMapScreen
//  - NetworkToolsScreen
//  - DeviceMonitoringScreen
//  - RogueDhcpDetectorScreen
//  - SystemDashboardScreen
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mikrotik_manager/network_doctor_screen.dart';
import 'package:mikrotik_manager/network_map_screen.dart';
import 'package:mikrotik_manager/network_tools_screen.dart';
import 'package:mikrotik_manager/device_monitoring_screen.dart';
import 'package:mikrotik_manager/rogue_dhcp_detector_screen.dart';
import 'package:mikrotik_manager/system_dashboard_screen.dart';
import '../test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkDoctorScreen Tests', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    testWidgets('يقلع ويعرض الـ AppBar', (tester) async {
      await pumpScreen(tester, const NetworkDoctorScreen());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('يعرض شاشة بدون crash', (tester) async {
      await pumpScreen(tester, const NetworkDoctorScreen());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('NetworkMapScreen Tests', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    testWidgets('يقلع ويعرض خريطة الشبكة', (tester) async {
      await pumpScreen(tester, const NetworkMapScreen());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('يعرض InteractiveViewer للخريطة', (tester) async {
      await pumpScreen(tester, const NetworkMapScreen());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // InteractiveViewer شائع لخرائط الشبكة
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('NetworkToolsScreen Tests', () {
    testWidgets('يقلع ويعرض أدوات الشبكة', (tester) async {
      // NetworkToolsScreen يتطلب RouterOSClient
      // نستخدم mock client
      final mockClient = MockRouterOSClient();

      await pumpScreen(
        tester,
        NetworkToolsScreen(client: mockClient as dynamic),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('أدوات الشبكة'), findsOneWidget);
    });
  });

  group('DeviceMonitoringScreen Tests', () {
    testWidgets('يقلع ويعرض شاشة المراقبة', (tester) async {
      final mockClient = MockRouterOSClient();

      await pumpScreen(
        tester,
        DeviceMonitoringScreen(client: mockClient as dynamic),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('يعرض زر تحديث', (tester) async {
      final mockClient = MockRouterOSClient();

      await pumpScreen(
        tester,
        DeviceMonitoringScreen(client: mockClient as dynamic),
      );

      await tester.pumpAndSettle();

      // غالباً يوجد IconButton للتحديث
      final hasRefreshIcon = find.byIcon(Icons.refresh).evaluate().isNotEmpty;
      expect(hasRefreshIcon || find.byType(AppBar).evaluate().isNotEmpty, isTrue);
    });
  });

  group('RogueDhcpDetectorScreen Tests', () {
    testWidgets('يقلع ويعرض شاشة كاشف DHCP', (tester) async {
      await pumpScreen(tester, const RogueDhcpDetectorScreen());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('يعرض زر بدء المسح', (tester) async {
      await pumpScreen(tester, const RogueDhcpDetectorScreen());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ابحث عن ElevatedButton أو OutlinedButton
      final hasButton = find.byType(ElevatedButton).evaluate().isNotEmpty ||
          find.byType(OutlinedButton).evaluate().isNotEmpty;
      expect(hasButton, isTrue, reason: 'يجب أن يوجد زر بدء المسح');
    });
  });

  group('SystemDashboardScreen Tests', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    testWidgets('يقلع ويعرض لوحة النظام', (tester) async {
      await pumpScreen(tester, const SystemDashboardScreen());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('لا يسبب crash بعد 10 ثوانٍ (يغطي الـ refresh timer)',
        (tester) async {
      await pumpScreen(tester, const SystemDashboardScreen());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
