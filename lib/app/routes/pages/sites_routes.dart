import 'package:get/get.dart';
import 'package:mikronet/app/routes/app_routes.dart';
import 'package:mikronet/features/sites/controllers/blocked_sites_controller.dart';
import 'package:mikronet/features/sites/controllers/dns_cache_controller.dart';
import 'package:mikronet/features/sites/controllers/dns_settings_controller.dart';
import 'package:mikronet/features/sites/controllers/sites_unit_controller.dart';
import 'package:mikronet/features/sites/views/blocked_sites_page.dart';
import 'package:mikronet/features/sites/views/dns_cache_page.dart';
import 'package:mikronet/features/sites/views/dns_settings_page.dart';
import 'package:mikronet/features/sites/views/sites_unit.dart';

class SitesRoutes {
  static final List<GetPage> routes = [
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
  ];
}
