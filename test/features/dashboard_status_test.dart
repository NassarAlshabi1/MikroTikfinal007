import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/features/dashboard/domain/dashboard_status.dart';

void main() {
  DashboardStatus status({
    required double cpu,
    required double memory,
    double download = 0,
    double upload = 0,
  }) {
    return DashboardStatus(
      cpuUsage: cpu,
      memoryUsage: memory,
      uptime: '1h',
      dataDownloadedMb: download,
      dataUploadedMb: upload,
      activeUsers: 1,
      version: '6.49',
    );
  }

  test('classifies healthy, warning, and critical resource pressure', () {
    expect(status(cpu: 30, memory: 40).health, DashboardHealth.healthy);
    expect(status(cpu: 75, memory: 40).health, DashboardHealth.warning);
    expect(status(cpu: 20, memory: 90).health, DashboardHealth.critical);
  });

  test('calculates a bounded weighted health score', () {
    expect(status(cpu: 0, memory: 0).healthScore, 100);
    expect(status(cpu: 100, memory: 100).healthScore, 0);
    expect(status(cpu: 80, memory: 60).healthScore, 29);
  });

  test('aggregates uploaded and downloaded traffic', () {
    expect(
      status(cpu: 10, memory: 10, download: 120.5, upload: 29.5)
          .totalTrafficMb,
      150,
    );
  });
}
