import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/features/backup/controllers/backup_restore_controller.dart';
import 'package:mikronet/features/backup/controllers/router_backup_controller.dart';
import 'package:mikronet/features/backup/views/backup_restore_page.dart';
import 'package:mikronet/features/backup/views/router_backup_page.dart';

class BackupRoutes {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.backup, 
      page: () => const BackupRestorePage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => BackupRestoreController())),
    ),
    GetPage(
      name: AppRoutes.routerBackup,
      page: () => const RouterBackupPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => RouterBackupController())),
    ),
  ];
}
