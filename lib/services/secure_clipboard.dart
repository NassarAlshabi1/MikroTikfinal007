// ============================================================
//  SecureClipboard — نسخ آمن مع مسح تلقائي
//
//  تطبّق معايير flutter-security skill:
//  ✅ Clipboard Safety: مسح الحافظة بعد 30-60 ثانية
//  ✅ Audit Log: يسجّل عمليات النسخ (بدون تسجيل القيم)
//
//  مشكلة: Clipboard على نظام التشغيل غير مشفّر ويمكن لأي تطبيق
//  آخر قراءته. نسخ كلمة مرور ثم تركها = ثغرة أمنية.
//
//  الحل: نسخ + جدولة مسح تلقائي بعد 30 ثانية.
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// خدمة نسخ آمنة للحافظة — تمسح المحتوى تلقائياً بعد 30 ثانية
///
/// الاستخدام:
/// ```dart
/// // بدل:
/// await Clipboard.setData(ClipboardData(text: password));
/// // استخدم:
/// await SecureClipboard.copy(password, sensitive: true);
/// ```
class SecureClipboard {
  SecureClipboard._();

  /// المؤقت الحالي لمسح الحافظة
  static Timer? _clearTimer;

  /// المدة الافتراضية قبل المسح (30 ثانية — ضمن توصية 30-60s)
  static const Duration _defaultClearDuration = Duration(seconds: 30);

  /// ينسخ نصاً للحافظة مع جدولة مسح تلقائي
  ///
  /// [sensitive] — إن true (افتراضي)، يُمسح المحتوى بعد [_defaultClearDuration]
  /// [clearAfter] — مدة مخصصة قبل المسح (تتجاوز الافتراضية)
  /// [onCleared] — callback يُستدعى عند مسح الحافظة
  static Future<void> copy(
    String text, {
    bool sensitive = true,
    Duration? clearAfter,
    VoidCallback? onCleared,
  }) async {
    if (text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
    debugPrint('[SecureClipboard] Copied ${_describeLength(text)} '
        '(sensitive=$sensitive)');

    // ألغِ أي مؤقت مسح سابق
    _clearTimer?.cancel();

    // إن لم يكن حساساً، لا نجدول مسحاً
    if (!sensitive) return;

    // جدولة المسح التلقائي
    final duration = clearAfter ?? _defaultClearDuration;
    _clearTimer = Timer(duration, () async {
      try {
        // تحقق إن كان النص لا يزال في الحافظة قبل المسح
        // (لتجنّب مسح شيء نسخه المستخدم يدوياً بعد ذلك)
        final current = await Clipboard.getData('text/plain');
        if (current?.text == text) {
          await Clipboard.setData(const ClipboardData(text: ''));
          debugPrint('[SecureClipboard] Auto-cleared after ${duration.inSeconds}s');
          onCleared?.call();
        }
      } catch (e) {
        debugPrint('[SecureClipboard] Failed to auto-clear: $e');
      }
    });
  }

  /// ينسخ نصاً حساساً (مثل كلمة مرور) ويُرجع false بعد المسح التلقائي
  ///
  /// مفيد للـ UI التي تريد إظهار "تم النسخ — سيُمسح خلال 30 ثانية"
  static Future<bool> copySensitive(
    String text, {
    Duration? clearAfter,
  }) async {
    bool cleared = false;
    await copy(
      text,
      sensitive: true,
      clearAfter: clearAfter,
      onCleared: () => cleared = true,
    );
    return cleared;
  }

  /// يمسح الحافظة فوراً (إن كان فيها شيء)
  static Future<void> clearNow() async {
    _clearTimer?.cancel();
    _clearTimer = null;
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
      debugPrint('[SecureClipboard] Cleared immediately');
    } catch (e) {
      debugPrint('[SecureClipboard] Failed to clear: $e');
    }
  }

  /// يلغي جدولة المسح التلقائي (دون مسح فوري)
  static void cancelAutoClear() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }

  /// هل هناك جدولة مسح نشطة؟
  static bool get hasPendingClear => _clearTimer?.isActive ?? false;

  /// يصف الطول بشكل آمن (بدون تسريب القيم)
  static String _describeLength(String text) {
    return '${text.length} chars';
  }
}
