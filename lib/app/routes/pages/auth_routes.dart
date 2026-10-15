import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/features/auth/controllers/login_controller.dart';
import 'package:mikronet/features/auth/views/login_page.dart';

class AuthRoutes {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(), 
      binding: BindingsBuilder(() => Get.lazyPut(() => LoginController())),
    ),
  ];
}
