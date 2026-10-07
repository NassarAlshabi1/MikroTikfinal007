class SellesReportModel {
  final int? id;
  final String card;
  final String profile;
  final double price;
  final String date;
  final int timestamp;
  
  SellesReportModel({
    this.id,
    required this.card,
    required this.profile,
    required this.price,
    required this.date,
    int? timestamp,
  }) : timestamp = timestamp ?? 0;

  static SellesReportModel fromDatabase(Map data) {
    return SellesReportModel(
      id: data['id'] is int ? data['id'] : int.tryParse(data['id']?.toString() ?? '0'),
      card: data['card_username']?.toString() ?? '',
      profile: data['profile_name']?.toString() ?? '',
      price: double.tryParse(data['price']?.toString() ?? '0') ?? 0.0,
      date: data['sale_date']?.toString() ?? '',
      timestamp: data['timestamp'] is int ? data['timestamp'] : int.tryParse(data['timestamp']?.toString() ?? '0') ?? 0,
    );
  }

  static SellesReportModel fromMikrotik(Map session) {
    return SellesReportModel(
      card: session["user"]?.toString() ?? "", 
      profile: session["profile"]?.toString() ?? session["profie"]?.toString() ?? "", 
      price: double.tryParse(session["price"]?.toString() ?? "0") ?? 0.0, 
      date: session["trans-start"]?.toString() ?? session["tras-start"]?.toString() ?? "", 
    );
  }

  Map<String, dynamic> toDatabase({String routerSerial = '', String source = 'usermanager'}) {
    return {
      'card_username': card,
      'profile_name': profile,
      'price': price,
      'sale_date': date,
      'timestamp': timestamp > 0 ? timestamp : DateTime.now().millisecondsSinceEpoch,
      'router_serial': routerSerial,
      'source': source,
    };
  }
}

class SystemStateModel {
  final String uptime;
  final String totalMemory;
  final String freeMemory;
  final String cpu;
  final String version;
  final String totalDiskSpace;
  final String freeDiskSpace;
  
  SystemStateModel({
    required this.uptime,
    required this.totalMemory,
    required this.freeMemory,
    required this.cpu,
    required this.version,
    required this.totalDiskSpace,
    required this.freeDiskSpace,
  });

  static SystemStateModel fromMikrotik(Map system) {
    return SystemStateModel(
      uptime: system["uptime"] ?? "", 
      totalMemory: system["total-memory"] ?? "", 
      freeMemory: system["free-memory"] ?? "", 
      cpu: system["cpu-load"] ?? "", 
      version: system["version"] ?? "", 
      totalDiskSpace: system["total-hdd-space"]?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? "", 
      freeDiskSpace: system["free-hdd-space"]?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? "", 
    );
  }
}
