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
  static const String backupSystem = '/backup-system';
  static const String cardSearch = '/card-search';
  static const String monthlyReport = '/monthly-report';
}
