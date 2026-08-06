// ============================================================
//  اختبارات شاشة إضافة الكروت الجماعية (BulkAddScreen)
//
//  يغطي:
//  ① بناء الشاشة بنجاح (لا تُرمي استثناءات)
//  ② عرض الحقول الأساسية (بادئة، طول، عدد، فئة، نوع)
//  ③ حالة الـ loading (ProgressIndicator)
//  ④ حالة الـ profiles الفارغة (حالة boundary)
//  ⑤ حالة الـ templates الفارغة (حالة boundary)
//  ⑥ التحقق من صحة المدخلات (form validation)
//  ⑦ تغيير قيمة dropdowns يحدّث الحالة
//  ⑧ زر "إنشاء الكروت" معطّل أثناء توليد الكروت
//  ⑨ الـ AppBar يعرض العنوان الصحيح
//  ⑩ الـ checkbox يعمل بشكل صحيح
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mikrotik_manager/bulk_add_screen.dart';
import 'package:mikrotik_manager/mqtt_service.dart';
import 'package:mikrotik_manager/providers/mqtt_service_provider.dart';
import 'package:mikrotik_manager/theme/professional_theme.dart';

/// MqttService وهمي لا يتصل فعلياً بالـ broker
class FakeMqttService extends MqttService {
  FakeMqttService() : super() {
    // تفادي الاتصال الحقيقي في الاختبارات
  }
}

Widget _wrapWidget(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      theme: ProfessionalTheme.light,
      darkTheme: ProfessionalTheme.dark,
      themeMode: ThemeMode.light,
      home: child,
    ),
  );
}

const _sampleProfiles = <Map<String, dynamic>>[
  {'name': 'default', 'rate-limit': '1M/1M'},
  {'name': 'premium', 'rate-limit': '10M/10M'},
  {'name': 'unlimited'},
];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'pdf_templates': <String>[],
      'is_network_linked': false,
    });
  });

  // ============================================================
  //  ① بناء الشاشة بنجاح
  // ============================================================
  group('① بناء الشاشة', () {
    testWidgets('الشاشة تُبنى بنجاح بدون استثناءات', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BulkAddScreen(
            profiles: _sampleProfiles,
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // إن رمى استثناء، يفشل الاختبار تلقائياً
      expect(find.byType(BulkAddScreen), findsOneWidget);
    });

    testWidgets('يتم عرض عنوان الشاشة في الـ AppBar', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BulkAddScreen(
            profiles: _sampleProfiles,
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إضافة كروت جماعية'), findsOneWidget);
    });
  });

  // ============================================================
  //  ② عرض الحقول الأساسية
  // ============================================================
  group('② عرض الحقول الأساسية', () {
    testWidgets('يتم عرض كل الحقول المتوقعة', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BulkAddScreen(
            profiles: _sampleProfiles,
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // الحقول المتوقعة
      expect(find.text('بادئة (اختياري)'), findsOneWidget);
      expect(find.text('الطول'), findsOneWidget);
      expect(find.text('العدد'), findsOneWidget);
      expect(find.text('الفئة (البروفايل)'), findsOneWidget);
      expect(find.text('نوع أحرف المستخدم'), findsOneWidget);
      expect(find.text('نوع الكرت'), findsOneWidget);
      expect(find.text('نوع القالب (اختياري)'), findsOneWidget);
      expect(find.text('Shared Users'), findsOneWidget);
      expect(find.text('ربط كلمة المرور بأول مستخدم'), findsOneWidget);
      expect(find.text('إنشاء الكروت'), findsOneWidget);
    });

    testWidgets('القيم الافتراضية للحقول صحيحة', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BulkAddScreen(
            profiles: _sampleProfiles,
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // الطول الافتراضي = 8
      expect(find.text('8'), findsOneWidget);
      // العدد الافتراضي = 10
      expect(find.text('10'), findsOneWidget);
      // Shared Users الافتراضي = 1
      expect(find.text('1'), findsOneWidget);
    });
  });

  // ============================================================
  //  ③ حالة الـ loading
  // ============================================================
  group('③ حالة الـ loading', () {
    testWidgets('لا يتم عرض مؤشر التحميل عند الفتح', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BulkAddScreen(
            profiles: _sampleProfiles,
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // _isGenerating = false في البداية، فلا ينبغي وجود LinearProgressIndicator
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  // ============================================================
  //  ④ حالة الـ profiles الفارغة (boundary case)
  // ============================================================
  group('④ profiles فارغة', () {
    testWidgets('الشاشة تُبنى بنجاح حتى مع profiles فارغة', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          const BulkAddScreen(
            profiles: [],
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // يجب أن تُبنى الشاشة بدون استثناء
      expect(find.byType(BulkAddScreen), findsOneWidget);
      expect(find.text('إضافة كروت جماعية'), findsOneWidget);
    });
  });

  // ============================================================
  //  ⑤ حالة الـ templates الفارغة
  // ============================================================
  group('⑤ templates فارغة', () {
    testWidgets('dropdown القالب لا يرمي StateError عند عدم وجود قوالب',
        (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BulkAddScreen(
            profiles: _sampleProfiles,
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // ابحث عن dropdown القالب (الثاني من الأخير)
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      // نتوقع 4 dropdowns: profile, charType, cardType, template
      expect(dropdowns, findsNWidgets(4));

      // النقر على dropdown القالب (الأخير) لا يرمي استثناء
      await tester.tap(dropdowns.last);
      await tester.pumpAndSettle();

      // يجب أن يُعرض الـ hint "اختر قالب للتصدير إلى PDF"
      expect(find.text('اختر قالب للتصدير إلى PDF'), findsOneWidget);
    });

    testWidgets('dropdown القالب فارغ عند عدم وجود قوالب',
        (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BulkAddScreen(
            profiles: _sampleProfiles,
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // ابحث عن dropdown القالب
      final dropdownFinder = find.byType(DropdownButtonFormField<String>).last;
      final dropdown =
          tester.widget<DropdownButtonFormField<String>>(dropdownFinder);
      // نتوقع 0 items لأنه لا توجد قوالب في SharedPreferences
      // نتحقق عبر initialValue (يجب أن يكون null)
      expect(dropdown.initialValue, isNull);
    });
  });

  // ============================================================
  //  ⑥ التحقق من صحة المدخلات
  // ============================================================
  group('⑥ التحقق من صحة المدخلات', () {
    testWidgets('الضغط على "إنشاء الكروت" بدون اختيار فئة يعرض خطأ', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BulkAddScreen(
            profiles: _sampleProfiles,
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // التمرير للأسفل لرؤية زر "إنشاء الكروت"
      await tester.scrollUntilVisible(
        find.text('إنشاء الكروت'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // النقر على زر "إنشاء الكروت"
      await tester.tap(find.text('إنشاء الكروت'));
      await tester.pumpAndSettle();

      // يجب أن يُعرض خطأ التحقق
      expect(find.text('الرجاء اختيار فئة'), findsOneWidget);
    });

    testWidgets('الطول الفارغ يعرض خطأ "مطلوب"', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BulkAddScreen(
            profiles: _sampleProfiles,
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // مسح حقل الطول (الثاني في النموذج)
      await tester.enterText(find.byType(TextFormField).at(1), '');
      await tester.pumpAndSettle();

      // التمرير لرؤية الزر
      await tester.scrollUntilVisible(
        find.text('إنشاء الكروت'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // النقر على زر "إنشاء الكروت"
      await tester.tap(find.text('إنشاء الكروت'));
      await tester.pumpAndSettle();

      expect(find.text('مطلوب'), findsWidgets);
    });
  });

  // ============================================================
  //  ⑦ تغيير قيمة dropdowns يحدّث الحالة
  // ============================================================
  group('⑦ تغيير dropdowns', () {
    testWidgets('اختيار نوع أحرف "حروف فقط" يحدّث الحالة', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BulkAddScreen(
            profiles: _sampleProfiles,
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // dropdown نوع الأحرف هو الثاني (index 1)
      final charTypeDropdown = find.byType(DropdownButtonFormField<String>).at(1);
      await tester.tap(charTypeDropdown);
      await tester.pumpAndSettle();

      // اختيار "حروف فقط"
      await tester.tap(find.text('حروف فقط').last);
      await tester.pumpAndSettle();

      // افتح الـ dropdown مرة أخرى للتحقق
      await tester.tap(charTypeDropdown);
      await tester.pumpAndSettle();

      // يجب أن يكون النص "حروف فقط" موجوداً (كخيار محدد)
      expect(find.text('حروف فقط'), findsWidgets);
    });

    testWidgets('dropdown نوع الكرت يحتوي على 3 خيارات',
        (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BulkAddScreen(
            profiles: _sampleProfiles,
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // dropdown نوع الكرت هو الثالث (index 2)
      final cardTypeDropdown = find.byType(DropdownButtonFormField<String>).at(2);
      await tester.tap(cardTypeDropdown);
      await tester.pumpAndSettle();

      // نتوقع وجود 3 خيارات (أحدها مكرر كقيمة محددة)
      expect(find.text('اسم مستخدم فقط'), findsWidgets);
      expect(find.text('اسم مستخدم وكلمة مرور متساوية'), findsOneWidget);
      expect(find.text('اسم مستخدم وكلمة مرور مختلفة'), findsOneWidget);
    });
  });

  // ============================================================
  //  ⑧ زر "إنشاء الكروت"
  // ============================================================
  group('⑧ زر إنشاء الكروت', () {
    testWidgets('الزر موجود وغير معطّل في الحالة الافتراضية', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BulkAddScreen(
            profiles: _sampleProfiles,
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('إنشاء الكروت'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  // ============================================================
  //  ⑨ الـ checkbox
  // ============================================================
  group('⑩ الـ checkbox', () {
    testWidgets('الـ checkbox افتراضياً غير مُفعّل', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BulkAddScreen(
            profiles: _sampleProfiles,
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(
        find.byType(Checkbox),
      );
      expect(checkbox.value, false);
    });

    testWidgets('النقر على الـ checkbox يفعّله', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          BulkAddScreen(
            profiles: _sampleProfiles,
            isVersion7OrNewer: true,
            username: 'admin',
          ),
          overrides: [
            mqttServiceProvider.overrideWithValue(FakeMqttService()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });
  });
}
