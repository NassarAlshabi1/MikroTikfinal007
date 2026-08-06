// ============================================================
//  IsarProvider — Singleton لإدارة مثيل Isar
//
//  المميزات:
//  - singleton حي طوال عمر التطبيق
//  - تهيئة lazy (لا تُفتح قاعدة البيانات إلا عند الحاجة)
//  - دعم الاختبارات (يُحقن instance مخصص)
//  - دعم Web (Isar في الـ browser)
// ============================================================

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'isar/card_collection.dart';
import 'isar/profile_collection.dart';
import 'isar/ai_diagnostic_collection.dart';
import 'isar/executed_command_collection.dart';

/// Singleton لإدارة مثيل Isar
class IsarProvider {
  IsarProvider._();
  static final IsarProvider _instance = IsarProvider._();
  factory IsarProvider() => _instance;

  Isar? _isar;

  /// المثيل الحالي (يُنشأ تلقائياً عند أول استخدام)
  Future<Isar> get instance async {
    if (_isar != null) return _isar!;
    _isar = await _openIsar();
    return _isar!;
  }

  /// المثيل الحالي دون إنشاء (يُرجع null إن لم يُفتح بعد)
  Isar? get maybeInstance => _isar;

  /// فتح قاعدة بيانات Isar جديدة
  Future<Isar> _openIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [
        CardCollectionSchema,
        ProfileCollectionSchema,
        AiDiagnosticCollectionSchema,
        ExecutedCommandCollectionSchema,
      ],
      directory: dir.path,
      inspector: true,
    );
  }

  /// للـ testing — يسمح بحقن instance مخصص (in-memory)
  void setTestInstance(Isar isar) {
    _isar = isar;
  }

  /// إغلاق قاعدة البيانات
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
