import 'package:get/get.dart';

import 'package:mikronet/features/sites/models/sites_model.dart';
import 'package:mikronet/features/cards/models/profiles_model.dart';
import 'package:mikronet/core/mikrotik/mikrotik_client.dart';
import 'package:mikronet/core/models/app_response.dart';
import 'package:mikronet/features/cards/models/cards_model.dart';


class SitesApi7 {

  
    // ==========================================
  // Layer7 Methods (RouterOS v7)
  // ==========================================

  static Future<AppResponse> addBlockByLayer7(BlockedSiteModel site) async {
    try {
      String comment = "MikroNet_Block_${site.name}_[v7]";
      
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

  static Future<AppResponse> editBlockByLayer7(BlockedSiteModel site) async {
    try {
      String comment = "MikroNet_Block_${site.name}_[v7]";
      
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

  // ==========================================
  // SSL Methods
  // ==========================================
  // ==========================================
  // SSL Methods (RouterOS v7)
  // ==========================================

  static Future<AppResponse> _addSSLMangleV7(String name, String domain, String comment) async {
    try {
      var response = await MikrotikClient.addData(
        command: "/ip/firewall/mangle/add",
        data: {
          'action': 'add-dst-to-address-list',
          'address-list': name,
          'address-list-timeout': '1d',
          'chain': 'prerouting',
          'protocol': 'tcp',
          'dst-port': '443', // إضافة مخصصة لـ V7
          'tls-host': '*$domain*',
          'comment': comment,
        }
      );
      return AppResponse(status: true, message: "done", data: response);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse> _addSSLFilterTlsV7(String outInterface, String domain, String comment) async {
    try {
      var response = await MikrotikClient.addData(
        command: "/ip/firewall/filter/add",
        data: {
          'action': 'drop',
          'chain': 'forward',
          'protocol': 'tcp',
          'dst-port': '443', // إضافة مخصصة لـ V7
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

  static Future<AppResponse> _linkFilterWithMangleV7(String name, String outInterface, String comment) async {
    try {
      var response = await MikrotikClient.addData(
        command: "/ip/firewall/filter/add",
        data: {
          'action': 'drop',
          'chain': 'forward',
          // الانتباه هنا: لا نضيف dst-port بناءً على السكربت الذي أرسلته لفلتر الـ IP
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

  static Future<AppResponse> addBlockBySSL(BlockedSiteModel site) async {
    try {
      String comment = "MikroNet_Block_${site.name}_[v7]"; // تمييز التعليق بـ v7
      String outInterface = site.interface.isEmpty ? "all-ethernet" : site.interface;

      var mangle = await _addSSLMangleV7(site.name, site.blockValue, comment);
      var tls = await _addSSLFilterTlsV7(outInterface, site.blockValue, comment);
      var link = await _linkFilterWithMangleV7(site.name, outInterface, comment);
      
      var response = [mangle, tls, link];
      return AppResponse(status: true, message: "${mangle.message} , ${tls.message} , ${link.message}", data: response);
      
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse> editBlockBySSL(BlockedSiteModel site) async {
    try {
      String comment = "MikroNet_Block_${site.name}_[v7]";

      // 1. تعديل المانجل
      await MikrotikClient.addData(
        command: "/ip/firewall/mangle/set",
        data: {
          '.id': site.id, 
          'address-list': site.name,
          'protocol': 'tcp',
          'dst-port': '443', // تأكيد وجود البورت عند التعديل
          'tls-host': '*${site.blockValue}*',
          'comment': comment,
        }
      );

      // 2. تعديل فلتر الـ TLS
      await MikrotikClient.addData(
        command: "/ip/firewall/filter/set",
        data: {
          '.id': site.filterId,
          'protocol': 'tcp',
          'dst-port': '443', // تأكيد وجود البورت عند التعديل
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

  

}
