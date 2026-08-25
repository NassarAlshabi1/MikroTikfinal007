import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_logger.dart';

abstract class SecureCredentialsStorage {
  Future<String?> getMikrotikPassword();
  Future<void> setMikrotikPassword(String? password);
  Future<String?> getRemotePassword();
  Future<void> setRemotePassword(String? password);
  Future<String?> getTelegramBotToken();
  Future<void> setTelegramBotToken(String? token);
  Future<void> clearAll();
  Future<void> clearMikrotikCredentials();
  Future<bool> hasStoredCredentials();
  Future<void> migrateFromSharedPreferences();
}

class SecureCredentialsStorageImpl implements SecureCredentialsStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyMikrotikPass = 'mikrotik_pass';
  static const _keyRemotePass = 'remote_pass';
  static const _keyTelegramBotToken = 'telegram_bot_token';
  static const _migrationDoneKey = 'secure_storage_migrated';

  @override
  Future<String?> getMikrotikPassword() => _storage.read(key: _keyMikrotikPass);

  @override
  Future<void> setMikrotikPassword(String? password) async {
    if (password == null || password.isEmpty) {
      await _storage.delete(key: _keyMikrotikPass);
      await _removeLegacy('pass');
      return;
    }
    await _storage.write(key: _keyMikrotikPass, value: password);
  }

  @override
  Future<String?> getRemotePassword() => _storage.read(key: _keyRemotePass);

  @override
  Future<void> setRemotePassword(String? password) async {
    if (password == null || password.isEmpty) {
      await _storage.delete(key: _keyRemotePass);
      await _removeLegacy('remote_pass');
      return;
    }
    await _storage.write(key: _keyRemotePass, value: password);
  }

  @override
  Future<String?> getTelegramBotToken() =>
      _storage.read(key: _keyTelegramBotToken);

  @override
  Future<void> setTelegramBotToken(String? token) async {
    if (token == null || token.trim().isEmpty) {
      await _storage.delete(key: _keyTelegramBotToken);
      await _removeLegacy(_keyTelegramBotToken);
      return;
    }
    await _storage.write(key: _keyTelegramBotToken, value: token.trim());
  }

  Future<void> _removeLegacy(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  @override
  Future<void> clearAll() async {
    await _storage.delete(key: _keyMikrotikPass);
    await _storage.delete(key: _keyRemotePass);
    await _storage.delete(key: _keyTelegramBotToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pass');
    await prefs.remove('remote_pass');
    await prefs.remove(_keyTelegramBotToken);
  }

  @override
  Future<void> clearMikrotikCredentials() async {
    await _storage.delete(key: _keyMikrotikPass);
    await _removeLegacy('pass');
  }

  @override
  Future<bool> hasStoredCredentials() async {
    final pass = await getMikrotikPassword();
    return pass != null && pass.isNotEmpty;
  }

  @override
  Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationDoneKey) ?? false) return;

    // Fail closed: write every legacy secret to secure storage and verify the
    // write before deleting the legacy value or marking migration complete.
    final legacy = <String, String?>{
      _keyMikrotikPass: prefs.getString('pass'),
      _keyRemotePass: prefs.getString('remote_pass'),
      _keyTelegramBotToken: prefs.getString(_keyTelegramBotToken),
    };

    try {
      for (final entry in legacy.entries) {
        final value = entry.value;
        if (value == null || value.isEmpty) continue;
        await _storage.write(key: entry.key, value: value);
        final verified = await _storage.read(key: entry.key);
        if (verified != value) {
          throw StateError('Secure storage verification failed for ${entry.key}');
        }
      }
      for (final key in ['pass', 'remote_pass', _keyTelegramBotToken]) {
        await prefs.remove(key);
      }
      await prefs.setBool(_migrationDoneKey, true);
      AppLogger.security('secure credential migration completed');
    } catch (error, stackTrace) {
      AppLogger.error(
        'secure credential migration failed; legacy values were retained',
        error: error,
        stackTrace: stackTrace,
        category: LogCategory.storage,
      );
      rethrow;
    }
  }
}

class InMemorySecureCredentialsStorage implements SecureCredentialsStorage {
  final Map<String, String> _store = {};

  void seed({String? mikrotikPass, String? remotePass, String? telegramBotToken}) {
    if (mikrotikPass != null) _store['mikrotik_pass'] = mikrotikPass;
    if (remotePass != null) _store['remote_pass'] = remotePass;
    if (telegramBotToken != null) _store['telegram_bot_token'] = telegramBotToken;
  }

  @override
  Future<String?> getMikrotikPassword() async => _store['mikrotik_pass'];
  @override
  Future<void> setMikrotikPassword(String? password) async =>
      _set('mikrotik_pass', password);
  @override
  Future<String?> getRemotePassword() async => _store['remote_pass'];
  @override
  Future<void> setRemotePassword(String? password) async =>
      _set('remote_pass', password);
  @override
  Future<String?> getTelegramBotToken() async => _store['telegram_bot_token'];
  @override
  Future<void> setTelegramBotToken(String? token) async =>
      _set('telegram_bot_token', token?.trim());
  Future<void> _set(String key, String? value) async {
    if (value == null || value.isEmpty) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }
  @override
  Future<void> clearAll() async => _store.clear();
  @override
  Future<void> clearMikrotikCredentials() async => _store.remove('mikrotik_pass');
  @override
  Future<bool> hasStoredCredentials() async =>
      (_store['mikrotik_pass'] ?? '').isNotEmpty;
  @override
  Future<void> migrateFromSharedPreferences() async {}
}

class SecureCredentialsStorageContainer {
  SecureCredentialsStorageContainer._();
  static SecureCredentialsStorage instance = SecureCredentialsStorageImpl();
  static void resetToProduction() => instance = SecureCredentialsStorageImpl();
}
