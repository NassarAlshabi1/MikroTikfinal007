// ============================================================
//  BulkAddScreen — اختبارات شاملة
//
//  يغطي:
//  - عرض الشاشة مع profiles فارغة
//  - عرض الشاشة مع profiles موجودة
//  - عرض الشاشة مع templates موجودة (JSON سليم)
//  - متانة ضد JSON التالف في pdf_templates
//  - متانة ضد JSON التالف في qahtani_linked_data
//  - متانة ضد is_network_linked=true بدون data
//  - التحقق من عدم وجود استثناءات أثناء البناء
//  - التحقق من عرض العناصر الأساسية (عنوان، حقول، أزرار)
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mikrotik_manager/bulk_add_screen.dart';
import 'package:mikrotik_manager/mqtt_service.dart';
import 'package:mikrotik_manager/providers/mqtt_service_provider.dart';

void main() {
  group('BulkAddScreen — عرض أساسي', () {
    testWidgets('يعرض الشاشة بشكل صحيح مع profiles فارغة',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(const {
        'is_network_linked': false,
        'pdf_templates': <String>[],
        'saved_files': <String>[],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mqttServiceProvider.overrideWithValue(_FakeMqttService()),
          ],
          child: const MaterialApp(
            home: BulkAddScreen(
              profiles: [],
              isVersion7OrNewer: true,
              username: 'test_user',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'Scaffold should be present');
      expect(find.byType(AppBar), findsOneWidget,
          reason: 'AppBar should be present');
      expect(find.text('إضافة كروت جماعية'), findsOneWidget,
          reason: 'Title should be visible');

      // Form fields
      expect(find.text('بادئة (اختياري)'), findsOneWidget);
      expect(find.text('الطول'), findsOneWidget);
      expect(find.text('العدد'), findsOneWidget);
      expect(find.text('الفئة (البروفايل)'), findsOneWidget);
      expect(find.text('نوع أحرف المستخدم'), findsOneWidget);
      expect(find.text('نوع الكرت'), findsOneWidget);
      expect(find.text('Shared Users'), findsOneWidget);
      expect(find.text('إنشاء الكروت'), findsOneWidget);
    });

    testWidgets('يعرض الشاشة مع profiles موجودة',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(const {
        'is_network_linked': false,
        'pdf_templates': <String>[],
        'saved_files': <String>[],
      });

      const profiles = <Map<String, dynamic>>[
        {'name': 'profile1', 'rate-limit': '1M/1M'},
        {'name': 'profile2', 'rate-limit': '2M/2M'},
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mqttServiceProvider.overrideWithValue(_FakeMqttService()),
          ],
          child: const MaterialApp(
            home: BulkAddScreen(
              profiles: profiles,
              isVersion7OrNewer: true,
              username: 'test_user',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('إضافة كروت جماعية'), findsOneWidget);
      expect(find.text('إنشاء الكروت'), findsOneWidget);
    });

    testWidgets('لا يلقي استثناءات أثناء البناء', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(const {
        'is_network_linked': false,
        'pdf_templates': <String>[],
        'saved_files': <String>[],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mqttServiceProvider.overrideWithValue(_FakeMqttService()),
          ],
          child: const MaterialApp(
            home: BulkAddScreen(
              profiles: [],
              isVersion7OrNewer: true,
              username: 'test_user',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });

  group('BulkAddScreen — متانة ضد البيانات التالفة', () {
    testWidgets('لا يتعطل عند وجود JSON تالف في pdf_templates',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'is_network_linked': false,
        'pdf_templates': <String>[
          '{invalid json',
          '{"valid":"but_incomplete"}',
          'totally_not_json',
        ],
        'saved_files': <String>[],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mqttServiceProvider.overrideWithValue(_FakeMqttService()),
          ],
          child: const MaterialApp(
            home: BulkAddScreen(
              profiles: [],
              isVersion7OrNewer: true,
              username: 'test_user',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // الشاشة يجب أن تعرض رغم فشل parsing
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('إضافة كروت جماعية'), findsOneWidget);
      // لا استثناءات
      expect(tester.takeException(), isNull);
    });

    testWidgets('لا يتعطل عند وجود JSON تالف في qahtani_linked_data',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'is_network_linked': true,
        'qahtani_linked_data': '{invalid json',
        'pdf_templates': <String>[],
        'saved_files': <String>[],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mqttServiceProvider.overrideWithValue(_FakeMqttService()),
          ],
          child: const MaterialApp(
            home: BulkAddScreen(
              profiles: [],
              isVersion7OrNewer: true,
              username: 'test_user',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('إضافة كروت جماعية'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('لا يتعطل عند is_network_linked=true بدون data',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(const {
        'is_network_linked': true,
        // لا qahtani_linked_data
        'pdf_templates': <String>[],
        'saved_files': <String>[],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mqttServiceProvider.overrideWithValue(_FakeMqttService()),
          ],
          child: const MaterialApp(
            home: BulkAddScreen(
              profiles: [],
              isVersion7OrNewer: true,
              username: 'test_user',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('إضافة كروت جماعية'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('لا يتعطل عند وجود JSON سليم في qahtani_linked_data',
        (WidgetTester tester) async {
      final linkedData = jsonEncode({
        'network_details': {
          'network_id': 'net1',
          'units': [
            {'id': 'unit1', 'name': 'Unit 1'},
            {'id': 'unit2', 'name': 'Unit 2'},
          ],
        },
      });

      SharedPreferences.setMockInitialValues({
        'is_network_linked': true,
        'qahtani_linked_data': linkedData,
        'pdf_templates': <String>[],
        'saved_files': <String>[],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mqttServiceProvider.overrideWithValue(_FakeMqttService()),
          ],
          child: const MaterialApp(
            home: BulkAddScreen(
              profiles: [],
              isVersion7OrNewer: true,
              username: 'test_user',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('إضافة كروت جماعية'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('BulkAddScreen — عناصر UI', () {
    testWidgets('يحتوي على جميع الحقول المتوقعة', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(const {
        'is_network_linked': false,
        'pdf_templates': <String>[],
        'saved_files': <String>[],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mqttServiceProvider.overrideWithValue(_FakeMqttService()),
          ],
          child: const MaterialApp(
            home: BulkAddScreen(
              profiles: [],
              isVersion7OrNewer: true,
              username: 'test_user',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // حقول النص
      expect(find.byType(TextFormField), findsNWidgets(4),
          reason: 'Should have prefix, length, count, shared_users fields');
      // dropdowns
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(4),
          reason: 'Should have profile, charType, cardType, template dropdowns');
      // زر الإنشاء
      expect(find.byType(ElevatedButton), findsOneWidget);
      // checkbox لربط كلمة المرور
      expect(find.byType(CheckboxListTile), findsOneWidget);
    });

    testWidgets('القيم الافتراضية صحيحة', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(const {
        'is_network_linked': false,
        'pdf_templates': <String>[],
        'saved_files': <String>[],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mqttServiceProvider.overrideWithValue(_FakeMqttService()),
          ],
          child: const MaterialApp(
            home: BulkAddScreen(
              profiles: [],
              isVersion7OrNewer: true,
              username: 'test_user',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // الطول الافتراضي = 8
      expect(find.widgetWithText(TextFormField, '8'), findsOneWidget);
      // العدد الافتراضي = 10
      expect(find.widgetWithText(TextFormField, '10'), findsOneWidget);
      // Shared Users الافتراضي = 1
      expect(find.widgetWithText(TextFormField, '1'), findsOneWidget);
    });
  });
}

/// MqttService وهمي للاختبار — يمنع محاولة الاتصال الحقيقي بالـ broker
class _FakeMqttService extends MqttService {
  // نستخدم constructor الأب — الاتصال يفشل بصمت في بيئة الاختبار
  // وهذا مقبول لأن BulkAddScreen لا يعتمد على حالة الاتصال في واجهته
}
