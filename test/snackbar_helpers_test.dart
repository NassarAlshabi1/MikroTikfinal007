import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/snackbar_helpers.dart';
import 'package:mikrotik_manager/theme/app_palette.dart';

Future<BuildContext> pumpScaffold(WidgetTester tester) async {
  late BuildContext capturedContext;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );

  return capturedContext;
}

void main() {
  group('SnackBar helpers', () {
    testWidgets('showErrorSnackBar shows the configured error message', (
      tester,
    ) async {
      final context = await pumpScaffold(tester);

      showErrorSnackBar(context, 'تعذر الاتصال بالراوتر');
      await tester.pump();

      expect(find.text('تعذر الاتصال بالراوتر'), findsOneWidget);
      expect(find.text('إغلاق'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, AppPalette.error);
      expect(snackBar.duration, const Duration(seconds: 5));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.margin, const EdgeInsets.all(16));
      expect(snackBar.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('showSuccessSnackBar shows a green confirmation message', (
      tester,
    ) async {
      final context = await pumpScaffold(tester);

      showSuccessSnackBar(context, 'تم حفظ الإعدادات');
      await tester.pump();

      expect(find.text('تم حفظ الإعدادات'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, AppPalette.success);
      expect(snackBar.duration, const Duration(seconds: 3));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.margin, const EdgeInsets.all(16));
      expect(snackBar.shape, isA<RoundedRectangleBorder>());
    });
  });
}
