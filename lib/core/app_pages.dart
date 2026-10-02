import 'package:get/get.dart';
import 'package:mikronet/controllers/cards/profiles/add_profile_controller.dart';
import 'package:mikronet/controllers/cards/profiles/edit_profile_controller.dart';
import 'package:mikronet/controllers/more/backup_restore_controller.dart';
import 'package:mikronet/controllers/more/more_unit_controller.dart';
import 'package:mikronet/controllers/prints/prints_unit_controller.dart';
import 'package:mikronet/controllers/prints/templates/add_template_controller.dart';
import 'package:mikronet/controllers/prints/templates/edit_template_controller.dart';
import 'package:mikronet/controllers/prints/templates/templates_list_controller.dart';
import 'package:mikronet/controllers/reports/reports_unit_controller.dart';
import 'package:mikronet/controllers/reports/sales_report_controller.dart';
import 'package:mikronet/controllers/reports/system_status_report_controller.dart';
import 'package:mikronet/controllers/sites/dns_settings_controller.dart';
import 'package:mikronet/views/cards/profiles/add_profile_page.dart';
import 'package:mikronet/views/cards/profiles/edit_profile_page.dart';
import 'package:mikronet/views/more/backup_restore_page.dart';
import 'package:mikronet/views/more/more_unit.dart';
import 'package:mikronet/views/prints/batches/batches_list_page.dart';
import 'package:mikronet/views/prints/templates/add_template_page.dart';
import 'package:mikronet/views/prints/templates/edit_template_page.dart';
import 'package:mikronet/views/prints/templates/templates_list_page.dart';
import 'package:mikronet/views/reports/sales_report_page.dart';
// import 'package:mikronet/views/prints/batches/add_batch.dart';
import 'package:mikronet/views/reports/system_status_report_page.dart';
import 'package:mikronet/views/sites/dns_settings_page.dart';
//import 'package:mikronet/controllers/users/devices_controller.dart';

// ================= استيراد الواجهات (Views) =================
//import '../../views/users/devices_manager.dart';
import '../controllers/prints/batches/batches_list_controller.dart';
import '/views/login_page.dart';
import '/views/home_page.dart';
import '/controllers/login_controller.dart';
import '/controllers/home_controller.dart';


import '../views/cards/cards_unit.dart';

import '../views/cards/cards/cards_list_page.dart';
import '../views/cards/cards/add_single_card_page.dart';
import '../views/cards/cards/card_info_page.dart';
import '../views/cards/cards/card_sessions_page.dart';
import '../views/cards/profiles/profiles_list_page.dart';



import '../controllers/cards/cards_unit_controller.dart';
import '../controllers/cards/cards/cards_list_controller.dart';
import '../controllers/cards/cards/add_single_card_controller.dart';
import '../controllers/cards/cards/card_info_controller.dart';
import '../controllers/cards/cards/card_sessions_controller.dart';
import '../controllers/cards/profiles/profiles_list_controller.dart';


import '../views/users/users_unit.dart';
import '../views/users/saved_users_page.dart';
import '../views/users/host_users_page.dart';
import '../views/users/active_users_page.dart';

import '../controllers/users/users_unit_controller.dart';
import '../controllers/users/saved_users_controller.dart';
import '/controllers/users/active_users_controller.dart';
import '../controllers/users/host_users_controller.dart';

import '../views/sites/sites_unit.dart';
import '../views/sites/dns_cache_page.dart';
import '../views/sites/blocked_sites_page.dart';


import '../controllers/sites/sites_unit_controller.dart';
import '/controllers/sites/dns_cache_controller.dart';
import '/controllers/sites/blocked_sites_controller.dart';


import '../views/prints/prints_unit.dart';
import '../views/reports/reports_unit.dart';

/*
import '/view/backups/backup_view.dart';

// ================= استيراد المتحكمات (Controllers) =================




import '/controller/reports/reports_controller.dart';
import '/controller/settings/backup_controller.dart';
*/
class AppRoutes {
  static const String login = '/';
  static const String home = '/home';

  static const String cards = '/cards';
  static const String cardsList = '/cards/cards_list';
  static const String addSingleCard = '/cards/add_single_card';
  static const String cardDetails = '/cards/card_details';
  static const String cardSessions = '/cards/card_sessions';
  static const String packages = '/cards/packages';
  static const String addProfile = '/cards/profiles/add_profile';
  static const String editProfile = '/cards/profiles/edit_profile';

  static const String users = '/users';
  static const String savedUsers= '/users/binding';
  static const String activeUsers= '/users/active';
  static const String hostUsers= '/users/hosts';

  static const String sites = '/sites';
  static const String dnsCache = '/sites/dns_cache';
  static const String blockedSites = '/sites/blocked_sites';
  static const String dnsSettings = '/sites/dns_settings';
  
  static const String reports = '/reports';
  static const String salesReport = '/reports/sales_report';
  static const String systemStatus = '/reports/system_status';
  

  static const String print = '/print';
  static const String batches = '/print/batches';
  static const String templates= '/print/templates';
  static const String addBatch = '/print/add_batch';
  static const String addTemplate = '/print/add_template';
  static const String editTemplate = '/print/edit_template';

  static const String more = '/more';
  static const String backup = '/more/backup';
  // مسارات إدارة المواقع
}

class AppPages {
  static final routes = [
    // Login
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(), 
      binding: BindingsBuilder(() => Get.lazyPut(() => LoginController())),
    ),
    
    // Home
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(), 
      binding: BindingsBuilder(() => Get.lazyPut(() => HomeController())),
    ),
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
    // ابحث عن مسار cardSessions وقم بتعديله كالتالي:
    GetPage(
      name: AppRoutes.cardSessions,
      page: () => CardSessionsPage(username: Get.arguments),
      binding: BindingsBuilder(() {
        // تمرير القيمة الممررة (Get.arguments) إلى مشيد المتحكم
        Get.lazyPut(() => CardSessionsController(cardCode: Get.arguments));
      }),
    ),
    // صفحات إدارة المواقع
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
    GetPage(
      name: AppRoutes.sites, 
      page: () => const SitesUnitPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => SitesUnitController())),
    ),
    GetPage(
      name: AppRoutes.dnsCache,
      page: () => const DnsCachePage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => DnsCacheController())),
    ),
    GetPage(
      name: AppRoutes.blockedSites,
      page: () => const BlockedSitesPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => BlockedSitesController())),
    ),
     GetPage(
      name: AppRoutes.dnsSettings,
      page: () => const DnsSettingsPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => DnsSettingsController())),
    ),
    GetPage(
      name: AppRoutes.print, 
      page: () => const PrintsUnitPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => PrintsUnitController())),
    ),
    GetPage(
      name: AppRoutes.batches, 
      page: () => BatchesView(),
      binding: BindingsBuilder(() => Get.lazyPut(() => BatchesListController())),
    ),
    GetPage(
      name: AppRoutes.templates, 
      page: () => const TemplatesListPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => TemplatesListController())),
    ),
    GetPage(
      name: AppRoutes.addTemplate, 
      page: () => const AddTemplatePage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => AddTemplateController())),
    ),
    GetPage(
      name: AppRoutes.editTemplate, 
      page: () => const EditTemplatePage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => EditTemplateController(editedTemplate: Get.arguments))),
    ),
    GetPage(
      name: AppRoutes.reports, 
      page: () => const ReportsUnitPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => ReportsUnitController())),
    ),
    GetPage(
      name: AppRoutes.salesReport, 
      page: () => const SalesReportPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => SalesReportController())),
    ),
    GetPage(
      name: AppRoutes.systemStatus, 
      page: () => const SystemStatusReportPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => SystemStatusReportController())),
    ),
    GetPage(
      name: AppRoutes.more, 
      page: () => const MoreUnitPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => MoreUnitController())),
    ),
    GetPage(
      name: AppRoutes.backup, 
      page: () => const BackupRestorePage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => BackupRestoreController())),
    ),
  ];
}