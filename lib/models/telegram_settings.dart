import '../services/secure_store.dart';
import '../services/settings_store.dart';

/// إعدادات تكامل Telegram.
///
/// تُحفظ الإعدادات في SharedPreferences، أما التوكن فيُخزَّن مشفّرًا
/// عبر [SecureStore] ولا يُحفظ كنص صريح.
class TelegramSettings {
  final bool enabled;
  final String botToken;
  final String chatId;
  final int intervalMinutes;
  final bool sendSalesReport;
  final bool sendRouterStatus;
  final bool sendActiveUsers;

  const TelegramSettings({
    required this.enabled,
    required this.botToken,
    required this.chatId,
    required this.intervalMinutes,
    required this.sendSalesReport,
    required this.sendRouterStatus,
    required this.sendActiveUsers,
  });

  factory TelegramSettings.defaults() => const TelegramSettings(
        enabled: false,
        botToken: '',
        chatId: '',
        intervalMinutes: 60,
        sendSalesReport: true,
        sendRouterStatus: true,
        sendActiveUsers: true,
      );

  bool get isConfigured =>
      botToken.trim().isNotEmpty && chatId.trim().isNotEmpty;

  TelegramSettings copyWith({
    bool? enabled,
    String? botToken,
    String? chatId,
    int? intervalMinutes,
    bool? sendSalesReport,
    bool? sendRouterStatus,
    bool? sendActiveUsers,
  }) {
    return TelegramSettings(
      enabled: enabled ?? this.enabled,
      botToken: botToken ?? this.botToken,
      chatId: chatId ?? this.chatId,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      sendSalesReport: sendSalesReport ?? this.sendSalesReport,
      sendRouterStatus: sendRouterStatus ?? this.sendRouterStatus,
      sendActiveUsers: sendActiveUsers ?? this.sendActiveUsers,
    );
  }
}

/// تحميل وحفظ إعدادات Telegram.
class TelegramSettingsStore {
  static const String _kEnabled = 'telegram_enabled';
  static const String _kToken = 'telegram_bot_token';
  static const String _kChat = 'telegram_chat_id';
  static const String _kInterval = 'telegram_interval_minutes';
  static const String _kSales = 'telegram_send_sales';
  static const String _kRouter = 'telegram_send_router';
  static const String _kUsers = 'telegram_send_users';

  static Future<TelegramSettings> load() async {
    final rawToken = await SettingsStore.get(_kToken) ?? '';
    final token = await SecureStore.decryptText(rawToken);

    return TelegramSettings(
      enabled: await _getBool(_kEnabled, false),
      botToken: token,
      chatId: await SettingsStore.get(_kChat) ?? '',
      intervalMinutes: int.tryParse(await SettingsStore.get(_kInterval) ?? '') ?? 60,
      sendSalesReport: await _getBool(_kSales, true),
      sendRouterStatus: await _getBool(_kRouter, true),
      sendActiveUsers: await _getBool(_kUsers, true),
    );
  }

  static Future<void> save(TelegramSettings settings) async {
    await SettingsStore.set(_kEnabled, settings.enabled ? '1' : '0');
    await SettingsStore.set(_kToken, await SecureStore.encryptText(settings.botToken.trim()));
    await SettingsStore.set(_kChat, settings.chatId.trim());
    await SettingsStore.set(_kInterval, settings.intervalMinutes.toString());
    await SettingsStore.set(_kSales, settings.sendSalesReport ? '1' : '0');
    await SettingsStore.set(_kRouter, settings.sendRouterStatus ? '1' : '0');
    await SettingsStore.set(_kUsers, settings.sendActiveUsers ? '1' : '0');
  }

  static Future<bool> _getBool(String key, bool fallback) async {
    final value = await SettingsStore.get(key);
    if (value == null) return fallback;
    return value == '1' || value.toLowerCase() == 'true';
  }
}
