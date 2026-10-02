import '../models/response.dart';
import '../services/cable_diagnostics.dart';
import '../services/mikrotik_client.dart';

/// أدوات الصيانة والتشخيص لراوتر RouterOS.
///
/// تغطّي: Ping، اختبار النطاق (Traceroute)، Torch، Fetch، Sniffer،
/// السجل (Log)، الجيران (Neighbor)، الاتصالات النشطة، RouterBOARD،
/// والقراءة العامة لأي قائمة في الراوتر (IP / DHCP / ARP / NAT / Firewall / Queue).
class MaintenanceApi {
  // ================= أدوات التشخيص =================

  /// Ping إلى عنوان، مع إرجاع أسطر النتائج.
  static Future<AppResponse<List<Map<String, String>>>> ping({
    required String address,
    int count = 5,
  }) async {
    try {
      final response = await MikrotikClient.fetch(
        command: ["/ping"],
        params: {"address": address, "count": "$count"},
        customTag: "tool_ping",
      );

      final rows = response
          .whereType<Map>()
          .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
          .toList();

      if (rows.isEmpty) {
        return AppResponse(status: false, message: "لا يوجد رد من العنوان $address");
      }
      return AppResponse(status: true, message: "done", data: rows);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// اختبار النطاق (Traceroute).
  static Future<AppResponse<List<Map<String, String>>>> traceroute({
    required String address,
    int count = 1,
  }) async {
    try {
      final response = await MikrotikClient.fetch(
        command: ["/tool/traceroute"],
        params: {"address": address, "count": "$count"},
        customTag: "tool_traceroute",
      );

      final rows = response
          .whereType<Map>()
          .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
          .toList();

      if (rows.isEmpty) {
        return AppResponse(status: false, message: "لا توجد نتائج للعنوان $address");
      }
      return AppResponse(status: true, message: "done", data: rows);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// Torch: عرض حيّ للحركة على منفذ (يبقى مفتوحًا حتى الإيقاف).
  static Stream<Map<String, String>> torch({required String interface}) async* {
    final stream = MikrotikClient.fetchStream(
      command: ["/tool/torch"],
      params: {
        "interface": interface,
        "src-address": "0.0.0.0/0",
        "dst-address": "0.0.0.0/0",
      },
      customTag: "tool_torch",
    );

    await for (final row in stream) {
      yield row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ""));
    }
  }

  static Future<void> stopTorch() => MikrotikClient.cancelCommand("tool_torch");

  /// Fetch: تنزيل ملف إلى ذاكرة الراوتر.
  static Future<AppResponse<List<Map<String, String>>>> fetchUrl({
    required String url,
    String dstPath = "",
    String mode = "",
  }) async {
    try {
      final params = <String, String>{"url": url};
      if (dstPath.isNotEmpty) params["dst-path"] = dstPath;
      if (mode.isNotEmpty) params["mode"] = mode;

      final response = await MikrotikClient.fetch(
        command: ["/tool/fetch"],
        params: params,
        customTag: "tool_fetch",
      );

      final rows = response
          .whereType<Map>()
          .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
          .toList();
      return AppResponse(status: true, message: "تم تنفيذ Fetch", data: rows);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // ================= تنقيط الحزم Sniffer =================

  static Future<AppResponse<Map<String, String>>> snifferStatus() async {
    try {
      final response = await MikrotikClient.printData(
        commands: ["/tool/sniffer/print"],
        tag: "tool_sniffer_status",
      );
      if (response.isNotEmpty && response.first is Map) {
        final row = (response.first as Map)
            .map((key, value) => MapEntry(key.toString(), value?.toString() ?? ""));
        return AppResponse(status: true, message: "done", data: row);
      }
      return AppResponse(status: false, message: "لا توجد بيانات للـ Sniffer");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<void>> snifferStart({
    required String interface,
    String fileName = "mikronet_sniffer",
    String memoryLimit = "1000",
    String filterStream = "",
  }) async {
    try {
      final params = <String, String>{
        "interface": interface,
        "file-name": fileName,
        "memory-limit": memoryLimit,
      };
      if (filterStream.isNotEmpty) params["filter-stream"] = filterStream;

      await MikrotikClient.fetch(
        command: ["/tool/sniffer/start"],
        params: params,
        customTag: "tool_sniffer_start",
      );
      return AppResponse(status: true, message: "تم تشغيل التقاط الحزم على $interface");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<void>> snifferStop() async {
    try {
      await MikrotikClient.fetch(
        command: ["/tool/sniffer/stop"],
        customTag: "tool_sniffer_stop",
      );
      return AppResponse(status: true, message: "تم إيقاف التقاط الحزم");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // ================= مراقبة الأداء =================

  /// بطاقة RouterBOARD.
  static Future<AppResponse<Map<String, String>>> routerboard() async {
    try {
      final response = await MikrotikClient.printData(
        commands: ["/system/routerboard/print"],
        tag: "tool_routerboard",
      );
      return _firstRow(response);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// الاتصالات النشطة (عدد + عيّنة).
  static Future<AppResponse<List<Map<String, String>>>> activeConnections({int limit = 100}) async {
    try {
      final response = await MikrotikClient.printData(
        commands: ["/ip/firewall/connection/print"],
        fields: ".id,protocol,src-address,dst-address,state,timeout",
        tag: "tool_connections",
      );
      final rows = response
          .whereType<Map>()
          .take(limit)
          .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
          .toList();
      return AppResponse(status: true, message: "done", data: rows);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// أجهزة البث (Neighbor Discovery).
  static Future<AppResponse<List<Map<String, String>>>> neighbors() async {
    return _printList(
      command: "/ip/neighbor/print",
      fields: ".id,address,mac-address,identity,platform,version,interface,board",
      tag: "tool_neighbors",
    );
  }

  /// سجل النظام (آخر الأحداث).
  static Future<AppResponse<List<Map<String, String>>>> logs({int limit = 150}) async {
    try {
      final response = await MikrotikClient.printData(
        commands: ["/log/print"],
        fields: ".id,time,topics,message",
        tag: "tool_logs",
      );
      final rows = response
          .whereType<Map>()
          .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
          .toList()
          .reversed
          .take(limit)
          .toList();
      return AppResponse(status: true, message: "done", data: rows);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// رسم بياني (Graphing) للمنافذ المفعّلة.
  static Future<AppResponse<List<Map<String, String>>>> graphing() async {
    return _printList(
      command: "/tool/graphing/print",
      fields: ".id,name,interface,allow-address,disabled",
      tag: "tool_graphing",
    );
  }

  // ================= القراءة العامة لأي قائمة =================

  // ================= فحص الكيبل والمنافذ =================

  /// منافذ الإيثرنت في الراوتر (للاختيار في صفحة فحص الكيبل).
  static Future<AppResponse<List<Map<String, String>>>> ethernetPorts() async {
    const attempts = [
      ".id,name,default-name,running,disabled,slave,switch,comment",
      ".id,name,running,disabled,comment",
      ".id,name",
    ];

    Object? lastError;
    for (final fields in attempts) {
      try {
        final response = await MikrotikClient.printData(
          commands: ["/interface/ethernet/print"],
          fields: fields,
          tag: "tool_eth_ports",
        );
        return AppResponse(status: true, message: "done", data: _toRows(response));
      } catch (e) {
        lastError = e;
      }
    }

    // بعض الأجهزة القديمة لا تملك قائمة /interface/ethernet ⇒ نرجع لكل المنافذ
    try {
      final response = await MikrotikClient.printData(
        commands: ["/interface/print"],
        fields: ".id,name,type,running,disabled,comment",
        tag: "tool_iface_ports",
      );
      final rows = _toRows(response).where((row) {
        final type = (row["type"] ?? "").toLowerCase();
        final name = (row["name"] ?? "").toLowerCase();
        if (type.isNotEmpty && !type.contains('ether')) return false;
        if (name.startsWith('sfp')) return false;
        return true;
      }).toList();
      return AppResponse(status: true, message: "done", data: rows);
    } catch (_) {
      return AppResponse(
        status: false,
        message: lastError?.toString() ?? "تعذّر قراءة منافذ الإيثرنت",
      );
    }
  }

  /// فحص أزواج الكيبل (`/interface/ethernet/cable-test`).
  ///
  /// يرجع الصفوف الخام ليتولّى `CableTestResult.parse` تفسيرها، مع رسالة خطأ
  /// عربية واضحة عند عدم دعم الميزة (SFP / CHR / إصدار بلا دعم).
  static Future<AppResponse<List<Map<String, String>>>> cableTest({
    required String interfaceName,
  }) async {
    Object? lastError;

    for (final command in CableDiagnostics.cableTestCommandCandidates(interfaceName)) {
      try {
        final response = await MikrotikClient.fetch(
          command: command,
          customTag: "tool_cable_test",
        );
        return AppResponse(status: true, message: "done", data: _toRows(response));
      } catch (e) {
        lastError = e;
        final text = e.toString().toLowerCase();
        // خطأ "غير مدعوم"/"لا يوجد أمر" ⇒ لا فائدة من تجربة صيغ أخرى
        if (text.contains('not supported') ||
            text.contains('unsupported') ||
            text.contains('no such command') ||
            text.contains('unknown command')) {
          break;
        }
      }
    }

    return AppResponse(
      status: false,
      message: CableDiagnostics.friendlyError(lastError?.toString() ?? ""),
    );
  }

  /// معلومات الاتصال الفعلية (السرعة · duplex) من `/interface/ethernet/monitor once`.
  static Future<AppResponse<EthernetLinkInfo>> ethernetMonitor({
    required String interfaceName,
  }) async {
    Object? lastError;

    for (final command in CableDiagnostics.monitorCommandCandidates(interfaceName)) {
      try {
        final response = await MikrotikClient.fetch(
          command: command,
          customTag: "tool_eth_monitor",
        );
        return AppResponse(
          status: true,
          message: "done",
          data: EthernetLinkInfo.parse(interfaceName: interfaceName, rows: response),
        );
      } catch (e) {
        lastError = e;
      }
    }

    return AppResponse(
      status: false,
      message: CableDiagnostics.friendlyError(lastError?.toString() ?? ""),
    );
  }

  /// تحويل استجابة الراوتر إلى قائمة صفوف نصية.
  static List<Map<String, String>> _toRows(List response) {
    return response
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
        .toList();
  }

  /// قراءة أي قائمة في RouterOS (تُستخدم لعرض IP / DHCP / ARP / NAT / Queue ...).
  static Future<AppResponse<List<Map<String, String>>>> printList(RouterMenuSpec menu) {
    return _printList(command: menu.command, fields: menu.fields, tag: "tool_menu_${menu.id}");
  }

  /// عدّ العناصر فقط (طلب خفيف بـ .id).
  static Future<int> countOnly(String command) async {
    try {
      final response = await MikrotikClient.printData(
        commands: [command],
        fields: ".id",
        tag: "tool_count",
      );
      return response.length;
    } catch (_) {
      return -1;
    }
  }

  static Future<AppResponse<List<Map<String, String>>>> _printList({
    required String command,
    required String fields,
    required String tag,
  }) async {
    try {
      final response = await MikrotikClient.printData(
        commands: [command],
        fields: fields,
        tag: tag,
      );
      final rows = response
          .whereType<Map>()
          .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
          .toList();
      return AppResponse(status: true, message: "done", data: rows);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static AppResponse<Map<String, String>> _firstRow(List response) {
    if (response.isEmpty || response.first is! Map) {
      return AppResponse(status: false, message: "لا توجد بيانات");
    }
    final row = (response.first as Map)
        .map((key, value) => MapEntry(key.toString(), value?.toString() ?? ""));
    return AppResponse(status: true, message: "done", data: row);
  }
}

/// وصف قائمة في RouterOS لعرضها في واجهة عامة.
class RouterMenuSpec {
  final String id;
  final String title;
  final String subtitle;
  final String command;
  final String fields;
  final List<String> primaryKeys;

  const RouterMenuSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.command,
    required this.fields,
    this.primaryKeys = const ["name", "address", "src-address", "dst-address", "mac-address"],
  });
}
