// ============================================================
//  MikrotikProvider — Riverpod provider للاتصال والتشخيص
//
//  يوفر:
//  - حالة الاتصال (connected/disconnected/connecting/error)
//  - بيانات الاعتماد (IP, user, pass, port)
//  - تشغيل التشخيص الكامل
//  - إعادة الاتصال التلقائي
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/diagnostic_result.dart' as diag;
import '../services/mikrotik_diagnostic.dart';
import '../mikrotik_connector.dart';

/// حالة الاتصال
enum MikrotikStatus { disconnected, connecting, connected, error }

/// حالة الـ provider الكاملة
class MikrotikState {
  final MikrotikStatus status;
  final String? errorMessage;
  final String? ip;
  final int? port;
  final diag.DiagnosticResult? lastDiagnostic;
  final bool isDiagnosing;
  final String? diagnosticStage;

  const MikrotikState({
    this.status = MikrotikStatus.disconnected,
    this.errorMessage,
    this.ip,
    this.port,
    this.lastDiagnostic,
    this.isDiagnosing = false,
    this.diagnosticStage,
  });

  bool get isConnected => status == MikrotikStatus.connected;
  bool get isConnecting => status == MikrotikStatus.connecting;

  MikrotikState copyWith({
    MikrotikStatus? status,
    String? errorMessage,
    String? ip,
    int? port,
    diag.DiagnosticResult? lastDiagnostic,
    bool? isDiagnosing,
    String? diagnosticStage,
    bool clearError = false,
    bool clearStage = false,
  }) =>
      MikrotikState(
        status: status ?? this.status,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        ip: ip ?? this.ip,
        port: port ?? this.port,
        lastDiagnostic: lastDiagnostic ?? this.lastDiagnostic,
        isDiagnosing: isDiagnosing ?? this.isDiagnosing,
        diagnosticStage:
            clearStage ? null : (diagnosticStage ?? this.diagnosticStage),
      );
}

/// StateNotifier لإدارة اتصال MikroTik
class MikrotikNotifier extends StateNotifier<MikrotikState> {
  MikrotikNotifier() : super(const MikrotikState());

  /// يتصل بـ MikroTik
  Future<void> connect() async {
    state = state.copyWith(
      status: MikrotikStatus.connecting,
      clearError: true,
    );

    try {
      await MikrotikConnector.connect();
      state = state.copyWith(
        status: MikrotikStatus.connected,
        ip: MikrotikConnector.currentIp,
        port: MikrotikConnector.currentPort,
      );
      debugPrint('[MikrotikProvider] Connected to ${state.ip}:${state.port}');
    } on MikrotikCredentialsMissingException catch (e) {
      state = state.copyWith(
        status: MikrotikStatus.error,
        errorMessage: 'بيانات الاعتماد غير موجودة: ${e.message}',
      );
    } on MikrotikConnectionException catch (e) {
      state = state.copyWith(
        status: MikrotikStatus.error,
        errorMessage: 'فشل الاتصال: ${e.message}',
      );
    } catch (e) {
      state = state.copyWith(
        status: MikrotikStatus.error,
        errorMessage: 'خطأ غير متوقع: $e',
      );
    }
  }

  /// يفصل الاتصال
  void disconnect() {
    MikrotikConnector.forceDisconnect();
    state = const MikrotikState(status: MikrotikStatus.disconnected);
  }

  /// يشغّل تشخيصاً كاملاً
  Future<void> runDiagnostic() async {
    if (!state.isConnected) {
      state = state.copyWith(
        errorMessage: 'غير متصل بـ MikroTik. اتصل أولاً.',
      );
      return;
    }

    state = state.copyWith(
      isDiagnosing: true,
      diagnosticStage: 'بدء التشخيص...',
      clearError: true,
    );

    try {
      // ملاحظة: MikrotikDiagnostic لم يعد ضرورياً — نستخدم MikrotikConnector مباشرة
      // لكن نترك الاستدعاء للتوافق مع أي مراجع مستقبلية
      // ignore: unused_local_variable
      final diagnostic = MikrotikDiagnostic(
        routerIp: state.ip!,
        username: '', // يُقرأ من prefs داخل MikrotikConnector
        password: '',
        port: state.port ?? 8728,
      );

      // نستخدم MikrotikConnector مباشرة بدل إنشاء RouterOSClient جديد
      final result = await _runDiagnosticViaConnector(
        onProgress: (stage) {
          state = state.copyWith(diagnosticStage: stage);
        },
      );

      state = state.copyWith(
        isDiagnosing: false,
        lastDiagnostic: result,
        clearStage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isDiagnosing: false,
        errorMessage: 'فشل التشخيص: $e',
        clearStage: true,
      );
    }
  }

  /// ينفّذ التشخيص عبر MikrotikConnector الموجود
  Future<diag.DiagnosticResult> _runDiagnosticViaConnector({
    void Function(String stage)? onProgress,
  }) async {
    onProgress?.call('جاري جمع البيانات...');

    try {
      final client = await MikrotikConnector.connect();

      // 1) موارد النظام
      onProgress?.call('موارد النظام...');
      final resResp = await client.talk([
        '/system/resource/print',
        '=.proplist=cpu-load,cpu-frequency,free-memory,total-memory,uptime,'
            'architecture-name,platform,board-name,version',
      ]);

      final res = resResp.isNotEmpty ? resResp.first : {};
      final cpuLoad = res['cpu-load'] ?? '0';
      final freeMem = int.tryParse(res['free-memory'] ?? '0') ?? 0;
      final totalMem = int.tryParse(res['total-memory'] ?? '1') ?? 1;
      final memUsage = ((1 - freeMem / totalMem) * 100).round();

      final resources = diag.SystemResources(
        cpuLoad: '$cpuLoad%',
        cpuFrequency: res['cpu-frequency'] ?? '',
        cpuTemperature: '',
        memoryFree: _formatBytes(freeMem),
        memoryTotal: _formatBytes(totalMem),
        memoryUsage: '$memUsage%',
        uptime: res['uptime'] ?? '',
        performanceIssues: [],
      );

      // 2) الواجهات
      onProgress?.call('الواجهات...');
      final ifaceResp = await client.talk([
        '/interface/print',
        '=.proplist=name,type,running,rx-byte,tx-byte,rx-error,tx-error',
      ]);
      final interfaces = ifaceResp.map((d) => diag.InterfaceInfo(
            name: d['name'] ?? 'unknown',
            isActive: d['running'] == 'true',
            rxErrors: d['rx-error'] ?? '0',
            txErrors: d['tx-error'] ?? '0',
            speed: d['rx-byte'] ?? '0',
            type: d['type'] ?? 'unknown',
          )).toList();

      // 3) الأمان
      onProgress?.call('الأمان...');
      final svcResp = await client.talk([
        '/ip/service/print',
        '=.proplist=name,port,disabled',
      ]);
      final services = svcResp.map((d) => diag.ServiceInfo(
            name: d['name'] ?? 'unknown',
            disabled: d['disabled'] == 'true',
            port: d['port'] ?? '',
          )).toList();

      final enabledServices = services
          .where((s) => !s.disabled)
          .map((s) => s.name)
          .toList();

      final secIssues = <String>[];
      if (enabledServices.contains('telnet')) {
        secIssues.add('⚠️ Telnet مُفعّل');
      }
      if (enabledServices.contains('ftp')) {
        secIssues.add('⚠️ FTP مُفعّل');
      }

      final fwResp = await client.talk([
        '/ip/firewall/filter/print',
        '?count-only',
      ]);
      final fwCount = int.tryParse(fwResp.first['ret'] ?? '0') ?? 0;

      // 4) Logs
      onProgress?.call('السجلات...');
      final logResp = await client.talk([
        '/log/print',
        '=.proplist=message,time,topics',
      ]);
      final logs = logResp.take(30).map((d) {
        final time = d['time'] ?? '';
        final msg = d['message'] ?? '';
        return '[$time] $msg';
      }).toList();

      // 5) تحليل المشاكل
      onProgress?.call('تحليل المشاكل...');
      final issues = <diag.DiagnosticIssue>[];

      final cpuVal = int.tryParse(cpuLoad) ?? 0;
      if (cpuVal > 90) {
        issues.add(diag.DiagnosticIssue(
          type: 'CPU',
          severity: 'critical',
          message: 'CPU load حرج: $cpuLoad%',
          solution: 'فعّل FastTrack:\n/ip firewall filter add chain=forward '
              'action=fasttrack-connection connection-state=established,related',
        ));
      }

      if (memUsage > 85) {
        issues.add(diag.DiagnosticIssue(
          type: 'Memory',
          severity: 'high',
          message: 'استخدام الذاكرة: $memUsage%',
          solution: 'تحقق من: /system resource print',
        ));
      }

      for (final iface in interfaces) {
        if (!iface.isActive) {
          issues.add(diag.DiagnosticIssue(
            type: 'Interface',
            severity: 'medium',
            message: 'الواجهة ${iface.name} غير نشطة',
            solution: '/interface enable ${iface.name}',
          ));
        }
      }

      for (final secIssue in secIssues) {
        issues.add(diag.DiagnosticIssue(
          type: 'Security',
          severity: 'high',
          message: secIssue,
          solution: '/ip service disable telnet\n/ip service disable ftp',
        ));
      }

      // 6) الملخص
      final criticalCount =
          issues.where((i) => i.severity == 'critical').length;
      final warningCount =
          issues.where((i) => i.severity == 'high' || i.severity == 'medium')
              .length;
      final status = criticalCount > 0
          ? 'CRITICAL'
          : warningCount > 0
              ? 'WARNING'
              : 'HEALTHY';

      final connectivity = diag.ConnectivityStatus(
        pingSuccess: true,
        pingTimeMs: 0,
        status: '✅ متصل',
      );

      final quality = diag.ConnectionQuality(
        wirelessIssues: [],
        activeConnections: 0,
        networkCongestion: '✅ طبيعي',
      );

      final security = diag.SecurityStatus(
        failedLogins: 0,
        firewallRules: fwCount,
        enabledServices: enabledServices,
        issues: secIssues,
      );

      return diag.DiagnosticResult(
        connectivity: connectivity,
        resources: resources,
        interfaces: interfaces,
        quality: quality,
        security: security,
        services: services,
        issues: issues,
        recentLogs: logs,
        summary: diag.Summary(
          criticalIssues: criticalCount,
          warnings: warningCount,
          status: status,
        ),
      );
    } catch (e) {
      return diag.DiagnosticResult(
        connectivity: diag.ConnectivityStatus(
          pingSuccess: false, pingTimeMs: 0, status: '❌ $e',
        ),
        resources: diag.SystemResources(
          cpuLoad: '0%', cpuFrequency: '', cpuTemperature: '',
          memoryFree: '', memoryTotal: '', memoryUsage: '0%',
          uptime: '', performanceIssues: [],
        ),
        interfaces: [],
        quality: diag.ConnectionQuality(
          wirelessIssues: [], activeConnections: 0, networkCongestion: '',
        ),
        security: diag.SecurityStatus(
          failedLogins: 0, firewallRules: 0, enabledServices: [], issues: [],
        ),
        services: [],
        issues: [diag.DiagnosticIssue(
          type: 'Connection', severity: 'critical',
          message: '$e', solution: 'تحقق من الاتصال',
        )],
        recentLogs: [],
        summary: diag.Summary(criticalIssues: 1, warnings: 0, status: 'CRITICAL'),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Riverpod provider
final mikrotikProvider =
    StateNotifierProvider<MikrotikNotifier, MikrotikState>((ref) {
  return MikrotikNotifier();
});
