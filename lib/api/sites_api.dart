import 'package:mikronet/api/version7_api.dart';
import 'package:mikronet/models/response.dart';
// import 'package:mikronet/models/response.dart';
import '/services/mikrotik_client.dart';
// تأكد من استيراد ملف المودل
 import '/models/sites_model.dart'; 

class SitesApi {

  static Future<AppResponse> getDnsData() async {
    try {
      var response = await MikrotikClient.printData(commands: ["/ip/dns/print"]);
      return AppResponse(status: true, message: "done", data: response);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse> setDns({String main = "8.8.8.8", String secondary = "8.8.4.4", bool allowRemoteRequests = true}) async {
    try {
      String dns = '$main,$secondary';
      await MikrotikClient.addData(
        command: "/ip/dns/set", 
        data: {'servers': dns, 'allow-remote-requests': allowRemoteRequests ? 'yes' : 'no'}
      );
      return AppResponse(status: true, message: "done");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // تم التعديل لإرجاع قائمة من DNSCacheModel
  static Future<AppResponse<List<DNSCacheModel>>> getDnsCache() async {
    try {
      var response = await MikrotikClient.printData(commands: ["/ip/dns/cache/print"]);
      List<DNSCacheModel> cacheList = response.map((e) => DNSCacheModel.fromMikrotik(e)).toList();
      return AppResponse<List<DNSCacheModel>>(status: true, message: "done", data: cacheList);
    } catch (e) {
      return AppResponse<List<DNSCacheModel>>(status: false, message: e.toString());
    }
  }

  // ==========================================
  // Layer7 Methods
  // ==========================================

  static Future<List> _getLayer7List() async {
    try {
      return await MikrotikClient.printData(commands: ["/ip/firewall/layer7-protocol/print"]);
    } catch (e) {
      throw e.toString();
    }
  }

  // تم التعديل لإرجاع قائمة من BlockedSiteModel
  static List<BlockedSiteModel> _getRegExp(List filterList, List layer7List) {
    try {
      var newFilters = filterList.where((f) => !f["layer7-protocol"].toString().startsWith("*")).toList();
      List<BlockedSiteModel> result = [];

      for (var filter in newFilters) {
        Map temp = layer7List.firstWhere((layer) => layer["name"] == filter["layer7-protocol"], orElse: () => <String,String>{});

        if (temp["name"] != null && temp['regexp'] != null && temp['regexp'] != '' && temp['.id'] != null) {
          var r = {
            'id': temp['.id'], // المعرف الأساسي للـ Layer7
            'name': temp["name"] ?? "",
            'interface': filter['out-interface'] ?? "all-ethernet",
            'value': temp['regexp'] ?? "",
            'type': 'layer7',
            'layer7-id': temp['.id'] ?? "",
            'filter-id': filter['.id'] ?? "",
          };
          result.add(BlockedSiteModel.fromMikrotik(r));
        }
      }
      return result;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<AppResponse<List<BlockedSiteModel>>> getLayer7BlockedSites() async {
    try {
      var layer7List = await _getLayer7List();
      var response = await MikrotikClient.printData(
        commands: ['/ip/firewall/filter/print'],
        conditions: [
          '?-layer7-protocol',
          '?#!', 
          '?action=drop',
          //'?disabled=no'
        ]
      );
      List<BlockedSiteModel> result = _getRegExp(response, layer7List);
      return AppResponse<List<BlockedSiteModel>>(status: true, message: "done", data: result);
    } catch (e) {
      return AppResponse<List<BlockedSiteModel>>(status: false, message: e.toString());
    }
  }

  // التعديل: تستقبل المودل
  static Future<AppResponse> addBlockByLayer7(BlockedSiteModel site) async {
    try {
      if (MikrotikClient.version==7) {
        return await SitesApi7.addBlockByLayer7(site);
      }
      String comment = "MikroNet_Block_${site.name}";
      
      var layer7 = await MikrotikClient.addData(
        command: "/ip/firewall/layer7-protocol/add",
        data: {'name': site.name, 'regexp': site.blockValue, 'comment': comment}
      );

      var filter = await MikrotikClient.addData(
        command: "/ip/firewall/filter/add",
        data: {
          'action': 'drop',
          'chain': 'forward',
          'layer7-protocol': site.name,
          'out-interface': site.interface.isEmpty ? "all-ethernet" : site.interface,
          'comment': comment
        }
      );
      return AppResponse(status: true, message: "${layer7.toString()} , ${filter.toString()}");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // التعديل: تستقبل المودل
  static Future<AppResponse> editBlockByLayer7(BlockedSiteModel site) async {
    try {
      String comment = "MikroNet_Block_${site.name}";
      
      await MikrotikClient.addData(
        command: "/ip/firewall/layer7-protocol/set",
        data: {
          '.id': site.layer7Id,
          'name': site.name,
          'regexp': site.blockValue,
          'comment': comment
        }
      );

      await MikrotikClient.addData(
        command: "/ip/firewall/filter/set",
        data: {
          '.id': site.filterId,
          'layer7-protocol': site.name,
          'out-interface': site.interface,
          'comment': comment
        }
      );
      
      return AppResponse(status: true, message: "تم التعديل بنجاح");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // التعديل: تستقبل المودل
  static Future<AppResponse> deleteBlockByLayer7(BlockedSiteModel site) async {
    try {
      await MikrotikClient.addData(
        command: "/ip/firewall/filter/remove",
        data: {'.id': site.filterId}
      );

      await MikrotikClient.addData(
        command: "/ip/firewall/layer7-protocol/remove",
        data: {'.id': site.layer7Id}
      );

      return AppResponse(status: true, message: "تم فك الحظر بنجاح");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // ==========================================
  // SSL Methods
  // ==========================================

  static Future<List> _getMangleList() async {
    try {
      return await MikrotikClient.printData(
        commands: ["/ip/firewall/mangle/print"],
        conditions: [
          //"?disabled=no"
          ]
      );
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List> _getFilterList() async {
    try {
      return await MikrotikClient.printData(
        commands: ['/ip/firewall/filter/print'],
        conditions: [
          '?action=drop',
          //'?disabled=no'
          ]
      );
    } catch (e) {
      throw e.toString();
    }
  }

  // تم التعديل لإرجاع قائمة من BlockedSiteModel
  static Future<AppResponse<List<BlockedSiteModel>>> getSSLBlockedSites() async {
    try {
      List filterList = await _getFilterList();
      var mangleList = await _getMangleList();
      
      List tlsFilters = [];
      List dstAddressesFilters = [];
      List tlsMangle = [];

      for (Map i in mangleList) {
        if (i.keys.contains("tls-host") && i.keys.contains("address-list")) {
          tlsMangle.add(i);
        }
      }

      for (Map i in filterList) {
        if (i.keys.contains("tls-host")) {
          tlsFilters.add(i);
        }
        if (i.keys.contains("dst-address-list")) {
          dstAddressesFilters.add(i);
        }
      }

      List<BlockedSiteModel> result = [];

      for (var m in tlsMangle) {
        var matchingTls = tlsFilters.where((t) => t["tls-host"] == m["tls-host"]);
        var matchingDst = dstAddressesFilters.where((d) => d["dst-address-list"] == m["address-list"]);

        if (matchingTls.isNotEmpty && matchingDst.isNotEmpty) {
          var tls = matchingTls.first;
          var dst = matchingDst.first;
          
          // إزالة النجوم من النطاق لعرضه في الواجهة بشكل نظيف
          String domainClean = m['tls-host'].toString().replaceAll('*', '');

          var r = {
            'id': m['.id'], // المعرف الأساسي (Mangle)
            'name': m['address-list'],
            'value': domainClean,
            'interface': tls['out-interface'] ?? "all-ethernet",
            'type': 'ssl',
            'filter-id': tls['.id'],
            'link-id': dst['.id'],
          };
          
          result.add(BlockedSiteModel.fromMikrotik(r));
        }
      }

      return AppResponse<List<BlockedSiteModel>>(status: true, message: "done", data: result);
    } catch (e) {
      return AppResponse<List<BlockedSiteModel>>(status: false, message: e.toString());
    }
  }

  static Future<AppResponse> _addSSLMangle(String name, String domain, String comment) async {
    try {
      var response = await MikrotikClient.addData(
        command: "/ip/firewall/mangle/add",
        data: {
          'action': 'add-dst-to-address-list',
          'address-list': name,
          'address-list-timeout': '1d',
          'chain': 'prerouting',
          'protocol': 'tcp',
          'tls-host': '*$domain*',
          'comment': comment,
        }
      );
      return AppResponse(status: true, message: "done", data: response);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse> _addSSLFilterTls(String outInterface, String domain, String comment) async {
    try {
      var response = await MikrotikClient.addData(
        command: "/ip/firewall/filter/add",
        data: {
          'action': 'drop',
          'chain': 'forward',
          'protocol': 'tcp',
          'tls-host': '*$domain*',
          'out-interface': outInterface,
          'comment': comment,
        }
      );
      return AppResponse(status: true, message: "done", data: response);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse> _linkFilterWithMangle(String name, String outInterface, String comment) async {
    try {
      var response = await MikrotikClient.addData(
        command: "/ip/firewall/filter/add",
        data: {
          'action': 'drop',
          'chain': 'forward',
          'protocol': 'tcp',
          'dst-address-list': name,
          'out-interface': outInterface,
          'comment': comment,
        }
      );
      return AppResponse(status: true, message: "done", data: response);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // التعديل: تستقبل المودل
  static Future<AppResponse> addBlockBySSL(BlockedSiteModel site) async {
    try {
      if (MikrotikClient.version==7) {
        return await SitesApi7.addBlockBySSL(site);
      }
      String comment = "MikroNet_Block_${site.name}";
      String outInterface = site.interface.isEmpty ? "all-ethernet" : site.interface;

      var mangle = await _addSSLMangle(site.name, site.blockValue, comment);
      var tls = await _addSSLFilterTls(outInterface, site.blockValue, comment);
      var link = await _linkFilterWithMangle(site.name, outInterface, comment);
      
      var response = [mangle, tls, link];
      return AppResponse(status: true, message: "${mangle.message} , ${tls.message} , ${link.message}", data: response);
      
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // التعديل: تستقبل المودل
  static Future<AppResponse> editBlockBySSL(BlockedSiteModel site) async {
    try {
      String comment = "MikroNet_Block_${site.name}";

      // 1. تعديل المانجل (يستخدم site.id لأنه تم تعيينه ليكون mangleId في دالة الجلب)
      await MikrotikClient.addData(
        command: "/ip/firewall/mangle/set",
        data: {
          '.id': site.id, 
          'address-list': site.name,
          'tls-host': '*${site.blockValue}*',
          'comment': comment,
        }
      );

      // 2. تعديل فلتر الـ TLS
      await MikrotikClient.addData(
        command: "/ip/firewall/filter/set",
        data: {
          '.id': site.filterId,
          'tls-host': '*${site.blockValue}*',
          'out-interface': site.interface,
          'comment': comment,
        }
      );

      // 3. تعديل فلتر الربط
      await MikrotikClient.addData(
        command: "/ip/firewall/filter/set",
        data: {
          '.id': site.linkId,
          'dst-address-list': site.name,
          'out-interface': site.interface,
          'comment': comment,
        }
      );

      return AppResponse(status: true, message: "تم التعديل بنجاح");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // التعديل: تستقبل المودل
  static Future<AppResponse> deleteBlockBySSL(BlockedSiteModel site) async {
    try {
      // 1. حذف المانجل
      await MikrotikClient.addData(
        command: "/ip/firewall/mangle/remove",
        data: {'.id': site.id} // site.id هو mangleId
      );

      // 2. حذف فلتر الـ TLS
      await MikrotikClient.addData(
        command: "/ip/firewall/filter/remove",
        data: {'.id': site.filterId}
      );

      // 3. حذف فلتر الربط
      await MikrotikClient.addData(
        command: "/ip/firewall/filter/remove",
        data: {'.id': site.linkId}
      );

      return AppResponse(status: true, message: "تم فك الحظر بنجاح");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // ==========================================
  // Fetch All Blocked Sites
  // ==========================================

  // تم التعديل لإرجاع قائمة مدمجة من BlockedSiteModel
  static Future<AppResponse<List<BlockedSiteModel>>> getAllBlockedSites() async {
    try {
      var layer7Response = await getLayer7BlockedSites();
      var sslResponse = await getSSLBlockedSites();
      
      if (!layer7Response.status && !sslResponse.status) {
        return AppResponse<List<BlockedSiteModel>>(status: false, message: "${layer7Response.message} , ${sslResponse.message}");
      }
      
      List<BlockedSiteModel> result = [];
      
      if (sslResponse.data != null) {
        result.addAll(sslResponse.data!);
      }
      
      if (layer7Response.data != null) {
        result.addAll(layer7Response.data!);
      }

      return AppResponse<List<BlockedSiteModel>>(status: true, message: "done", data: result);
      
    } catch (e) {
      return AppResponse<List<BlockedSiteModel>>(status: false, message: e.toString());
    }
  }

}