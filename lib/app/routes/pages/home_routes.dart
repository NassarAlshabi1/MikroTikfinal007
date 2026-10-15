import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/features/home/controllers/home_controller.dart';
import 'package:mikronet/features/home/views/home_page.dart';

class HomeRoutes {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(), 
      binding: BindingsBuilder(() => Get.lazyPut(() => HomeController())),
    ),
  ];
}
