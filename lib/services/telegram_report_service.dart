import 'dart:async';

import '../api/reports_api.dart';
import '../api/users/active_users_api.dart';
import '../models/response.dart';
import '../models/telegram_settings.dart';
import 'telegram_client.dart';

/// خدمة إرسال تقارير الشبكة والمبيعات إلى Telegram.
///
/// ملاحظة: الإرسال الدوري يعمل أثناء تشغيل التطبيق (Timer)، أما الإرسال
/// والتطبيق مغلق تمامًا فيحتاج خدمة خلفية (Foreground Service) لاحقًا.
class TelegramReportService {
  static Timer? _timer;
  static DateTime? lastSentAt;
  static String? lastError;

  static bool get isRunning => _timer != null;

  /// (إعادة) تشغيل المؤقّت حسب الإعدادات المحفوظة.
  static Future<void> restart() async {
    stop();
    try {
      final settings = await TelegramSettingsStore.load();
      if (!settings.enabled || !settings.isConfigured) return;

      final minutes = settings.intervalMinutes <= 0 ? 60 : settings.intervalMinutes;
      _timer = Timer.periodic(Duration(minutes: minutes), (_) => sendReport());
    } catch (_) {
      // لا نُفشل تشغيل التطبيق بسبب إعدادات غير مكتملة
    }
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// بناء نص التقرير حسب الإعدادات المختارة.
  static Future<String> buildReport(TelegramSettings settings) async {
    final now = DateTime.now();
    final buffer = StringBuffer();

    buffer.writeln("<b>📊 تقرير MikroNet</b>");
    buffer.writeln("<i>${_formatDateTime(now)}</i>");
    buffer.writeln();

    if (settings.sendSalesReport) {
      try {
        final startOfDay = DateTime(now.year, now.month, now.day);
        final sales = await ReportsApi.getSallesReport(from: startOfDay, to: now);
        if (sales.status && sales.data != null) {
          final cards = sales.data!.length;
          final total = sales.data!.fold<double>(0, (sum, item) => sum + item.price);
          buffer.writeln("💰 <b>مبيعات اليوم</b>");
          buffer.writeln("• عدد الكروت: <code>$cards</code>");
          buffer.writeln("• الإجمالي: <code>${total.toStringAsFixed(2)}</code>");
        } else {
          buffer.writeln("💰 مبيعات اليوم: لا توجد بيانات");
        }
        buffer.writeln();
      } catch (e) {
        buffer.writeln("💰 تعذّر جلب المبيعات: ${_short(e)}");
        buffer.writeln();
      }
    }

    if (settings.sendRouterStatus) {
      try {
        final state = await ReportsApi.getSystemState();
        if (state.status && state.data != null) {
          final system = state.data!;
          buffer.writeln("🖥 <b>حالة الراوتر</b>");
          buffer.writeln("• المعالج: <code>${system.cpu}%</code>");
          buffer.writeln("• الذاكرة: <code>${system.freeMemory} حرة</code>");
          buffer.writeln("• مدة التشغيل: <code>${system.uptime}</code>");
          buffer.writeln("• الإصدار: <code>${system.version}</code>");
        } else {
          buffer.writeln("🖥 حالة الراوتر: غير متاحة");
        }
        buffer.writeln();
      } catch (e) {
        buffer.writeln("🖥 تعذّر جلب حالة الراوتر: ${_short(e)}");
        buffer.writeln();
      }
    }

    if (settings.sendActiveUsers) {
      try {
        final active = await ActiveUsersApi.getAllActive();
        if (active.status && active.data != null) {
          buffer.writeln("👥 المتصلون الآن: <code>${active.data!.length}</code>");
        }
      } catch (e) {
        buffer.writeln("👥 تعذّر جلب المتصلين: ${_short(e)}");
      }
    }

    return buffer.toString();
  }

  /// إرسال تقرير الآن (يدويًا أو من المؤقّت).
  static Future<AppResponse<void>> sendReport([TelegramSettings? provided]) async {
    final settings = provided ?? await TelegramSettingsStore.load();

    if (!settings.isConfigured) {
      return AppResponse(
        status: false,
        message: "أكمل إعدادات Telegram أولًا (التوكن ومعرّف المحادثة)",
      );
    }

    try {
      final text = await buildReport(settings);
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
    } catch (e) {
      lastError = e.toString();
      return AppResponse(status: false, message: e.toString());
    }
  }

  static String _short(Object error) {
    final text = error.toString();
    return text.length > 60 ? "${text.substring(0, 60)}…" : text;
  }

  static String _formatDateTime(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return "${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}";
  }
}
