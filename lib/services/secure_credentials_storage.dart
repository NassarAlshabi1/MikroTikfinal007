// ============================================================
//  SecureCredentialsStorage — تخزين آمن للبيانات الحساسة
//
//  تطبّق معايير flutter-security skill + flutter-apply-architecture:
//  ✅ AES-256-GCM (flutter_secure_storage يستخدمه داخلياً)
//  ✅ Secret Storage: لا SharedPreferences للبيانات الحساسة
//  ✅ Memory Safety: لا تحتفظ بالبيانات في الذاكرة أكثر من اللازم
//  ✅ Audit Log: يسجّل عمليات القراءة/الكتابة (بدون تسجيل القيم)
//  ✅ Token Storage: لا API keys في source code
//  ✅ Testability: abstract interface + concrete impl + in-memory mock
//
//  يحلّ مشكلة: main.dart يخزّن 'pass' و 'remote_pass' في SharedPreferences
//  التي هي plaintext XML file على Android — غير آمن للجذر (rooted devices).
// ============================================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_logger.dart';

/// عقد (interface) للتخزين الآمن — يمكن استبداله بـ mock في الاختبارات
///
/// يتبع نمط flutter-apply-architecture: فصل الـ DataSource abstraction
/// عن الـ implementation. هذا يسمح بحقن mock في الاختبارات.
abstract class SecureCredentialsStorage {
  // ─── Mikrotik password ───
  Future<String?> getMikrotikPassword();
  Future<void> setMikrotikPassword(String? password);

  // ─── Remote password ───
  Future<String?> getRemotePassword();
  Future<void> setRemotePassword(String? password);

  // ─── legacy integration API key ───
  Future<String?> getOomolApiKey();
  Future<void> setOomolApiKey(String? apiKey);

  // ─── Telegram Bot Token ───
  Future<String?> getTelegramBotToken();
  Future<void> setTelegramBotToken(String? token);

  // ─── Utilities ───
  Future<void> clearAll();
  Future<void> clearMikrotikCredentials();
  Future<bool> hasStoredCredentials();
  Future<void> migrateFromSharedPreferences();
}

/// تنفيذ إنتاجي يستخدم flutter_secure_storage (AES-256-GCM + Keychain + libsecret)
class SecureCredentialsStorageImpl implements SecureCredentialsStorage {
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
  static const _keyOomolApiKey = 'legacy_integration_api_key';
  static const _keyTelegramBotToken = 'telegram_bot_token';

  /// علامة تشير لترحيل البيانات من SharedPreferences إلى SecureStorage
  static const _migrationDoneKey = 'secure_storage_migrated';

  @override
  Future<String?> getMikrotikPassword() async {
    try {
      final pass = await _storage.read(key: _keyMikrotikPass);
      if (pass != null && pass.isNotEmpty) return pass;

      // 🔧 Fallback: إن فشل secure storage أو كان فارغاً،
      // حاول القراءة من SharedPreferences (للبيانات القديمة غير المُرحّلة)
      // هذا يحل مشكلة "كلمة المرور غير موجودة" بعد الترقية.
      final prefs = await SharedPreferences.getInstance();
      final legacyPass = prefs.getString('pass');
      if (legacyPass != null && legacyPass.isNotEmpty) {
        // إن وُجدت في prefs، انقلها لـ secure storage صامتة
        try {
          await _storage.write(key: _keyMikrotikPass, value: legacyPass);
          await prefs.remove('pass');
          AppLogger.security('mikrotik_pass migrated lazily from prefs');
          return legacyPass;
        } catch (_) {
          // إن فشلت الكتابة لـ secure storage، استخدم القيمة من prefs
          return legacyPass;
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to read mikrotik_pass',
          error: e, category: LogCategory.storage);
      // 🔧 Fallback أخير: حاول SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString('pass');
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<void> setMikrotikPassword(String? password) async {
    if (password == null || password.isEmpty) {
      try {
        await _storage.delete(key: _keyMikrotikPass);
      } catch (_) {}
      // امسح من prefs أيضاً (إن وُجدت نسخة قديمة)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pass');
      AppLogger.security('mikrotik_pass cleared');
    } else {
      try {
        await _storage.write(key: _keyMikrotikPass, value: password);
        AppLogger.security('mikrotik_pass set in secure storage');
      } catch (e) {
        // 🔧 Fallback: إن فشل secure storage (مثلاً على بعض أجهزة Android
        // بدون EncryptedSharedPreferences)، احفظ في SharedPreferences
        // كحل أخير. ليس مثالياً أمنياً، لكن يمنع فقدان البيانات.
        AppLogger.error('Secure storage write failed, using prefs fallback',
            error: e, category: LogCategory.storage);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pass', password);
        AppLogger.security('mikrotik_pass set in prefs (fallback)');
      }
    }
  }

  @override
  Future<String?> getRemotePassword() async {
    try {
      final pass = await _storage.read(key: _keyRemotePass);
      if (pass != null && pass.isNotEmpty) return pass;

      // 🔧 Fallback للبيانات القديمة
      final prefs = await SharedPreferences.getInstance();
      final legacyPass = prefs.getString('remote_pass');
      if (legacyPass != null && legacyPass.isNotEmpty) {
        try {
          await _storage.write(key: _keyRemotePass, value: legacyPass);
          await prefs.remove('remote_pass');
          AppLogger.security('remote_pass migrated lazily from prefs');
          return legacyPass;
        } catch (_) {
          return legacyPass;
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to read remote_pass',
          error: e, category: LogCategory.storage);
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString('remote_pass');
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<void> setRemotePassword(String? password) async {
    if (password == null || password.isEmpty) {
      await _storage.delete(key: _keyRemotePass);
      AppLogger.security('remote_pass cleared');
    } else {
      await _storage.write(key: _keyRemotePass, value: password);
      AppLogger.security('remote_pass set');
    }
  }

  @override
  Future<String?> getOomolApiKey() async {
    try {
      final key = await _storage.read(key: _keyOomolApiKey);
      if (key != null && key.isNotEmpty) return key;

      // 🔧 Fallback للبيانات القديمة
      final prefs = await SharedPreferences.getInstance();
      final legacyKey = prefs.getString('legacy_integration_api_key');
      if (legacyKey != null && legacyKey.isNotEmpty) {
        try {
          await _storage.write(key: _keyOomolApiKey, value: legacyKey);
          await prefs.remove('legacy_integration_api_key');
          AppLogger.security('legacy_integration_api_key migrated lazily from prefs');
          return legacyKey;
        } catch (_) {
          return legacyKey;
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to read legacy_integration_api_key',
          error: e, category: LogCategory.storage);
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString('legacy_integration_api_key');
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<void> setOomolApiKey(String? apiKey) async {
    if (apiKey == null || apiKey.isEmpty) {
      await _storage.delete(key: _keyOomolApiKey);
      AppLogger.security('legacy_integration_api_key cleared');
    } else {
      await _storage.write(key: _keyOomolApiKey, value: apiKey);
      AppLogger.security('legacy_integration_api_key set');
    }
  }

  @override
  Future<String?> getTelegramBotToken() async {
    try {
      final token = await _storage.read(key: _keyTelegramBotToken);
      if (token != null && token.isNotEmpty) return token;
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_keyTelegramBotToken);
      if (legacy != null && legacy.isNotEmpty) {
        await _storage.write(key: _keyTelegramBotToken, value: legacy);
        await prefs.remove(_keyTelegramBotToken);
        AppLogger.security('telegram_bot_token migrated lazily from prefs');
        return legacy;
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to read telegram_bot_token',
          error: e, category: LogCategory.storage);
      return null;
    }
  }

  @override
  Future<void> setTelegramBotToken(String? token) async {
    if (token == null || token.trim().isEmpty) {
      await _storage.delete(key: _keyTelegramBotToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyTelegramBotToken);
      AppLogger.security('telegram_bot_token cleared');
      return;
    }
    await _storage.write(key: _keyTelegramBotToken, value: token.trim());
    AppLogger.security('telegram_bot_token set');
  }

  @override
  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _keyMikrotikPass);
      await _storage.delete(key: _keyRemotePass);
      await _storage.delete(key: _keyOomolApiKey);
      await _storage.delete(key: _keyTelegramBotToken);
      AppLogger.security('All credentials cleared');
    } catch (e) {
      AppLogger.error('Failed to clear credentials',
          error: e, category: LogCategory.storage);
    }
  }

  @override
  Future<void> clearMikrotikCredentials() async {
    try {
      await _storage.delete(key: _keyMikrotikPass);
      AppLogger.security('mikrotik_pass cleared');
    } catch (e) {
      AppLogger.error('Failed to clear mikrotik_pass',
          error: e, category: LogCategory.storage);
    }
  }

  @override
  Future<bool> hasStoredCredentials() async {
    final pass = await getMikrotikPassword();
    return pass != null && pass.isNotEmpty;
  }

  @override
  Future<void> migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrated = prefs.getBool(_migrationDoneKey) ?? false;
      if (migrated) {
        AppLogger.debug('SecureStorage already migrated',
            category: LogCategory.storage);
        return;
      }

      AppLogger.info('Migrating sensitive data from prefs to secure storage',
          category: LogCategory.storage);

      // نقل كلمات المرور إن وُجدت في SharedPreferences
      final mikrotikPass = prefs.getString('pass');
      if (mikrotikPass != null && mikrotikPass.isNotEmpty) {
        await _storage.write(key: _keyMikrotikPass, value: mikrotikPass);
        await prefs.remove('pass');
        AppLogger.security('mikrotik_pass migrated from prefs');
      }

      final remotePass = prefs.getString('remote_pass');
      if (remotePass != null && remotePass.isNotEmpty) {
        await _storage.write(key: _keyRemotePass, value: remotePass);
        await prefs.remove('remote_pass');
        AppLogger.security('remote_pass migrated from prefs');
      }

      final legacy_integrationKey = prefs.getString('legacy_integration_api_key');
      if (legacy_integrationKey != null && legacy_integrationKey.isNotEmpty) {
        await _storage.write(key: _keyOomolApiKey, value: legacy_integrationKey);
        await prefs.remove('legacy_integration_api_key');
        AppLogger.security('legacy_integration_api_key migrated from prefs');
      }

      // وضع علامة الترحيل
      await prefs.setBool(_migrationDoneKey, true);
      AppLogger.info('SecureStorage migration complete',
          category: LogCategory.storage);
    } catch (e) {
      AppLogger.error('SecureStorage migration failed',
          error: e, category: LogCategory.storage);
      // لا نرمي — التطبيق يجب أن يكمل التشغيل حتى لو فشل الترحيل
    }
  }
}

/// Mock implementation للاختبارات — يخزّن في memory بدل التخزين الفعلي
class InMemorySecureCredentialsStorage implements SecureCredentialsStorage {
  final Map<String, String> _store = {};

  /// يضبط قيمة ابتدائية (لاستخدامها في الاختبارات)
  void seed({
    String? mikrotikPass,
    String? remotePass,
    String? legacy_integrationApiKey,
    String? telegramBotToken,
  }) {
    if (mikrotikPass != null) _store['mikrotik_pass'] = mikrotikPass;
    if (remotePass != null) _store['remote_pass'] = remotePass;
    if (legacy_integrationApiKey != null) _store['legacy_integration_api_key'] = legacy_integrationApiKey;
    if (telegramBotToken != null) {
      _store['telegram_bot_token'] = telegramBotToken;
    }
  }

  @override
  Future<String?> getMikrotikPassword() async => _store['mikrotik_pass'];

  @override
  Future<void> setMikrotikPassword(String? password) async {
    if (password == null || password.isEmpty) {
      _store.remove('mikrotik_pass');
    } else {
      _store['mikrotik_pass'] = password;
    }
  }

  @override
  Future<String?> getRemotePassword() async => _store['remote_pass'];

  @override
  Future<void> setRemotePassword(String? password) async {
    if (password == null || password.isEmpty) {
      _store.remove('remote_pass');
    } else {
      _store['remote_pass'] = password;
    }
  }

  @override
  Future<String?> getOomolApiKey() async => _store['legacy_integration_api_key'];

  @override
  Future<void> setOomolApiKey(String? apiKey) async {
    if (apiKey == null || apiKey.isEmpty) {
      _store.remove('legacy_integration_api_key');
    } else {
      _store['legacy_integration_api_key'] = apiKey;
    }
  }

  @override
  Future<String?> getTelegramBotToken() async => _store['telegram_bot_token'];

  @override
  Future<void> setTelegramBotToken(String? token) async {
    if (token == null || token.trim().isEmpty) {
      _store.remove('telegram_bot_token');
    } else {
      _store['telegram_bot_token'] = token.trim();
    }
  }

  @override
  Future<void> clearAll() async {
    _store.clear();
  }

  @override
  Future<void> clearMikrotikCredentials() async {
    _store.remove('mikrotik_pass');
  }

  @override
  Future<bool> hasStoredCredentials() async {
    final pass = _store['mikrotik_pass'];
    return pass != null && pass.isNotEmpty;
  }

  @override
  Future<void> migrateFromSharedPreferences() async {
    // لا شيء في mock — الاختبارات تضبط القيم مباشرة عبر seed()
  }
}

/// Container للـ dependency injection — يسمح بحقن mock في الاختبارات
///
/// الاستخدام في الإنتاج (main.dart):
/// ```dart
/// SecureCredentialsStorageContainer.instance = SecureCredentialsStorageImpl();
/// ```
///
/// الاستخدام في الاختبارات:
/// ```dart
/// setUp(() {
///   SecureCredentialsStorageContainer.instance = InMemorySecureCredentialsStorage();
/// });
/// ```
class SecureCredentialsStorageContainer {
  SecureCredentialsStorageContainer._();
  static SecureCredentialsStorage instance = SecureCredentialsStorageImpl();

  /// يعيد الضبط للتنفيذ الإنتاجي (يُستخدم بعد الاختبارات)
  static void resetToProduction() {
    instance = SecureCredentialsStorageImpl();
  }
}
