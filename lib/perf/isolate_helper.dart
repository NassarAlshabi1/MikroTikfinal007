// ============================================================
//  IsolateHelper — تشغيل العمليات الثقيلة في isolate منفصل
//  يمنع تجميد الـ UI (Jank) على الأجهزة الضعيفة
// ============================================================

import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

/// تشغيل دالة ثقيلة في isolate منفصل (Flutter 3.7+)
/// مثال:
///   final json = await runInIsolate((data) => jsonDecode(data), bigString);
Future<R> runInIsolate<R, P>(
  R Function(P) computation,
  P parameter,
) async {
  // Isolate.run متاح من Flutter 3.7
  // يُنشئ isolate جديد لكل استدعاء، لكنه أسرع من compute() للعمليات الكبيرة
  try {
    return await Isolate.run(() => computation(parameter));
  } catch (e) {
    // في حال فشل الـ isolate (نادر)، نُشغّل في الـ main thread
    debugPrint('Isolate failed, fallback to main: $e');
    return computation(parameter);
  }
}

/// تشغيل دالة ثقيلة بدون parameter (لاقطات)
Future<R> runComputationInIsolate<R>(R Function() computation) async {
  try {
    return await Isolate.run(computation);
  } catch (e) {
    debugPrint('Isolate failed, fallback to main: $e');
    return computation();
  }
}

// ============================================================
//  حالات استخدام شائعة جاهزة
// ============================================================

/// فك تشفير JSON كبير في isolate
Future<dynamic> parseJsonInIsolate(String jsonString) {
  return runInIsolate((s) => jsonDecode(s), jsonString);
}

/// فك تشفير قائمة JSON كبيرة
Future<List<dynamic>> parseJsonListInIsolate(String jsonString) async {
  return (await parseJsonInIsolate(jsonString)) as List<dynamic>;
}

/// تحويل List<dynamic> إلى List<Map<String, dynamic>> في isolate
/// (مهم لاستجابات MikroTik التي قد تحتوي آلاف العناصر)
Future<List<Map<String, dynamic>>> castListInIsolate(List<dynamic> source) {
  return runInIsolate(
    (list) => list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false),
    source,
  );
}

/// ترتيب قائمة في isolate (مفيد لترتيب آلاف المستخدمين)
Future<List<T>> sortInIsolate<T>(List<T> items, int Function(T, T) compare) {
  return runInIsolate((list) {
    final copy = List<T>.from(list);
    copy.sort(compare);
    return copy;
  }, items);
}
