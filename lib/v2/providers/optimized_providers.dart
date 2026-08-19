// ============================================================
//  Providers محسّنة للأداء — باستخدام select() و keepAlive
//  تُستخدم في الشاشات الجديدة (V2) لتقليل إعادة البناء
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/router_service.dart';

/// Cache بسيط في الذاكرة لآخر استجابة لكل path
/// يمنع إعادة الجلب عند الـ scroll وإعادة بناء الشاشة
class ResponseCache {
  ResponseCache._();
  static final ResponseCache instance = ResponseCache._();

  final Map<String, _CacheEntry> _cache = {};

  List<Map<String, dynamic>>? get(String key) {
    final e = _cache[key];
    if (e == null) return null;
    if (DateTime.now().difference(e.time) > const Duration(minutes: 2)) {
      _cache.remove(key);
      return null;
    }
    return e.data;
  }

  void put(String key, List<Map<String, dynamic>> data) {
    // حدّ الذاكرة: 50 مفتاح
    if (_cache.length > 50) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = _CacheEntry(data, DateTime.now());
  }

  void invalidate(String key) => _cache.remove(key);
  void clear() => _cache.clear();
}

class _CacheEntry {
  final List<Map<String, dynamic>> data;
  final DateTime time;
  _CacheEntry(this.data, this.time);
}

/// Provider لـ cache — يبقى حياً طوال الجلسة
final responseCacheProvider = Provider<ResponseCache>((ref) {
  return ResponseCache.instance;
});

/// Provider للاتصال — Singleton
final routerServiceProvider = Provider<RouterService>((ref) {
  return RouterService();
});

/// عينة سريعة فقط لأول N عنصر — للأجهزة الضعيفة
/// مثال: بدلاً من جلب 50 مستخدم، نعرض أول 20 فقط
final compactModeProvider = Provider<bool>((ref) {
  // يمكن ربطه بالـ DeviceCapability لاحقاً
  return true;
});
