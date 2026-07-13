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
///
/// ملاحظة: التطبيق يدعم RouterOS v6 فقط. كل الأوامر هنا متوافقة مع v6.
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
        apiArgs: [
          '/ip/service/print',
          '=.proplist=name,port,address,certificate,disabled',
        ],
      ),
      _CollectorCommand(
        sectionName: 'USERS',
        sshCommand: 'user print',
        apiArgs: [
          '/user/print',
          '=.proplist=name,group,address,comment,disabled',
        ],
      ),
      _CollectorCommand(
        sectionName: 'USER GROUPS',
        sshCommand: 'user group print',
        apiArgs: [
          '/user/group/print',
          '=.proplist=name,policy',
        ],
        // v6: policy syntax يختلف قليلاً عن v7 (يسطر سياسات مثل local, telnet, ssh, ftp, read, write, winbox, password, web, api, api-ssl, sensitive, rest-api)
      ),
      _CollectorCommand(
        sectionName: 'IP FIREWALL NAT',
        sshCommand: 'ip firewall nat print',
        apiArgs: [
          '/ip/firewall/nat/print',
          '=.proplist=chain,action,protocol,src-address,dst-address,to-addresses,to-ports,in-interface,out-interface,comment,disabled',
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
          '=.proplist=list,address,comment,disabled,timeout,dynamic',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP FIREWALL CONNECTION TRACKING (v6)',
        sshCommand: 'ip firewall connection tracking print',
        apiArgs: [
          '/ip/firewall/connection/tracking/print',
          '=.proplist=enabled,active-max,tcp-established-timeout,tcp-syn-sent-timeout,tcp-syn-received-timeout,tcp-fin-wait-timeout,tcp-close-wait-timeout,tcp-close-timeout,udp-timeout,udp-stream-timeout,icmp-timeout,generic-timeout',
        ],
        // v6: connection tracking settings. v7 أضاف loose-tcp-tracking و conntrack sync
      ),
      _CollectorCommand(
        sectionName: 'IP FIREWALL SERVICE-PORT (v6)',
        sshCommand: 'ip firewall service-port print',
        apiArgs: [
          '/ip/firewall/service-port/print',
          '=.proplist=name,ports,disabled',
        ],
        // v6: helpers لبروتوكولات (ftp, tftp, irc, h323, sip, pptp, rtsp, udplite, dccp, sctp)
      ),
      _CollectorCommand(
        sectionName: 'IP FIREWALL LAYER7-PROTOCOL (v6)',
        sshCommand: 'ip firewall layer7-protocol print',
        apiArgs: [
          '/ip/firewall/layer7-protocol/print',
          '=.proplist=name,regexp,comment',
        ],
        // v6-only: layer7 matching. v7 محدود/مهمل — استخدم TLS SNI matching في mangle
      ),
      _CollectorCommand(
        sectionName: 'IP FIREWALL CONNECTION',
        sshCommand: 'ip firewall connection print',
        apiArgs: [
          '/ip/firewall/connection/print',
          '=.proplist=protocol,src-address,dst-address,reply-src-address,reply-dst-address,timeout,tcp-state,orig-bytes,orig-packets,repl-bytes,repl-packets,connection-mark',
        ],
        // v6: عرض active connections. مفيد لمراقبة NAT/attacks
      ),
      _CollectorCommand(
        sectionName: 'IP UPNP',
        sshCommand: 'ip upnp print',
        apiArgs: [
          '/ip/upnp/print',
          '=.proplist=enabled,allow-disable-external-interface,show-dummy-empty-rule',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP UPNP INTERFACES',
        sshCommand: 'ip upnp interfaces print',
        apiArgs: [
          '/ip/upnp/interfaces/print',
          '=.proplist=interface,type,enabled,forced-ip',
        ],
        // v6: UPnP interface config (external/internal)
      ),
      _CollectorCommand(
        sectionName: 'IP DNS',
        sshCommand: 'ip dns print',
        apiArgs: [
          '/ip/dns/print',
          '=.proplist=servers,allow-remote-requests,max-udp-packet-size,query-server-timeout,query-total-timeout,cache-size,cache-max-ttl,dynamic-servers',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP SOCKS',
        sshCommand: 'ip socks print',
        apiArgs: [
          '/ip/socks/print',
          '=.proplist=enabled,connection-idle-timeout,auth-method,max-connections',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP PROXY',
        sshCommand: 'ip proxy print',
        apiArgs: [
          '/ip/proxy/print',
          '=.proplist=enabled,enabled,port,max-client-connections,parent-proxy,parent-proxy-port,cache-administrator,cache-on-disk,max-cache-size,max-fresh-time',
        ],
      ),
      _CollectorCommand(
        sectionName: 'TOOLS MAC-WINBOX',
        sshCommand: 'tool mac-winbox print',
        apiArgs: [
          '/tool/mac-winbox/print',
          '=.proplist=enabled',
        ],
      ),
      _CollectorCommand(
        sectionName: 'TOOLS MAC-TELNET (v6)',
        sshCommand: 'tool mac-telnet print',
        apiArgs: [
          '/tool/mac-telnet/print',
          '=.proplist=enabled',
        ],
        // v6: MAC Telnet service (دخول عبر MAC بدون IP)
      ),
      _CollectorCommand(
        sectionName: 'IP IPSEC SETTINGS (v6)',
        sshCommand: 'ip ipsec settings print',
        apiArgs: [
          '/ip/ipsec/settings/print',
          '=.proplist=xauth-use-radius,interim-update,accounts-list,ph2-count,max-sa-entries',
        ],
        // v6: IPsec global settings
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
      // ملاحظة: التطبيق يدعم RouterOS v6 فقط.
      // الأوامر التالية متوافقة مع v6 (لا WireGuard، لا IPsec profile منفصل).
      // في v6: IPsec peer يحوي إعدادات profile داخله (enc-algorithm, hash-algorithm, dh-group).
      _CollectorCommand(
        sectionName: 'IP IPSEC PEER',
        sshCommand: 'ip ipsec peer print',
        apiArgs: [
          '/ip/ipsec/peer/print',
          '=.proplist=name,address,port,auth-method,enc-algorithm,hash-algorithm,dh-group,lifetime,nat-traversal,exchange-mode,passive,send-initial-contact,my-id,peer-id,profile,disabled,comment',
        ],
        // v6: peer يحوي كل Phase 1 params (enc-algorithm, hash-algorithm, dh-group, lifetime, nat-traversal)
      ),
      _CollectorCommand(
        sectionName: 'IP IPSEC PROPOSAL',
        sshCommand: 'ip ipsec proposal print',
        apiArgs: [
          '/ip/ipsec/proposal/print',
          '=.proplist=name,enc-algorithms,auth-algorithms,lifetime,pfs-group,disabled,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP IPSEC POLICY',
        sshCommand: 'ip ipsec policy print',
        apiArgs: [
          '/ip/ipsec/policy/print',
          '=.proplist=src-address,dst-address,protocol,action,level,ipsec-protocols,tunnel,sa-src-address,sa-dst-address,proposal,template,disabled,comment',
        ],
        // v6-specific: /ip/ipsec/policy في v6 يحدد traffic الذي يجب تشفيره
        // في v7 أصبح peer-centric (policy تُنشأ تلقائياً من peer generate-policy)
      ),
      _CollectorCommand(
        sectionName: 'IP IPSEC MODE-CONFIG',
        sshCommand: 'ip ipsec mode-config print',
        apiArgs: [
          '/ip/ipsec/mode-config/print',
          '=.proplist=name,address-pool,split-include,split-dns,dns,system-dns,disabled,comment',
        ],
        // v6: mode-config لتوزيع IPs و DNS على Road Warrior clients
      ),
      _CollectorCommand(
        sectionName: 'IP IPSEC SETTINGS',
        sshCommand: 'ip ipsec settings print',
        apiArgs: [
          '/ip/ipsec/settings/print',
          '=.proplist=xauth-use-radius,interim-update,accounts-list,ph2-count,max-sa-entries',
        ],
        // v6: إعدادات IPsec العامة (XAUTH, RADIUS)
      ),
      _CollectorCommand(
        sectionName: 'IP IPSEC ACTIVE-PEERS',
        sshCommand: 'ip ipsec active-peers print',
        apiArgs: [
          '/ip/ipsec/active-peers/print',
          '=.proplist=local-address,remote-address,side,state,uptime,phase2-total,ph2-state,exchange-mode,peer-id',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP IPSEC INSTALLED-SA',
        sshCommand: 'ip ipsec installed-sa print',
        apiArgs: [
          '/ip/ipsec/installed-sa/print',
          '=.proplist=spi,addtime,enc-algorithm,auth-algorithm,src,dst,lifetime,bytes,addtime',
        ],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE L2TP-SERVER',
        sshCommand: 'interface l2tp-server server print',
        apiArgs: [
          '/interface/l2tp-server/server/print',
          '=.proplist=enabled,max-mtu,max-mru,authentication,use-ipsec,ipsec-secret,default-profile,caller-id',
        ],
        // v6: use-ipsec=yes + ipsec-secret للـ L2TP/IPSec
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE SSTP-SERVER',
        sshCommand: 'interface sstp-server server print',
        apiArgs: [
          '/interface/sstp-server/server/print',
          '=.proplist=enabled,max-mtu,max-mru,authentication,certificate,verify-client,pfs,encryption',
        ],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE OVPN-SERVER',
        sshCommand: 'interface ovpn-server server print',
        apiArgs: [
          '/interface/ovpn-server/server/print',
          '=.proplist=enabled,port,mode,authentication,certificate,verify-client,require-client-certificate,auth,cipher',
        ],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE PPTP-SERVER',
        sshCommand: 'interface pptp-server server print',
        apiArgs: [
          '/interface/pptp-server/server/print',
          '=.proplist=enabled,max-mtu,max-mru,authentication,default-profile',
        ],
        // v6: PPTP مدعوم (deprecated أمنياً لكنه متاح)
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
        apiArgs: [
          '/ppp/profile/print',
          '=.proplist=name,local-address,remote-address,rate-limit,dns-server,use-encryption,use-ipv6,use-mpls,bridge,insert-queue-before,only-one',
        ],
        // v6: rate-limit, use-encryption, bridge parameters
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE GRE',
        sshCommand: 'interface gre print',
        apiArgs: [
          '/interface/gre/print',
          '=.proplist=name,mtu,local-address,remote-address,keepalive,disabled,comment',
        ],
        // v6: keepalive مدعوم في v6 (لا يختلف عن v7)
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE EOIP',
        sshCommand: 'interface eoip print',
        apiArgs: [
          '/interface/eoip/print',
          '=.proplist=name,mtu,local-address,remote-address,tunnel-id,keepalive,disabled,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE IPIP',
        sshCommand: 'interface ipip print',
        apiArgs: [
          '/interface/ipip/print',
          '=.proplist=name,mtu,local-address,remote-address,disabled,comment',
        ],
      ),
    ],

    DiagnosticMode.routing: [
      // ملاحظة: التطبيق يدعم RouterOS v6 فقط.
      // BGP في v6: /routing/bgp/{instance, peer, network, aggregate, vpn}
      // OSPF في v6: /routing/ospf/{instance, area, neighbor, interface, network} + /routing/ospf-v3
      // RIP في v6: /routing/rip + /routing/rip/network
      // Routing rules في v6: /ip/route/rule (وليس /routing/rule كما في v7)
      // Routing filters في v6: /routing/filter بـ action= و prefix= (وليس rule= كما في v7)
      _CollectorCommand(
        sectionName: 'BGP INSTANCE (v6)',
        sshCommand: 'routing bgp instance print',
        apiArgs: [
          '/routing/bgp/instance/print',
          '=.proplist=name,as,router-id,redistribute-static,redistribute-connected,redistribute-rip,redistribute-ospf,redistribute-other-bgp,client-to-client-reflection,comment,disabled',
        ],
        // v6-only: instance يحوي AS, router-id, redistribute flags
        // في v7 استُبدل بـ /routing/bgp/template
      ),
      _CollectorCommand(
        sectionName: 'BGP INSTANCE VRF (v6)',
        sshCommand: 'routing bgp instance vrf print',
        apiArgs: [
          '/routing/bgp/instance/vrf/print',
          '=.proplist=instance,as,router-id,redistribute',
        ],
        // v6-only: VRF-specific BGP instances
      ),
      _CollectorCommand(
        sectionName: 'BGP PEERS (v6)',
        sshCommand: 'routing bgp peer print',
        apiArgs: [
          '/routing/bgp/peer/print',
          '=.proplist=instance,remote-address,remote-as,peer-as,name,update-source,in-filter,out-filter,as-overrides,nexthop-choice,multihop,route-reflector,default-originate,remove-private-as,hold-time,ttl,disabled,comment',
        ],
        // v6-only: peer يحوي كل params. v7 استُبدل بـ /routing/bgp/connection
      ),
      _CollectorCommand(
        sectionName: 'BGP NETWORK (v6)',
        sshCommand: 'routing bgp network print',
        apiArgs: [
          '/routing/bgp/network/print',
          '=.proplist=network,synchronize,comment,disabled',
        ],
        // v6-only: networks تُعرَّف هنا. v7 تُضاف لـ /ip firewall address-list
      ),
      _CollectorCommand(
        sectionName: 'BGP AGGREGATE (v6)',
        sshCommand: 'routing bgp aggregate print',
        apiArgs: [
          '/routing/bgp/aggregate/print',
          '=.proplist=instance,prefix,inherit-med,as-set,summary-only,suppress-filter,advertise-filter,comment,disabled',
        ],
        // v6-only: aggregation. v7 يتم بـ routing filters
      ),
      _CollectorCommand(
        sectionName: 'BGP VPN (v6)',
        sshCommand: 'routing bgp vpn print',
        apiArgs: [
          '/routing/bgp/vpn/print',
          '=.proplist=instance,export-route-targets,import-route-targets,route-distinguisher',
        ],
        // v6-only: MPLS L3VPN. v7 أعيد تصميمه
      ),
      _CollectorCommand(
        sectionName: 'OSPF INSTANCE (v6)',
        sshCommand: 'routing ospf instance print',
        apiArgs: [
          '/routing/ospf/instance/print',
          '=.proplist=name,router-id,redistribute-static,redistribute-connected,redistribute-default,redistribute-rip,redistribute-bgp,redistribute-other-ospf,route-tag,metric-default,as-default',
        ],
        // v6: OSPFv2 فقط هنا. v7 أصبح version=2|3 داخل instance موحّد
      ),
      _CollectorCommand(
        sectionName: 'OSPF AREA (v6)',
        sshCommand: 'routing ospf area print',
        apiArgs: [
          '/routing/ospf/area/print',
          '=.proplist=instance,area-id,name,type,default-cost,stub,nssa',
        ],
      ),
      _CollectorCommand(
        sectionName: 'OSPF NEIGHBOR (v6)',
        sshCommand: 'routing ospf neighbor print',
        apiArgs: [
          '/routing/ospf/neighbor/print',
          '=.proplist=instance,router-id,address,state,priority,dead-interval,dr,bdr',
        ],
      ),
      _CollectorCommand(
        sectionName: 'OSPF INTERFACE (v6)',
        sshCommand: 'routing ospf interface print',
        apiArgs: [
          '/routing/ospf/interface/print',
          '=.proplist=interface,instance,area,cost,priority,hello-interval,dead-interval,authentication-type,authentication-key,network-type,passive',
        ],
        // v6: تكوين مباشر. v7 أصبح read-only والتكوين عبر interface-template
      ),
      _CollectorCommand(
        sectionName: 'OSPF NETWORK (v6)',
        sshCommand: 'routing ospf network print',
        apiArgs: [
          '/routing/ospf/network/print',
          '=.proplist=network,area,comment,disabled',
        ],
        // v6-only: شبكات OSPF. v7 استُبدل بـ interface-template
      ),
      _CollectorCommand(
        sectionName: 'OSPF-V3 (v6)',
        sshCommand: 'routing ospf-v3 print',
        apiArgs: [
          '/routing/ospf-v3/print',
          '=.proplist=instance,area,interface,neighbor',
        ],
        // v6-only: OSPFv3 منفصل. v7 دُمج في /routing/ospf بـ version=3
      ),
      _CollectorCommand(
        sectionName: 'RIP (v6)',
        sshCommand: 'routing rip print',
        apiArgs: [
          '/routing/rip/print',
          '=.proplist=name,redistribute-static,redistribute-connected,redistribute-default,redistribute-ospf,redistribute-bgp,metric-default',
        ],
        // v6-only: RIP instance. v7 أصبح /routing/rip/instance + interface-template
      ),
      _CollectorCommand(
        sectionName: 'RIP NETWORK (v6)',
        sshCommand: 'routing rip network print',
        apiArgs: [
          '/routing/rip/network/print',
          '=.proplist=network,comment,disabled',
        ],
        // v6-only. v7 استُبدل بـ interface-template
      ),
      _CollectorCommand(
        sectionName: 'BFD NEIGHBOR (v6)',
        sshCommand: 'routing bfd neighbor print',
        apiArgs: [
          '/routing/bfd/neighbor/print',
          '=.proplist=interface,address,disabled,comment',
        ],
        // v6: /routing/bfd/neighbor (لا /configuration في v6)
      ),
      _CollectorCommand(
        sectionName: 'ROUTING FILTER (v6 syntax)',
        sshCommand: 'routing filter print',
        apiArgs: [
          '/routing/filter/print',
          '=.proplist=chain,action,prefix,prefix-length,protocol,bgp-local-pref,bgp-med,bgp-as-path,bgp-communities,bgp-path-prepend,set-bgp-local-pref,set-bgp-med,set-bgp-path-prepend',
        ],
        // v6-only: action=accept/discard, prefix=, prefix-length=
        // v7 أصبح /routing/filter/rule بـ script-like: rule="if (dst in x && protocol static) { accept }"
      ),
      _CollectorCommand(
        sectionName: 'IP ROUTE RULE (v6)',
        sshCommand: 'ip route rule print',
        apiArgs: [
          '/ip/route/rule/print',
          '=.proplist=dst-address,src-address,action,table,routing-mark,interface,comment,disabled',
        ],
        // v6-only: policy routing في /ip/route/rule. v7 انتقل لـ /routing/rule
      ),
      _CollectorCommand(
        sectionName: 'IP ROUTE',
        sshCommand: 'ip route print',
        apiArgs: [
          '/ip/route/print',
          '=.proplist=dst-address,gateway,distance,scope,target-scope,check-gateway,routing-mark,active,comment,disabled',
        ],
        // v6: الجدول الرئيسي للـ routes. v7 أصبح /routing/route لعرض كل route families
      ),
      _CollectorCommand(
        sectionName: 'ROUTING MARKS',
        sshCommand: 'ip firewall mangle print where new-routing-mark!=""',
        apiArgs: [
          '/ip/firewall/mangle/print',
          '?#new-routing-mark=!',
        ],
        // v6: routing marks في mangle. v7 يدعم routing tables منفصلة بدلاً من marks
      ),
    ],

    DiagnosticMode.wifi: [
      // ملاحظة: v6 يستخدم حزمة wireless القديمة التي تدعم:
      // - frequency-mode=superchannel (Conformance Testing Mode)
      // - wireless-protocol={802.11|nstreme|nv2|nv2-nstreme|nv2-nstreme-802.11}
      // - nstreme / nstreme-dual protocols
      // - WDS (wireless distribution system)
      // v7 wifi/wifiwave2 package أزالت superchannel, NV2, nstreme
      _CollectorCommand(
        sectionName: 'INTERFACE WIRELESS (v6)',
        sshCommand: 'interface wireless print',
        apiArgs: [
          '/interface/wireless/print',
          '=.proplist=name,mode,frequency,frequency-mode,band,channel-width,ssid,wireless-protocol,wds-mode,wds-default-bridge,rate-set,wmm-support,scan-list,hw-retries,distance,tx-power,security-profile,disable-running-check,adaptive-noise-immunity',
        ],
        // v6-specific: frequency-mode=superchannel, wireless-protocol=nv2/nstreme
      ),
      _CollectorCommand(
        sectionName: 'WIRELESS NSTREME (v6)',
        sshCommand: 'interface wireless nstreme print',
        apiArgs: [
          '/interface/wireless/nstreme/print',
          '=.proplist=enable-nstreme,enable-polling,framer-limit,framer-policy',
        ],
        // v6-only: nstreme protocol. غير متاح في wifi package
      ),
      _CollectorCommand(
        sectionName: 'WIRELESS NV2 (v6)',
        sshCommand: 'interface wireless nv2 print',
        apiArgs: [
          '/interface/wireless/nv2/print',
          '=.proplist=nv2-cell-radius,nv2-downlink-ratio,nv2-mode,nv2-preshared-key,nv2-qos,nv2-security',
        ],
        // v6-only: NV2 TDMA protocol. غير متاح في wifiwave2
      ),
      _CollectorCommand(
        sectionName: 'WIRELESS NSTREME-DUAL (v6)',
        sshCommand: 'interface wireless nstreme-dual print',
        apiArgs: [
          '/interface/wireless/nstreme-dual/print',
          '=.proplist=name,rx-band,tx-band,rx-frequency,tx-frequency,remote-rx-frequency,remote-tx-frequency',
        ],
        // v6-only: nstreme dual (full-duplex). mode=nstreme-dual-slave
      ),
      _CollectorCommand(
        sectionName: 'WIRELESS ALIGN (v6)',
        sshCommand: 'interface wireless align print',
        apiArgs: [
          '/interface/wireless/align/print',
          '=.proplist=active-mode,receive-mode,audio-monitor,frame-size,active-mode,speed',
        ],
        // v6-only: وضع alignment للتهييف (antenna alignment)
      ),
      _CollectorCommand(
        sectionName: 'WIRELESS WDS (v6)',
        sshCommand: 'interface wireless wds print',
        apiArgs: [
          '/interface/wireless/wds/print',
          '=.proplist=wds-address,interface,master-interface,wds-ignore-ssid',
        ],
        // v6-specific: wds-mode={disabled|static|dynamic|static-mesh|dynamic-mesh}
      ),
      _CollectorCommand(
        sectionName: 'WIRELESS SECURITY-PROFILES (v6)',
        sshCommand: 'interface wireless security-profiles print',
        apiArgs: [
          '/interface/wireless/security-profiles/print',
          '=.proplist=name,mode,authentication-types,unicast-ciphers,group-ciphers,wpa-pre-shared-key,wpa2-pre-shared-key,wpa-eap-methods,eap-methods,tls-mode,tls-certificate',
        ],
        // v6: TKIP مدعوم. v7 wifi: TKIP-only غير مدعوم لـ WPA2
      ),
      _CollectorCommand(
        sectionName: 'WIRELESS ACCESS-LIST (v6)',
        sshCommand: 'interface wireless access-list print',
        apiArgs: [
          '/interface/wireless/access-list/print',
          '=.proplist=mac-address,interface,signal-range,allow,deny,authentication,forwarding,comment,disabled',
        ],
        // v6 wireless package. v7 wifi: /interface/wifi/access-list
      ),
      _CollectorCommand(
        sectionName: 'WIRELESS CONNECT-LIST (v6)',
        sshCommand: 'interface wireless connect-list print',
        apiArgs: [
          '/interface/wireless/connect-list/print',
          '=.proplist=interface,mac-address,ssid,signal-range,area,allow,comment,disabled',
        ],
        // v6-only wireless package
      ),
      _CollectorCommand(
        sectionName: 'WIRELESS REGISTRATION-TABLE (v6)',
        sshCommand: 'interface wireless registration-table print',
        apiArgs: [
          '/interface/wireless/registration-table/print',
          '=.proplist=interface,mac-address,ap,signal-strength,signal-to-noise,tx-rate,rx-rate,uptime,bytes,packets,encryption,wds',
        ],
        // v6 wireless package. v7 wifi: /interface/wifi/registration
      ),
      _CollectorCommand(
        sectionName: 'WIRELESS INFO ALLOWED-CHANNELS (v6)',
        sshCommand: 'interface wireless info allowed-channels',
        apiArgs: [
          '/interface/wireless/info/allowed-channels',
        ],
        // v6-only: لعرض channels المتاحة في superchannel mode
      ),
      _CollectorCommand(
        sectionName: 'CAPsMAN MANAGER (v6)',
        sshCommand: 'caps-man manager print',
        apiArgs: [
          '/caps-man/manager/print',
          '=.proplist=enabled,interface,ca-certificate,certificate,require-peer-certificate',
        ],
        // v6 CAPsMAN. v7 أعيد تصميمه باسم wifiwave2 capsman
      ),
      _CollectorCommand(
        sectionName: 'CAPsMAN INTERFACE (v6)',
        sshCommand: 'caps-man interface print',
        apiArgs: [
          '/caps-man/interface/print',
          '=.proplist=name,mac-address,radio-mac,configuration,running,disabled',
        ],
      ),
      _CollectorCommand(
        sectionName: 'CAPsMAN CONFIGURATION (v6)',
        sshCommand: 'caps-man configuration print',
        apiArgs: [
          '/caps-man/configuration/print',
          '=.proplist=name,mode,channel,country,datapath,security,ssid,hide-ssid,max-clients',
        ],
      ),
      _CollectorCommand(
        sectionName: 'CAPsMAN DATAPATH (v6)',
        sshCommand: 'caps-man datapath print',
        apiArgs: [
          '/caps-man/datapath/print',
          '=.proplist=name,client-to-client-forwarding,bridge,interface-list,vlan-mode,vlan-id,local-forwarding',
        ],
      ),
      _CollectorCommand(
        sectionName: 'CAPsMAN SECURITY (v6)',
        sshCommand: 'caps-man security print',
        apiArgs: [
          '/caps-man/security/print',
          '=.proplist=name,authentication-types,unicast-ciphers,group-ciphers,wpa-pre-shared-key,wpa2-pre-shared-key',
        ],
      ),
      _CollectorCommand(
        sectionName: 'CAPsMAN PROVISIONING (v6)',
        sshCommand: 'caps-man provisioning print',
        apiArgs: [
          '/caps-man/provisioning/print',
          '=.proplist=action,radio-mac,common-name-regexp,ip-address-ranges,hostname-regexp,identity-regexp,comment,disabled',
        ],
      ),
      _CollectorCommand(
        sectionName: 'INTERFACE WIRELESS CAP',
        sshCommand: 'interface wireless cap print',
        apiArgs: [
          '/interface/wireless/cap/print',
          '=.proplist=enabled,interfaces,caps-man-addresses,caps-man-names,caps-man-certificate-common-names,discovery,lock-to-caps-man',
        ],
        // v6: CAP (Controlled Access Point) settings
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
      // ملاحظة: /system/routing/stats/print متاح في v7 فقط — تم حذفه (v6-only).
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
          '=.proplist=host,timeout,interval,status,since,comment,disabled',
        ],
        // v6: netwatch بـ host/timeout/interval (v7 أضاف type=icmp/tcp/http)
      ),
      _CollectorCommand(
        sectionName: 'IP ARP TABLE',
        sshCommand: 'ip arp print',
        apiArgs: [
          '/ip/arp/print',
          '=.proplist=ip-address,mac-address,interface,comment,disabled,dhcp',
        ],
      ),
      _CollectorCommand(
        sectionName: 'IP NEIGHBOR',
        sshCommand: 'ip neighbor print',
        apiArgs: [
          '/ip/neighbor/print',
          '=.proplist=address,identity,interface,platform,version,system-caps',
        ],
      ),
      _CollectorCommand(
        sectionName: 'SNMP (v6)',
        sshCommand: 'snmp print',
        apiArgs: [
          '/snmp/print',
          '=.proplist=enabled,contact,location,engine-id,trap-target,trap-community',
        ],
        // v6: SNMP بـ engine-id, trap-target. v7 أضاف snmp community submenu منفصل
      ),
      _CollectorCommand(
        sectionName: 'SNMP COMMUNITY (v6)',
        sshCommand: 'snmp community print',
        apiArgs: [
          '/snmp/community/print',
          '=.proplist=name,address,security,read-access,write-access,authentication-protocol,encryption-protocol',
        ],
        // v6: SNMP communities (public, private)
      ),
      _CollectorCommand(
        sectionName: 'IP UPNP',
        sshCommand: 'ip upnp print',
        apiArgs: [
          '/ip/upnp/print',
          '=.proplist=enabled,allow-disable-external-interface',
        ],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM LOG',
        sshCommand: 'log print where topics~"error" or topics~"warning"',
        apiArgs: ['/log/print'],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM LOGGING ACTIONS',
        sshCommand: 'system logging action print',
        apiArgs: [
          '/system/logging/action/print',
          '=.proplist=name,target,remember,src-address,dst-address,bsd-syslog',
        ],
        // v6: logging targets (memory, disk, echo, remote)
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM LOGGING',
        sshCommand: 'system logging print',
        apiArgs: [
          '/system/logging/print',
          '=.proplist=topics,action,prefix,disabled',
        ],
        // v6: logging rules (topics → action)
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM HEALTH',
        sshCommand: 'system health print',
        apiArgs: [
          '/system/health/print',
          '=.proplist=voltage,temperature,cpu-temperature,fan1-speed,fan2-speed,power-consumption',
        ],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM ROUTERBOARD',
        sshCommand: 'system routerboard print',
        apiArgs: [
          '/system/routerboard/print',
          '=.proplist=routerboard,model,serial-number,current-firmware,upgrade-firmware,revision',
        ],
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM CLOCK (v6)',
        sshCommand: 'system clock print',
        apiArgs: [
          '/system/clock/print',
          '=.proplist=time,date,time-zone-name,time-zone-autodetect,dst-active,gmt-offset',
        ],
        // v6: time-zone-name متاح منذ v6.27
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM CLOCK MANUAL (v6)',
        sshCommand: 'system clock manual print',
        apiArgs: [
          '/system/clock/manual/print',
          '=.proplist=time-zone,dst-delta,dst-start,dst-end',
        ],
        // v6: time-zone هنا = GMT offset (مثل +03:00)
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM NTP CLIENT (v6 syntax)',
        sshCommand: 'system ntp client print',
        apiArgs: [
          '/system/ntp/client/print',
          '=.proplist=enabled,primary-ntp,secondary-ntp,mode',
        ],
        // v6-only: primary-ntp, secondary-ntp, mode=unicast/broadcast
        // v7 implementation جديد: servers=, enabled=, fw-action=
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM NTP SERVER (v6 syntax)',
        sshCommand: 'system ntp server print',
        apiArgs: [
          '/system/ntp/server/print',
          '=.proplist=enabled,broadcast,manycast,max-association-count',
        ],
        // v6-only: NTP server implementation قديم. v7 أعيد تصميمه
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
      _CollectorCommand(
        sectionName: 'SYSTEM HISTORY (v6)',
        sshCommand: 'system history print',
        apiArgs: [
          '/system/history/print',
          '=.proplist=message,policy,user,time',
        ],
        // v6: undo/redo history. مفيد لمراجعة التغييرات
      ),
      _CollectorCommand(
        sectionName: 'SYSTEM NOTE (v6)',
        sshCommand: 'system note print',
        apiArgs: [
          '/system/note/print',
          '=.proplist=note,show-at-login',
        ],
        // v6: system notes تُعرض عند الـ login
      ),
      _CollectorCommand(
        sectionName: 'TOOL GRAPHING (v6)',
        sshCommand: 'tool graphing print',
        apiArgs: [
          '/tool/graphing/print',
          '=.proplist=store-every,allow-target,allow-list',
        ],
        // v6: graphing لـ interfaces, queues, resources
      ),
      _CollectorCommand(
        sectionName: 'TOOL GRAPHING INTERFACE (v6)',
        sshCommand: 'tool graphing interface print',
        apiArgs: [
          '/tool/graphing/interface/print',
          '=.proplist=interface,allow-target,store-on-disk,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'TOOL GRAPHING QUEUE (v6)',
        sshCommand: 'tool graphing queue print',
        apiArgs: [
          '/tool/graphing/queue/print',
          '=.proplist=simple-queue,allow-target,allow-list,store-on-disk,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'TOOL GRAPHING RESOURCE (v6)',
        sshCommand: 'tool graphing resource print',
        apiArgs: [
          '/tool/graphing/resource/print',
          '=.proplist=allow-target,store-on-disk,comment',
        ],
      ),
      _CollectorCommand(
        sectionName: 'TOOL PROFILE (v6)',
        sshCommand: 'tool profile print',
        apiArgs: [
          '/tool/profile/print',
          '=.proplist=name,usage,type',
        ],
        // v6: per-process CPU usage. v7 أضاف processes أكثر
      ),
      _CollectorCommand(
        sectionName: 'TOOL ROMON (v6)',
        sshCommand: 'tool romon print',
        apiArgs: [
          '/tool/romon/print',
          '=.proplist=enabled,id,forbid-mac-discovery,secrets',
        ],
        // v6: RoMON (Router Management Overlay Network)
      ),
      _CollectorCommand(
        sectionName: 'TOOL SNIFFER (v6)',
        sshCommand: 'tool sniffer print',
        apiArgs: [
          '/tool/sniffer/print',
          '=.proplist=interface,only-headers,only-frames,memory-limit,file-name,file-limit,filter-stream,filter-ip-address,filter-port,filter-protocol,filter-mac-address',
        ],
        // v6: packet sniffer settings
      ),
      _CollectorCommand(
        sectionName: 'TOOL EMAIL (v6)',
        sshCommand: 'tool email print',
        apiArgs: [
          '/tool/email/print',
          '=.proplist=server,port,from,user,password,start-tls',
        ],
        // v6: email sender للـ alerts/scripts
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

      // تنفيذ الأوامر الإضافية حسب الوضع (كلها متوافقة مع v6)
      final extraCommands = _modeCommands[mode] ?? const <_CollectorCommand>[];
      final extraData = <String, String>{};
      if (extraCommands.isNotEmpty) {
        debugPrint('[MikrotikDataCollector] Collecting ${extraCommands.length} extra commands for mode=${mode.name} (v6-only)');
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

      // تنفيذ الأوامر الإضافية حسب الوضع (كلها متوافقة مع v6)
      final extraCommands = _modeCommands[mode] ?? const <_CollectorCommand>[];
      final extraData = <String, String>{};
      if (extraCommands.isNotEmpty) {
        debugPrint('[MikrotikDataCollector] Collecting ${extraCommands.length} extra commands for mode=${mode.name} (v6-only)');
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
