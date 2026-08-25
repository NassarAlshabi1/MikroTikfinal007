//  IsarProvider — Singleton لإدارة مثيل Isar
//
//  المميزات:
//  - singleton حي طوال عمر التطبيق
//  - تهيئة lazy مع حماية من استدعاءات الفتح المتزامنة
//  - دعم الاختبارات (يُحقن instance مخصص)
//  - إعداد directory متوافق مع Web والمنصات الأصلية
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'isar/ai_diagnostic_collection.dart';
import 'isar/card_collection.dart';
import 'isar/card_generation_job.dart';
import 'isar/executed_command_collection.dart';
import 'isar/profile_collection.dart';

/// Singleton لإدارة مثيل Isar.
class IsarProvider {
  IsarProvider._();
  static final IsarProvider _instance = IsarProvider._();
  factory IsarProvider() => _instance;

  Isar? _isar;
  Future<Isar>? _opening;

  /// المثيل الحالي؛ يضمن مشاركة عملية الفتح بين كل المستدعين المتزامنين.
  Future<Isar> get instance {
    final current = _isar;
    if (current != null) return Future<Isar>.value(current);

    return _opening ??= _openIsar().then(
      (opened) {
        _isar = opened;
        _opening = null;
        return opened;
      },
      onError: (Object error, StackTrace stackTrace) {
        _opening = null;
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }

  /// المثيل الحالي دون إنشاء؛ يُرجع null إن لم يُفتح بعد.
  Isar? get maybeInstance => _isar;

  /// فتح قاعدة بيانات Isar جديدة.
  Future<Isar> _openIsar() async {
    const schemas = [
      CardCollectionSchema,
      CardGenerationJobSchema,
      ProfileCollectionSchema,
      AiDiagnosticCollectionSchema,
      ExecutedCommandCollectionSchema,
    ];

    final directory =
        kIsWeb ? '' : (await getApplicationDocumentsDirectory()).path;

    return Isar.open(
      schemas,
      directory: directory,
      inspector: kDebugMode,
    );
  }

  /// للـ testing — يسمح بحقن instance مخصص (in-memory).
  void setTestInstance(Isar isar) {
    _opening = null;
    _isar = isar;
  }

  /// إغلاق قاعدة البيانات وإلغاء حالة الفتح الحالية.
  Future<void> close() async {
    final current = _isar;
    _isar = null;
    _opening = null;
    await current?.close();
  }
}
