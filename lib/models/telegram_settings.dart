import '../services/secure_store.dart';
import '../services/settings_store.dart';
import '../services/telegram_features.dart';

/// إعدادات تكامل Telegram.
///
/// - التوكن يُخزَّن **مشفّرًا** عبر [SecureStore] ولا يُحفظ كنص صريح.
/// - الميزات تُخزَّن كمفاتيح مستقلة `telegram_feature_<id>` ⇒ إضافة ميزات
///   جديدة لاحقًا لا تُفسد الإعدادات المحفوظة.
class TelegramSettings {
  final bool enabled;
  final String botToken;
  final String chatId;

  /// الفاصل بين التقارير الدورية (بالدقائق).
  final int intervalMinutes;

  /// حالة كل ميزة (المعرّف ⇒ مفعّلة؟).
  final Map<String, bool> features;

  /// وقت إرسال الملخص اليومي (24 ساعة).
  final int dailySummaryHour;

  const TelegramSettings({
    required this.enabled,
    required this.botToken,
    required this.chatId,
    required this.intervalMinutes,
    required this.features,
    this.dailySummaryHour = 23,
  });

  factory TelegramSettings.defaults() => TelegramSettings(
        enabled: false,
        botToken: '',
        chatId: '',
        intervalMinutes: 60,
        features: TelegramFeatureCatalog.defaultFlags(),
      );

  bool get isConfigured =>
      botToken.trim().isNotEmpty && chatId.trim().isNotEmpty;

  /// عدد الميزات المفعّلة.
  int get enabledFeaturesCount => TelegramFeatureCatalog.enabledCount(features);

  /// هل ميزة معيّنة مفعّلة؟
  bool isFeatureEnabled(String id) => features[id] == true;

  TelegramSettings copyWith({
    bool? enabled,
    String? botToken,
    String? chatId,
    int? intervalMinutes,
    Map<String, bool>? features,
    int? dailySummaryHour,
  }) {
    return TelegramSettings(
      enabled: enabled ?? this.enabled,
      botToken: botToken ?? this.botToken,
      chatId: chatId ?? this.chatId,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      features: features ?? this.features,
      dailySummaryHour: dailySummaryHour ?? this.dailySummaryHour,
    );
  }
}

/// تحميل وحفظ إعدادات Telegram.
class TelegramSettingsStore {
  static const String _kEnabled = 'telegram_enabled';
  static const String _kToken = 'telegram_bot_token';
  static const String _kChat = 'telegram_chat_id';
  static const String _kInterval = 'telegram_interval_minutes';
  static const String _kDailyHour = 'telegram_daily_hour';
  static const String _featurePrefix = 'telegram_feature_';

  // مفاتيح النسخة القديمة (توافق خلفي: تُقرأ مرة وتُحوَّل للميزات الجديدة)
  static const String _oldSales = 'telegram_send_sales';
  static const String _oldRouter = 'telegram_send_router';
  static const String _oldUsers = 'telegram_send_users';

  static Future<TelegramSettings> load() async {
    final rawToken = await SettingsStore.get(_kToken) ?? '';
    final token = await SecureStore.decryptText(rawToken);

    final interval =
        int.tryParse(await SettingsStore.get(_kInterval) ?? '') ?? 60;

    // الميزات: نقرأ كل ميزة بمفتاحها، وإن لم توجد أي قيمة نستعمل الافتراضي.
    final rawFeatures = <String, dynamic>{};
    for (final id in TelegramFeatureCatalog.ids) {
      final value = await SettingsStore.get('$_featurePrefix$id');
      if (value != null) rawFeatures[id] = value;
    }
    var features = TelegramFeatureCatalog.normalize(
      rawFeatures.isEmpty ? null : rawFeatures,
    );

    // ترقية من النسخة القديمة: تحويل المفاتيح الثلاثة إلى ميزاتها المقابلة
    if (rawFeatures.isEmpty) {
      final oldSales = await SettingsStore.get(_oldSales);
      final oldRouter = await SettingsStore.get(_oldRouter);
      final oldUsers = await SettingsStore.get(_oldUsers);
      if (oldSales != null) features = {...features, 'sales': oldSales == '1'};
      if (oldRouter != null) {
        features = {...features, 'router_status': oldRouter == '1'};
      }
      if (oldUsers != null) {
        features = {...features, 'active_users': oldUsers == '1'};
      }
    }

    return TelegramSettings(
      enabled: await _getBool(_kEnabled, false),
      botToken: token,
      chatId: await SettingsStore.get(_kChat) ?? '',
      intervalMinutes: interval,
      features: features,
      dailySummaryHour:
          int.tryParse(await SettingsStore.get(_kDailyHour) ?? '') ?? 23,
    );
  }

  static Future<void> save(TelegramSettings settings) async {
    await SettingsStore.set(_kEnabled, settings.enabled ? '1' : '0');
    await SettingsStore.set(
      _kToken,
      await SecureStore.encryptText(settings.botToken.trim()),
    );
    await SettingsStore.set(_kChat, settings.chatId.trim());
    await SettingsStore.set(_kInterval, settings.intervalMinutes.toString());
    await SettingsStore.set(_kDailyHour, settings.dailySummaryHour.toString());

    final normalized = TelegramFeatureCatalog.normalize(settings.features);
    for (final entry in normalized.entries) {
      await SettingsStore.set(
        '$_featurePrefix${entry.key}',
        entry.value ? '1' : '0',
      );
    }
  }

  static Future<bool> _getBool(String key, bool fallback) async {
    final value = await SettingsStore.get(key);
    if (value == null) return fallback;
    return value == '1' || value.toLowerCase() == 'true';
  }
}
