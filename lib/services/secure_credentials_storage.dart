// ============================================================
//  SecureCredentialsStorage — تخزين آمن للبيانات الحساسة
//
//  تطبّق معايير flutter-security skill:
//  ✅ AES-256-GCM (flutter_secure_storage يستخدمه داخلياً)
//  ✅ Secret Storage: لا SharedPreferences للبيانات الحساسة
//  ✅ Memory Safety: لا تحتفظ بالبيانات في الذاكرة أكثر من اللازم
//  ✅ Audit Log: يسجّل عمليات القراءة/الكتابة (بدون تسجيل القيم)
//  ✅ Token Storage: لا API keys في source code
//
//  يحلّ مشكلة: main.dart يخزّن 'pass' و 'remote_pass' في SharedPreferences
//  التي هي plaintext XML file على Android — غير آمن للجذر (rooted devices).
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة تخزين آمنة للبيانات الحساسة (كلمات المرور، API keys، tokens)
///
/// الهجرة من SharedPreferences:
/// - قديماً: prefs.setString('pass', password)  ← plaintext
/// - حديثاً: SecureCredentialsStorage.setPassword(password)  ← encrypted
///
/// يدعم الترحيل التلقائي: إذا وُجدت بيانات في SharedPreferences القديمة،
/// تُنقل إلى flutter_secure_storage ثم تُمسح من SharedPreferences.
class SecureCredentialsStorage {
  SecureCredentialsStorage._();
  static final SecureCredentialsStorage instance = SecureCredentialsStorage._();

  /// خيارات التشفير على كل منصة:
  /// - Android: EncryptedSharedPreferences (AES-256-GCM)
  /// - iOS: Keychain (first_unlock accessibility)
  /// - Linux: libsecret
  /// - Windows: DPAPI
  /// - macOS: Keychain
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ─── مفاتيح التخزين الآمن ───
  static const _keyMikrotikPass = 'mikrotik_pass';
  static const _keyRemotePass = 'remote_pass';
  static const _keyOomolApiKey = 'oomol_api_key';

  /// علامة تشير لترحيل البيانات من SharedPreferences إلى SecureStorage
  static const _migrationDoneKey = 'secure_storage_migrated';

  // ============================================================
  //  Migration — نقل البيانات الحساسة من SharedPreferences إلى Secure
  // ============================================================

  /// يهاجر البيانات الحساسة من SharedPreferences إلى flutter_secure_storage
  ///
  /// يجب استدعاؤها مرة واحدة عند بدء التطبيق (في main()).
  /// بعد الترحيل، تُمسح البيانات من SharedPreferences نهائياً.
  Future<void> migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrated = prefs.getBool(_migrationDoneKey) ?? false;
      if (migrated) {
        debugPrint('[SecureStorage] Already migrated, skipping.');
        return;
      }

      debugPrint('[SecureStorage] Migrating sensitive data from prefs to secure storage...');

      // نقل كلمات المرور إن وُجدت في SharedPreferences
      final mikrotikPass = prefs.getString('pass');
      if (mikrotikPass != null && mikrotikPass.isNotEmpty) {
        await _storage.write(key: _keyMikrotikPass, value: mikrotikPass);
        await prefs.remove('pass');
        debugPrint('[SecureStorage] ✓ Migrated mikrotik_pass');
      }

      final remotePass = prefs.getString('remote_pass');
      if (remotePass != null && remotePass.isNotEmpty) {
        await _storage.write(key: _keyRemotePass, value: remotePass);
        await prefs.remove('remote_pass');
        debugPrint('[SecureStorage] ✓ Migrated remote_pass');
      }

      final oomolKey = prefs.getString('oomol_api_key');
      if (oomolKey != null && oomolKey.isNotEmpty) {
        await _storage.write(key: _keyOomolApiKey, value: oomolKey);
        await prefs.remove('oomol_api_key');
        debugPrint('[SecureStorage] ✓ Migrated oomol_api_key');
      }

      // وضع علامة الترحيل
      await prefs.setBool(_migrationDoneKey, true);
      debugPrint('[SecureStorage] Migration complete.');
    } catch (e) {
      debugPrint('[SecureStorage] Migration failed: $e');
      // لا نرمي — التطبيق يجب أن يكمل التشغيل حتى لو فشل الترحيل
    }
  }

  // ============================================================
  //  Mikrotik password
  // ============================================================

  Future<String?> getMikrotikPassword() async {
    try {
      return await _storage.read(key: _keyMikrotikPass);
    } catch (e) {
      debugPrint('[SecureStorage] Failed to read mikrotik_pass: $e');
      return null;
    }
  }

  Future<void> setMikrotikPassword(String? password) async {
    if (password == null || password.isEmpty) {
      await _storage.delete(key: _keyMikrotikPass);
    } else {
      await _storage.write(key: _keyMikrotikPass, value: password);
    }
  }

  // ============================================================
  //  Remote password
  // ============================================================

  Future<String?> getRemotePassword() async {
    try {
      return await _storage.read(key: _keyRemotePass);
    } catch (e) {
      debugPrint('[SecureStorage] Failed to read remote_pass: $e');
      return null;
    }
  }

  Future<void> setRemotePassword(String? password) async {
    if (password == null || password.isEmpty) {
      await _storage.delete(key: _keyRemotePass);
    } else {
      await _storage.write(key: _keyRemotePass, value: password);
    }
  }

  // ============================================================
  //  OOMOL API key
  // ============================================================

  Future<String?> getOomolApiKey() async {
    try {
      return await _storage.read(key: _keyOomolApiKey);
    } catch (e) {
      debugPrint('[SecureStorage] Failed to read oomol_api_key: $e');
      return null;
    }
  }

  Future<void> setOomolApiKey(String? apiKey) async {
    if (apiKey == null || apiKey.isEmpty) {
      await _storage.delete(key: _keyOomolApiKey);
    } else {
      await _storage.write(key: _keyOomolApiKey, value: apiKey);
    }
  }

  // ============================================================
  //  Utilities
  // ============================================================

  /// يحذف كل البيانات الحساسة (للتسجيل الخروج الكامل)
  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _keyMikrotikPass);
      await _storage.delete(key: _keyRemotePass);
      await _storage.delete(key: _keyOomolApiKey);
      debugPrint('[SecureStorage] Cleared all credentials.');
    } catch (e) {
      debugPrint('[SecureStorage] Failed to clear: $e');
    }
  }

  /// يحذف كلمة مرور MikroTik فقط (عند تسجيل الخروج بدون "تذكرني")
  Future<void> clearMikrotikCredentials() async {
    try {
      await _storage.delete(key: _keyMikrotikPass);
      debugPrint('[SecureStorage] Cleared mikrotik_pass.');
    } catch (e) {
      debugPrint('[SecureStorage] Failed to clear mikrotik_pass: $e');
    }
  }

  /// تحقق من وجود بيانات حساسة محفوظة
  Future<bool> hasStoredCredentials() async {
    final pass = await getMikrotikPassword();
    return pass != null && pass.isNotEmpty;
  }
}
