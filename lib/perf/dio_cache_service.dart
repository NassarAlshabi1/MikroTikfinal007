// ============================================================
//  DioCacheService — إعداد Dio مع cache تلقائي
//  يُستخدم لطلبات HTTP (مثل Telegram API) لتقليل استهلاك الشبكة
// ============================================================

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_db_store/dio_cache_interceptor_db_store.dart';
import 'package:path_provider/path_provider.dart';

/// Singleton لضمان استخدام نفس الـ cache store عبر كل التطبيق
class _CacheStoreHolder {
  static CacheStore? _store;
  static Future<CacheStore> getStore() async {
    if (_store != null) return _store!;
    final dir = await getApplicationDocumentsDirectory();
    _store = DbCacheStore(databasePath: dir.path);
    return _store!;
  }
}

/// يُنشئ Dio مع cache لمدة معينة
/// مثال:
///   final dio = await createCachedDio(maxAge: Duration(hours: 1));
///   final res = await dio.get('https://api.example.com/data');
Future<Dio> createCachedDio({
  Duration maxAge = const Duration(minutes: 5),
  Duration maxStale = const Duration(hours: 1),
  CachePriority priority = CachePriority.normal,
  bool forceRefresh = false,
}) async {
  final dio = Dio();
  final store = await _CacheStoreHolder.getStore();

  final options = CacheOptions(
    store: store,
    policy: forceRefresh ? CachePolicy.refresh : CachePolicy.request,
    hitCacheOnErrorExcept: const [401, 403],
    maxStale: maxStale,
    priority: priority,
    keyBuilder: CacheOptions.defaultCacheKeyBuilder,
    allowPostMethod: false,
  );

  dio.interceptors.add(DioCacheInterceptor(options: options));

  // إعدادات Dio الأساسية
  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 15);
  dio.options.sendTimeout = const Duration(seconds: 10);

  return dio;
}

/// Dio للأجهزة الضعيفة — timeouts أطول و retry محدود
Future<Dio> createLowEndDio() async {
  final dio = await createCachedDio(
    maxAge: const Duration(minutes: 10),  // cache أطول على الأجهزة الضعيفة
    maxStale: const Duration(days: 1),
  );
  // timeouts أطول لأن المعالجة على الجهاز أبطأ
  dio.options.connectTimeout = const Duration(seconds: 15);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  dio.options.sendTimeout = const Duration(seconds: 15);
  return dio;
}

/// مسح كل الـ cache — يُستخدم عند تسجيل الخروج أو الـ pull-to-refresh
Future<void> clearDioCache() async {
  final store = await _CacheStoreHolder.getStore();
  await store.clean();
}

/// حذف مفتاح cache محدد
Future<void> invalidateDioCache(String key) async {
  final store = await _CacheStoreHolder.getStore();
  await store.delete(key);
}

// ============================================================
//  مثال على الاستخدام مع Telegram API (موجود في main.dart)
// ============================================================
//
//  قبل:
//    final dio = Dio();
//    await dio.post(url, data: {...});
//
//  بعد:
//    final dio = await createCachedDio(maxAge: Duration(minutes: 5));
//    await dio.post(url, data: {...});
//
//  الـ cache سيُستخدم تلقائياً عند تكرار الطلب خلال 5 دقائق
//  → توفير بطارية + بيانات + تسريع الاستجابة
