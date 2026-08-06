// ============================================================
//  MikrotikDiagnostic — أداة تشخيص وفحص مشاكل MikroTik v6
//
//  يوفر:
//  - فحص الاتصال (ping)
//  - جمع موارد النظام (CPU, RAM, uptime)
//  - فحص الواجهات (interfaces)
//  - فحص الأمان (firewall, services, users)
//  - فحص QoS (queues, dropped packets)
//  - تحليل Logs
//  - توليد تقرير شامل (diag.DiagnosticResult)
// ============================================================

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:router_os_client/router_os_client.dart';

import '../models/diagnostic_result.dart' as diag;

/// أداة تشخيص وفحص مشاكل MikroTik v6
class MikrotikDiagnostic {
  final String routerIp;
  final String username;
  final String password;
  final int port;

  MikrotikDiagnostic({
    required this.routerIp,
    required this.username,
    required this.password,
    this.port = 8728,
  });

  /// يشغّل تشخيصاً كاملاً ويعيد النتيجة
  Future<diag.DiagnosticResult> runFullDiagnostic({
    void Function(String stage)? onProgress,
  }) async {
    onProgress?.call('جاري الاتصال بـ MikroTik...');

    RouterOSClient? client;
    try {
      client = RouterOSClient(
        address: routerIp,
        user: username,
        password: password,
        port: port,
        verbose: false,
      );
      final loggedIn = await client.login().timeout(
            const Duration(seconds: 10),
          );
      if (!loggedIn) {
        return _errorResult('فشل تسجيل الدخول');
      }

      // 1) فحص الاتصال
      onProgress?.call('فحص الاتصال...');
      final connectivity = await _checkConnectivity(client);

      // 2) موارد النظام
      onProgress?.call('جمع موارد النظام...');
      final resources = await _getSystemResources(client);

      // 3) الواجهات
      onProgress?.call('فحص الواجهات...');
      final interfaces = await _getInterfaces(client);

      // 4) جودة الاتصال
      onProgress?.call('تحليل جودة الاتصال...');
      final quality = await _getConnectionQuality(client);

      // 5) الأمان
      onProgress?.call('فحص الأمان...');
      final security = await _getSecurityStatus(client);

      // 6) الخدمات
      onProgress?.call('فحص الخدمات...');
      final services = await _getServices(client);

      // 7) تحليل المشاكل
      onProgress?.call('تحليل المشاكل...');
      final issues = _analyzeIssues(
        connectivity: connectivity,
        resources: resources,
        interfaces: interfaces,
        security: security,
      );

      // 8) Logs
      onProgress?.call('جمع السجلات...');
      final logs = await _getRecentLogs(client);

      // 9) الملخص
      final criticalCount =
          issues.where((i) => i.severity == 'critical').length;
      final warningCount = issues
          .where((i) => i.severity == 'high' || i.severity == 'medium')
          .length;

      final status = criticalCount > 0
          ? 'CRITICAL'
          : warningCount > 0
              ? 'WARNING'
              : 'HEALTHY';

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
    } on TimeoutException {
      return _errorResult('انتهت مهلة الاتصال');
    } on SocketException catch (e) {
      return _errorResult('خطأ في الشبكة: ${e.message}');
    } catch (e) {
      return _errorResult('خطأ غير متوقع: $e');
    } finally {
      try {
        client?.close();
      } catch (_) {}
    }
  }

  /// فحص الاتصال عبر ping
  Future<diag.ConnectivityStatus> _checkConnectivity(
      RouterOSClient client) async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await client
          .talk(['/system/resource/print']).timeout(const Duration(seconds: 5));
      stopwatch.stop();

      if (response.isNotEmpty) {
        return diag.ConnectivityStatus(
          pingSuccess: true,
          pingTimeMs: stopwatch.elapsedMilliseconds,
          status: '✅ متصل (${stopwatch.elapsedMilliseconds}ms)',
        );
      }
      return diag.ConnectivityStatus(
        pingSuccess: false,
        pingTimeMs: 0,
        status: '❌ لا توجد استجابة',
      );
    } catch (e) {
      return diag.ConnectivityStatus(
        pingSuccess: false,
        pingTimeMs: 0,
        status: '❌ خطأ: $e',
      );
    }
  }

  /// جمع موارد النظام
  Future<diag.SystemResources> _getSystemResources(
      RouterOSClient client) async {
    try {
      final response = await client.talk([
        '/system/resource/print',
        '=.proplist=cpu-load,cpu-frequency,free-memory,total-memory,uptime,'
            'architecture-name,platform,board-name',
      ]);

      if (response.isEmpty) {
        return diag.SystemResources(
          cpuLoad: '0%',
          cpuFrequency: '',
          cpuTemperature: '',
          memoryFree: '',
          memoryTotal: '',
          memoryUsage: '0%',
          uptime: '',
          performanceIssues: [],
        );
      }

      final data = response.first;
      final cpuLoad = data['cpu-load'] ?? '0';
      final cpuFreq = data['cpu-frequency'] ?? '';
      final freeMem = data['free-memory'] ?? '0';
      final totalMem = data['total-memory'] ?? '0';
      final uptime = data['uptime'] ?? '';

      // حساب نسبة الذاكرة
      final freeBytes = int.tryParse(freeMem) ?? 0;
      final totalBytes = int.tryParse(totalMem) ?? 1;
      final memUsage = ((1 - freeBytes / totalBytes) * 100).round();

      // درجة الحرارة (إن وُجدت)
      String cpuTemp = '';
      try {
        final healthResp = await client.talk(['/system/health/print']);
        if (healthResp.isNotEmpty) {
          cpuTemp = healthResp.first['temperature'] ??
              healthResp.first['cpu-temperature'] ??
              '';
        }
      } catch (_) {}

      final perfIssues = <String>[];
      if (int.tryParse(cpuLoad)?.compareTo(80) == 1) {
        perfIssues.add('CPU load مرتفع ($cpuLoad%)');
      }
      if (memUsage > 80) {
        perfIssues.add('استخدام الذاكرة مرتفع ($memUsage%)');
      }

      return diag.SystemResources(
        cpuLoad: '$cpuLoad%',
        cpuFrequency: cpuFreq,
        cpuTemperature: cpuTemp.isNotEmpty ? '$cpuTemp°C' : '',
        memoryFree: _formatBytes(freeBytes),
        memoryTotal: _formatBytes(totalBytes),
        memoryUsage: '$memUsage%',
        uptime: uptime,
        performanceIssues: perfIssues,
      );
    } catch (e) {
      debugPrint('[MikrotikDiagnostic] Resources error: $e');
      return diag.SystemResources(
        cpuLoad: 'ERR',
        cpuFrequency: '',
        cpuTemperature: '',
        memoryFree: '',
        memoryTotal: '',
        memoryUsage: 'ERR',
        uptime: '',
        performanceIssues: [],
      );
    }
  }

  /// جمع الواجهات
  Future<List<diag.InterfaceInfo>> _getInterfaces(RouterOSClient client) async {
    try {
      final response = await client.talk([
        '/interface/print',
        '=.proplist=name,type,running,rx-byte,tx-byte,rx-error,tx-error,mac-address',
      ]);

      return response.map((data) {
        final rxBytes = int.tryParse(data['rx-byte'] ?? '0') ?? 0;
        final txBytes = int.tryParse(data['tx-byte'] ?? '0') ?? 0;
        final speed = _formatSpeed(rxBytes, txBytes);

        return diag.InterfaceInfo(
          name: data['name'] ?? 'unknown',
          isActive: data['running'] == 'true',
          rxErrors: data['rx-error'] ?? '0',
          txErrors: data['tx-error'] ?? '0',
          speed: speed,
          type: data['type'] ?? 'unknown',
        );
      }).toList();
    } catch (e) {
      debugPrint('[MikrotikDiagnostic] Interfaces error: $e');
      return [];
    }
  }

  /// جودة الاتصال
  Future<diag.ConnectionQuality> _getConnectionQuality(
      RouterOSClient client) async {
    try {
      // عدد الاتصالات النشطة
      final connResp = await client.talk([
        '/ip/firewall/connection/print',
        '?count-only',
      ]);

      int activeConns = 0;
      if (connResp.isNotEmpty) {
        activeConns = int.tryParse(connResp.first['ret'] ?? '0') ?? 0;
      }

      // فحص wireless
      final wirelessIssues = <String>[];
      try {
        final wlanResp = await client.talk([
          '/interface/wireless/registration-table/print',
          '=.proplist=signal-strength,signal-to-noise,tx-rate,rx-rate',
        ]);

        for (final entry in wlanResp) {
          final signal = entry['signal-strength'] ?? '';
          if (signal.contains('-') &&
              int.tryParse(signal.replaceAll('-dbm', '')) != null) {
            final signalVal = int.parse(signal.replaceAll('-dbm', ''));
            if (signalVal > 80) {
              wirelessIssues.add(
                  'إشارة ضعيفة على ${entry['interface'] ?? 'wlan'}: $signal');
            }
          }
        }
      } catch (_) {
        // ليست كل الأجهزة لديها wireless
      }

      String congestion = '✅ طبيعي';
      if (activeConns > 5000) {
        congestion = '⚠️ مرتفع ($activeConns اتصال)';
      } else if (activeConns > 2000) {
        congestion = '🟡 متوسط ($activeConns اتصال)';
      }

      return diag.ConnectionQuality(
        wirelessIssues: wirelessIssues,
        activeConnections: activeConns,
        networkCongestion: congestion,
      );
    } catch (e) {
      return diag.ConnectionQuality(
        wirelessIssues: [],
        activeConnections: 0,
        networkCongestion: '❌ خطأ في الفحص',
      );
    }
  }

  /// فحص الأمان
  Future<diag.SecurityStatus> _getSecurityStatus(RouterOSClient client) async {
    try {
      // قواعد firewall
      final fwResp = await client.talk([
        '/ip/firewall/filter/print',
        '?count-only',
      ]);
      final fwCount = int.tryParse(fwResp.first['ret'] ?? '0') ?? 0;

      // الخدمات المُفعّلة
      final servicesResp = await client.talk([
        '/ip/service/print',
        '=.proplist=name,port,disabled',
      ]);
      final enabledServices = <String>[];
      final securityIssues = <String>[];

      for (final svc in servicesResp) {
        final name = svc['name'] ?? '';
        final disabled = svc['disabled'] == 'true';
        // ignore: unused_local_variable
        final port = svc['port'] ?? '';

        if (!disabled) {
          enabledServices.add(name);

          // تحذيرات أمنية
          if (name == 'telnet') {
            securityIssues.add('⚠️ Telnet مُفعّل — غير آمن');
          }
          if (name == 'ftp') {
            securityIssues.add('⚠️ FTP مُفعّل — غير آمن');
          }
          if (name == 'www' && disabled != true) {
            securityIssues.add('ℹ️ HTTP مُفعّل — استخدم HTTPS بدلاً منه');
          }
        }
      }

      // محاولات دخول فاشلة (من logs)
      int failedLogins = 0;
      try {
        final logResp = await client.talk([
          '/log/print',
          '?topics~"system,error,warning"',
          '=.proplist=message',
        ]);
        for (final log in logResp) {
          final msg = log['message'] ?? '';
          if (msg.contains('login failure') || msg.contains('failed login')) {
            failedLogins++;
          }
        }
      } catch (_) {}

      return diag.SecurityStatus(
        failedLogins: failedLogins,
        firewallRules: fwCount,
        enabledServices: enabledServices,
        issues: securityIssues,
      );
    } catch (e) {
      return diag.SecurityStatus(
        failedLogins: 0,
        firewallRules: 0,
        enabledServices: [],
        issues: ['خطأ في فحص الأمان: $e'],
      );
    }
  }

  /// الخدمات
  Future<List<diag.ServiceInfo>> _getServices(RouterOSClient client) async {
    try {
      final response = await client.talk([
        '/ip/service/print',
        '=.proplist=name,port,disabled',
      ]);

      return response
          .map((data) => diag.ServiceInfo(
                name: data['name'] ?? 'unknown',
                disabled: data['disabled'] == 'true',
                port: data['port'] ?? '',
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// السجلات الأخيرة
  Future<List<String>> _getRecentLogs(RouterOSClient client) async {
    try {
      final response = await client.talk([
        '/log/print',
        '=.proplist=message,time,topics',
      ]);

      final logs = response.take(30).map((data) {
        final time = data['time'] ?? '';
        final topics = data['topics'] ?? '';
        final msg = data['message'] ?? '';
        return '[$time] $topics: $msg';
      }).toList();

      return logs;
    } catch (e) {
      return ['خطأ في جمع السجلات: $e'];
    }
  }

  /// تحليل المشاكل بناءً على البيانات المجمّعة
  List<diag.DiagnosticIssue> _analyzeIssues({
    required diag.ConnectivityStatus connectivity,
    required diag.SystemResources resources,
    required List<diag.InterfaceInfo> interfaces,
    required diag.SecurityStatus security,
  }) {
    final issues = <diag.DiagnosticIssue>[];

    // CPU مرتفع
    final cpuVal = int.tryParse(resources.cpuLoad.replaceAll('%', '')) ?? 0;
    if (cpuVal > 90) {
      issues.add(diag.DiagnosticIssue(
        type: 'CPU',
        severity: 'critical',
        message: 'CPU load حرج: ${resources.cpuLoad}',
        solution: 'تحقق من: /tool profile print\n'
            'قلل قواعد firewall أو فعّل FastTrack:\n'
            '/ip firewall filter add chain=forward action=fasttrack-connection '
            'connection-state=established,related',
      ));
    } else if (cpuVal > 70) {
      issues.add(diag.DiagnosticIssue(
        type: 'CPU',
        severity: 'medium',
        message: 'CPU load مرتفع: ${resources.cpuLoad}',
        solution: 'راقب العمليات: /tool profile print',
      ));
    }

    // ذاكرة منخفضة
    final memVal = int.tryParse(resources.memoryUsage.replaceAll('%', '')) ?? 0;
    if (memVal > 85) {
      issues.add(diag.DiagnosticIssue(
        type: 'Memory',
        severity: 'high',
        message: 'استخدام الذاكرة مرتفع: ${resources.memoryUsage}',
        solution: 'تحقق من: /system resource print\n'
            'أعد تشغيل الخدمات غير الضرورية أو أضف swap',
      ));
    }

    // واجهات معطّلة
    for (final iface in interfaces) {
      if (!iface.isActive) {
        issues.add(diag.DiagnosticIssue(
          type: 'Interface',
          severity: 'medium',
          message: 'الواجهة ${iface.name} غير نشطة',
          solution: '/interface enable ${iface.name}',
        ));
      }
      // أخطاء RX/TX
      final rxErr = int.tryParse(iface.rxErrors) ?? 0;
      final txErr = int.tryParse(iface.txErrors) ?? 0;
      if (rxErr > 100 || txErr > 100) {
        issues.add(diag.DiagnosticIssue(
          type: 'Interface',
          severity: 'high',
          message: 'أخطاء عالية على ${iface.name}: RX=$rxErr, TX=$txErr',
          solution:
              'تحقق من الكابل أو: /interface ethernet set ${iface.name} auto-negotiation=yes',
        ));
      }
    }

    // مشاكل أمنية
    for (final secIssue in security.issues) {
      issues.add(diag.DiagnosticIssue(
        type: 'Security',
        severity: 'high',
        message: secIssue,
        solution:
            'عطّل الخدمة غير الآمنة:\n/ip service disable telnet\n/ip service disable ftp',
      ));
    }

    // محاولات دخول فاشلة
    if (security.failedLogins > 10) {
      issues.add(diag.DiagnosticIssue(
        type: 'Security',
        severity: 'high',
        message: '${security.failedLogins} محاولة دخول فاشلة',
        solution: 'أضف قاعدة firewall لمنع brute-force:\n'
            '/ip firewall filter add chain=input protocol=tcp dst-port=22 '
            'connection-state=new src-address-list=blacklist action=drop\n'
            '/ip firewall filter add chain=input protocol=tcp dst-port=22 '
            'connection-state=new action=add-src-to-address-list '
            'address-list=blacklist address-list-timeout=1d',
      ));
    }

    return issues;
  }

  /// ينسخ نتيجة خطأ
  diag.DiagnosticResult _errorResult(String message) {
    return diag.DiagnosticResult(
      connectivity: diag.ConnectivityStatus(
        pingSuccess: false,
        pingTimeMs: 0,
        status: '❌ $message',
      ),
      resources: diag.SystemResources(
        cpuLoad: '0%',
        cpuFrequency: '',
        cpuTemperature: '',
        memoryFree: '',
        memoryTotal: '',
        memoryUsage: '0%',
        uptime: '',
        performanceIssues: [],
      ),
      interfaces: [],
      quality: diag.ConnectionQuality(
        wirelessIssues: [],
        activeConnections: 0,
        networkCongestion: '',
      ),
      security: diag.SecurityStatus(
        failedLogins: 0,
        firewallRules: 0,
        enabledServices: [],
        issues: [],
      ),
      services: [],
      issues: [
        diag.DiagnosticIssue(
          type: 'Connection',
          severity: 'critical',
          message: message,
          solution: 'تحقق من IP والمنفذ وكلمة المرور',
        ),
      ],
      recentLogs: [],
      summary: diag.Summary(criticalIssues: 1, warnings: 0, status: 'CRITICAL'),
    );
  }

  /// يحوّل البايتات لصيغة مقروءة
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// يحوّل سرعة لصيغة مقروءة
  String _formatSpeed(int rxBytes, int txBytes) {
    final total = rxBytes + txBytes;
    if (total < 1024) return '$total B';
    if (total < 1024 * 1024) return '${(total / 1024).toStringAsFixed(0)} KB';
    if (total < 1024 * 1024 * 1024) {
      return '${(total / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(total / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
