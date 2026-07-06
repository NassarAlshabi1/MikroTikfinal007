// ============================================================
//  Test Helpers — مساعدات الاختبارات للشاشات
//  يوفر mocks و pump helpers لاختبار كل شاشة بمعزل عن الشبكة
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:mikrotik_manager/mqtt_service.dart';

/// بيانات تجريبية للملفات الشخصية (تُستخدم في AddUserScreen, BulkAddScreen, etc.)
final List<Map<String, dynamic>> mockProfiles = [
  {
    '.id': '*1',
    'name': 'default',
    'rate-limit': '1M/1M',
    'shared-users': '1',
  },
  {
    '.id': '*2',
    'name': 'premium',
    'rate-limit': '10M/10M',
    'shared-users': '2',
  },
  {
    '.id': '*3',
    'name': 'unlimited',
    'rate-limit': '100M/100M',
    'shared-users': '5',
  },
];

/// قائمة كروت تجريبية
final List<String> mockCardList = [
  'user001',
  'user002',
  'user003',
  'user004',
  'user005',
];

/// بيانات شبكة مرتبطة تجريبية
final Map<String, dynamic> mockLinkedData = {
  'name': 'Test Customer',
  'profile': 'premium',
  'phone': '0501234567',
};

/// mock router client — يلبي الـ interface الأساسي
/// (لا يمكننا استخدام RouterOSClient الحقيقي لأنه يتطلب اتصال شبكة)
class MockRouterOSClient {
  final bool shouldFail;
  MockRouterOSClient({this.shouldFail = false});

  Future<List<Map<String, dynamic>>> talk(List<String> args) async {
    if (shouldFail) {
      throw Exception('Mock: connection failed');
    }
    // ردود مختلفة حسب المسار
    if (args.isNotEmpty && args.first.contains('hotspot/active')) {
      return [
        {'user': 'test_user_1', 'address': '192.168.1.10', 'uptime': '1h30m'},
        {'user': 'test_user_2', 'address': '192.168.1.11', 'uptime': '2h15m'},
      ];
    }
    if (args.isNotEmpty && args.first.contains('user-manager/user')) {
      return mockProfiles;
    }
    return [];
  }

  Future<bool> login() async => !shouldFail;
  void close() {}
}

/// يُهيّئ SharedPreferences بقيم افتراضية (مهم لتجنب الـ crashes)
Future<void> setupMockSharedPreferences({
  String ip = '192.168.1.1',
  String user = 'admin',
  String pass = 'admin',
  String port = '8728',
  bool rememberMe = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'ip': ip,
    'user': user,
    'pass': pass,
    'port': port,
    'remember_me': rememberMe,
    'mqtt_username': '',
    'mqtt_password': '',
  });
}

/// يضخ شاشة معينة في MaterialApp مع theme التطبيق الأصلي
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  bool withMqttProvider = false,
  Size screenSize = const Size(1080, 1920),
}) async {
  tester.view.physicalSize = screenSize;
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);

  Widget child = MaterialApp(
    theme: _testTheme,
    home: screen,
    scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
  );

  if (withMqttProvider) {
    child = ChangeNotifierProvider<MqttService>(
      create: (_) => MqttService(
        scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
      ),
      child: MaterialApp(
        theme: _testTheme,
        home: screen,
      ),
    );
  }

  await tester.pumpWidget(child);
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

/// Theme مطابق للتطبيق
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
    error: Colors.redAccent,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onError: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2d213f),
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
);

/// يتحقق من عدم وجود render errors (شائعة على الأجهزة الصغيرة)
void expectNoOverflowErrors(WidgetTester tester) {
  // flutter test يُسجل overflow errors تلقائياً
  // نتحقق من عدم وجودها بعد البناء
  expect(tester.takeException(), isNull,
      reason: 'لا يجب أن تكون هناك استثناءات أثناء البناء');
}

/// يبحث عن widget من نوع معيّن أو يفشل برسالة واضحة
Finder findByText(String text) => find.text(text);
Finder findByKey(String key) => find.byKey(Key(key));

/// انتظار آمن للعنصر مع timeout
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  await tester.pumpAndSettle(timeout);
  expect(finder, findsWidgets,
      reason: 'العنصر المطلوب لم يظهر خلال ${timeout.inSeconds} ثانية');
}
