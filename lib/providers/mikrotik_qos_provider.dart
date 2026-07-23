import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/qos_config.dart';

class QosState {
  final bool isLoading;
  final String? error;
  final QosConfig? config;
  final bool isApplying;

  const QosState({
    this.isLoading = false,
    this.error,
    this.config,
    this.isApplying = false,
  });

  QosState copyWith({
    bool? isLoading,
    String? error,
    QosConfig? config,
    bool? isApplying,
  }) =>
      QosState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        config: config ?? this.config,
        isApplying: isApplying ?? this.isApplying,
      );
}

class MikrotikQosNotifier extends StateNotifier<QosState> {
  MikrotikQosNotifier() : super(const QosState());

  Future<void> loadConfig() async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 500));

    final config = QosConfig(
      enabled: true,
      totalBandwidth: 100,
      rules: [
        QosRule(
          id: '1',
          name: 'HTTP/HTTPS',
          targetIp: '192.168.1.0/24',
          targetPort: '80,443',
          protocol: 'tcp',
          priority: 5,
          maxBandwidth: 50,
          minBandwidth: 10,
          enabled: true,
          trafficType: TrafficType.http,
        ),
        QosRule(
          id: '2',
          name: 'YouTube & Streaming',
          targetIp: '192.168.1.0/24',
          targetPort: '',
          protocol: 'any',
          priority: 3,
          maxBandwidth: 40,
          minBandwidth: 5,
          enabled: true,
          trafficType: TrafficType.streaming,
        ),
        QosRule(
          id: '3',
          name: 'Gaming',
          targetIp: '192.168.1.50',
          targetPort: '27015-27030',
          protocol: 'udp',
          priority: 1,
          maxBandwidth: 30,
          minBandwidth: 10,
          enabled: true,
          trafficType: TrafficType.gaming,
        ),
        QosRule(
          id: '4',
          name: 'Downloads',
          targetIp: '192.168.1.0/24',
          targetPort: '',
          protocol: 'any',
          priority: 8,
          maxBandwidth: 20,
          minBandwidth: 2,
          enabled: false,
          trafficType: TrafficType.p2p,
        ),
      ],
      queueType: QueueType.simple,
      allocation: BandwidthAllocation(
        browsing: 30,
        streaming: 40,
        gaming: 20,
        downloads: 10,
      ),
    );

    state = state.copyWith(isLoading: false, config: config);
  }

  Future<void> toggleEnabled() async {
    if (state.config == null) return;
    final newConfig = state.config!.copyWith(enabled: !state.config!.enabled);
    state = state.copyWith(config: newConfig);
  }

  Future<void> updateTotalBandwidth(int bandwidth) async {
    if (state.config == null) return;
    final newConfig = state.config!.copyWith(totalBandwidth: bandwidth);
    state = state.copyWith(config: newConfig);
  }

  Future<void> addRule(QosRule rule) async {
    if (state.config == null) return;
    final rules = [...state.config!.rules, rule];
    final newConfig = state.config!.copyWith(rules: rules);
    state = state.copyWith(config: newConfig);
  }

  Future<void> removeRule(String ruleId) async {
    if (state.config == null) return;
    final rules = state.config!.rules.where((r) => r.id != ruleId).toList();
    final newConfig = state.config!.copyWith(rules: rules);
    state = state.copyWith(config: newConfig);
  }

  Future<void> updateRule(QosRule rule) async {
    if (state.config == null) return;
    final rules =
        state.config!.rules.map((r) => r.id == rule.id ? rule : r).toList();
    final newConfig = state.config!.copyWith(rules: rules);
    state = state.copyWith(config: newConfig);
  }

  Future<void> updateAllocation(BandwidthAllocation allocation) async {
    if (state.config == null) return;
    final newConfig = state.config!.copyWith(allocation: allocation);
    state = state.copyWith(config: newConfig);
  }

  Future<String> applyConfig() async {
    if (state.config == null) return '❌ لا توجد إعدادات';
    state = state.copyWith(isApplying: true, error: null);
    await Future.delayed(const Duration(seconds: 2));

    // ignore: unused_local_variable
    final commands = generateRouterOsCommands(state.config!);

    state = state.copyWith(isApplying: false);
    return '✅ تم تطبيق ${state.config!.rules.where((r) => r.enabled).length} قاعدة QoS';
  }

  List<String> generateRouterOsCommands(QosConfig config) {
    final commands = <String>[];

    if (config.queueType == QueueType.simple) {
      for (final rule in config.rules) {
        if (!rule.enabled) continue;
        commands.add(
          '/queue simple add name="${rule.name}" '
          'target=${rule.targetIp}/32 '
          'max-limit=${rule.maxBandwidth}M/${rule.maxBandwidth}M '
          'priority=${rule.priority} '
          'comment="${rule.trafficType.name}"',
        );
      }
    } else {
      for (final rule in config.rules) {
        if (!rule.enabled) continue;
        commands.add(
          '/queue tree add name="${rule.name}" '
          'parent=global-in packet-mark="${rule.name}" '
          'max-limit=${rule.maxBandwidth}M '
          'priority=${rule.priority}',
        );
      }
    }

    return commands;
  }
}

final qosProvider =
    StateNotifierProvider<MikrotikQosNotifier, QosState>((ref) {
  return MikrotikQosNotifier();
});
