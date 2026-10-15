import 'package:get/get.dart' show GetPage;
import 'pages/auth_routes.dart';
import 'pages/home_routes.dart';
import 'pages/more_routes.dart';
import 'pages/cards_routes.dart';
import 'pages/users_routes.dart';
import 'pages/sites_routes.dart';
import 'pages/prints_routes.dart';
import 'pages/reports_routes.dart';
import 'pages/backup_routes.dart';
import 'pages/distributors_routes.dart';
import 'pages/maintenance_routes.dart';
import 'pages/hotspot_routes.dart';
import 'pages/telegram_routes.dart';

class AppPages {
  static final routes = <GetPage>[
    ...AuthRoutes.routes,
    ...HomeRoutes.routes,
    ...MoreRoutes.routes,
    ...CardsRoutes.routes,
    ...UsersRoutes.routes,
    ...SitesRoutes.routes,
    ...PrintsRoutes.routes,
    ...ReportsRoutes.routes,
    ...BackupRoutes.routes,
    ...DistributorsRoutes.routes,
    ...MaintenanceRoutes.routes,
    ...HotspotRoutes.routes,
    ...TelegramRoutes.routes,
  ];
}

