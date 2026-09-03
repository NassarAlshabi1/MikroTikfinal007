enum QueueType { simple, queueTree, pcq }

enum TrafficType { http, streaming, gaming, voip, p2p, other }

class QosConfig {
  final bool enabled;
  final int totalBandwidth;
  final List<QosRule> rules;
  final QueueType queueType;
  final BandwidthAllocation allocation;

  QosConfig({
    required this.enabled,
    required this.totalBandwidth,
    required this.rules,
    required this.queueType,
    required this.allocation,
  });

  factory QosConfig.initial() => QosConfig(
        enabled: false,
        totalBandwidth: 100,
        rules: [],
        queueType: QueueType.simple,
        allocation: BandwidthAllocation(
          browsing: 30,
          streaming: 40,
          gaming: 20,
          downloads: 10,
        ),
      );

  QosConfig copyWith({
    bool? enabled,
    int? totalBandwidth,
    List<QosRule>? rules,
    QueueType? queueType,
    BandwidthAllocation? allocation,
  }) =>
      QosConfig(
        enabled: enabled ?? this.enabled,
        totalBandwidth: totalBandwidth ?? this.totalBandwidth,
        rules: rules ?? this.rules,
        queueType: queueType ?? this.queueType,
        allocation: allocation ?? this.allocation,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'totalBandwidth': totalBandwidth,
        'rules': rules.map((e) => e.toJson()).toList(),
        'queueType': queueType.name,
        'allocation': allocation.toJson(),
      };

  factory QosConfig.fromJson(Map<String, dynamic> json) => QosConfig(
        enabled: json['enabled'],
        totalBandwidth: json['totalBandwidth'],
        rules: (json['rules'] as List).map((e) => QosRule.fromJson(e)).toList(),
        queueType: QueueType.values.firstWhere(
          (e) => e.name == json['queueType'],
          orElse: () => QueueType.simple,
        ),
        allocation: BandwidthAllocation.fromJson(json['allocation']),
      );
}

class QosRule {
  final String id;
  final String name;
  final String targetIp;
  final String targetPort;
  final String protocol;
  final int priority;
  final int maxBandwidth;
  final int minBandwidth;
  final bool enabled;
  final TrafficType trafficType;

  QosRule({
    required this.id,
    required this.name,
    required this.targetIp,
    required this.targetPort,
    required this.protocol,
    required this.priority,
    required this.maxBandwidth,
    required this.minBandwidth,
    required this.enabled,
    required this.trafficType,
  });

  QosRule copyWith({
    String? id,
    String? name,
    String? targetIp,
    String? targetPort,
    String? protocol,
    int? priority,
    int? maxBandwidth,
    int? minBandwidth,
    bool? enabled,
    TrafficType? trafficType,
  }) =>
      QosRule(
        id: id ?? this.id,
        name: name ?? this.name,
        targetIp: targetIp ?? this.targetIp,
        targetPort: targetPort ?? this.targetPort,
        protocol: protocol ?? this.protocol,
        priority: priority ?? this.priority,
        maxBandwidth: maxBandwidth ?? this.maxBandwidth,
        minBandwidth: minBandwidth ?? this.minBandwidth,
        enabled: enabled ?? this.enabled,
        trafficType: trafficType ?? this.trafficType,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetIp': targetIp,
        'targetPort': targetPort,
        'protocol': protocol,
        'priority': priority,
        'maxBandwidth': maxBandwidth,
        'minBandwidth': minBandwidth,
        'enabled': enabled,
        'trafficType': trafficType.name,
      };

  factory QosRule.fromJson(Map<String, dynamic> json) => QosRule(
        id: json['id'],
        name: json['name'],
        targetIp: json['targetIp'],
        targetPort: json['targetPort'] ?? '',
        protocol: json['protocol'] ?? 'any',
        priority: json['priority'],
        maxBandwidth: json['maxBandwidth'],
        minBandwidth: json['minBandwidth'] ?? 0,
        enabled: json['enabled'],
        trafficType: TrafficType.values.firstWhere(
          (e) => e.name == json['trafficType'],
          orElse: () => TrafficType.other,
        ),
      );
}

class BandwidthAllocation {
  final int browsing;
  final int streaming;
  final int gaming;
  final int downloads;

  BandwidthAllocation({
    required this.browsing,
    required this.streaming,
    required this.gaming,
    required this.downloads,
  });

  int get total => browsing + streaming + gaming + downloads;
  bool get isValid => total == 100;

  BandwidthAllocation copyWith({
    int? browsing,
    int? streaming,
    int? gaming,
    int? downloads,
  }) =>
      BandwidthAllocation(
        browsing: browsing ?? this.browsing,
        streaming: streaming ?? this.streaming,
        gaming: gaming ?? this.gaming,
        downloads: downloads ?? this.downloads,
      );

  Map<String, dynamic> toJson() => {
        'browsing': browsing,
        'streaming': streaming,
        'gaming': gaming,
        'downloads': downloads,
      };

  factory BandwidthAllocation.fromJson(Map<String, dynamic> json) =>
      BandwidthAllocation(
        browsing: json['browsing'],
        streaming: json['streaming'],
        gaming: json['gaming'],
        downloads: json['downloads'],
      );
}
