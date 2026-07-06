// ============================================================
//  DioCacheService — إعداد Dio مع cache تلقائي
//  يُستخدم لطلبات HTTP (مثل Telegram API) لتقليل استهلاك الشبكة
// ============================================================
//
//  ملاحظة: هذا الملف يعمل كقالب. لإضافة dio_cache_interceptor فعلياً
//  أضف إلى pubspec.yaml:
//
//  dependencies:
//    dio_cache_interceptor: ^3.5.0
//    dio_cache_interceptor_db_store: ^5.1.0
//
//  ثم ألغِ التعليقات من الكود أدناه.

import 'package:dio/dio.dart';

/// يُنشئ Dio مع cache لمدة معينة
/// مثال:
///   final dio = createCachedDio(maxAge: Duration(hours: 1));
///   final res = await dio.get('https://api.example.com/data');
Dio createCachedDio({
  Duration maxAge = const Duration(minutes: 5),
  Duration maxStale = const Duration(hours: 1),
}) {
  final dio = Dio();

  // TODO: أضف dio_cache_interceptor بعد إضافته لـ pubspec.yaml
  // dio.interceptors.add(DioCacheManager(
  //   CacheConfig(
  //     defaultMaxAge: maxAge,
  //     defaultMaxStale: maxStale,
  //   ),
  // ).interceptor);

  // إعدادات Dio الأساسية
  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 15);
  dio.options.sendTimeout = const Duration(seconds: 10);

  return dio;
}

/// Dio للأجهزة الضعيفة — timeouts أطول و retry محدود
Dio createLowEndDio() {
  final dio = Dio();
  // timeouts أطول لأن المعالجة على الجهاز أبطأ
  dio.options.connectTimeout = const Duration(seconds: 15);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  dio.options.sendTimeout = const Duration(seconds: 15);
  return dio;
}
