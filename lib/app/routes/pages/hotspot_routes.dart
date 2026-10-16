import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/features/hotspot/controllers/hotspot_controller.dart';
import 'package:mikronet/features/hotspot/views/hotspot_page.dart';

class HotspotRoutes {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.hotspot,
      page: () => const HotspotPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => HotspotController())),
    ),
  ];
}
