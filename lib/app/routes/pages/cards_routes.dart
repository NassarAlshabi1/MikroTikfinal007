import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/features/cards/controllers/cards/add_single_card_controller.dart';
import 'package:mikronet/features/cards/controllers/cards/card_info_controller.dart';
import 'package:mikronet/features/cards/controllers/cards/card_sessions_controller.dart';
import 'package:mikronet/features/cards/controllers/cards/cards_list_controller.dart';
import 'package:mikronet/features/cards/controllers/cards_unit_controller.dart';
import 'package:mikronet/features/cards/controllers/expired_users_controller.dart';
import 'package:mikronet/features/cards/controllers/profiles/add_profile_controller.dart';
import 'package:mikronet/features/cards/controllers/profiles/edit_profile_controller.dart';
import 'package:mikronet/features/cards/controllers/profiles/profiles_list_controller.dart';
import 'package:mikronet/features/cards/views/cards/add_single_card_page.dart';
import 'package:mikronet/features/cards/views/cards/card_info_page.dart';
import 'package:mikronet/features/cards/views/cards/card_sessions_page.dart';
import 'package:mikronet/features/cards/views/cards/cards_list_page.dart';
import 'package:mikronet/features/cards/views/cards_unit.dart';
import 'package:mikronet/features/cards/views/expired_users_page.dart';
import 'package:mikronet/features/cards/views/profiles/add_profile_page.dart';
import 'package:mikronet/features/cards/views/profiles/edit_profile_page.dart';
import 'package:mikronet/features/cards/views/profiles/profiles_list_page.dart';

class CardsRoutes {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.cards, 
      page: () => const CardsUnitPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => CardsUnitController())),
    ),
    GetPage(
      name: AppRoutes.cardsList, 
      page: () => const CardsListPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => CardsListController())),
    ),
    GetPage(
      name: AppRoutes.addSingleCard, 
      page: () => const AddSingleCardPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => AddSingleCardController())),
    ),
    GetPage(
      name: AppRoutes.expiredUsers,
      page: () => const ExpiredUsersPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => ExpiredUsersController())),
    ),
    GetPage(
      name: AppRoutes.packages, 
      page: () => const ProfilesListPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => ProfilesListController())),
    ),
    GetPage(
      name: AppRoutes.addProfile, 
      page: () => const AddProfilePage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => AddProfileController())),
    ),
    GetPage(
      name: AppRoutes.editProfile, 
      page: () => const EditProfilePage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => EditProfileController(profile: Get.arguments))),
    ),
    GetPage(
      name: AppRoutes.cardDetails,
      page: () => CardInfoPage(card: Get.arguments), 
      binding: BindingsBuilder(() => Get.lazyPut(() => CardInfoController(card: Get.arguments))),
    ),
    GetPage(
      name: AppRoutes.cardSessions,
      page: () => CardSessionsPage(username: Get.arguments),
      binding: BindingsBuilder(() {
        // تمرير القيمة الممررة (Get.arguments) إلى مشيد المتحكم
        Get.lazyPut(() => CardSessionsController(cardCode: Get.arguments));
      }),
    ),
  ];
}
