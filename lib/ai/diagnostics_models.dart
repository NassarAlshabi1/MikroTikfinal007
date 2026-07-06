// ============================================================
//  Diagnostics Models — هياكل البيانات للتشخيص بالـ AI
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;

/// نوع/وضع التشخيص — يحدّد الـ System Prompt المُستخدم
enum DiagnosticMode {
  general,        // تشخيص عام شامل
  security,       // فحص أمني
  performance,    // تحسين الأداء
  hotspot,        // مشاكل Hotspot و User Manager
  vpn,            // VPN و tunneling
  routing,        // مشاكل التوجيه و BGP/OSPF
  wifi,           // Wireless و CAPsMAN
}

extension DiagnosticModeExtension on DiagnosticMode {
  String get displayName {
    switch (this) {
      case DiagnosticMode.general:
        return 'تشخيص عام';
      case DiagnosticMode.security:
        return 'فحص أمني';
      case DiagnosticMode.performance:
        return 'تحسين الأداء';
      case DiagnosticMode.hotspot:
        return 'Hotspot و User Manager';
      case DiagnosticMode.vpn:
        return 'VPN و Tunneling';
      case DiagnosticMode.routing:
        return 'التوجيه و BGP/OSPF';
      case DiagnosticMode.wifi:
        return 'Wireless و CAPsMAN';
    }
  }

  String get description {
    switch (this) {
      case DiagnosticMode.general:
        return 'تحليل شامل لكل جوانب الجهاز';
      case DiagnosticMode.security:
        return 'فحص ثغرات Firewall و الأمان';
      case DiagnosticMode.performance:
        return 'تحسين CPU/RAM/Throughput';
      case DiagnosticMode.hotspot:
        return 'مشاكل تسجيل الدخول والكروت والملفات الشخصية';
      case DiagnosticMode.vpn:
        return 'IPSec, WireGuard, L2TP, OpenVPN, SSTP';
      case DiagnosticMode.routing:
        return 'Static routes, BGP, OSPF, BFD, policy routing';
      case DiagnosticMode.wifi:
        return 'WIFI signal, CAPsMAN, roaming, channel optimization';
    }
  }

  IconData get icon {
    switch (this) {
      case DiagnosticMode.general:
        return Icons.healing;
      case DiagnosticMode.security:
        return Icons.security;
      case DiagnosticMode.performance:
        return Icons.speed;
      case DiagnosticMode.hotspot:
        return Icons.wifi_tethering;
      case DiagnosticMode.vpn:
        return Icons.vpn_lock;
      case DiagnosticMode.routing:
        return Icons.alt_route;
      case DiagnosticMode.wifi:
        return Icons.wifi;
    }
  }
}

/// مزود خدمة الـ AI
enum AiProvider {
  openAI,    // GPT-4o, GPT-4o-mini
  gemini,    // gemini-1.5-flash, gemini-1.5-pro
}

extension AiProviderExtension on AiProvider {
  String get displayName {
    switch (this) {
      case AiProvider.openAI:
        return 'OpenAI (ChatGPT)';
      case AiProvider.gemini:
        return 'Google Gemini';
    }
  }

  String get defaultModel {
    switch (this) {
      case AiProvider.openAI:
        return 'gpt-4o-mini';
      case AiProvider.gemini:
        return 'gemini-1.5-flash';
    }
  }

  List<String> get availableModels {
    switch (this) {
      case AiProvider.openAI:
        return ['gpt-4o-mini', 'gpt-4o', 'gpt-4-turbo'];
      case AiProvider.gemini:
        return ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-1.0-pro'];
    }
  }
}

/// طريقة الاتصال بـ MikroTik
enum MikrotikConnectionMethod {
  routerOS,  // API على منفذ 8728/8729 (موجود مسبقاً)
  ssh,       // SSH على منفذ 22 (أوامر نصية كاملة)
}

extension MikrotikConnectionMethodExtension on MikrotikConnectionMethod {
  String get displayName {
    switch (this) {
      case MikrotikConnectionMethod.routerOS:
        return 'RouterOS API (منفذ 8728)';
      case MikrotikConnectionMethod.ssh:
        return 'SSH (منفذ 22)';
    }
  }
}

/// نوع رسالة المحادثة
enum MessageType { user, assistant, system, error }

/// رسالة في محادثة التشخيص
@immutable
class DiagnosticMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final List<String>? suggestedCommands; // أوامر اقترحها الـ AI

  const DiagnosticMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.suggestedCommands,
  });

  factory DiagnosticMessage.user(String content) => DiagnosticMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: content,
        type: MessageType.user,
        timestamp: DateTime.now(),
      );

  factory DiagnosticMessage.assistant(
    String content, {
    List<String>? commands,
  }) =>
      DiagnosticMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: content,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        suggestedCommands: commands,
      );

  factory DiagnosticMessage.error(String content) => DiagnosticMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: content,
        type: MessageType.error,
        timestamp: DateTime.now(),
      );

  factory DiagnosticMessage.system(String content) => DiagnosticMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: content,
        type: MessageType.system,
        timestamp: DateTime.now(),
      );
}

/// البيانات المجمّعة من MikroTik للتشخيص
@immutable
class MikrotikSnapshot {
  final String interfaces;
  final String routes;
  final String firewall;
  final String logs;
  final String system;
  final String ipAddress;
  final DateTime collectedAt;

  const MikrotikSnapshot({
    required this.interfaces,
    required this.routes,
    required this.firewall,
    required this.logs,
    required this.system,
    required this.ipAddress,
    required this.collectedAt,
  });

  /// يحوّل البيانات إلى نص مضغوط لإرساله للـ AI
  /// (يحدّ عدد أسطر الـ log لتوفير tokens)
  String toAiContext({int maxLogLines = 30}) {
    // اقتصار الـ logs على آخر N سطر
    final logLines = logs.split('\n');
    final trimmedLogs = logLines.length > maxLogLines
        ? logLines.sublist(logLines.length - maxLogLines).join('\n')
        : logs;

    return '''
=== SYSTEM ===
$system

=== INTERFACES ===
$interfaces

=== ROUTES ===
$routes

=== FIREWALL FILTER ===
$firewall

=== RECENT LOGS (last $maxLogLines lines) ===
$trimmedLogs

=== DEVICE IP ===
$ipAddress

=== SNAPSHOT TIME ===
${collectedAt.toIso8601String()}
''';
  }
}

/// إعدادات الـ AI (تُحمّل من secure storage)
@immutable
class AiSettings {
  final AiProvider provider;
  final String model;
  final String apiKey;
  final MikrotikConnectionMethod connectionMethod;
  final int maxTokens;
  final DiagnosticMode mode;  // نوع/وضع التشخيص

  const AiSettings({
    required this.provider,
    required this.model,
    required this.apiKey,
    required this.connectionMethod,
    required this.mode,
    this.maxTokens = 1500,
  });

  static AiSettings get default_ => const AiSettings(
        provider: AiProvider.openAI,
        model: 'gpt-4o-mini',
        apiKey: '',
        connectionMethod: MikrotikConnectionMethod.routerOS,
        mode: DiagnosticMode.general,
      );

  AiSettings copyWith({
    AiProvider? provider,
    String? model,
    String? apiKey,
    MikrotikConnectionMethod? connectionMethod,
    int? maxTokens,
    DiagnosticMode? mode,
  }) =>
      AiSettings(
        provider: provider ?? this.provider,
        model: model ?? this.model,
        apiKey: apiKey ?? this.apiKey,
        connectionMethod: connectionMethod ?? this.connectionMethod,
        maxTokens: maxTokens ?? this.maxTokens,
        mode: mode ?? this.mode,
      );

  bool get isConfigured => apiKey.isNotEmpty;
}

/// حالة التشخيص الكاملة
@immutable
class DiagnosticsState {
  final List<DiagnosticMessage> messages;
  final bool isLoading;
  final String? loadingStage;  // "جاري جمع البيانات..." | "جاري التحليل..."
  final MikrotikSnapshot? lastSnapshot;
  final AiSettings settings;

  const DiagnosticsState({
    required this.messages,
    required this.isLoading,
    this.loadingStage,
    this.lastSnapshot,
    required this.settings,
  });

  static DiagnosticsState initial(AiSettings settings) => DiagnosticsState(
        messages: [
          DiagnosticMessage.system(
            'مرحباً! اضغط على زر "تشخيص" لجمع بيانات الـ MikroTik وتحليلها بالـ AI، '
            'أو اكتب سؤالك مباشرةً.',
          ),
        ],
        isLoading: false,
        settings: settings,
      );

  DiagnosticsState copyWith({
    List<DiagnosticMessage>? messages,
    bool? isLoading,
    String? loadingStage,
    MikrotikSnapshot? lastSnapshot,
    AiSettings? settings,
    bool clearLoadingStage = false,
  }) =>
      DiagnosticsState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        loadingStage:
            clearLoadingStage ? null : (loadingStage ?? this.loadingStage),
        lastSnapshot: lastSnapshot ?? this.lastSnapshot,
        settings: settings ?? this.settings,
      );
}
