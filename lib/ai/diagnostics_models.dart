// ============================================================
//  Diagnostics Models — هياكل البيانات للتشخيص بالـ AI
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;

// استيراد CommandResult (لتضمينه في DiagnosticsState)
import 'command_executor.dart' show CommandResult;

/// نوع/وضع التشخيص — يحدّد الـ System Prompt المُستخدم
enum DiagnosticMode {
  general,        // تشخيص عام شامل
  security,       // فحص أمني
  performance,    // تحسين الأداء
  hotspot,        // مشاكل Hotspot و User Manager
  vpn,            // VPN و tunneling
  routing,        // مشاكل التوجيه و BGP/OSPF
  wifi,           // Wireless و CAPsMAN
  qos,            // QoS و Queue management
  dhcp,           // DHCP و IP allocation (مستوحى من Mikrotik-AI-Cloud)
  monitoring,     // Netwatch, SNMP, logs, health check
  infrastructure, // Bridge, VLAN, Bonding, Tunnels, IPv6
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
      case DiagnosticMode.qos:
        return 'QoS و Queue Management';
      case DiagnosticMode.dhcp:
        return 'DHCP و IP Allocation';
      case DiagnosticMode.monitoring:
        return 'مراقبة و Netwatch';
      case DiagnosticMode.infrastructure:
        return 'بنية تحتية (Bridge/VLAN/IPv6)';
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
      case DiagnosticMode.qos:
        return 'Queues, PCQ, HTB, traffic shaping, bandwidth control';
      case DiagnosticMode.dhcp:
        return 'DHCP servers, leases, networks, pools, static bindings';
      case DiagnosticMode.monitoring:
        return 'Netwatch, SNMP, logs, ARP, neighbors, health check';
      case DiagnosticMode.infrastructure:
        return 'Bridge, VLAN, Bonding, EoIP/GRE/IPIP, IPv6, packages';
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
      case DiagnosticMode.qos:
        return Icons.tune;
      case DiagnosticMode.dhcp:
        return Icons.dns;
      case DiagnosticMode.monitoring:
        return Icons.visibility;
      case DiagnosticMode.infrastructure:
        return Icons.hub;
    }
  }
}

/// مزود خدمة الـ AI
enum AiProvider {
  openAI,    // GPT-4o, GPT-4o-mini
  gemini,    // gemini-2.5-flash, gemini-2.5-pro
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
        return 'gemini-2.5-flash';
    }
  }

  List<String> get availableModels {
    switch (this) {
      case AiProvider.openAI:
        return ['gpt-4o-mini', 'gpt-4o', 'gpt-4-turbo'];
      case AiProvider.gemini:
        return ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-1.5-flash', 'gemini-1.5-pro'];
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

  /// بيانات إضافية مجمّعة حسب وضع التشخيص (security, vpn, qos, إلخ)
  /// المفتاح = اسم القسم (مثلاً "IP SERVICES")
  /// القيمة = مخرجات الأمر كنص
  final Map<String, String> extraData;

  const MikrotikSnapshot({
    required this.interfaces,
    required this.routes,
    required this.firewall,
    required this.logs,
    required this.system,
    required this.ipAddress,
    required this.collectedAt,
    this.extraData = const {},
  });

  /// يحوّل البيانات إلى نص مضغوط لإرساله للـ AI
  /// (يحدّ عدد أسطر الـ log لتوفير tokens)
  String toAiContext({int maxLogLines = 30}) {
    // اقتصار الـ logs على آخر N سطر
    final logLines = logs.split('\n');
    final trimmedLogs = logLines.length > maxLogLines
        ? logLines.sublist(logLines.length - maxLogLines).join('\n')
        : logs;

    // بناء أقسام البيانات الإضافية (extraData) ديناميكياً
    final extraSections = StringBuffer();
    if (extraData.isNotEmpty) {
      for (final entry in extraData.entries) {
        final value = entry.value.trim().isEmpty
            ? '(empty)'
            : entry.value.trim();
        extraSections.writeln('\n=== ${entry.key} ===');
        extraSections.writeln(value);
      }
    }

    return '''
=== SYSTEM ===
$system

=== ROUTEROS VERSION ===
RouterOS v6.x (التطبيق يدعم v6 فقط — استخدم أوامر v6 syntax)

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
${collectedAt.toIso8601String()}$extraSections''';
  }
}

/// إعدادات الـ AI (تُحمّل من secure storage)
@immutable
class AiSettings {
  final AiProvider provider;
  final String model;
  final String apiKey;
  final String? baseUrl;  // عنوان API مخصص (OpenRouter, Azure, Ollama, إلخ)
  final MikrotikConnectionMethod connectionMethod;
  final int maxTokens;
  final DiagnosticMode mode;  // نوع/وضع التشخيص

  const AiSettings({
    required this.provider,
    required this.model,
    required this.apiKey,
    this.baseUrl,
    required this.connectionMethod,
    required this.mode,
    this.maxTokens = 1500,
  });

  /// يعيد الـ baseUrl الافتراضي للمزود إذا لم يُحدَّد مخصص
  String get effectiveBaseUrl {
    if (baseUrl != null && baseUrl!.isNotEmpty) return baseUrl!;
    switch (provider) {
      case AiProvider.openAI:
        return 'https://api.openai.com/v1';
      case AiProvider.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta';
    }
  }

  static AiSettings get default_ => const AiSettings(
        provider: AiProvider.openAI,
        model: 'gpt-4o-mini',
        apiKey: '',
        baseUrl: null,
        connectionMethod: MikrotikConnectionMethod.routerOS,
        mode: DiagnosticMode.general,
      );

  AiSettings copyWith({
    AiProvider? provider,
    String? model,
    String? apiKey,
    String? baseUrl,
    MikrotikConnectionMethod? connectionMethod,
    int? maxTokens,
    DiagnosticMode? mode,
  }) =>
      AiSettings(
        provider: provider ?? this.provider,
        model: model ?? this.model,
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl ?? this.baseUrl,
        connectionMethod: connectionMethod ?? this.connectionMethod,
        maxTokens: maxTokens ?? this.maxTokens,
        mode: mode ?? this.mode,
      );

  bool get isConfigured => apiKey.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiSettings &&
          runtimeType == other.runtimeType &&
          provider == other.provider &&
          model == other.model &&
          apiKey == other.apiKey &&
          baseUrl == other.baseUrl &&
          connectionMethod == other.connectionMethod &&
          maxTokens == other.maxTokens &&
          mode == other.mode;

  @override
  int get hashCode => Object.hash(
        provider,
        model,
        apiKey,
        baseUrl,
        connectionMethod,
        maxTokens,
        mode,
      );
}

/// حالة التشخيص الكاملة
@immutable
class DiagnosticsState {
  final List<DiagnosticMessage> messages;
  final bool isLoading;
  final String? loadingStage;  // "جاري جمع البيانات..." | "جاري التحليل..."
  final MikrotikSnapshot? lastSnapshot;
  final AiSettings settings;
  final CommandResult? lastCommandResult;  // نتيجة آخر أمر منفّذ

  const DiagnosticsState({
    required this.messages,
    required this.isLoading,
    this.loadingStage,
    this.lastSnapshot,
    required this.settings,
    this.lastCommandResult,
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
    CommandResult? lastCommandResult,
    bool clearLoadingStage = false,
    bool clearLastCommandResult = false,
  }) =>
      DiagnosticsState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        loadingStage:
            clearLoadingStage ? null : (loadingStage ?? this.loadingStage),
        lastSnapshot: lastSnapshot ?? this.lastSnapshot,
        settings: settings ?? this.settings,
        lastCommandResult: clearLastCommandResult
            ? null
            : (lastCommandResult ?? this.lastCommandResult),
      );
}
