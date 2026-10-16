import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mikronet/app/theme/app_theme.dart';

import 'package:mikronet/features/users/controllers/saved_users_controller.dart';
import 'package:mikronet/features/users/views/saved_users_page.dart';
import 'package:mikronet/features/users/controllers/active_users_controller.dart';
import 'package:mikronet/features/users/views/active_users_page.dart';
import 'package:mikronet/features/users/controllers/host_users_controller.dart';
import 'package:mikronet/features/users/views/host_users_page.dart';
import 'package:mikronet/features/prints/controllers/batches/batches_list_controller.dart';
import 'package:mikronet/features/prints/views/batches/batches_list_page.dart';
import 'package:mikronet/features/reports/controllers/sales_report_controller.dart';
import 'package:mikronet/features/reports/views/sales_report_page.dart';
import 'package:mikronet/features/distributors/controllers/distributors_list_controller.dart';
import 'package:mikronet/features/distributors/views/distributors_list_page.dart';
import 'package:mikronet/features/hotspot/controllers/hotspot_controller.dart';
import 'package:mikronet/features/hotspot/views/hotspot_page.dart';
import 'package:mikronet/features/sites/controllers/dns_settings_controller.dart';
import 'package:mikronet/features/sites/views/dns_settings_page.dart';
import 'package:mikronet/features/sites/controllers/dns_cache_controller.dart';
import 'package:mikronet/features/sites/views/dns_cache_page.dart';
import 'package:mikronet/features/sites/controllers/blocked_sites_controller.dart';
import 'package:mikronet/features/sites/views/blocked_sites_page.dart';
import 'package:mikronet/features/backup/controllers/backup_restore_controller.dart';
import 'package:mikronet/features/backup/views/backup_restore_page.dart';
import 'package:mikronet/features/reports/controllers/monitor_controller.dart';
import 'package:mikronet/features/reports/views/monitor_page.dart';
import 'package:mikronet/features/maintenance/controllers/cable_test_controller.dart';
import 'package:mikronet/features/maintenance/views/cable_test_page.dart';
import 'package:mikronet/features/maintenance/controllers/diagnostics_controller.dart';
import 'package:mikronet/features/maintenance/models/maintenance_tools.dart';
import 'package:mikronet/features/maintenance/views/diagnostics_page.dart';
import 'package:mikronet/features/cards/controllers/expired_users_controller.dart';
import 'package:mikronet/features/cards/views/expired_users_page.dart';
import 'package:mikronet/features/cards/controllers/cards/cards_list_controller.dart';
import 'package:mikronet/features/cards/views/cards/cards_list_page.dart';
import 'package:mikronet/features/cards/controllers/cards/add_single_card_controller.dart';
import 'package:mikronet/features/cards/views/cards/add_single_card_page.dart';
import 'package:mikronet/features/telegram/controllers/telegram_controller.dart';
import 'package:mikronet/features/telegram/views/telegram_page.dart';
import 'package:mikronet/features/backup/controllers/router_backup_controller.dart';
import 'package:mikronet/features/backup/views/router_backup_page.dart';
import 'package:mikronet/features/prints/controllers/batches/add_batch_controller.dart';
import 'package:mikronet/features/prints/views/batches/add_batch_page.dart';
import 'package:mikronet/features/cards/controllers/cards/card_sessions_controller.dart';
import 'package:mikronet/features/cards/views/cards/card_sessions_page.dart';

void main() {
  final cases = <String, List<Object>>{
    'saved_users': [const SavedUsersPage(), () { Get.put(SavedUsersController(), permanent: true); }],
    'active_users': [const ActiveUsersPage(), () { Get.put(ActiveUsersController(), permanent: true); }],
    'host_users': [const HostUsersPage(), () { Get.put(HostUsersController(), permanent: true); }],
    'batches_list': [const BatchesView(), () { Get.put(BatchesListController(), permanent: true); }],
    'sales_report': [const SalesReportPage(), () { Get.put(SalesReportController(), permanent: true); }],
    // skipped in sweep: fetch shows error dialog in test env
    // 'templates_list': [const TemplatesListPage(), () { Get.put(TemplatesListController(), permanent: true); }],
    'distributors_list': [const DistributorsListPage(), () { Get.put(DistributorsListController(), permanent: true); }],
    'hotspot': [const HotspotPage(), () { Get.put(HotspotController(), permanent: true); }],
    // skipped in sweep: fetch shows snackbar in test env
    // 'system_status': [const SystemStatusReportPage(), () { Get.put(SystemStatusReportController(), permanent: true); }],
    'dns_settings': [const DnsSettingsPage(), () { Get.put(DnsSettingsController(), permanent: true); }],
    'dns_cache': [const DnsCachePage(), () { Get.put(DnsCacheController(), permanent: true); }],
    'blocked_sites': [const BlockedSitesPage(), () { Get.put(BlockedSitesController(), permanent: true); }],
    'backup_restore': [const BackupRestorePage(), () { Get.put(BackupRestoreController(), permanent: true); }],
    'monitor': [const MonitorPage(), () { Get.put(MonitorController(), permanent: true); }],
    'cable_test': [const CableTestPage(), () { Get.put(CableTestController(), permanent: true); }],
    'diagnostics': [const DiagnosticsPage(), () { Get.put(DiagnosticsController(DiagnosticTool.ping), permanent: true); }],
    'expired_users': [const ExpiredUsersPage(), () { Get.put(ExpiredUsersController(), permanent: true); }],
    'cards_list': [const CardsListPage(), () { Get.put(CardsListController(), permanent: true); }],
    'add_single_card': [const AddSingleCardPage(), () { Get.put(AddSingleCardController(), permanent: true); }],
    'telegram': [const TelegramPage(), () { Get.put(TelegramSetupController(), permanent: true); }],
    'router_backup': [const RouterBackupPage(), () { Get.put(RouterBackupController(), permanent: true); }],
    'add_batch': [AddBatchView(controller: BatchesFormController()), () { Get.put(BatchesFormController(), permanent: true); }],
    'card_sessions': [const CardSessionsPage(username: 'test'), () { Get.put(CardSessionsController(cardCode: 'test'), permanent: true); }],
  };

  for (final entry in cases.entries) {
    testWidgets('screen layout: ${entry.key}', (tester) async {
      tester.view.physicalSize = const Size(420, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final page = entry.value[0] as Widget;
      (entry.value[1] as void Function())();
      try {
        await tester.pumpWidget(
            GetMaterialApp(theme: AppTheme.dark(), home: page));
        await tester.pump(const Duration(milliseconds: 300));
      } finally {
        Get.deleteAll(force: true);
        await tester.pump();
      }
    });
  }
}
