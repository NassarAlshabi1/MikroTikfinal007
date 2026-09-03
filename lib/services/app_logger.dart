// ============================================================
//  AppLogger — نظام تسجيل موحّد بدل print() / debugPrint()
//
//  تطبّق معايير المهارات:
//  ✅ flutter-security: "STRICTLY prohibit print(). Use AppLogger."
//  ✅ flutter-apply-architecture: "STRICTLY prohibit print(). Use AppLogger."
//  ✅ flutter-debugging: structured logs + levels + filtering
//
//  المميزات:
//  - مستويات: debug, info, warning, error, security
//  - تصنيفات: network, ui, ai, security, storage, system
//  - لا يسجّل القيم الحساسة (passwords, API keys, tokens)
//  - redact تلقائي للأنماط الحساسة
//  - وضع release: يُسجّل info+ فقط (لا debug)
//  - وضع debug: يُسجّل كل شيء
// ============================================================

import 'package:flutter/foundation.dart';

/// مستوى السجل
enum LogLevel {
  debug, // ⚪ تتبع — يُسجّل فقط في وضع debug
  info, // 🟢 معلومات عامة
  warning, // 🟡 تحذير
  error, // 🔴 خطأ
  security, // 🔒 حدث أمني (دائماً يُسجّل)
}

extension LogLevelX on LogLevel {
  String get emoji {
    switch (this) {
      case LogLevel.debug:
        return '⚪';
      case LogLevel.info:
        return '🟢';
      case LogLevel.warning:
        return '🟡';
      case LogLevel.error:
        return '🔴';
      case LogLevel.security:
        return '🔒';
    }
  }

  String get label {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.security:
        return 'SECURITY';
    }
  }
}

/// تصنيف السجل
enum LogCategory {
  network, // اتصالات MikroTik + SSH
  ui, // واجهة المستخدم
  ai, // AI diagnostics + LLM calls
  security, // عمليات أمنية
  storage, // تخزين محلي
  system, // نظام + lifecycle
  other,
}

extension LogCategoryX on LogCategory {
  String get tag {
    switch (this) {
      case LogCategory.network:
        return 'NET';
      case LogCategory.ui:
        return 'UI';
      case LogCategory.ai:
        return 'AI';
      case LogCategory.security:
        return 'SEC';
      case LogCategory.storage:
        return 'STORE';
      case LogCategory.system:
        return 'SYS';
      case LogCategory.other:
        return 'GEN';
    }
  }
}

/// نظام التسجيل الموحّد
class AppLogger {
  AppLogger._();

  /// الحد الأدنى للمستوى المُسجَّل
  /// في release: info+
  /// في debug: debug+
  static LogLevel get _minLevel =>
      kReleaseMode ? LogLevel.info : LogLevel.debug;

  /// أنماط حساسة يجب إخفاؤها من السجلات
  /// (كلمات مرور، API keys، tokens، bearer tokens)
  /// ملاحظة: نستخدم raw string triple-quoted لتجنّب مشاكل escape
  static final List<RegExp> _sensitivePatterns = [
    RegExp(r"""(api[_-]?key\s*[=:]\s*)["']?[\w-]+""", caseSensitive: false),
    RegExp(r"""(password\s*[=:]\s*)["']?[^\s"']+""", caseSensitive: false),
    RegExp(r"""(pass\s*[=:]\s*)["']?[^\s"']+""", caseSensitive: false),
    RegExp(r"""(token\s*[=:]\s*)["']?[\w.-]+""", caseSensitive: false),
    RegExp(r"""(bearer\s+)[\w.-]+""", caseSensitive: false),
    RegExp(r"""(authorization\s*[:=]\s*)["']?[\w.-]+""", caseSensitive: false),
    // API key format: api-xxxxxxxxxxxxxxxxxxxx
    RegExp(r"""\bapi-[a-f0-9]{40,}\b""", caseSensitive: false),
    // JWT
    RegExp(r"""\beyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\b"""),
  ];

  /// يخفي البيانات الحساسة من نص السجل
  static String _redact(String message) {
    var redacted = message;
    for (final pattern in _sensitivePatterns) {
      redacted = redacted.replaceAllMapped(pattern, (match) {
        // أبقي اسم الحقل إن وُجد، أخفي القيمة
        // تحقق إن كان الـ pattern يحتوي على capture group
        if (match.groupCount >= 1) {
          final prefix = match.group(1);
          if (prefix != null) {
            return '$prefix[REDACTED]';
          }
        }
        return '[REDACTED]';
      });
    }
    return redacted;
  }

  /// يسجّل رسالة بمستوى وتصنيف محدد
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    LogCategory category = LogCategory.other,
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (level.index < _minLevel.index) return;

    final redacted = _redact(message);
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final tagStr = tag != null ? '[$tag]' : '';
    final buffer = StringBuffer()
      ..write(timestamp)
      ..write(' ')
      ..write(level.emoji)
      ..write(' [')
      ..write(category.tag)
      ..write(']')
      ..write(tagStr)
      ..write(' ')
      ..write(redacted);

    if (error != null) {
      buffer.write(' | error: ${_redact(error.toString())}');
    }
    if (stackTrace != null && level == LogLevel.error) {
      buffer.write('\n$stackTrace');
    }

    // استخدم debugPrint لتفادي مشاكل الـ buffering
    debugPrint(buffer.toString());
  }

  // ============================================================
  //  اختصارات للوصول السريع
  // ============================================================

  /// سجل debug (يُسجَّل فقط في وضع debug)
  static void debug(String message,
          {LogCategory category = LogCategory.other, String? tag}) =>
      log(message, level: LogLevel.debug, category: category, tag: tag);

  /// سجل info
  static void info(String message,
          {LogCategory category = LogCategory.other, String? tag}) =>
      log(message, level: LogLevel.info, category: category, tag: tag);

  /// سجل warning
  static void warning(String message,
          {LogCategory category = LogCategory.other, String? tag}) =>
      log(message, level: LogLevel.warning, category: category, tag: tag);

  /// سجل error (مع stackTrace اختياري)
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogCategory category = LogCategory.other,
    String? tag,
  }) =>
      log(message,
          level: LogLevel.error,
          category: category,
          error: error,
          stackTrace: stackTrace,
          tag: tag);

  /// سجل security (دائماً يُسجَّل، حتى في release)
  static void security(String message, {String? tag}) => log(message,
      level: LogLevel.security, category: LogCategory.security, tag: tag);
}
