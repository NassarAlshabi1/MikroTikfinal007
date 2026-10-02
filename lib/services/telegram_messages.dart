import 'telegram_features.dart';

/// بناء نصوص رسائل Telegram — **منطق نقي** بلا اتصال شبكة ⇒ قابل للاختبار مباشرة.
///
/// كل دالة تستقبل البيانات جاهزة وتُرجع نص الرسالة (بوسوم HTML التي يدعمها
/// Telegram: `<b>` و `<code>` و `<i>`).
class TelegramMessages {
  const TelegramMessages._();

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// 2026-10-03 14:05
  static String formatDateTime(DateTime date) =>
      "${date.year}-${_two(date.month)}-${_two(date.day)} "
      "${_two(date.hour)}:${_two(date.minute)}";

  static String get header => "<b>📊 تقرير MikroNet</b>";

  /// 🔌 انقطاع/عودة جهاز بث (Netwatch).
  static String netwatch({
    required String device,
    required bool isUp,
    String ip = '',
    String comment = '',
    DateTime? at,
  }) {
    final time = formatDateTime(at ?? DateTime.now());
    final icon = isUp ? '🟢' : '🔴';
    final state = isUp ? 'عاد إلى الشبكة' : 'انقطع عن الشبكة';
    final buffer = StringBuffer()
      ..writeln("$icon <b>جهاز بث $state</b>")
      ..writeln("• الاسم: <code>${device.trim()}</code>");
    if (ip.trim().isNotEmpty) buffer.writeln("• العنوان: <code>${ip.trim()}</code>");
    if (comment.trim().isNotEmpty) buffer.writeln("• ملاحظة: ${comment.trim()}");
    buffer.write("<i>$time</i>");
    return buffer.toString();
  }

  /// 📡 حالة أجهزة البث الدورية.
  static String devicesStatus({
    required int total,
    int online = 0,
    int offline = 0,
    DateTime? at,
  }) {
    final warn = offline > 0 ? '⚠️' : '✅';
    return "$warn <b>حالة أجهزة البث</b>\n"
        "• الإجمالي: <code>$total</code>\n"
        "• متصلة: <code>$online</code>\n"
        "• منقطعة: <code>$offline</code>\n"
        "<i>${formatDateTime(at ?? DateTime.now())}</i>";
  }

  /// 🖥 حالة الراوتر.
  static String routerStatus({
    required String cpu,
    required String freeMemory,
    required String uptime,
    required String version,
    DateTime? at,
  }) {
    return "🖥 <b>حالة الراوتر</b>\n"
        "• المعالج: <code>$cpu</code>\n"
        "• الذاكرة الحرة: <code>$freeMemory</code>\n"
        "• مدة التشغيل: <code>$uptime</code>\n"
        "• الإصدار: <code>$version</code>\n"
        "<i>${formatDateTime(at ?? DateTime.now())}</i>";
  }

  /// 💰 تقرير المبيعات.
  static String sales({
    required int cardsCount,
    required double total,
    String currency = '',
    DateTime? at,
  }) {
    final suffix = currency.trim().isEmpty ? '' : ' ${currency.trim()}';
    return "💰 <b>مبيعات اليوم</b>\n"
        "• عدد الكروت: <code>$cardsCount</code>\n"
        "• الإجمالي: <code>${total.toStringAsFixed(2)}$suffix</code>\n"
        "<i>${formatDateTime(at ?? DateTime.now())}</i>";
  }

  /// 👥 المتصلون الآن.
  static String activeUsers({required int count, DateTime? at}) {
    return "👥 <b>المتصلون الآن</b>: <code>$count</code>\n"
        "<i>${formatDateTime(at ?? DateTime.now())}</i>";
  }

  /// 💾 تنبيه مساحة التخزين.
  static String diskAlert({
    required String free,
    required String total,
    double? percentFree,
    DateTime? at,
  }) {
    final percent = percentFree == null
        ? ''
        : ' (${percentFree.toStringAsFixed(0)}% متاح)';
    return "💾 <b>تحذير: مساحة التخزين منخفضة</b>$percent\n"
        "• الحرة: <code>$free</code>\n"
        "• الإجمالي: <code>$total</code>\n"
        "<i>${formatDateTime(at ?? DateTime.now())}</i>";
  }

  /// 📋 ملخص يومي شامل.
  static String dailySummary({
    required int cardsCount,
    required double total,
    required int activeUsers,
    required String routerUptime,
    required int offlineDevices,
    DateTime? at,
  }) {
    final warn = offlineDevices > 0 ? '\n⚠️ أجهزة منقطعة: <code>$offlineDevices</code>' : '';
    return "📋 <b>ملخص اليوم — MikroNet</b>\n"
        "• كروت مبيعة: <code>$cardsCount</code>\n"
        "• الإجمالي: <code>${total.toStringAsFixed(2)}</code>\n"
        "• المتصلون الآن: <code>$activeUsers</code>\n"
        "• مدة تشغيل الراوتر: <code>$routerUptime</code>$warn\n"
        "<i>${formatDateTime(at ?? DateTime.now())}</i>";
  }

  /// 🚀 رسالة تجربة ميزة (زر «إرسال تجربة الميزة»).
  static String testFor(String featureId) {
    final feature = TelegramFeatureCatalog.byId(featureId);
    final name = feature?.title ?? featureId;
    final buffer = StringBuffer()
      ..writeln("🚀 <b>تجربة الميزة: $name</b>")
      ..writeln("<i>هذه رسالة تجريبية للتأكد من وصول الإشعارات.</i>")
      ..writeln();

    switch (featureId) {
      case 'netwatch':
        buffer.write(netwatch(
          device: 'tower-01',
          ip: '10.5.50.2',
          comment: 'تجربة',
          isUp: false,
        ));
        break;
      case 'devices_status':
        buffer.write(devicesStatus(total: 12, online: 10, offline: 2));
        break;
      case 'router_status':
        buffer.write(routerStatus(
          cpu: '18%',
          freeMemory: '142 MiB',
          uptime: '12d 4h',
          version: '7.15.3',
        ));
        break;
      case 'sales':
        buffer.write(sales(cardsCount: 24, total: 4800));
        break;
      case 'active_users':
        buffer.write(activeUsers(count: 37));
        break;
      case 'disk_alert':
        buffer.write(diskAlert(free: '96 MiB', total: '128 MiB', percentFree: 75));
        break;
      case 'daily_summary':
        buffer.write(dailySummary(
          cardsCount: 24,
          total: 4800,
          activeUsers: 37,
          routerUptime: '12d 4h',
          offlineDevices: 2,
        ));
        break;
      default:
        buffer.write("ميزة غير معروفة: <code>$featureId</code>");
    }
    return buffer.toString();
  }

  /// تلميح للرسالة النهائية عند عدم تفعيل أي ميزة.
  static const String noFeaturesEnabled =
      "لم تُفعّل أي ميزة — فعّل ميزة واحدة على الأقل من شاشة «تفعيل المميزات»";
}
