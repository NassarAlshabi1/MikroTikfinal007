// ============================================================
//  MikrotikDataCollector — يجمع بيانات التشخيص من MikroTik
//
//  يدعم طريقتين:
//  1) RouterOS API (موجود مسبقاً عبر router_os_client)
//  2) SSH (عبر dartssh2) — أكثر مرونة، ينفذ أوامر نصية كاملة
//
//  يدعم جمع بيانات إضافية حسب وضع التشخيص (DiagnosticMode):
//  - security : services, users, NAT, addresses, address-lists, IPsec
//  - hotspot  : hotspot profiles, active, user-manager
//  - vpn      : IPsec, WireGuard, OpenVPN, L2TP, SSTP
//  - routing  : BGP, OSPF, BFD
//  - wifi     : wireless, CAPsMAN
//  - qos      : queue simple, queue tree, queue types, mangle
//  - performance: CPU per-core, queues stats, interface stats
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'diagnostics_models.dart';

/// أمر يجمع عنوان القسم وأمر RouterOS (سواء بصيغة SSH أو RouterOS API)
class _CollectorCommand {
  final String sectionName;   // يظهر كـ "=== SECTION ===" في السياق
  final String sshCommand;    // للأمر بصيغة SSH (مثلاً: "ip service print")
  final List<String> apiArgs; // للأمر بصيغة RouterOS API (مثلاً: ['/ip/service/print', '=.proplist=...'])

  const _CollectorCommand({
    required this.sectionName,
    required this.sshCommand,
    required this.apiArgs,
  });
}

class MikrotikDataCollector {
  MikrotikDataCollector._();

  // ============================================================
  //  تعريف الأوامر حسب وضع التشخيص
  // ============================================================

  /// الأوامر الإضافية لكل وضع تشخيص
  /// تُضاف إلى الأوامر الأساسية (system/interface/route/firewall/log)
  static const Map<DiagnosticMode, List<_CollectorCommand>> _modeCommands = {
    DiagnosticMode.security: [
      _CollectorCommand(
        sectionName: 'IP SERVICES',
        sshCommand: 'ip service print',
        apiArgs: ['/ip/service/print'],
      ),
      _CollectorCommand(
        sectionName: 'USERS',
        sshCommand: 'user print',
        apiArgs: ['/user/print'],
      ),
      _CollectorCommand(
        sectionName: 'IP FIREWALL NAT',
        sshCommand: 'ip firewall nat print',
        apiArgs: [
          '/ip/firewall/nat/print',
          '=.proplist=chain,action,protocol,src-address,dst-address,to-addresses,to-ports,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP ADDRESS',
        sshCommand: 'ip address print',
        apiArgs: [
          '/ip/address/print',
          '=.proplist=address,interface,network,disabled',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP FIREWALL ADDRESS-LIST',
        sshCommand: 'ip firewall address-list print',
        apiArgs: [
          '/ip/firewall/address-list/print',
          '=.proplist=list,address,comment,disabled',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP UPNP',
        sshCommand: 'ip upnp print',
        apiArgs: ['/ip/upnp/print'],
      ),
      _CollectorCommand(
        sectionName: 'IP DNS',
        sshCommand: 'ip dns print',
        apiArgs: ['/ip/dns/print'],
      ),
      _CollectorCommand(
        sectionName: 'IP SOCKS',
        sshCommand: 'ip socks print',
        apiArgs: ['/ip/socks/print'],
      ),
      _CollectorCommand(
        sectionName: 'IP PROXY',
        sshCommand: 'ip proxy print',
        apiArgs: ['/ip/proxy/print'],
      ),
      _CollectorCommand(
        sectionName: 'TOOLS MAC-WINBOX',
        sshCommand: 'tool mac-winbox print',
        apiArgs: ['/tool/mac-winbox/print'],
      ),
    ],

    DiagnosticMode.hotspot: [
      _CollectorCommand(
        sectionName: 'IP HOTSPOT',
        sshCommand: 'ip hotspot print',
        apiArgs: ['/ip/hotspot/print'],
      ),
      _CollectorCommand(
        sectionName: 'IP HOTSPOT PROFILE',
        sshCommand: 'ip hotspot profile print',
        apiArgs: ['/ip/hotspot/profile/print'],
      ),
      _CollectorCommand(
        sectionName: 'IP HOTSPOT ACTIVE',
        sshCommand: 'ip hotspot active print',
        apiArgs: [
          '/ip/hotspot/active/print',
          '=.proplist=user,address,mac-address,uptime,session-time-left,limit-bytes-in,limit-bytes-out',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP HOTSPOT USER',
        sshCommand: 'ip hotspot user print',
        apiArgs: [
          '/ip/hotspot/user/print',
          '=.proplist=name,address,mac-address,profile,uptime-limit,limit-bytes-total,disabled,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP HOTSPOT USER PROFILE',
        sshCommand: 'ip hotspot user profile print',
        apiArgs: ['/ip/hotspot/user/profile/print'],
      ),
      _CollectorCommand(
        sectionName: 'IP HOTSPOT WALLED-GARDEN',
        sshCommand: 'ip hotspot walled-garden print',
        apiArgs: ['/ip/hotspot/walled-garden/print'],
      ),
      _CollectorCommand(
        sectionName: 'QUEUE SIMPLE',
        sshCommand: 'queue simple print',
        apiArgs: [
          '/queue/simple/print',
          '=.proplist=name,target,dst-address,max-limit,limit-at,queue,parent',
        ],
      ),
    ],

    DiagnosticMode.vpn: [
      _CollectorCommand(
        sectionName: 'IP IPSEC PROFILE',
        sshCommand: 'ip ipsec profile print',
        apiArgs: ['/ip/ipsec/profile/print'],
      ),
      _CollectorCommand(
        sectionName: 'IP IPSEC PEER',
        sshCommand: 'ip ipsec peer print',
        apiArgs: ['/ip/ipsec/peer/print'],
      ),
      _CollectorCommand(
        sectionName: 'IP IPSEC PROPOSAL',
        sshCommand: 'ip ipsec proposal print',
        apiArgs: ['/ip/ipsec/proposal/print'],
      ),
      _CollectorCommand(
        sectionName: 'IP IPSEC ACTIVE-PEERS',
        sshCommand: 'ip ipsec active-peers print',
        apiArgs: ['/ip/ipsec/active-peers/print'],
      ),
      _CollectorCommand(
        sectionName: 'IP IPSEC INSTALLED-SA',
        sshCommand: 'ip ipsec installed-sa print',
        apiArgs: ['/ip/ipsec/installed-sa/print'],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE WIREGUARD',
        sshCommand: 'interface wireguard print',
        apiArgs: ['/interface/wireguard/print'],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE WIREGUARD PEERS',
        sshCommand: 'interface wireguard peers print',
        apiArgs: ['/interface/wireguard/peers/print'],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE L2TP-SERVER',
        sshCommand: 'interface l2tp-server server print',
        apiArgs: ['/interface/l2tp-server/server/print'],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE SSTP-SERVER',
        sshCommand: 'interface sstp-server server print',
        apiArgs: ['/interface/sstp-server/server/print'],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE OVPN-SERVER',
        sshCommand: 'interface ovpn-server server print',
        apiArgs: ['/interface/ovpn-server/server/print'],
      ),
      _CollectorCommand(
        sectionName: 'PPP SECRET',
        sshCommand: 'ppp secret print',
        apiArgs: [
          '/ppp/secret/print',
          '=.proplist=name,service,profile,local-address,remote-address,disabled,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'PPP PROFILE',
        sshCommand: 'ppp profile print',
        apiArgs: ['/ppp/profile/print'],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE GRE',
        sshCommand: 'interface gre print',
        apiArgs: ['/interface/gre/print'],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE EOIP',
        sshCommand: 'interface eoip print',
        apiArgs: ['/interface/eoip/print'],
      ),
    ],

    DiagnosticMode.routing: [
      _CollectorCommand(
        sectionName: 'BGP PEERS (v7)',
        sshCommand: 'routing bgp connection print',
        apiArgs: ['/routing/bgp/connection/print'],
      ),
      _CollectorCommand(
        sectionName: 'BGP PEERS (v6)',
        sshCommand: 'routing bgp peer print',
        apiArgs: ['/routing/bgp/peer/print'],
      ),
      _CollectorCommand(
        sectionName: 'BGP SESSIONS',
        sshCommand: 'routing bgp session print',
        apiArgs: ['/routing/bgp/session/print'],
      ),
      _CollectorCommand(
        sectionName: 'OSPF INSTANCE',
        sshCommand: 'routing ospf instance print',
        apiArgs: ['/routing/ospf/instance/print'],
      ),
      _CollectorCommand(
        sectionName: 'OSPF AREA',
        sshCommand: 'routing ospf area print',
        apiArgs: ['/routing/ospf/area/print'],
      ),
      _CollectorCommand(
        sectionName: 'OSPF NEIGHBOR',
        sshCommand: 'routing ospf neighbor print',
        apiArgs: ['/routing/ospf/neighbor/print'],
      ),
      _CollectorCommand(
        sectionName: 'OSPF INTERFACE',
        sshCommand: 'routing ospf interface print',
        apiArgs: ['/routing/ospf/interface/print'],
      ),
      _CollectorCommand(
        sectionName: 'BFD',
        sshCommand: 'routing bfd configuration print',
        apiArgs: ['/routing/bfd/configuration/print'],
      ),
      _CollectorCommand(
        sectionName: 'BFD NEIGHBOR',
        sshCommand: 'routing bfd neighbor print',
        apiArgs: ['/routing/bfd/neighbor/print'],
      ),
      _CollectorCommand(
        sectionName: 'ROUTING RULES',
        sshCommand: 'routing rule print',
        apiArgs: ['/routing/rule/print'],
      ),
      _CollectorCommand(
        sectionName: 'ROUTE TABLES',
        sshCommand: 'route table print',
        apiArgs: ['/route/table/print'],
      ),
    ],

    DiagnosticMode.wifi: [
      _CollectorCommand(
        sectionName: 'INTERFACE WIRELESS',
        sshCommand: 'interface wireless print',
        apiArgs: ['/interface/wireless/print'],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE WIRELESS SECURITY-PROFILES',
        sshCommand: 'interface wireless security-profiles print',
        apiArgs: ['/interface/wireless/security-profiles/print'],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE WIRELESS REGISTRATION-TABLE',
        sshCommand: 'interface wireless registration-table print',
        apiArgs: [
          '/interface/wireless/registration-table/print',
          '=.proplist=interface,mac-address,signal-strength,tx-rate,rx-rate,uptime,ap',
        ],
      ),
      _CollectorCommand(
        sectionName: 'CAPsMAN MANAGER',
        sshCommand: 'caps-man manager print',
        apiArgs: ['/caps-man/manager/print'],
      ),
      _CollectorCommand(
        sectionName: 'CAPsMAN INTERFACE',
        sshCommand: 'caps-man interface print',
        apiArgs: ['/caps-man/interface/print'],
      ),
      _CollectorCommand(
        sectionName: 'CAPsMAN CONFIGURATION',
        sshCommand: 'caps-man configuration print',
        apiArgs: ['/caps-man/configuration/print'],
      ),
      _CollectorCommand(
        sectionName: 'CAPsMAN DATAPATH',
        sshCommand: 'caps-man datapath print',
        apiArgs: ['/caps-man/datapath/print'],
      ),
      _CollectorCommand(
        sectionName: 'CAPsMAN SECURITY',
        sshCommand: 'caps-man security print',
        apiArgs: ['/caps-man/security/print'],
      ),
      _CollectorCommand(
        sectionName: 'CAPsMAN PROVISIONING',
        sshCommand: 'caps-man provisioning print',
        apiArgs: ['/caps-man/provisioning/print'],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE WIRELESS CAP',
        sshCommand: 'interface wireless cap print',
        apiArgs: ['/interface/wireless/cap/print'],
      ),
    ],

    DiagnosticMode.qos: [
      _CollectorCommand(
        sectionName: 'QUEUE SIMPLE',
        sshCommand: 'queue simple print',
        apiArgs: [
          '/queue/simple/print',
          '=.proplist=name,target,dst-address,max-limit,limit-at,priority,queue,parent',
        ],
      ),
      _CollectorCommand(
        sectionName: 'QUEUE TREE',
        sshCommand: 'queue tree print',
        apiArgs: [
          '/queue/tree/print',
          '=.proplist=name,parent,packet-mark,limit-at,max-limit,priority,queue',
        ],
      ),
      _CollectorCommand(
        sectionName: 'QUEUE TYPE',
        sshCommand: 'queue type print',
        apiArgs: ['/queue/type/print'],
      ),
      _CollectorCommand(
        sectionName: 'IP FIREWALL MANGLE',
        sshCommand: 'ip firewall mangle print',
        apiArgs: [
          '/ip/firewall/mangle/print',
          '=.proplist=chain,action,protocol,src-address,dst-address,new-connection-mark,new-packet-mark,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'QUEUE INTERFACE',
        sshCommand: 'queue interface print',
        apiArgs: ['/queue/interface/print'],
      ),
    ],

    DiagnosticMode.performance: [
      _CollectorCommand(
        sectionName: 'SYSTEM RESOURCE CPU',
        sshCommand: 'system resource cpu print',
        apiArgs: ['/system/resource/cpu/print'],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM RESOURCE IRQ',
        sshCommand: 'system resource irq print',
        apiArgs: ['/system/resource/irq/print'],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM RESOURCE PCI',
        sshCommand: 'system resource pci print',
        apiArgs: ['/system/resource/pci/print'],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM ROUTING STATS',
        sshCommand: 'system routing stats print',
        apiArgs: ['/system/routing/stats/print'],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE ETHERNET',
        sshCommand: 'interface ethernet print',
        apiArgs: [
          '/interface/ethernet/print',
          '=.proplist=name,mac-address,mtu,auto-negotiation,speed,rx-byte,tx-byte,rx-packet,tx-packet,rx-error,tx-error',
        ],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE PRINT STATS',
        sshCommand: 'interface print stats-detail',
        apiArgs: ['/interface/print'],
      ),
      _CollectorCommand(
        sectionName: 'QUEUE SIMPLE STATS',
        sshCommand: 'queue simple print stats',
        apiArgs: ['/queue/simple/print'],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM IDENTITY',
        sshCommand: 'system identity print',
        apiArgs: ['/system/identity/print'],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM ROUTING FIB',
        sshCommand: 'ip route print count-only',
        apiArgs: ['/ip/route/print'],
      ),
    ],

    // ============================================================
    //  وضع DHCP — مستوحى من MCP tools: list_dhcp_servers, list_dhcp_leases, ...
    // ============================================================
    DiagnosticMode.dhcp: [
      _CollectorCommand(
        sectionName: 'IP DHCP SERVER',
        sshCommand: 'ip dhcp-server print',
        apiArgs: [
          '/ip/dhcp-server/print',
          '=.proplist=name,interface,address-pool,lease-time,authoritative,disabled,dynamic',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP DHCP NETWORK',
        sshCommand: 'ip dhcp-server network print',
        apiArgs: [
          '/ip/dhcp-server/network/print',
          '=.proplist=address,gateway,netmask,dns-server,domain,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP DHCP LEASES',
        sshCommand: 'ip dhcp-server lease print',
        apiArgs: [
          '/ip/dhcp-server/lease/print',
          '=.proplist=address,mac-address,host-name,status,expires-after,last-seen,server,disabled,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP DHCP CLIENT',
        sshCommand: 'ip dhcp-client print',
        apiArgs: [
          '/ip/dhcp-client/print',
          '=.proplist=interface,status,address,expires-after,dhcp-server',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP POOL',
        sshCommand: 'ip pool print',
        apiArgs: [
          '/ip/pool/print',
          '=.proplist=name,ranges,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP ARP',
        sshCommand: 'ip arp print',
        apiArgs: [
          '/ip/arp/print',
          '=.proplist=ip-address,mac-address,interface,comment',
        ],
      ),
    ],

    // ============================================================
    //  وضع المراقبة — مستوحى من MCP: list_netwatch, list_arp_table, list_neighbors, ...
    // ============================================================
    DiagnosticMode.monitoring: [
      _CollectorCommand(
        sectionName: 'TOOL NETWATCH',
        sshCommand: 'tool netwatch print',
        apiArgs: [
          '/tool/netwatch/print',
          '=.proplist=host,timeout,interval,status,since,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP ARP TABLE',
        sshCommand: 'ip arp print',
        apiArgs: [
          '/ip/arp/print',
          '=.proplist=ip-address,mac-address,interface,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP NEIGHBOR',
        sshCommand: 'ip neighbor print',
        apiArgs: [
          '/ip/neighbor/print',
          '=.proplist=address,identity,interface,platform,version',
        ],
      ),
      _CollectorCommand(
        sectionName: 'SNMP',
        sshCommand: 'snmp print',
        apiArgs: ['/snmp/print'],
      ),
      _CollectorCommand(
        sectionName: 'IP UPNP',
        sshCommand: 'ip upnp print',
        apiArgs: ['/ip/upnp/print'],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM LOG',
        sshCommand: 'log print where topics~"error" or topics~"warning"',
        apiArgs: ['/log/print'],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM HEALTH',
        sshCommand: 'system health print',
        apiArgs: ['/system/health/print'],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM ROUTERBOARD',
        sshCommand: 'system routerboard print',
        apiArgs: ['/system/routerboard/print'],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM CLOCK',
        sshCommand: 'system clock print',
        apiArgs: ['/system/clock/print'],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM NTP CLIENT',
        sshCommand: 'system ntp client print',
        apiArgs: ['/system/ntp/client/print'],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM SCHEDULER',
        sshCommand: 'system scheduler print',
        apiArgs: [
          '/system/scheduler/print',
          '=.proplist=name,on-event,start-date,start-time,interval,disabled,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM SCRIPTS',
        sshCommand: 'system script print',
        apiArgs: [
          '/system/script/print',
          '=.proplist=name,source,comment',
        ],
      ),
    ],

    // ============================================================
    //  وضع البنية التحتية — مستوحى من MCP: bridge, vlan, bonding, tunnels, ipv6
    // ============================================================
    DiagnosticMode.infrastructure: [
      _CollectorCommand(
        sectionName: 'INTERFACE BRIDGE',
        sshCommand: 'interface bridge print',
        apiArgs: [
          '/interface/bridge/print',
          '=.proplist=name,mtu,protocol-mode,vlan-filtering,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE BRIDGE PORT',
        sshCommand: 'interface bridge port print',
        apiArgs: [
          '/interface/bridge/port/print',
          '=.proplist=interface,bridge,pvid,path-cost,priority,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE BRIDGE VLAN',
        sshCommand: 'interface bridge vlan print',
        apiArgs: ['/interface/bridge/vlan/print'],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE VLAN',
        sshCommand: 'interface vlan print',
        apiArgs: [
          '/interface/vlan/print',
          '=.proplist=name,vlan-id,interface,mtu,disabled,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE BONDING',
        sshCommand: 'interface bonding print',
        apiArgs: ['/interface/bonding/print'],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE EOIP',
        sshCommand: 'interface eoip print',
        apiArgs: [
          '/interface/eoip/print',
          '=.proplist=name,local-address,remote-address,tunnel-id,mtu,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE GRE',
        sshCommand: 'interface gre print',
        apiArgs: [
          '/interface/gre/print',
          '=.proplist=name,local-address,remote-address,mtu,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE IPIP',
        sshCommand: 'interface ipip print',
        apiArgs: [
          '/interface/ipip/print',
          '=.proplist=name,local-address,remote-address,mtu,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IPV6 ADDRESS',
        sshCommand: 'ipv6 address print',
        apiArgs: [
          '/ipv6/address/print',
          '=.proplist=address,interface,advertise,disabled,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IPV6 ROUTE',
        sshCommand: 'ipv6 route print',
        apiArgs: [
          '/ipv6/route/print',
          '=.proplist=dst-address,gateway,distance,active',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IPV6 DHCP SERVER',
        sshCommand: 'ipv6 dhcp-server print',
        apiArgs: ['/ipv6/dhcp-server/print'],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM PACKAGES',
        sshCommand: 'system package print',
        apiArgs: [
          '/system/package/print',
          '=.proplist=name,version,disabled',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP ADDRESS',
        sshCommand: 'ip address print',
        apiArgs: [
          '/ip/address/print',
          '=.proplist=address,interface,network,disabled',
        ],
      ),
    ],

    // وضع التشخيص العام لا يجمع بيانات إضافية (يكتفي بالأساسية)
    DiagnosticMode.general: [],
  };

  // ============================================================
  //  الطريقة 1: SSH (الأكثر مرونة)
  // ============================================================

  /// يجمع البيانات عبر SSH (ينفذ أوامر RouterOS النصية)
  /// [mode] يحدد أي أوامر إضافية تُجمَع (security, vpn, qos, إلخ)
  static Future<MikrotikSnapshot> collectViaSSH({
    required String host,
    required String username,
    required String password,
    int port = 22,
    Duration timeout = const Duration(seconds: 15),
    DiagnosticMode mode = DiagnosticMode.general,
  }) async {
    SSHClient? client;
    SSHSocket? socket;
    try {
      debugPrint('[MikrotikDataCollector] SSH connect to $host:$port (mode=${mode.name})');
      socket = await SSHSocket.connect(
        host,
        port,
        timeout: timeout,
      );
      client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      // تنفيذ الأوامر الأساسية بالتوازي (Future.wait) لتقليل زمن الانتظار
      final baseResults = await Future.wait([
        _executeSafely(client, 'system resource print'),
        _executeSafely(client, 'interface print'),
        _executeSafely(client, 'ip route print'),
        _executeSafely(client, 'ip firewall filter print'),
        _executeSafely(client, 'log print where topics~"error" or topics~"warning"'),
      ]);

      // تنفيذ الأوامر الإضافية حسب الوضع
      final extraCommands = _modeCommands[mode] ?? const <_CollectorCommand>[];
      final extraData = <String, String>{};
      if (extraCommands.isNotEmpty) {
        debugPrint('[MikrotikDataCollector] Collecting ${extraCommands.length} extra commands for mode=${mode.name}');
        final extraResults = await Future.wait(
          extraCommands.map((cmd) => _executeSafely(client!, cmd.sshCommand)),
        );
        for (var i = 0; i < extraCommands.length; i++) {
          extraData[extraCommands[i].sectionName] = extraResults[i];
        }
      }

      final snapshot = MikrotikSnapshot(
        system: baseResults[0],
        interfaces: baseResults[1],
        routes: baseResults[2],
        firewall: baseResults[3],
        logs: baseResults[4],
        ipAddress: host,
        collectedAt: DateTime.now(),
        extraData: extraData,
      );

      debugPrint('[MikrotikDataCollector] SSH collection done, '
          '${snapshot.system.length} chars system, ${snapshot.interfaces.length} chars interfaces, '
          '${extraData.length} extra sections');
      return snapshot;
    } catch (e) {
      debugPrint('[MikrotikDataCollector] SSH error: $e');
      rethrow;
    } finally {
      client?.close();
    }
  }

  /// ينفذ أمراً واحداً عبر SSH ويتحمل الأخطاء
  static Future<String> _executeSafely(SSHClient client, String command) async {
    try {
      // client.run() يُرجع Uint8List للمخرجات (stdout+stderr).
      // (سابقاً كان يُستخدم client.execute().toString() الذي يُرجع
      //  "Instance of 'SSHSession'" بدل النص الفعلي.)
      final result = await client.run(command);
      return utf8.decode(result, allowMalformed: true).trim();
    } catch (e) {
      return 'ERROR executing "$command": $e';
    }
  }

  // ============================================================
  //  الطريقة 2: RouterOS API (موجود مسبقاً)
  // ============================================================

  /// يجمع البيانات عبر RouterOS API
  /// يستخدم SharedPreferences للحصول على بيانات الاعتماد المخزّنة
  /// [mode] يحدد أي أوامر إضافية تُجمَع (security, vpn, qos, إلخ)
  static Future<MikrotikSnapshot> collectViaRouterOS({
    RouterOSClient? client,
    Duration timeout = const Duration(seconds: 15),
    DiagnosticMode mode = DiagnosticMode.general,
  }) async {
    RouterOSClient? internalClient = client;
    bool createdInternally = false;

    try {
      if (internalClient == null) {
        // قراءة بيانات الاعتماد من SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final ip = prefs.getString('ip');
        final user = prefs.getString('user');
        final pass = prefs.getString('pass');
        final portStr = prefs.getString('port') ?? '8728';
        final port = int.tryParse(portStr) ?? 8728;

        if (ip == null || user == null || pass == null) {
          throw Exception('بيانات اعتماد MikroTik غير موجودة. سجّل الدخول أولاً.');
        }

        debugPrint('[MikrotikDataCollector] RouterOS API connect to $ip:$port (mode=${mode.name})');
        internalClient = RouterOSClient(
          address: ip,
          user: user,
          password: pass,
          port: port,
          verbose: false,
        );
        final ok = await internalClient.login().timeout(timeout);
        if (!ok) {
          throw Exception('فشل تسجيل الدخول إلى MikroTik');
        }
        createdInternally = true;
      }

      // تنفيذ أوامر RouterOS API الأساسية
      // كل أمر هو list من المسار + الـ proplist
      final baseResults = await Future.wait([
        _talkSafely(internalClient, ['/system/resource/print']),
        _talkSafely(internalClient, [
          '/interface/print',
          '=.proplist=name,type,running,mac-address,mtu,rx-byte,tx-byte',
        ]),
        _talkSafely(internalClient, [
          '/ip/route/print',
          '=.proplist=dst-address,gateway,distance,active',
        ]),
        _talkSafely(internalClient, [
          '/ip/firewall/filter/print',
          '=.proplist=chain,action,protocol,src-address,dst-address,comment',
        ]),
        _talkSafely(internalClient, ['/log/print']),
      ]);

      // تنفيذ الأوامر الإضافية حسب الوضع
      final extraCommands = _modeCommands[mode] ?? const <_CollectorCommand>[];
      final extraData = <String, String>{};
      if (extraCommands.isNotEmpty) {
        debugPrint('[MikrotikDataCollector] Collecting ${extraCommands.length} extra commands for mode=${mode.name}');
        final extraResults = await Future.wait(
          extraCommands.map((cmd) => _talkSafely(internalClient!, cmd.apiArgs)),
        );
        for (var i = 0; i < extraCommands.length; i++) {
          extraData[extraCommands[i].sectionName] =
              _formatMapList(extraResults[i]);
        }
      }

      final snapshot = MikrotikSnapshot(
        system: _formatMapList(baseResults[0]),
        interfaces: _formatMapList(baseResults[1]),
        routes: _formatMapList(baseResults[2]),
        firewall: _formatMapList(baseResults[3]),
        logs: _formatMapList(baseResults[4]),
        ipAddress: internalClient.address,
        collectedAt: DateTime.now(),
        extraData: extraData,
      );

      debugPrint('[MikrotikDataCollector] RouterOS API collection done, ${extraData.length} extra sections');
      return snapshot;
    } finally {
      if (createdInternally && internalClient != null) {
        // لا نغلق العميل إذا كان مُمرّراً من خارج (يُديره MikrotikConnector)
        // لكن نغلق الذي أنشأناه داخلياً
        try {
          internalClient.close();
        } catch (_) {}
      }
    }
  }

  /// ينفذ أمر RouterOS ويتحمل الأخطاء
  static Future<List<Map<String, dynamic>>> _talkSafely(
    RouterOSClient client,
    List<String> args,
  ) async {
    try {
      final res = await client.talk(args).timeout(const Duration(seconds: 10));
      return res.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('[MikrotikDataCollector] talk error for $args: $e');
      return [];
    }
  }

  /// يحوّل list من maps إلى نص قابل للقراءة
  static String _formatMapList(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '(empty)';
    final buffer = StringBuffer();
    for (final item in data) {
      final entries = item.entries
          .where((e) => !e.key.startsWith('.id'))
          .map((e) => '${e.key}=${e.value}');
      buffer.writeln(entries.join('  '));
    }
    return buffer.toString();
  }

  // ============================================================
  //  Dispatcher — يختار الطريقة المناسبة حسب الإعدادات
  // ============================================================

  static Future<MikrotikSnapshot> collect({
    required MikrotikConnectionMethod method,
    RouterOSClient? routerOSClient,
    DiagnosticMode mode = DiagnosticMode.general,
    // لـ SSH:
    String? sshHost,
    String? sshUsername,
    String? sshPassword,
    int sshPort = 22,
  }) async {
    switch (method) {
      case MikrotikConnectionMethod.routerOS:
        return collectViaRouterOS(client: routerOSClient, mode: mode);
      case MikrotikConnectionMethod.ssh:
        if (sshHost == null || sshUsername == null || sshPassword == null) {
          throw Exception('بيانات SSH غير مكتملة');
        }
        return collectViaSSH(
          host: sshHost,
          username: sshUsername,
          password: sshPassword,
          port: sshPort,
          mode: mode,
        );
    }
  }
}
