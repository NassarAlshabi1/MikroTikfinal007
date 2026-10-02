import '/models/response.dart';
import '/services/mikrotik_client.dart';

/// منفذ (Interface) في الراوتر مع عدّادات حركة البيانات.
class RouterInterfaceModel {
  final String id;
  final String name;
  final String type;
  final bool running;
  final bool disabled;
  final int rxByte;
  final int txByte;
  final String comment;

  // تُحدَّث من /interface/monitor-traffic
  double rxBitsPerSecond;
  double txBitsPerSecond;

  RouterInterfaceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.running,
    required this.disabled,
    required this.rxByte,
    required this.txByte,
    required this.comment,
    this.rxBitsPerSecond = 0,
    this.txBitsPerSecond = 0,
  });

  String get statusLabel {
    if (disabled) return "معطّل";
    return running ? "يعمل" : "متوقف";
  }

  static RouterInterfaceModel fromMikrotik(Map data) {
    return RouterInterfaceModel(
      id: data[".id"]?.toString() ?? "",
      name: data["name"]?.toString() ?? "",
      type: data["type"]?.toString() ?? "",
      running: data["running"]?.toString().toLowerCase() == "true",
      disabled: data["disabled"]?.toString().toLowerCase() == "true",
      rxByte: _asInt(data["rx-byte"]),
      txByte: _asInt(data["tx-byte"]),
      comment: data["comment"]?.toString() ?? "",
    );
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// مراقبة متقدمة: الحساسات (الحرارة/الفولت) والمنافذ وحركة البيانات.
class RouterMonitorApi {
  static const String _interfacesFields =
      ".id,name,type,running,disabled,rx-byte,tx-byte,comment";

  /// قراءة الحساسات من `/system/health/print`
  /// (تختلف الأسماء حسب الموديل: temperature, cpu-temperature, voltage...).
  static Future<AppResponse<Map<String, String>>> getHealth() async {
    try {
      final response = await MikrotikClient.printData(
        commands: ["/system/health/print"],
        tag: "router_health",
      );

      final result = <String, String>{};
      for (final item in response) {
        if (item is Map) {
          item.forEach((key, value) {
            final name = key.toString().replaceAll('-', ' ').trim();
            if (value != null && value.toString().isNotEmpty && name != ".id") {
              result[name] = value.toString();
            }
          });
          break; // أول سجل يكفي
        }
      }
      return AppResponse(status: true, message: "done", data: result);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// قائمة المنافذ مع العدّادات.
  static Future<AppResponse<List<RouterInterfaceModel>>> getInterfaces() async {
    try {
      final response = await MikrotikClient.printData(
        commands: ["/interface/print"],
        fields: _interfacesFields,
        tag: "router_interfaces",
      );

      final interfaces = response
          .whereType<Map>()
          .map((e) => RouterInterfaceModel.fromMikrotik(e))
          .toList();

      return AppResponse(status: true, message: "done", data: interfaces);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// قراءة لحظية لحركة منفذ واحد (Kbit/s) عبر `/interface/monitor-traffic`.
  static Future<AppResponse<Map<String, double>>> getInterfaceTraffic(String interfaceName) async {
    try {
      final response = await MikrotikClient.fetch(
        command: ["/interface/monitor-traffic"],
        params: {
          "interface": interfaceName,
          "once": "",
        },
        customTag: "router_traffic",
      );

      double rx = 0;
      double tx = 0;

      for (final item in response) {
        if (item is Map) {
          rx = _asDouble(item["rx-bits-per-second"]);
          tx = _asDouble(item["tx-bits-per-second"]);
          break;
        }
      }

      return AppResponse(
        status: true,
        message: "done",
        data: {"rx": rx, "tx": tx},
      );
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
