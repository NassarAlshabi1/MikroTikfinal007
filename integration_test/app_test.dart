// ============================================================
//  نقطة الدخول الموحدة لاختبارات التكامل
//  يُشغّل عبر: flutter test integration_test/app_test.dart
//
//  يتضمن:
//  1. اختبارات شاشات (smoke tests) — screens/
//  2. اختبارات أداء (build time per screen) — performance_test.dart
//  3. اختبارات لوجيك (validation, business rules) — logic_test.dart
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// استيراد كل ملفات الاختبار
import 'screens/login_home_test.dart' as login_home;
import 'screens/users_stats_test.dart' as users_stats;
import 'screens/network_test.dart' as network;
import 'screens/pdf_image_test.dart' as pdf_image;
import 'screens/misc_v2_test.dart' as misc_v2;
import 'performance_test.dart' as performance;
import 'logic_test.dart' as logic;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ترتيب التشغيل: لوجيك أولاً (أسرع) ← شاشات ← أداء (أبطأ)
  group('=== Logic Tests (Validation) ===', logic.main);
  group('=== Screen Smoke Tests ===', () {
    group('Login & Home', login_home.main);
    group('Users & Stats', users_stats.main);
    group('Network', network.main);
    group('PDF & Image', pdf_image.main);
    group('Misc & V2', misc_v2.main);
  });
  group('=== Performance Tests (Build Time) ===', performance.main);
}
