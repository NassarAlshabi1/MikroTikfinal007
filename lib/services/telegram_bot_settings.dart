import 'package:shared_preferences/shared_preferences.dart';

import 'secure_credentials_storage.dart';

/// أنماط نشر Telegram Bot المدعومة.
enum TelegramDeploymentMode {
  /// سكربت RouterOS v6 داخل الراوتر (polling عبر /tool fetch).
  routerOsScript,

  /// Cloudflare Worker يستقبل webhook ويخزن الحالة في KV.
  cloudflareWorker,

  /// خدمة Python محلية على جهاز Linux (النمط القديم).
  localPython,
}

/// إعدادات Telegram Bot المحلية.
///
/// لا تُحفظ قيم Bot Token أو مفتاح Worker في SharedPreferences؛ تُحفظ عبر
/// [SecureCredentialsStorage] فقط. أما قيم المراقبة فهي غير حساسة.
class TelegramBotSettings {
  final TelegramDeploymentMode deploymentMode;
  final String botToken;
  final String allowedChatIds;
  final String allowedUserIds;
  final String workerUrl;
  final String umCustomer;
  final String umProfile;
  final String defaultCardLimit;
  final int pollSeconds;

  /// فترة استطلاع أوامر Telegram في مجدول الراوتر (نمط RouterOS v6).
  final int routerPollSeconds;
  final String monitorTarget;
  final int monitorIntervalSeconds;
  final String trafficInterface;
  final int trafficIntervalSeconds;
  final String dailyReportTime;
  final String offsetFile;
  final String trafficStateFile;

  const TelegramBotSettings({
    required this.deploymentMode,
    required this.botToken,
    required this.allowedChatIds,
    required this.allowedUserIds,
    required this.workerUrl,
    required this.umCustomer,
    required this.umProfile,
    required this.defaultCardLimit,
    required this.pollSeconds,
    required this.routerPollSeconds,
    required this.monitorTarget,
    required this.monitorIntervalSeconds,
    required this.trafficInterface,
    required this.trafficIntervalSeconds,
    required this.dailyReportTime,
    required this.offsetFile,
    required this.trafficStateFile,
  });

  factory TelegramBotSettings.defaults({String botToken = ''}) {
    return TelegramBotSettings(
      deploymentMode: TelegramDeploymentMode.routerOsScript,
      botToken: botToken,
      allowedChatIds: '',
      allowedUserIds: '',
      workerUrl: '',
      umCustomer: 'admin',
      umProfile: 'default',
      defaultCardLimit: '1w',
      pollSeconds: 20,
      routerPollSeconds: 10,
      monitorTarget: '1.1.1.1',
      monitorIntervalSeconds: 30,
      trafficInterface: 'ether1',
      trafficIntervalSeconds: 60,
      dailyReportTime: '23:59',
      offsetFile: '/var/lib/mikrotik-telegram/.telegram_offset',
      trafficStateFile: '/var/lib/mikrotik-telegram/traffic-state.json',
    );
  }

  bool get isConfigured =>
      botToken.trim().isNotEmpty &&
      allowedChatIds.trim().isNotEmpty &&
      allowedUserIds.trim().isNotEmpty;

  /// هل نمط النشر الحالي مكتمل الإعدادات؟
  bool get isDeploymentConfigured {
    switch (deploymentMode) {
      case TelegramDeploymentMode.routerOsScript:
        return isConfigured &&
            umCustomer.trim().isNotEmpty &&
            umProfile.trim().isNotEmpty;
      case TelegramDeploymentMode.cloudflareWorker:
        return isConfigured && workerUrl.trim().isNotEmpty;
      case TelegramDeploymentMode.localPython:
        return isConfigured;
    }
  }

  TelegramBotSettings copyWith({
    TelegramDeploymentMode? deploymentMode,
    String? botToken,
    String? allowedChatIds,
    String? allowedUserIds,
    String? workerUrl,
    String? umCustomer,
    String? umProfile,
    String? defaultCardLimit,
    int? pollSeconds,
    int? routerPollSeconds,
    String? monitorTarget,
    int? monitorIntervalSeconds,
    String? trafficInterface,
    int? trafficIntervalSeconds,
    String? dailyReportTime,
    String? offsetFile,
    String? trafficStateFile,
  }) {
    return TelegramBotSettings(
      deploymentMode: deploymentMode ?? this.deploymentMode,
      botToken: botToken ?? this.botToken,
      allowedChatIds: allowedChatIds ?? this.allowedChatIds,
      allowedUserIds: allowedUserIds ?? this.allowedUserIds,
      workerUrl: workerUrl ?? this.workerUrl,
      umCustomer: umCustomer ?? this.umCustomer,
      umProfile: umProfile ?? this.umProfile,
      defaultCardLimit: defaultCardLimit ?? this.defaultCardLimit,
      pollSeconds: pollSeconds ?? this.pollSeconds,
      routerPollSeconds: routerPollSeconds ?? this.routerPollSeconds,
      monitorTarget: monitorTarget ?? this.monitorTarget,
      monitorIntervalSeconds:
          monitorIntervalSeconds ?? this.monitorIntervalSeconds,
      trafficInterface: trafficInterface ?? this.trafficInterface,
      trafficIntervalSeconds:
          trafficIntervalSeconds ?? this.trafficIntervalSeconds,
      dailyReportTime: dailyReportTime ?? this.dailyReportTime,
      offsetFile: offsetFile ?? this.offsetFile,
      trafficStateFile: trafficStateFile ?? this.trafficStateFile,
    );
  }
}

class TelegramBotSettingsStore {
  static const _deploymentModeKey = 'telegram_deployment_mode';
  static const _allowedChatIdsKey = 'telegram_allowed_chat_ids';
  static const _allowedUserIdsKey = 'telegram_allowed_user_ids';
  static const _workerUrlKey = 'telegram_worker_url';
  static const _umCustomerKey = 'telegram_um_customer';
  static const _umProfileKey = 'telegram_um_profile';
  static const _defaultCardLimitKey = 'telegram_default_card_limit';
  static const _pollSecondsKey = 'telegram_poll_seconds';
  static const _routerPollSecondsKey = 'telegram_router_poll_seconds';
  static const _monitorTargetKey = 'telegram_monitor_target';
  static const _monitorIntervalKey = 'telegram_monitor_interval_seconds';
  static const _trafficInterfaceKey = 'telegram_traffic_interface';
  static const _trafficIntervalKey = 'telegram_traffic_interval_seconds';
  static const _dailyReportTimeKey = 'telegram_daily_report_time';
  static const _offsetFileKey = 'telegram_offset_file';
  static const _trafficStateFileKey = 'telegram_traffic_state_file';

  const TelegramBotSettingsStore();

  Future<TelegramBotSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        await SecureCredentialsStorageContainer.instance.getTelegramBotToken();
    final defaults = TelegramBotSettings.defaults(botToken: token ?? '');

    final modeIndex = prefs.getInt(_deploymentModeKey);
    final mode = modeIndex == null ||
            modeIndex < 0 ||
            modeIndex >= TelegramDeploymentMode.values.length
        ? defaults.deploymentMode
        : TelegramDeploymentMode.values[modeIndex];

    return TelegramBotSettings(
      deploymentMode: mode,
      botToken: token ?? '',
      allowedChatIds:
          prefs.getString(_allowedChatIdsKey) ?? defaults.allowedChatIds,
      allowedUserIds:
          prefs.getString(_allowedUserIdsKey) ?? defaults.allowedUserIds,
      workerUrl: prefs.getString(_workerUrlKey) ?? defaults.workerUrl,
      umCustomer: prefs.getString(_umCustomerKey) ?? defaults.umCustomer,
      umProfile: prefs.getString(_umProfileKey) ?? defaults.umProfile,
      defaultCardLimit:
          prefs.getString(_defaultCardLimitKey) ?? defaults.defaultCardLimit,
      pollSeconds: prefs.getInt(_pollSecondsKey) ?? defaults.pollSeconds,
      routerPollSeconds:
          prefs.getInt(_routerPollSecondsKey) ?? defaults.routerPollSeconds,
      monitorTarget:
          prefs.getString(_monitorTargetKey) ?? defaults.monitorTarget,
      monitorIntervalSeconds:
          prefs.getInt(_monitorIntervalKey) ?? defaults.monitorIntervalSeconds,
      trafficInterface:
          prefs.getString(_trafficInterfaceKey) ?? defaults.trafficInterface,
      trafficIntervalSeconds:
          prefs.getInt(_trafficIntervalKey) ?? defaults.trafficIntervalSeconds,
      dailyReportTime:
          prefs.getString(_dailyReportTimeKey) ?? defaults.dailyReportTime,
      offsetFile: prefs.getString(_offsetFileKey) ?? defaults.offsetFile,
      trafficStateFile:
          prefs.getString(_trafficStateFileKey) ?? defaults.trafficStateFile,
    );
  }

  Future<String?> loadWorkerAdminKey() async {
    return SecureCredentialsStorageContainer.instance.getWorkerAdminKey();
  }

  Future<void> save(TelegramBotSettings settings,
      {String? workerAdminKey}) async {
    final prefs = await SharedPreferences.getInstance();
    await SecureCredentialsStorageContainer.instance
        .setTelegramBotToken(settings.botToken);
    if (workerAdminKey != null) {
      await SecureCredentialsStorageContainer.instance
          .setWorkerAdminKey(workerAdminKey);
    }
    await prefs.setInt(_deploymentModeKey, settings.deploymentMode.index);
    await prefs.setString(_allowedChatIdsKey, settings.allowedChatIds.trim());
    await prefs.setString(_allowedUserIdsKey, settings.allowedUserIds.trim());
    await prefs.setString(_workerUrlKey, settings.workerUrl.trim());
    await prefs.setString(_umCustomerKey, settings.umCustomer.trim());
    await prefs.setString(_umProfileKey, settings.umProfile.trim());
    await prefs.setString(
        _defaultCardLimitKey, settings.defaultCardLimit.trim());
    await prefs.setInt(_pollSecondsKey, settings.pollSeconds);
    await prefs.setInt(_routerPollSecondsKey, settings.routerPollSeconds);
    await prefs.setString(_monitorTargetKey, settings.monitorTarget.trim());
    await prefs.setInt(_monitorIntervalKey, settings.monitorIntervalSeconds);
    await prefs.setString(
        _trafficInterfaceKey, settings.trafficInterface.trim());
    await prefs.setInt(_trafficIntervalKey, settings.trafficIntervalSeconds);
    await prefs.setString(_dailyReportTimeKey, settings.dailyReportTime.trim());
    await prefs.setString(_offsetFileKey, settings.offsetFile.trim());
    await prefs.setString(
        _trafficStateFileKey, settings.trafficStateFile.trim());
  }
}
