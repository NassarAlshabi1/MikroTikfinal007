// ============================================================
//  AI Settings Service — تخزين آمن لإعدادات الـ AI
//  يستخدم flutter_secure_storage (لا تُكتب في SharedPreferences)
// ============================================================

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

import 'diagnostics_models.dart';

class AiSettingsService {
  AiSettingsService._();
  static final AiSettingsService instance = AiSettingsService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keySettings = 'ai_settings';
  static const _keyApiKey = 'ai_api_key';
  static const _keyProvider = 'ai_provider';
  static const _keyModel = 'ai_model';
  static const _keyConnectionMethod = 'ai_connection_method';
  static const _keyMaxTokens = 'ai_max_tokens';

  /// يحمّل الإعدادات المحفوظة (أو الإعدادات الافتراضية)
  Future<AiSettings> load() async {
    try {
      final apiKey = await _storage.read(key: _keyApiKey) ?? '';
      final providerStr = await _storage.read(key: _keyProvider) ?? 'openAI';
      final model = await _storage.read(key: _keyModel) ?? 'gpt-4o-mini';
      final methodStr =
          await _storage.read(key: _keyConnectionMethod) ?? 'routerOS';
      final maxTokensStr = await _storage.read(key: _keyMaxTokens) ?? '1500';

      return AiSettings(
        apiKey: apiKey,
        provider: AiProvider.values.firstWhere(
          (p) => p.name == providerStr,
          orElse: () => AiProvider.openAI,
        ),
        model: model,
        connectionMethod: MikrotikConnectionMethod.values.firstWhere(
          (m) => m.name == methodStr,
          orElse: () => MikrotikConnectionMethod.routerOS,
        ),
        maxTokens: int.tryParse(maxTokensStr) ?? 1500,
      );
    } catch (e) {
      debugPrint('[AiSettingsService] Load error: $e');
      return AiSettings.default_;
    }
  }

  /// يحفظ الإعدادات
  Future<void> save(AiSettings settings) async {
    try {
      await _storage.write(key: _keyApiKey, value: settings.apiKey);
      await _storage.write(key: _keyProvider, value: settings.provider.name);
      await _storage.write(key: _keyModel, value: settings.model);
      await _storage.write(
          key: _keyConnectionMethod, value: settings.connectionMethod.name);
      await _storage.write(
          key: _keyMaxTokens, value: settings.maxTokens.toString());
      debugPrint('[AiSettingsService] Settings saved');
    } catch (e) {
      debugPrint('[AiSettingsService] Save error: $e');
      rethrow;
    }
  }

  /// يحذف المفتاح (عند تسجيل الخروج)
  Future<void> clear() async {
    await _storage.delete(key: _keyApiKey);
    await _storage.delete(key: _keyProvider);
    await _storage.delete(key: _keyModel);
    await _storage.delete(key: _keyConnectionMethod);
    await _storage.delete(key: _keyMaxTokens);
  }
}
