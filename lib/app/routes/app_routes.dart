class AppRoutes {
  static const String login = '/';
  static const String home = '/home';

  static const String cards = '/cards';
  static const String cardsList = '/cards/cards_list';
  static const String addSingleCard = '/cards/add_single_card';
  static const String cardDetails = '/cards/card_details';
  static const String cardSessions = '/cards/card_sessions';
  static const String packages = '/cards/packages';
  static const String expiredUsers = '/cards/expired_users';
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
  static const String routerBackup = '/more/router_backup';

  // الموزعون والمحاسبة
  static const String distributors = '/distributors';
  static const String distributorForm = '/distributors/form';
  static const String distributorStatement = '/distributors/statement';

  // مراقبة الشبكة
  static const String monitor = '/reports/monitor';

  // أدوات الصيانة
  static const String maintenance = '/maintenance';
  static const String maintenanceTool = '/maintenance/tool';
  static const String maintenanceDiagnostics = '/maintenance/diagnostics';
  static const String maintenanceCableTest = '/maintenance/cable_test';

  // Hotspot
  static const String hotspot = '/hotspot';
  static const String telegram = '/telegram';
  static const String telegramSetup = '/telegram/setup';
  static const String telegramFeatures = '/telegram/features';
  // مسارات إدارة المواقع
}

