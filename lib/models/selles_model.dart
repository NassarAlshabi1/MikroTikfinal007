class SellesReportModel {
  final String card;
  final String profile;
  final double price;
  final String date;
  
  SellesReportModel({
    required this.card,
    required this.profile,
    required this.price,
    required this.date,
  });

  static SellesReportModel fromMikrotik(Map session){
    return SellesReportModel(
      card: session["user"]??"", 
      profile: session["profie"]??"", // تأكد من الإملاء إذا كان profile في المايكروتك
      price: session["price"]??"", 
      date: session["tras-start"]??"", // تأكد من الإملاء trans-start
    );
  }
}

class SystemStateModel {
  final String uptime;
  final String totalMemory;
  final String freeMemory;
  final String cpu;
  final String version;
  // 🔹 الحقول الجديدة للقرص
  final String totalDiskSpace;
  final String freeDiskSpace;
  
  SystemStateModel({
    required this.uptime,
    required this.totalMemory,
    required this.freeMemory,
    required this.cpu,
    required this.version,
    required this.totalDiskSpace, // 🔹 إضافة للمُشيد
    required this.freeDiskSpace,  // 🔹 إضافة للمُشيد
  });

  static SystemStateModel fromMikrotik(Map system){
    return SystemStateModel(
      uptime: system["uptime"]??"", 
      totalMemory: system["total-memory"]??"", 
      freeMemory: system["free-memory"]??"", 
      cpu: system["cpu-load"]??"", 
      version: system["version"]??"", 
      // 🔹 ربط قيم القرص من المايكروتك
      totalDiskSpace: system["total-hdd-space"]?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? "", 
      freeDiskSpace: system["free-hdd-space"]?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? "", 
    );
  }
}