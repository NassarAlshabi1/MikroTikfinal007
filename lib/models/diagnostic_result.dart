
class DiagnosticResult {
  final ConnectivityStatus connectivity;
  final SystemResources resources;
  final List<InterfaceInfo> interfaces;
  final ConnectionQuality quality;
  final SecurityStatus security;
  final List<ServiceInfo> services;
  final List<DiagnosticIssue> issues;
  final List<String> recentLogs;
  final Summary summary;

  DiagnosticResult({
    required this.connectivity,
    required this.resources,
    required this.interfaces,
    required this.quality,
    required this.security,
    required this.services,
    required this.issues,
    required this.recentLogs,
    required this.summary,
  });

  factory DiagnosticResult.initial() => DiagnosticResult(
        connectivity: ConnectivityStatus(
          pingSuccess: false,
          pingTimeMs: 0,
          status: 'جاري الفحص...',
        ),
        resources: SystemResources(
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
        quality: ConnectionQuality(
          wirelessIssues: [],
          activeConnections: 0,
          networkCongestion: '',
        ),
        security: SecurityStatus(
          failedLogins: 0,
          firewallRules: 0,
          enabledServices: [],
          issues: [],
        ),
        services: [],
        issues: [],
        recentLogs: [],
        summary: Summary(
          criticalIssues: 0,
          warnings: 0,
          status: 'PENDING',
        ),
      );

  Map<String, dynamic> toJson() => {
        'connectivity': connectivity.toJson(),
        'resources': resources.toJson(),
        'interfaces': interfaces.map((e) => e.toJson()).toList(),
        'quality': quality.toJson(),
        'security': security.toJson(),
        'services': services.map((e) => e.toJson()).toList(),
        'issues': issues.map((e) => e.toJson()).toList(),
        'recentLogs': recentLogs,
        'summary': summary.toJson(),
      };

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) =>
      DiagnosticResult(
        connectivity: ConnectivityStatus.fromJson(json['connectivity']),
        resources: SystemResources.fromJson(json['resources']),
        interfaces: (json['interfaces'] as List)
            .map((e) => InterfaceInfo.fromJson(e))
            .toList(),
        quality: ConnectionQuality.fromJson(json['quality']),
        security: SecurityStatus.fromJson(json['security']),
        services: (json['services'] as List)
            .map((e) => ServiceInfo.fromJson(e))
            .toList(),
        issues: (json['issues'] as List)
            .map((e) => DiagnosticIssue.fromJson(e))
            .toList(),
        recentLogs: List<String>.from(json['recentLogs']),
        summary: Summary.fromJson(json['summary']),
      );
}

class ConnectivityStatus {
  final bool pingSuccess;
  final int pingTimeMs;
  final String status;

  ConnectivityStatus({
    required this.pingSuccess,
    required this.pingTimeMs,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'pingSuccess': pingSuccess,
        'pingTimeMs': pingTimeMs,
        'status': status,
      };

  factory ConnectivityStatus.fromJson(Map<String, dynamic> json) =>
      ConnectivityStatus(
        pingSuccess: json['pingSuccess'],
        pingTimeMs: json['pingTimeMs'],
        status: json['status'],
      );
}

class SystemResources {
  final String cpuLoad;
  final String cpuFrequency;
  final String cpuTemperature;
  final String memoryFree;
  final String memoryTotal;
  final String memoryUsage;
  final String uptime;
  final List<String> performanceIssues;

  SystemResources({
    required this.cpuLoad,
    required this.cpuFrequency,
    required this.cpuTemperature,
    required this.memoryFree,
    required this.memoryTotal,
    required this.memoryUsage,
    required this.uptime,
    required this.performanceIssues,
  });

  Map<String, dynamic> toJson() => {
        'cpuLoad': cpuLoad,
        'cpuFrequency': cpuFrequency,
        'cpuTemperature': cpuTemperature,
        'memoryFree': memoryFree,
        'memoryTotal': memoryTotal,
        'memoryUsage': memoryUsage,
        'uptime': uptime,
        'performanceIssues': performanceIssues,
      };

  factory SystemResources.fromJson(Map<String, dynamic> json) =>
      SystemResources(
        cpuLoad: json['cpuLoad'],
        cpuFrequency: json['cpuFrequency'] ?? '',
        cpuTemperature: json['cpuTemperature'] ?? '',
        memoryFree: json['memoryFree'] ?? '',
        memoryTotal: json['memoryTotal'] ?? '',
        memoryUsage: json['memoryUsage'],
        uptime: json['uptime'] ?? '',
        performanceIssues:
            List<String>.from(json['performanceIssues'] ?? []),
      );
}

class InterfaceInfo {
  final String name;
  final bool isActive;
  final String rxErrors;
  final String txErrors;
  final String speed;
  final String type;

  InterfaceInfo({
    required this.name,
    required this.isActive,
    required this.rxErrors,
    required this.txErrors,
    required this.speed,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'isActive': isActive,
        'rxErrors': rxErrors,
        'txErrors': txErrors,
        'speed': speed,
        'type': type,
      };

  factory InterfaceInfo.fromJson(Map<String, dynamic> json) => InterfaceInfo(
        name: json['name'],
        isActive: json['isActive'],
        rxErrors: json['rxErrors'] ?? '0',
        txErrors: json['txErrors'] ?? '0',
        speed: json['speed'] ?? '',
        type: json['type'] ?? '',
      );
}

class ConnectionQuality {
  final List<String> wirelessIssues;
  final int activeConnections;
  final String networkCongestion;

  ConnectionQuality({
    required this.wirelessIssues,
    required this.activeConnections,
    required this.networkCongestion,
  });

  Map<String, dynamic> toJson() => {
        'wirelessIssues': wirelessIssues,
        'activeConnections': activeConnections,
        'networkCongestion': networkCongestion,
      };

  factory ConnectionQuality.fromJson(Map<String, dynamic> json) =>
      ConnectionQuality(
        wirelessIssues: List<String>.from(json['wirelessIssues']),
        activeConnections: json['activeConnections'],
        networkCongestion: json['networkCongestion'] ?? '',
      );
}

class SecurityStatus {
  final int failedLogins;
  final int firewallRules;
  final List<String> enabledServices;
  final List<String> issues;

  SecurityStatus({
    required this.failedLogins,
    required this.firewallRules,
    required this.enabledServices,
    required this.issues,
  });

  Map<String, dynamic> toJson() => {
        'failedLogins': failedLogins,
        'firewallRules': firewallRules,
        'enabledServices': enabledServices,
        'issues': issues,
      };

  factory SecurityStatus.fromJson(Map<String, dynamic> json) =>
      SecurityStatus(
        failedLogins: json['failedLogins'],
        firewallRules: json['firewallRules'],
        enabledServices: List<String>.from(json['enabledServices']),
        issues: List<String>.from(json['issues']),
      );
}

class ServiceInfo {
  final String name;
  final bool disabled;
  final String port;

  ServiceInfo({
    required this.name,
    required this.disabled,
    required this.port,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'disabled': disabled,
        'port': port,
      };

  factory ServiceInfo.fromJson(Map<String, dynamic> json) => ServiceInfo(
        name: json['name'],
        disabled: json['disabled'] ?? false,
        port: json['port'] ?? '',
      );
}

class DiagnosticIssue {
  final String type;
  final String severity;
  final String message;
  final String solution;

  DiagnosticIssue({
    required this.type,
    required this.severity,
    required this.message,
    required this.solution,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'severity': severity,
        'message': message,
        'solution': solution,
      };

  factory DiagnosticIssue.fromJson(Map<String, dynamic> json) =>
      DiagnosticIssue(
        type: json['type'],
        severity: json['severity'],
        message: json['message'],
        solution: json['solution'] ?? '',
      );
}

class Summary {
  final int criticalIssues;
  final int warnings;
  final String status;

  Summary({
    required this.criticalIssues,
    required this.warnings,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'criticalIssues': criticalIssues,
        'warnings': warnings,
        'status': status,
      };

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
        criticalIssues: json['criticalIssues'],
        warnings: json['warnings'],
        status: json['status'],
      );
}
