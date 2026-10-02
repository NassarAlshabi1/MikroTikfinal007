import 'dart:async';

import '../models/telegram_settings.dart';
import 'telegram_netwatch.dart';
import 'telegram_report_service.dart';

/// مُجدوِل إشعارات Telegram — نبضة كل دقيقة تنفّذ:
///
/// 1. **فحص Netwatch** لأجهزة البث (فوري: خلال دقيقة من الانقطاع).
/// 2. **فحص مساحة التخزين** (كل 10 دقائق، مع تخميد التنبيهات).
/// 3. **الملخص اليومي** مرة واحدة في اليوم عند الساعة المختارة.
/// 4. **ضمان** عمل التقارير الدورية على الفاصل المحدد (دون إعادة تشغيله).
///
/// يعمل **أثناء فتح التطبيق** فقط (Timer داخل العملية). الإرسال والتطبيق مغلق
/// تمامًا يحتاج Foreground Service (خطوة لاحقة).
class TelegramScheduler {
  const TelegramScheduler._();

  static Timer? _timer;
  static DateTime? _lastDailyRun;

  static bool get isRunning => _timer != null;

  /// بدء المُجدوِل (يُستدعى مرة واحدة عند تشغيل التطبيق).
  static void start() {
    stop();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => tick());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// نبضة واحدة — مفصولة لتكون قابلة للاختبار/الاستدعاء اليدوي.
  static Future<void> tick({DateTime? now}) async {
    try {
      final settings = await TelegramSettingsStore.load();
      if (!settings.enabled || !settings.isConfigured) return;

      final current = now ?? DateTime.now();
      final today = DateTime(current.year, current.month, current.day);

      // 1) فاحص أجهزة البث (يُرسل إشعارًا عند أي تغيّر — بعد خط الأساس)
      if (settings.isFeatureEnabled('netwatch')) {
        await TelegramNetwatch.scan(provided: settings);
      }

      // 2) تنبيه مساحة التخزين (مُخمَّد داخليًا: كل 10 دقائق فحصًا، وكل 6 ساعات تنبيهًا)
      if (settings.isFeatureEnabled('disk_alert')) {
        await TelegramReportService.checkDisk(settings);
      }

      // 3) الملخص اليومي مرة واحدة في اليوم عند الساعة المحددة
      if (settings.isFeatureEnabled('daily_summary') &&
          current.hour == settings.dailySummaryHour &&
          _lastDailyRun != today) {
        _lastDailyRun = today;
        await TelegramReportService.sendDailySummary(settings);
        return;
      }

      // 4) التقارير الدورية على الفاصل المحدد (بلا إعادة تشغيل للمؤقّت)
      await TelegramReportService.ensureRunning(settings);
    } catch (_) {
      // تجاهل: لا نُفشل التطبيق بسبب إعدادات أو شبكة
    }
  }
}
