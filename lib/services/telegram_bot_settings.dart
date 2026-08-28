import 'package:shared_preferences/shared_preferences.dart';

import 'secure_credentials_storage.dart';

/// إعدادات Telegram Bot المحلية.
///
/// لا تُحفظ قيمة Bot Token في SharedPreferences؛ تُحفظ عبر
/// [SecureCredentialsStorage] فقط. أما قيم المراقبة فهي غير حساسة.
class TelegramBotSettings {
  final String botToken;
  final String allowedChatIds;
  final String allowedUserIds;
  final int pollSeconds;
  final String monitorTarget;
  final int monitorIntervalSeconds;
  final String trafficInterface;
  final int trafficIntervalSeconds;
  final String dailyReportTime;
  final String offsetFile;
  final String trafficStateFile;

  const TelegramBotSettings({
    required this.botToken,
    required this.allowedChatIds,
    required this.allowedUserIds,
    required this.pollSeconds,
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
      botToken: botToken,
      allowedChatIds: '',
      allowedUserIds: '',
      pollSeconds: 20,
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

  TelegramBotSettings copyWith({
    String? botToken,
    String? allowedChatIds,
    String? allowedUserIds,
    int? pollSeconds,
    String? monitorTarget,
    int? monitorIntervalSeconds,
    String? trafficInterface,
    int? trafficIntervalSeconds,
    String? dailyReportTime,
    String? offsetFile,
    String? trafficStateFile,
  }) {
    return TelegramBotSettings(
      botToken: botToken ?? this.botToken,
      allowedChatIds: allowedChatIds ?? this.allowedChatIds,
      allowedUserIds: allowedUserIds ?? this.allowedUserIds,
      pollSeconds: pollSeconds ?? this.pollSeconds,
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
  static const _allowedChatIdsKey = 'telegram_allowed_chat_ids';
  static const _allowedUserIdsKey = 'telegram_allowed_user_ids';
  static const _pollSecondsKey = 'telegram_poll_seconds';
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

    return TelegramBotSettings(
      botToken: token ?? '',
      allowedChatIds:
          prefs.getString(_allowedChatIdsKey) ?? defaults.allowedChatIds,
      allowedUserIds:
          prefs.getString(_allowedUserIdsKey) ?? defaults.allowedUserIds,
      pollSeconds: prefs.getInt(_pollSecondsKey) ?? defaults.pollSeconds,
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

  Future<void> save(TelegramBotSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await SecureCredentialsStorageContainer.instance
        .setTelegramBotToken(settings.botToken);
    await prefs.setString(_allowedChatIdsKey, settings.allowedChatIds.trim());
    await prefs.setString(_allowedUserIdsKey, settings.allowedUserIds.trim());
    await prefs.setInt(_pollSecondsKey, settings.pollSeconds);
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
