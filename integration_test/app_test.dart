// ============================================================
//  نقطة الدخول الموحدة لاختبارات التكامل
//  يُشغّل عبر: flutter test integration_test/app_test.dart
//
//  يستدعي كل ملفات الاختبار في مجلد screens/
//  هذا يسمح بتشغيل كل الاختبارات بأمر واحد
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// استيراد كل ملفات الاختبار
import 'screens/login_home_test.dart' as login_home;
import 'screens/users_stats_test.dart' as users_stats;
import 'screens/network_test.dart' as network;
import 'screens/pdf_image_test.dart' as pdf_image;
import 'screens/misc_v2_test.dart' as misc_v2;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // تشغيل كل مجموعات الاختبارات
  // كل import يُعرّف main() الخاص به، نستدعيها هنا
  group('=== Login & Home Screens ===', login_home.main);
  group('=== Users & Stats Screens ===', users_stats.main);
  group('=== Network Screens ===', network.main);
  group('=== PDF & Image Screens ===', pdf_image.main);
  group('=== Misc & V2 Screens ===', misc_v2.main);
}
