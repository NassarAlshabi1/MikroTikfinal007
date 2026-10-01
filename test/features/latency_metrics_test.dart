import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/features/diagnostics/domain/latency_metrics.dart';

void main() {
  group('LatencyMetrics', () {
    test('calculates average, range, jitter, and packet loss', () {
      final metrics = LatencyMetrics.fromSamples(
        [10, 20, 30],
        packetsSent: 4,
      );

      expect(metrics.packetsSent, 4);
      expect(metrics.packetsReceived, 3);
      expect(metrics.packetLossPercent, 25);
      expect(metrics.averageMs, 20);
      expect(metrics.minimumMs, 10);
      expect(metrics.maximumMs, 30);
      expect(metrics.jitterMs, 10);
    });

    test('reports full packet loss when no valid replies arrive', () {
      final metrics = LatencyMetrics.fromSamples(
        [double.nan, -1, double.infinity],
        packetsSent: 4,
      );

      expect(metrics.packetsReceived, 0);
      expect(metrics.packetLossPercent, 100);
      expect(metrics.averageMs, isNull);
      expect(metrics.jitterMs, isNull);
    });

    test('ignores extra samples beyond the number of probes sent', () {
      final metrics = LatencyMetrics.fromSamples(
        [10, 20, 30, 40, 1000],
        packetsSent: 4,
      );

      expect(metrics.packetsReceived, 4);
      expect(metrics.averageMs, 25);
      expect(metrics.packetLossPercent, 0);
    });
  });
}
