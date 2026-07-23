import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/diagnostic_result.dart';

class DiagnosticState {
  final bool isLoading;
  final String? error;
  final DiagnosticResult? result;
  final bool isRunning;
  final String? currentStage;

  const DiagnosticState({
    this.isLoading = false,
    this.error,
    this.result,
    this.isRunning = false,
    this.currentStage,
  });

  DiagnosticState copyWith({
    bool? isLoading,
    String? error,
    DiagnosticResult? result,
    bool? isRunning,
    String? currentStage,
  }) =>
      DiagnosticState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        result: result ?? this.result,
        isRunning: isRunning ?? this.isRunning,
        currentStage: currentStage ?? this.currentStage,
      );

  int get healthScore {
    if (result == null) return 0;
    final r = result!;
    var score = 100;

    final cpu = int.tryParse(r.resources.cpuLoad.replaceAll('%', '')) ?? 0;
    if (cpu > 90) {
      score -= 30;
    } else if (cpu > 70) {
      score -= 15;
    } else if (cpu > 50) {
      score -= 5;
    }

    if (r.connectivity.pingTimeMs > 200) {
      score -= 20;
    } else if (r.connectivity.pingTimeMs > 100) {
      score -= 10;
    }

    score -= r.issues.length * 10;

    if (!r.connectivity.pingSuccess) score -= 50;
    score -= r.security.issues.length * 15;

    return score.clamp(0, 100);
  }
}

class MikrotikDiagnosticNotifier extends StateNotifier<DiagnosticState> {
  MikrotikDiagnosticNotifier() : super(const DiagnosticState());

  Future<void> runDiagnostic() async {
    state = state.copyWith(
        isLoading: true, error: null, currentStage: 'جاري جمع البيانات...');

    await Future.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(currentStage: 'فحص الاتصال...');
    await Future.delayed(const Duration(milliseconds: 800));

    state = state.copyWith(currentStage: 'فحص موارد النظام...');
    await Future.delayed(const Duration(milliseconds: 600));

    state = state.copyWith(currentStage: 'تحليل الأمان...');
    await Future.delayed(const Duration(milliseconds: 700));

    final result = DiagnosticResult(
      connectivity: ConnectivityStatus(
        pingSuccess: true,
        pingTimeMs: 15,
        status: '✅ متصل',
      ),
      resources: SystemResources(
        cpuLoad: '35%',
        cpuFrequency: '800MHz',
        cpuTemperature: '42°C',
        memoryFree: '128MiB',
        memoryTotal: '256MiB',
        memoryUsage: '50%',
        uptime: '15d 6h 30m',
        performanceIssues: [],
      ),
      interfaces: [
        InterfaceInfo(
          name: 'ether1',
          isActive: true,
          rxErrors: '0',
          txErrors: '0',
          speed: '1Gbps',
          type: 'Ethernet',
        ),
        InterfaceInfo(
          name: 'wlan1',
          isActive: true,
          rxErrors: '2',
          txErrors: '1',
          speed: '300Mbps',
          type: 'Wireless',
        ),
        InterfaceInfo(
          name: 'bridge_local',
          isActive: true,
          rxErrors: '0',
          txErrors: '0',
          speed: '1Gbps',
          type: 'Bridge',
        ),
      ],
      quality: ConnectionQuality(
        wirelessIssues: [],
        activeConnections: 1250,
        networkCongestion: '✅ طبيعي',
      ),
      security: SecurityStatus(
        failedLogins: 3,
        firewallRules: 15,
        enabledServices: ['ssh', 'api', 'winbox'],
        issues: [],
      ),
      services: [
        ServiceInfo(name: 'SSH', disabled: false, port: '22'),
        ServiceInfo(name: 'API', disabled: false, port: '8728'),
        ServiceInfo(name: 'DHCP Server', disabled: false, port: '67'),
        ServiceInfo(name: 'DNS', disabled: false, port: '53'),
        ServiceInfo(name: 'WinBox', disabled: false, port: '8291'),
      ],
      issues: [
        DiagnosticIssue(
          type: 'NAT',
          severity: 'medium',
          message: 'لا توجد قاعدة NAT Masquerade',
          solution:
              'أضف قاعدة NAT: /ip firewall nat add chain=srcnat action=masquerade out-interface=ether1',
        ),
        DiagnosticIssue(
          type: 'DNS',
          severity: 'low',
          message: 'لم يتم تعيين DNS سيرفر خارجي',
          solution: 'أضف DNS: /ip dns set servers=8.8.8.8,1.1.1.1',
        ),
      ],
      recentLogs: [
        'warning: interface ether1 link up',
        'info: DHCP lease 192.168.1.100 assigned',
        'error: failed login attempt from 10.0.0.50',
        'info: backup completed successfully',
      ],
      summary: Summary(
        criticalIssues: 0,
        warnings: 2,
        status: 'WARNING',
      ),
    );

    state = state.copyWith(
      isLoading: false,
      result: result,
      currentStage: null,
    );
  }

  void reset() {
    state = const DiagnosticState();
  }
}

final diagnosticProvider =
    StateNotifierProvider<MikrotikDiagnosticNotifier, DiagnosticState>((ref) {
  return MikrotikDiagnosticNotifier();
});
