/// **منطق فحص صحة الشبكة** — دوال نقية قابلة للاختبار بلا أي اتصال أو حالة.
///
/// يُستعمل في:
///  • فاحص Netwatch (هل وصل رد الـping؟).
///  • تنبيه مساحة التخزين (نسبة الحرة من الإجمالي).
class TelegramHealth {
  const TelegramHealth._();

  /// نسبة الحرة تحت هذا الحد تُطلق تنبيه المساحة.
  static const double diskWarnPercent = 15.0;

  /// تحويل حجم RouterOS النصّي إلى بايت.
  ///
  /// يقبل: `96 MiB` · `1.5GiB` · `2048 KiB` · `512 B` · `1073741824` (رقم مجرّد).
  /// أي صيغة غير مفهومة ⇒ `null` (لا تخمين).
  static double? parseSize(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    // رقم مجرّد (بايت)
    final plain = double.tryParse(text);
    if (plain != null) return plain;

    final match = RegExp(r'^([0-9]+(?:\.[0-9]+)?)\s*([KMGT]?)i?B?$',
            caseSensitive: false)
        .firstMatch(text);
    if (match == null) return null;

    final value = double.tryParse(match.group(1)!);
    if (value == null) return null;

    const factors = <String, double>{
      '': 1,
      'K': 1024,
      'M': 1024 * 1024,
      'G': 1024 * 1024 * 1024,
      'T': 1024 * 1024 * 1024 * 1024,
    };

    final unit = (match.group(2) ?? '').toUpperCase();
    final factor = factors[unit];
    if (factor == null) return null;
    return value * factor;
  }

  /// نسبة الحرة (%) — `null` إذا تعذّر الفهم أو كان الإجمالي صفرًا.
  static double? freePercent(String free, String total) {
    final freeBytes = parseSize(free);
    final totalBytes = parseSize(total);
    if (freeBytes == null || totalBytes == null || totalBytes <= 0) return null;
    return (freeBytes / totalBytes) * 100;
  }

  /// هل يستحق تنبيه مساحة؟ (الصيغة غير المفهومة ⇒ لا تنبيه ولا تخمين)
  static bool needsDiskAlert(
    String free,
    String total, {
    double threshold = diskWarnPercent,
  }) {
    final percent = freePercent(free, total);
    if (percent == null) return false;
    return percent < threshold;
  }

  /// هل نجح الـping؟ اعتمادًا على صفوف رد RouterOS:
  /// `received=1` ⇒ وصل · `status=timeout` ⇒ لم يصل · `time` موجود بلا status ⇒ وصل.
  static bool pingReachable(List<Map<String, String>> rows) {
    for (final row in rows) {
      final received = int.tryParse((row['received'] ?? '').trim());
      if (received != null && received > 0) return true;

      final status = (row['status'] ?? '').trim().toLowerCase();
      if (status.contains('timeout') || status.contains('unreachable')) {
        // صف صريح بالفشل ⇒ نكمل (قد يأتي صف نجاح بعده) لكن لا نعتبره نجاحًا
        continue;
      }
      if (status.isEmpty && (row['time'] ?? '').trim().isNotEmpty) return true;
    }
    return false;
  }
}
