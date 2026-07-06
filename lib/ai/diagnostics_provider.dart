// ============================================================
//  Diagnostics Provider — Riverpod state management
//  يدير: الإعدادات + المحادثة + التشخيص
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'diagnostics_models.dart';
import 'mikrotik_data_collector.dart';
import 'ai_service.dart';
import 'ai_settings_service.dart';

// ============================================================
//  Providers أساسية
// ============================================================

/// يحمّل الإعدادات المحفوظة عند بدء التطبيق
final aiSettingsProvider = FutureProvider<AiSettings>((ref) async {
  return await AiSettingsService.instance.load();
});

/// StateNotifier لإدارة إعدادات الـ AI
final aiSettingsNotifierProvider =
    StateNotifierProvider<AiSettingsNotifier, AsyncValue<AiSettings>>((ref) {
  final initial = ref.watch(aiSettingsProvider);
  return AiSettingsNotifier(initial);
});

class AiSettingsNotifier extends StateNotifier<AsyncValue<AiSettings>> {
  AiSettingsNotifier(AsyncValue<AiSettings> initial) : super(initial);

  Future<void> update(AiSettings settings) async {
    state = AsyncData(settings);
    await AiSettingsService.instance.save(settings);
  }

  Future<void> setApiKey(String apiKey) async {
    final current = state.valueOrNull ?? AiSettings.default_;
    final newSettings = current.copyWith(apiKey: apiKey);
    state = AsyncData(newSettings);
    await AiSettingsService.instance.save(newSettings);
  }

  Future<void> setProvider(AiProvider provider) async {
    final current = state.valueOrNull ?? AiSettings.default_;
    // عند تغيير المزود، نضبط الموديل على الافتراضي للمزود الجديد
    final newSettings = current.copyWith(
      provider: provider,
      model: provider.defaultModel,
    );
    state = AsyncData(newSettings);
    await AiSettingsService.instance.save(newSettings);
  }

  Future<void> setModel(String model) async {
    final current = state.valueOrNull ?? AiSettings.default_;
    final newSettings = current.copyWith(model: model);
    state = AsyncData(newSettings);
    await AiSettingsService.instance.save(newSettings);
  }

  Future<void> setConnectionMethod(MikrotikConnectionMethod method) async {
    final current = state.valueOrNull ?? AiSettings.default_;
    final newSettings = current.copyWith(connectionMethod: method);
    state = AsyncData(newSettings);
    await AiSettingsService.instance.save(newSettings);
  }
}

// ============================================================
//  Diagnostics State Notifier
// ============================================================

final diagnosticsProvider =
    StateNotifierProvider<DiagnosticsNotifier, DiagnosticsState>((ref) {
  final settings = ref.watch(aiSettingsProvider).valueOrNull ?? AiSettings.default_;
  return DiagnosticsNotifier(settings);
});

class DiagnosticsNotifier extends StateNotifier<DiagnosticsState> {
  DiagnosticsNotifier(AiSettings settings)
      : super(DiagnosticsState.initial(settings));

  /// يجمع بيانات MikroTik ثم يحللها بالـ AI
  Future<void> runDiagnostics({String? userQuery}) async {
    if (state.isLoading) return;

    final query = userQuery ?? 'حلل حالة الجهاز وحدد أي مشاكل محتملة.';

    // أضف رسالة المستخدم
    state = state.copyWith(
      messages: [...state.messages, DiagnosticMessage.user(query)],
      isLoading: true,
      loadingStage: 'جاري جمع البيانات من MikroTik...',
    );

    try {
      // 1) جمع البيانات
      final settings = state.settings;
      MikrotikSnapshot snapshot;

      if (settings.connectionMethod == MikrotikConnectionMethod.ssh) {
        // SSH: نحتاج بيانات اعتماد من SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final ip = prefs.getString('ip') ?? '';
        final user = prefs.getString('user') ?? '';
        final pass = prefs.getString('pass') ?? '';
        snapshot = await MikrotikDataCollector.collectViaSSH(
          host: ip,
          username: user,
          password: pass,
        );
      } else {
        // RouterOS API
        snapshot = await MikrotikDataCollector.collectViaRouterOS();
      }

      state = state.copyWith(
        lastSnapshot: snapshot,
        loadingStage: 'جاري التحليل بالـ AI...',
      );

      // 2) تحليل بالـ AI
      final result = await AiService.analyze(
        settings: settings,
        userQuery: query,
        snapshotContext: snapshot.toAiContext(),
        conversationHistory: state.messages,
      );

      // 3) أضف رد الـ AI
      state = state.copyWith(
        messages: [
          ...state.messages,
          DiagnosticMessage.assistant(
            result.content,
            commands: result.suggestedCommands,
          ),
        ],
        isLoading: false,
        clearLoadingStage: true,
      );
    } catch (e) {
      debugPrint('[DiagnosticsNotifier] Error: $e');
      state = state.copyWith(
        messages: [
          ...state.messages,
          DiagnosticMessage.error('فشل التشخيص: $e'),
        ],
        isLoading: false,
        clearLoadingStage: true,
      );
    }
  }

  /// يرسل سؤال متابعة بدون جمع بيانات جديدة (يستخدم آخر snapshot)
  Future<void> askFollowUp(String question) async {
    if (state.isLoading) return;
    if (state.lastSnapshot == null) {
      // لا يوجد snapshot — نشغّل تشخيص كامل
      await runDiagnostics(userQuery: question);
      return;
    }

    state = state.copyWith(
      messages: [...state.messages, DiagnosticMessage.user(question)],
      isLoading: true,
      loadingStage: 'جاري التحليل بالـ AI...',
    );

    try {
      final result = await AiService.analyze(
        settings: state.settings,
        userQuery: question,
        snapshotContext: state.lastSnapshot!.toAiContext(),
        conversationHistory: state.messages,
      );

      state = state.copyWith(
        messages: [
          ...state.messages,
          DiagnosticMessage.assistant(
            result.content,
            commands: result.suggestedCommands,
          ),
        ],
        isLoading: false,
        clearLoadingStage: true,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          DiagnosticMessage.error('فشل التحليل: $e'),
        ],
        isLoading: false,
        clearLoadingStage: true,
      );
    }
  }

  /// يمسح المحادثة
  void clearChat() {
    state = DiagnosticsState.initial(state.settings);
  }

  /// يحدّث الإعدادات (عند تغييرها من شاشة الإعدادات)
  void updateSettings(AiSettings settings) {
    state = state.copyWith(settings: settings);
  }
}
