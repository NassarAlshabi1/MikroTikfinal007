import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/features/users/controllers/active_users_controller.dart';
import 'package:mikronet/features/users/controllers/host_users_controller.dart';
import 'package:mikronet/features/users/controllers/saved_users_controller.dart';
import 'package:mikronet/features/users/controllers/users_unit_controller.dart';
import 'package:mikronet/features/users/views/active_users_page.dart';
import 'package:mikronet/features/users/views/host_users_page.dart';
import 'package:mikronet/features/users/views/saved_users_page.dart';
import 'package:mikronet/features/users/views/users_unit.dart';

class UsersRoutes {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.users, 
      page: () => const UsersUnitPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => UsersUnitController())),
    ),
    GetPage(
      name: AppRoutes.savedUsers, 
      page: () => const SavedUsersPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => SavedUsersController())),
    ),
    GetPage(
      name: AppRoutes.activeUsers, 
      page: () => const ActiveUsersPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => ActiveUsersController())),
    ),
    GetPage(
      name: AppRoutes.hostUsers, 
      page: () => const HostUsersPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => HostUsersController())),
    ),
  ];
}
