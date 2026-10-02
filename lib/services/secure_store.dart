import 'dart:convert';

import 'package:encrypt/encrypt.dart' as enc;

import 'settings_store.dart';

/// مخزن تشفير بسيط لبيانات الدخول (AES-256-CBC).
///
/// - المفتاح يُولَّد عشوائيًا على الجهاز أول مرة ويُحفظ في SharedPreferences.
/// - كل قيمة تُشفَّر بـ IV عشوائي مستقل وتُخزَّن بصيغة:
///   `enc:v1:<iv-base64>:<cipher-base64>`
/// - القيم القديمة غير المشفّرة تُقرأ كما هي (توافق خلفي) ثم تُشفَّر عند أول حفظ.
///
/// ملاحظة أمنية: هذا يحمي من قراءة قاعدة البيانات مباشرة، لكنه ليس
/// Android Keystore؛ للتصلب الكامل يُنصح لاحقًا بالانتقال إلى flutter_secure_storage.
class SecureStore {
  static const String _keyPrefName = 'mikronet_store_key_v1';
  static const String _prefix = 'enc:v1:';

  static enc.Encrypter? _encrypter;

  /// هل القيمة مشفّرة مسبقًا بهذا المخزن؟
  static bool isEncrypted(String value) => value.startsWith(_prefix);

  static Future<enc.Encrypter> _getEncrypter() async {
    if (_encrypter != null) return _encrypter!;

    var storedKey = await SettingsStore.get(_keyPrefName);

    if (storedKey == null || storedKey.isEmpty) {
      storedKey = enc.Key.fromSecureRandom(32).base64;
      await SettingsStore.set(_keyPrefName, storedKey);
    }

    _encrypter = enc.Encrypter(
      enc.AES(enc.Key.fromBase64(storedKey), mode: enc.AESMode.cbc),
    );
    return _encrypter!;
  }

  /// تشفير نص. عند أي خطأ يُعاد النص كما هو بدل إسقاط العملية.
  static Future<String> encryptText(String plainText) async {
    if (plainText.isEmpty) return plainText;
    try {
      final encrypter = await _getEncrypter();
      final iv = enc.IV.fromSecureRandom(16);
      final encrypted = encrypter.encryptBytes(utf8.encode(plainText), iv: iv);
      return '$_prefix${iv.base64}:${encrypted.base64}';
    } catch (_) {
      return plainText;
    }
  }

  /// فك تشفير نص. إن كان النص غير مشفّر (بيانات قديمة) يُعاد كما هو.
  static Future<String> decryptText(String storedText) async {
    if (storedText.isEmpty || !isEncrypted(storedText)) return storedText;
    try {
      final payload = storedText.substring(_prefix.length);
      final separator = payload.indexOf(':');
      if (separator <= 0) return storedText;

      final encrypter = await _getEncrypter();
      final iv = enc.IV.fromBase64(payload.substring(0, separator));
      final encrypted = enc.Encrypted.fromBase64(payload.substring(separator + 1));
      return utf8.decode(encrypter.decryptBytes(encrypted, iv: iv));
    } catch (_) {
      return storedText;
    }
  }

  /// إعادة توليد مفتاح جديد (يفقد إمكانية قراءة البيانات المشفّرة القديمة).
  static Future<void> resetKey() async {
    await SettingsStore.remove(_keyPrefName);
    _encrypter = null;
  }
}
