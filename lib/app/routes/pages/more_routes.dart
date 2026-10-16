import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/features/more/controllers/more_unit_controller.dart';
import 'package:mikronet/features/more/views/more_unit.dart';

class MoreRoutes {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.more, 
      page: () => const MoreUnitPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => MoreUnitController())),
    ),
  ];
}
