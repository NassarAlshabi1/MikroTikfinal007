import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_fonts.dart';
import 'package:get/get.dart';
import 'package:mikronet/features/home/controllers/home_controller.dart';
import 'package:mikronet/features/home/views/home_page.dart';
import 'package:mikronet/app/theme/app_theme.dart';

void main() {
  testWidgets('dashboard preview golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 780));
    tester.view.physicalSize = const Size(420, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await loadCairoFonts();
    Get.put(HomeController());
    await tester.pumpWidget(GetMaterialApp(
      theme: AppTheme.dark(),
      home: const HomePage(),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('dashboard_preview.png'),
    );

    Get.delete<HomeController>();
    await tester.pump();
  });
}
