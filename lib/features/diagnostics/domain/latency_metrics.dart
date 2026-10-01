/// Summary metrics for a batch of latency probes.
///
/// Only finite, non-negative samples are accepted. Samples beyond
/// [packetsSent] are ignored so a duplicated or malformed probe result cannot
/// inflate the received-packet count.
class LatencyMetrics {
  const LatencyMetrics({
    required this.packetsSent,
    required this.packetsReceived,
    required this.packetLossPercent,
    required this.averageMs,
    required this.minimumMs,
    required this.maximumMs,
    required this.jitterMs,
  });

  final int packetsSent;
  final int packetsReceived;
  final double? packetLossPercent;
  final double? averageMs;
  final double? minimumMs;
  final double? maximumMs;

  /// Mean absolute difference between adjacent samples, in milliseconds.
  /// This is a simple stability indicator, not an RFC smoothed-jitter value.
  final double? jitterMs;

  factory LatencyMetrics.fromSamples(
    List<double> samplesMs, {
    required int packetsSent,
  }) {
    if (packetsSent < 0) {
      throw ArgumentError.value(
        packetsSent,
        'packetsSent',
        'Must not be negative.',
      );
    }

    final validSamples = samplesMs
        .where((sample) => sample.isFinite && sample >= 0)
        .take(packetsSent)
        .toList(growable: false);
    final received = validSamples.length;
    final loss = packetsSent == 0
        ? null
        : (packetsSent - received) * 100 / packetsSent;

    if (validSamples.isEmpty) {
      return LatencyMetrics(
        packetsSent: packetsSent,
        packetsReceived: received,
        packetLossPercent: loss,
        averageMs: null,
        minimumMs: null,
        maximumMs: null,
        jitterMs: null,
      );
    }

    final sum = validSamples.reduce((left, right) => left + right);
    final minimum = validSamples.reduce(
      (left, right) => left < right ? left : right,
    );
    final maximum = validSamples.reduce(
      (left, right) => left > right ? left : right,
    );
    final jitter = validSamples.length < 2
        ? null
        : List<double>.generate(
                validSamples.length - 1,
                (index) =>
                    (validSamples[index + 1] - validSamples[index]).abs(),
              ).reduce((left, right) => left + right) /
            (validSamples.length - 1);

    return LatencyMetrics(
      packetsSent: packetsSent,
      packetsReceived: received,
      packetLossPercent: loss,
      averageMs: sum / received,
      minimumMs: minimum,
      maximumMs: maximum,
      jitterMs: jitter,
    );
  }
}
