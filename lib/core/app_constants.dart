// ============================================================
//  AppConstants — ثوابت التطبيق المركزية
//
//  تطبّق معايير flutter-apply-architecture-best-practices:
//  ✅ Centralized configuration
//  ✅ No magic numbers/strings في الكود
//  ✅ Reusable constants
// ============================================================

/// ثوابت التطبيق
abstract final class AppConstants {
  AppConstants._();

  // ─── MikroTik API defaults ───
  static const int defaultRouterOsApiPort = 8728;
  static const int defaultRouterOsApiSslPort = 8729;
  static const int defaultSshPort = 22;
  static const Duration defaultConnectionTimeout = Duration(seconds: 10);
  static const Duration defaultCommandTimeout = Duration(seconds: 30);

  // ─── Diagnostics ───
  static const int maxLogLines = 500;
  static const int maxAiContextLogLines = 30;
  static const int maxEventsDisplayed = 100;

  // ─── AI service ───
  static const Duration aiRequestTimeout = Duration(seconds: 60);
  static const int defaultAiMaxTokens = 1500;
  static const double defaultAiTemperature = 0.3;

  // ─── legacy integration integration ───
  static const String legacy_integrationMcpServerPackage = 'legacy_integration-cloud-mcp-sdk';
  static const String legacy_integrationMcpProtocolVersion = '2024-11-05';
  static const Duration legacy_integrationConnectTimeout = Duration(seconds: 30);
  static const Duration legacy_integrationTaskTimeout = Duration(minutes: 5);
  static const int legacy_integrationPollIntervalMs = 2000;

  // ─── Security ───
  static const Duration clipboardAutoClearDuration = Duration(seconds: 30);
  static const int maxLoginAttemptsBeforeLockout = 5;

  // ─── SharedPreferences keys (للبيانات غير الحساسة فقط) ───
  static const String prefsKeyIp = 'ip';
  static const String prefsKeyUser = 'user';
  static const String prefsKeyPort = 'port';
  static const String prefsKeySshPort = 'ssh_port';
  static const String prefsKeyUseSsl = 'use_ssl';
  static const String prefsKeyRememberMe = 'remember_me';
  static const String prefsKeyRememberMeRemote = 'remember_me_remote';
  static const String prefsKeyRemoteServer = 'remote_server';
  static const String prefsKeyRemotePort = 'remote_port';
  static const String prefsKeyRemoteUser = 'remote_user';
  static const String prefsKeyClearOnLogout = 'clear_on_logout';
  static const String prefsKeyOomolPackageName = 'legacy_integration_package_name';
  static const String prefsKeyOomolPackageVersion = 'legacy_integration_package_version';

  // ─── AI Settings keys (flutter_secure_storage) ───
  static const String secureKeyAiApiKey = 'ai_api_key';
  static const String secureKeyAiProvider = 'ai_provider';
  static const String secureKeyAiModel = 'ai_model';
  static const String secureKeyAiBaseUrl = 'ai_base_url';

  // ─── Code quality thresholds ───
  static const int maxFileLines = 300;
  static const int maxFunctionLines = 50;
  static const int maxPublicMethodsPerClass = 10;
}

/// أسماء الـ routing في التطبيق
abstract final class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String aiDiagnostics = '/ai-diagnostics';
  static const String terminal = '/terminal';
  static const String logAnalysis = '/log-analysis';
  static const String legacy_integrationSettings = '/legacy_integration-settings';
  static const String backupSystem = '/backup-system';
  static const String cardSearch = '/card-search';
  static const String monthlyReport = '/monthly-report';
}
