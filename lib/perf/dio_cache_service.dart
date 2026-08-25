// ============================================================
// DioCacheService — bounded in-memory HTTP cache.
// The previous persistent stores were removed to keep the Android native
// dependency set single-sourced and avoid cache data outliving credentials.
// ============================================================

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

class _CacheStoreHolder {
  static CacheStore? _store;
  static Future<CacheStore>? _opening;

  static Future<CacheStore> getStore() {
    final current = _store;
    if (current != null) return Future.value(current);

    return _opening ??= _open().then(
      (store) {
        _store = store;
        _opening = null;
        return store;
      },
      onError: (Object error, StackTrace stackTrace) {
        _opening = null;
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }

  static Future<CacheStore> _open() async {
    return MemCacheStore();
  }

  static Future<void> close() async {
    final store = _store;
    _store = null;
    _opening = null;
    await store?.close();
  }
}

/// Creates a Dio client with persistent HTTP caching.
///
/// `maxStale` controls how long an expired cached response may still be used.
/// Freshness itself follows the server's HTTP cache directives.
Future<Dio> createCachedDio({
  Duration maxStale = const Duration(hours: 1),
  CachePriority priority = CachePriority.normal,
  bool forceRefresh = false,
}) async {
  final dio = Dio();
  final store = await _CacheStoreHolder.getStore();

  final options = CacheOptions(
    store: store,
    policy: forceRefresh ? CachePolicy.refresh : CachePolicy.request,
    maxStale: maxStale,
    priority: priority,
    keyBuilder: CacheOptions.defaultCacheKeyBuilder,
    allowPostMethod: false,
  );

  dio.interceptors.add(DioCacheInterceptor(options: options));

  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 15);
  dio.options.sendTimeout = const Duration(seconds: 10);

  return dio;
}

Future<Dio> createLowEndDio() {
  return createCachedDio(
    maxStale: const Duration(days: 1),
  ).then((dio) {
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 15);
    return dio;
  });
}

Future<void> clearDioCache() async {
  final store = await _CacheStoreHolder.getStore();
  await store.clean();
}

Future<void> invalidateDioCache(String key) async {
  final store = await _CacheStoreHolder.getStore();
  await store.delete(key);
}

/// Call during application shutdown/tests.
Future<void> closeDioCache() => _CacheStoreHolder.close();
