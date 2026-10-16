import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/features/telegram/controllers/telegram_controller.dart';
import 'package:mikronet/features/telegram/views/telegram_features_page.dart';
import 'package:mikronet/features/telegram/views/telegram_page.dart';
import 'package:mikronet/features/telegram/views/telegram_setup_page.dart';

class TelegramRoutes {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.telegram,
      page: () => const TelegramPage(),
    ),
    GetPage(
      name: AppRoutes.telegramSetup,
      page: () => const TelegramSetupPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => TelegramSetupController())),
    ),
    GetPage(
      name: AppRoutes.telegramFeatures,
      page: () => const TelegramFeaturesPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => TelegramFeaturesController())),
    ),
  ];
}
