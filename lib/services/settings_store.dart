import '../api/database_api.dart';

/// مخزن إعدادات بسيط (مفتاح/قيمة) فوق قاعدة بيانات SQLite المحلية.
///
/// استُخدم بدل SharedPreferences لتقليل الاعتماديات، ويُخزَّن فيه
/// مفتاح التشفير الخاص بـ SecureStore وبقية إعدادات التطبيق.
class SettingsStore {
  static const String _table = "app_settings";

  static String _escape(String value) => value.replaceAll("'", "''");

  static Future<String?> get(String key) async {
    try {
      final rows = await DBApi.select(_table, "key='${_escape(key)}'", "value", null, "1");
      if (rows.isEmpty) return null;
      final row = rows.first;
      if (row is! Map) return null;
      final value = row["value"];
      return value?.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<void> set(String key, String value) async {
    try {
      await DBApi.execute(
        "INSERT OR REPLACE INTO $_table (key, value) VALUES "
        "('${_escape(key)}', '${_escape(value)}')",
      );
    } catch (_) {
      // لا نُفشل العملية إن تعذّر الحفظ
    }
  }

  static Future<void> remove(String key) async {
    try {
      await DBApi.delete(_table, "key='${_escape(key)}'");
    } catch (_) {
      // تجاهل
    }
  }
}
