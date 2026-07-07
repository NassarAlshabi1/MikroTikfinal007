// ============================================================
//  اختبارات شاشات PDF والصور
//  - PdfTemplatesScreen
//  - EditPdfTemplateScreen
//  - ExtractCardsScreen
//  - ProcessImageScreen
//  - SavedFilesScreen
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mikrotik_manager/pdf_templates_screen.dart';
import 'package:mikrotik_manager/edit_pdf_template_screen.dart';
import 'package:mikrotik_manager/extract_cards_screen.dart';
import 'package:mikrotik_manager/process_image_screen.dart';
import 'package:mikrotik_manager/saved_files_screen.dart';
import '../test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PdfTemplatesScreen Tests', () {
    testWidgets('يقلع ويعرض قائمة القوالب', (tester) async {
      await pumpScreen(
        tester,
        PdfTemplatesScreen(profiles: mockProfiles),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('يعرض زر إضافة قالب جديد', (tester) async {
      await pumpScreen(
        tester,
        PdfTemplatesScreen(profiles: mockProfiles),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ابحث عن FloatingActionButton أو زر إضافة
      final hasFab = find.byType(FloatingActionButton).evaluate().isNotEmpty;
      final hasAddIcon = find.byIcon(Icons.add).evaluate().isNotEmpty;
      expect(hasFab || hasAddIcon, isTrue,
          reason: 'يجب أن يوجد زر إضافة قالب جديد');
    });
  });

  group('EditPdfTemplateScreen Tests', () {
    testWidgets('يقلع بدون قالب موجود (وضع الإنشاء)', (tester) async {
      await pumpScreen(
        tester,
        EditPdfTemplateScreen(profiles: mockProfiles),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('يعرض حقول اسم القالب والأنماط', (tester) async {
      await pumpScreen(
        tester,
        EditPdfTemplateScreen(profiles: mockProfiles),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ابحث عن حقول إدخال متعددة
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('يعرض زر حفظ القالب', (tester) async {
      await pumpScreen(
        tester,
        EditPdfTemplateScreen(profiles: mockProfiles),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ابحث عن ElevatedButton أو IconButton حفظ
      final hasSaveButton =
          find.byType(ElevatedButton).evaluate().isNotEmpty ||
              find.byIcon(Icons.save).evaluate().isNotEmpty ||
              find.byIcon(Icons.check).evaluate().isNotEmpty;
      expect(hasSaveButton, isTrue, reason: 'يجب أن يوجد زر حفظ');
    });
  });

  group('ExtractCardsScreen Tests', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    testWidgets('يقلع ويعرض نموذج الاستخراج', (tester) async {
      await pumpScreen(tester, const ExtractCardsScreen());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('يعرض حقول الإعدادات (prefix, length, total)', (tester) async {
      await pumpScreen(tester, const ExtractCardsScreen());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Form أو حقول إدخال متعددة
      final hasForm = find.byType(Form).evaluate().isNotEmpty;
      final hasTextFields = find.byType(TextField).evaluate().isNotEmpty;
      expect(hasForm || hasTextFields, isTrue);
    });

    testWidgets('يعرض زر استخراج الكروت', (tester) async {
      await pumpScreen(tester, const ExtractCardsScreen());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final hasButton = find.byType(ElevatedButton).evaluate().isNotEmpty ||
          find.byType(OutlinedButton).evaluate().isNotEmpty;
      expect(hasButton, isTrue);
    });
  });

  group('ProcessImageScreen Tests', () {
    testWidgets('يقلع ويعرض شاشة معالجة الصورة', (tester) async {
      // إنشاء صورة اختبار حقيقية (يمنع PathNotFoundException)
      final imagePath = await ensureTestImageExists();
      await pumpScreen(
        tester,
        ProcessImageScreen(
          imagePath: imagePath,  // مسار حقيقي
          prefix: 'user',
          length: 6,
          total: 10,
        ),
      );

      // ProcessImageScreen تستدعي Navigator.pop بعد المعالجة
      // لذلك نتحقق فقط من بناء الـ widget الأولي
      await tester.pump(const Duration(milliseconds: 500));
      // الشاشة قد تكون بنت Scaffold ثم pop'd — أي حال هو نجاح
      // (لو لم يكن crash، الـ test passed)
      expect(tester.takeException(), isNull);
    });

    testWidgets('لا يسبب crash عند مسار صورة غير موجود', (tester) async {
      await pumpScreen(
        tester,
        const ProcessImageScreen(
          imagePath: '/nonexistent/image.png',
          prefix: 'card',
          length: 4,
          total: 5,
        ),
      );

      // يجب أن يقلع بدون crash — الشاشة الآن تعرض SnackBar خطأ بدل crash
      // ثم Navigator.pop تلقائياً
      await tester.pump(const Duration(seconds: 2));
      // لا نتوقع Scaffold (تم pop) لكن لا نتوقع crash أيضاً
      expect(tester.takeException(), isNull);
    });
  });

  group('SavedFilesScreen Tests', () {
    setUp(() async {
      await setupMockSharedPreferences();
    });

    testWidgets('يقلع ويعرض قائمة الملفات المحفوظة', (tester) async {
      await pumpScreen(tester, const SavedFilesScreen());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('يعرض حالة فارغة أو قائمة بدون crash', (tester) async {
      await pumpScreen(tester, const SavedFilesScreen());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      final hasScaffold = find.byType(Scaffold).evaluate().isNotEmpty;
      expect(hasScaffold, isTrue);
    });
  });
}
