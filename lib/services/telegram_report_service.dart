import 'dart:async';

import '../api/reports_api.dart';
import '../api/users/active_users_api.dart';
import '../models/response.dart';
import '../models/telegram_settings.dart';
import 'telegram_client.dart';
import 'telegram_health.dart';
import 'telegram_messages.dart';
import 'telegram_netwatch.dart';

/// خدمة إرسال تقارير الشبكة والمبيعات إلى Telegram.
///
/// الإرسال الدوري يعمل أثناء تشغيل التطبيق (Timer). الإرسال والتطبيق مغلق
/// تمامًا يحتاج خدمة خلفية (Foreground Service) — غير مُنفّذ حاليًا.
class TelegramReportService {
  static Timer? _timer;
  static int? _runningInterval;
  static DateTime? _lastDiskAlertAt;
  static DateTime? lastSentAt;
  static String? lastError;

  /// كل كم يجب أن يمر بين فحصين للمساحة؟
  static const Duration diskCheckEvery = Duration(minutes: 10);

  /// كل كم يجب أن يمر بين تنبيهين لنفس المشكلة؟
  static const Duration diskAlertCooldown = Duration(hours: 6);

  static bool get isRunning => _timer != null;

  /// يضمن وجود المؤقّت الدوري (ولا يعيد تشغيله كل دقيقة).
  static Future<void> ensureRunning([TelegramSettings? provided]) async {
    final settings = provided ?? await TelegramSettingsStore.load();

    if (!settings.enabled ||
        !settings.isConfigured ||
        settings.enabledFeaturesCount == 0) {
      stop();
      return;
    }

    final minutes =
        settings.intervalMinutes <= 0 ? 60 : settings.intervalMinutes;
    if (_timer != null && _runningInterval == minutes) return;

    stop();
    _runningInterval = minutes;
    _timer = Timer.periodic(Duration(minutes: minutes), (_) => sendPeriodic());
  }

  /// إعادة التشغيل القسرية (بعد تغيير الإعدادات).
  static Future<void> restart() async {
    stop();
    await ensureRunning();
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _runningInterval = null;
  }

  /// إرسال التقرير الدوري (يُبنى من الميزات المفعّلة فقط).
  static Future<AppResponse<void>> sendPeriodic([
    TelegramSettings? provided,
  ]) async {
    final settings = provided ?? await TelegramSettingsStore.load();

    if (!settings.isConfigured) {
      return AppResponse(
        status: false,
        message: "أكمل إعدادات Telegram أولًا (التوكن ومعرّف المحادثة)",
      );
    }
    if (settings.enabledFeaturesCount == 0) {
      return AppResponse(
        status: false,
        message: TelegramMessages.noFeaturesEnabled,
      );
    }

    try {
      final text = await buildReport(settings);
      return _send(settings, text);
    } catch (e) {
      lastError = e.toString();
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// بناء نص التقرير الدوري حسب الميزات المفعّلة.
  static Future<String> buildReport(TelegramSettings settings) async {
    final now = DateTime.now();
    final buffer = StringBuffer();

    buffer.writeln(TelegramMessages.header);
    buffer.writeln("<i>${TelegramMessages.formatDateTime(now)}</i>");
    buffer.writeln();

    // 🖥 حالة الراوتر (+ المساحة الحرة إن كانت ميزة التنبيه مفعّلة)
    final wantsRouter = settings.isFeatureEnabled('router_status');
    final wantsDisk = settings.isFeatureEnabled('disk_alert');

    if (wantsRouter || wantsDisk) {
      try {
        final state = await ReportsApi.getSystemState();
        if (state.status && state.data != null) {
          final system = state.data!;
          if (wantsRouter) {
            buffer.writeln(TelegramMessages.routerStatus(
              cpu: "${system.cpu}%",
              freeMemory: system.freeMemory,
              uptime: system.uptime,
              version: system.version,
              at: now,
            ));
            buffer.writeln();
          }
          if (wantsDisk &&
              TelegramHealth.needsDiskAlert(
                system.freeDiskSpace,
                system.totalDiskSpace,
              )) {
            buffer.writeln(TelegramMessages.diskAlert(
              free: system.freeDiskSpace,
              total: system.totalDiskSpace,
              percentFree: TelegramHealth.freePercent(
                system.freeDiskSpace,
                system.totalDiskSpace,
              ),
              at: now,
            ));
            buffer.writeln();
          }
        } else if (wantsRouter) {
          buffer.writeln("🖥 حالة الراوتر: غير متاحة");
          buffer.writeln();
        }
      } catch (e) {
        buffer.writeln("🖥 تعذّر جلب حالة الراوتر: ${_short(e)}");
        buffer.writeln();
      }
    }

    // 💰 المبيعات
    if (settings.isFeatureEnabled('sales')) {
      try {
        final startOfDay = DateTime(now.year, now.month, now.day);
        final sales = await ReportsApi.getSallesReport(from: startOfDay, to: now);
        if (sales.status && sales.data != null) {
          final total =
              sales.data!.fold<double>(0, (sum, item) => sum + item.price);
          buffer.writeln(TelegramMessages.sales(
            cardsCount: sales.data!.length,
            total: total,
            at: now,
          ));
        } else {
          buffer.writeln("💰 مبيعات اليوم: لا توجد بيانات");
        }
        buffer.writeln();
      } catch (e) {
        buffer.writeln("💰 تعذّر جلب المبيعات: ${_short(e)}");
        buffer.writeln();
      }
    }

    // 👥 المتصلون الآن
    if (settings.isFeatureEnabled('active_users')) {
      try {
        final active = await ActiveUsersApi.getAllActive();
        if (active.status && active.data != null) {
          buffer.writeln(
            TelegramMessages.activeUsers(count: active.data!.length, at: now),
          );
          buffer.writeln();
        }
      } catch (e) {
        buffer.writeln("👥 تعذّر جلب المتصلين: ${_short(e)}");
        buffer.writeln();
      }
    }

    // 📡 أجهزة البث (من فاحص Netwatch إن توفّرت بياناته)
    if (settings.isFeatureEnabled('devices_status')) {
      var total = TelegramNetwatch.lastTotal;
      var online = TelegramNetwatch.lastOnline;
      var offline = TelegramNetwatch.lastOffline;

      if (!TelegramNetwatch.hasData) {
        try {
          final active = await ActiveUsersApi.getAllActive();
          final count =
              (active.status && active.data != null) ? active.data!.length : 0;
          total = count;
          online = count;
          offline = 0;
        } catch (_) {
          // نتجاهل: نرسل التقرير ببيانات صفرية بدل الفشل الكامل
        }
      }

      buffer.writeln(TelegramMessages.devicesStatus(
        total: total,
        online: online,
        offline: offline,
        at: now,
      ));
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// إرسال رسالة مخصّصة (تُستخدم من فاحص netwatch والتنبيهات).
  static Future<AppResponse<void>> sendText(
    String text, [
    TelegramSettings? provided,
  ]) async {
    final settings = provided ?? await TelegramSettingsStore.load();
    if (!settings.isConfigured) {
      return AppResponse(
        status: false,
        message: "أكمل إعدادات Telegram أولًا (التوكن ومعرّف المحادثة)",
      );
    }
    return _send(settings, text);
  }

  /// إرسال «تجربة الميزة» لميزة محدّدة.
  static Future<AppResponse<void>> sendFeatureTest(String featureId) async {
    final settings = await TelegramSettingsStore.load();
    if (!settings.isConfigured) {
      return AppResponse(
        status: false,
        message: "أكمل إعدادات البوت أولًا (Token و Chat ID)",
      );
    }
    return _send(settings, TelegramMessages.testFor(featureId));
  }

  /// فحص المساحة الحرة وإرسال تنبيه عند الحاجة (مُخمَّد زمنيًا).
  ///
  /// يُرجع نص التنبيه المُرسل، أو `null` إن لم تكن هناك حاجة/لم يحن الوقت.
  static Future<String?> checkDisk([TelegramSettings? provided]) async {
    final settings = provided ?? await TelegramSettingsStore.load();
    if (!settings.enabled ||
        !settings.isConfigured ||
        !settings.isFeatureEnabled('disk_alert')) {
      return null;
    }

    final now = DateTime.now();
    if (_lastDiskAlertAt != null &&
        now.difference(_lastDiskAlertAt!) < diskCheckEvery) {
      return null;
    }
    _lastDiskAlertAt = now;

    try {
      final state = await ReportsApi.getSystemState();
      if (!state.status || state.data == null) return null;

      final system = state.data!;
      if (!TelegramHealth.needsDiskAlert(
        system.freeDiskSpace,
        system.totalDiskSpace,
      )) {
        return null;
      }

      // لا نكرّر التنبيه قبل انتهاء المهلة
      if (lastDiskAlertSentAt != null &&
          now.difference(lastDiskAlertSentAt!) < diskAlertCooldown) {
        return null;
      }

      final text = TelegramMessages.diskAlert(
        free: system.freeDiskSpace,
        total: system.totalDiskSpace,
        percentFree: TelegramHealth.freePercent(
          system.freeDiskSpace,
          system.totalDiskSpace,
        ),
        at: now,
      );

      final response = await _send(settings, text);
      if (response.status) {
        lastDiskAlertSentAt = now;
        return text;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// وقت آخر تنبيه مساحة أُرسل فعلًا.
  static DateTime? lastDiskAlertSentAt;

  /// إرسال ملخص يومي (يُستدعى من المؤقّت عند بلوغ الساعة المحددة).
  static Future<AppResponse<void>> sendDailySummary(
    TelegramSettings settings,
  ) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      var cardsCount = 0;
      double total = 0;
      final sales = await ReportsApi.getSallesReport(from: startOfDay, to: now);
      if (sales.status && sales.data != null) {
        cardsCount = sales.data!.length;
        total = sales.data!.fold<double>(0, (sum, item) => sum + item.price);
      }

      var activeCount = 0;
      final active = await ActiveUsersApi.getAllActive();
      if (active.status && active.data != null) {
        activeCount = active.data!.length;
      }

      var uptime = '-';
      final state = await ReportsApi.getSystemState();
      if (state.status && state.data != null) uptime = state.data!.uptime;

      return _send(
        settings,
        TelegramMessages.dailySummary(
          cardsCount: cardsCount,
          total: total,
          activeUsers: activeCount,
          routerUptime: uptime,
          offlineDevices: TelegramNetwatch.lastOffline,
        ),
      );
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<void>> _send(
    TelegramSettings settings,
    String text,
  ) async {
    final response = await TelegramClient.sendMessage(
      token: settings.botToken,
      chatId: settings.chatId,
      text: text,
    );

    if (response.status) {
      lastSentAt = DateTime.now();
      lastError = null;
    } else {
      lastError = response.message;
    }
    return response;
  }

  static String _short(Object error) {
    final text = error.toString();
    return text.length > 60 ? "${text.substring(0, 60)}…" : text;
  }
}
