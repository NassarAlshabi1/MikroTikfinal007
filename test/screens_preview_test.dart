import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_fonts.dart';
import 'package:get/get.dart';
import 'package:mikronet/app/theme/app_theme.dart';
import 'package:mikronet/features/cards/controllers/profiles/profiles_list_controller.dart';
import 'package:mikronet/features/cards/views/profiles/profiles_list_page.dart';
import 'package:mikronet/features/maintenance/controllers/maintenance_hub_controller.dart';
import 'package:mikronet/features/maintenance/views/maintenance_hub_page.dart';

void main() {
  Future<void> pump<T extends GetxController>(WidgetTester tester, Widget page, T c) async {
    tester.view.physicalSize = const Size(420, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await loadCairoFonts();
    Get.put<T>(c);
    await tester.pumpWidget(GetMaterialApp(theme: AppTheme.dark(), home: page));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('profiles list preview', (tester) async {
    final c = ProfilesListController();
    await pump(tester, const ProfilesListPage(), c);
    await expectLater(find.byType(ProfilesListPage),
        matchesGoldenFile('profiles_preview.png'));
    Get.delete<ProfilesListController>();
    await tester.pump();
  });

  testWidgets('maintenance hub preview', (tester) async {
    final c = MaintenanceHubController();
    await pump(tester, const MaintenanceHubPage(), c);
    await expectLater(find.byType(MaintenanceHubPage),
        matchesGoldenFile('maintenance_preview.png'));
    Get.delete<MaintenanceHubController>();
    await tester.pump();
  });
}
