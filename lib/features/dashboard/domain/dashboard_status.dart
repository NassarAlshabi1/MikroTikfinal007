enum DashboardHealth { healthy, warning, critical }

class DashboardStatus {
  final double cpuUsage;
  final double memoryUsage;
  final String uptime;
  final double dataDownloadedMb;
  final double dataUploadedMb;
  final int activeUsers;
  final String version;

  const DashboardStatus({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.uptime,
    required this.dataDownloadedMb,
    required this.dataUploadedMb,
    required this.activeUsers,
    required this.version,
  });

  factory DashboardStatus.fromJson(Map<String, dynamic> json) {
    return DashboardStatus(
      cpuUsage: (json['cpuUsage'] as num?)?.toDouble() ?? 0,
      memoryUsage: (json['memoryUsage'] as num?)?.toDouble() ?? 0,
      uptime: json['uptime']?.toString() ?? 'غير متوفر',
      dataDownloadedMb:
          (json['dataDownloaded'] as num?)?.toDouble() ?? 0,
      dataUploadedMb: (json['dataUploaded'] as num?)?.toDouble() ?? 0,
      activeUsers: (json['activeUsers'] as num?)?.toInt() ?? 0,
      version: json['version']?.toString() ?? 'غير معروف',
    );
  }

  double get healthScore {
    final pressure = (cpuUsage * 0.55) + (memoryUsage * 0.45);
    return (100 - pressure).clamp(0, 100).toDouble();
  }

  DashboardHealth get health {
    final peak = cpuUsage > memoryUsage ? cpuUsage : memoryUsage;
    if (peak >= 90) return DashboardHealth.critical;
    if (peak >= 75) return DashboardHealth.warning;
    return DashboardHealth.healthy;
  }

  double get totalTrafficMb => dataDownloadedMb + dataUploadedMb;

  Map<String, dynamic> toJson() => {
        'cpuUsage': cpuUsage,
        'memoryUsage': memoryUsage,
        'uptime': uptime,
        'dataDownloaded': dataDownloadedMb,
        'dataUploaded': dataUploadedMb,
        'activeUsers': activeUsers,
        'version': version,
      };
}

class NetworkLinkStatus {
  final bool isLinked;
  final String clientName;

  const NetworkLinkStatus({
    required this.isLinked,
    this.clientName = '',
  });
}
