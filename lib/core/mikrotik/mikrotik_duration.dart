/// محلّل مدد RouterOS — يحوّل صيغ مثل `1w2d3h4m5s` أو `1w2d03:04:05` إلى [Duration].
///
/// الصيغ المدعومة:
/// - `1w2d3h4m5s` (اسابيع/أيام/ساعات/دقائق/ثوانٍ، أي ترتيب وأي مجموعة)
/// - `1w2d03:04:05` و `03:04:05` و `1:02:03:04` (يوم ثم ساعة:دقيقة:ثانية)
/// - `3600` (ثوانٍ صحيحة)
/// - `0s` و `00:00:00` و `0` ← صفر
///
/// **قاعدة الأمان:** أي صيغة غير مفهومة أو مُلتبسة تُعيد `null` (لا نخمّن أبدًا)،
/// وبذلك تُستبعد من عمليات الحذف التلقائي.
class MikrotikDuration {
  const MikrotikDuration._();

  static final RegExp _unitTokens = RegExp(r'(\d+)\s*([wdhms])');
  static final RegExp _pureDigits = RegExp(r'^\d+$');
  static final RegExp _colonTail = RegExp(r'^(.*?)(\d{1,4}(?::\d{1,2}){2,3})$');

  /// تحويل نص مدة RouterOS إلى [Duration]، أو `null` إن لم يمكن تحليله بأمان.
  static Duration? parse(String? raw) {
    if (raw == null) return null;

    final text = raw.trim().toLowerCase().replaceAll(',', '');
    if (text.isEmpty) return null;

    // صيغة الساعة:دقيقة:ثانية (مع بادئة أسابيع/أيام اختيارية)
    if (text.contains(':')) {
      return _parseColon(text);
    }

    // أرقام صحيحة فقط ← ثوانٍ
    if (_pureDigits.hasMatch(text)) {
      return Duration(seconds: int.tryParse(text) ?? 0);
    }

    // صيغة الرموز: 1w2d3h4m5s
    return _parseUnitTokens(text);
  }

  static Duration? _parseColon(String text) {
    final compact = text.replaceAll(' ', '');
    final match = _colonTail.firstMatch(compact);
    if (match == null) return null;

    final prefix = match.group(1) ?? '';
    final clock = match.group(2) ?? '';
    final parts = clock.split(':').map((part) => int.tryParse(part) ?? -1).toList();

    // رفض أي جزء غير رقمي
    if (parts.any((value) => value < 0)) return null;

    Duration clockDuration;
    if (parts.length == 3) {
      // ساعة:دقيقة:ثانية
      clockDuration = Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    } else if (parts.length == 4) {
      // يوم:ساعة:دقيقة:ثانية
      clockDuration = Duration(
        days: parts[0],
        hours: parts[1],
        minutes: parts[2],
        seconds: parts[3],
      );
    } else {
      // جزءان ← مُلتبس (ساعة:دقيقة أم دقيقة:ثانية؟) نرفضه بدل التخمين
      return null;
    }

    if (prefix.isEmpty) return clockDuration;

    // بادئة مثل 1w2d
    final prefixDuration = _parseUnitTokens(prefix);
    if (prefixDuration == null) return null;

    return prefixDuration + clockDuration;
  }

  static Duration? _parseUnitTokens(String text) {
    final compact = text.replaceAll(' ', '');
    if (compact.isEmpty) return null;

    var consumed = 0;
    var totalSeconds = 0;

    for (final match in _unitTokens.allMatches(compact)) {
      // يجب أن تكون الرموز متتالية بلا فراغات غريبة
      if (match.start != consumed) return null;
      consumed = match.end;

      final value = int.tryParse(match.group(1) ?? '');
      if (value == null) return null;

      switch (match.group(2)) {
        case 'w':
          totalSeconds += value * 7 * 24 * 3600;
          break;
        case 'd':
          totalSeconds += value * 24 * 3600;
          break;
        case 'h':
          totalSeconds += value * 3600;
          break;
        case 'm':
          totalSeconds += value * 60;
          break;
        case 's':
          totalSeconds += value;
          break;
        default:
          return null;
      }
    }

    if (consumed != compact.length) return null; // بقايا غير مفهومة
    return Duration(seconds: totalSeconds);
  }

  /// تنسيق مدة بصيغة RouterOS المختصرة: `1w2d3h4m5s`.
  static String format(Duration duration) {
    var seconds = duration.inSeconds;
    if (seconds <= 0) return "0s";

    final weeks = seconds ~/ (7 * 24 * 3600);
    seconds -= weeks * 7 * 24 * 3600;
    final days = seconds ~/ (24 * 3600);
    seconds -= days * 24 * 3600;
    final hours = seconds ~/ 3600;
    seconds -= hours * 3600;
    final minutes = seconds ~/ 60;
    seconds -= minutes * 60;

    final buffer = StringBuffer();
    if (weeks > 0) buffer.write('${weeks}w');
    if (days > 0) buffer.write('${days}d');
    if (hours > 0) buffer.write('${hours}h');
    if (minutes > 0) buffer.write('${minutes}m');
    if (seconds > 0) buffer.write('${seconds}s');
    return buffer.isEmpty ? "0s" : buffer.toString();
  }
}

/// مقارنة ذكية بين المدة المستهلكة والحد المسموح.
class UptimeUsage {
  final Duration used;
  final Duration limit;

  const UptimeUsage({required this.used, required this.limit});

  /// هل استهلك المستخدم مدته كاملة؟ (هذا هو معيار الحذف)
  bool get isExhausted => limit > Duration.zero && used >= limit;

  Duration get remaining => limit - used;

  /// نسبة الاستهلاك (0.0 ← 1.0)، وقد تتجاوز 1 بقليل.
  double get ratio {
    final limitSeconds = limit.inSeconds;
    if (limitSeconds <= 0) return 0;
    return used.inSeconds / limitSeconds;
  }

  int get percent => (ratio * 100).clamp(0, 999).round();
}
