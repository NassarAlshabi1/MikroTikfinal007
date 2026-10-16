import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';

import 'package:mikronet/features/maintenance/data/maintenance_api.dart';

/// نوع الأداة يحدّد الواجهة التي تُفتح لها.
enum ToolKind {
  /// قائمة عامة تُقرأ من الراوتر (IP / DHCP / ARP / NAT / Queue ...).
  list,

  /// سجل مفاتيح وقيم (RouterBOARD / DNS).
  keyValue,

  /// أدوات التشخيص التفاعلية (Ping / Traceroute / Torch / Fetch / Sniffer / Log).
  diagnostics,

  /// صفحة فحص الكيبل وأزواج الإيثرنت.
  cable,
}

/// أدوات التشخيص المتاحة داخل صفحة الأدوات.
enum DiagnosticTool { ping, traceroute, torch, fetch, sniffer, logs }

/// أداة صيانة واحدة.
class MaintenanceTool {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final ToolKind kind;
  final RouterMenuSpec? menu;
  final DiagnosticTool? diagnostic;

  const MaintenanceTool({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.kind,
    this.menu,
    this.diagnostic,
  });

  /// أداة تفتح صفحة **فحص الكيبل**.
  factory MaintenanceTool.cable({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return MaintenanceTool(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      kind: ToolKind.cable,
    );
  }

  factory MaintenanceTool.list({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String command,
    required String fields,
  }) {
    return MaintenanceTool(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      kind: ToolKind.list,
      menu: RouterMenuSpec(
        id: id,
        title: title,
        subtitle: subtitle,
        command: command,
        fields: fields,
      ),
    );
  }
}

/// قسم (مجموعة) من الأدوات.
class MaintenanceSection {
  final String title;
  final IconData icon;
  final Color color;
  final List<MaintenanceTool> tools;
  final List<String> countCommands;

  const MaintenanceSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.tools,
    this.countCommands = const [],
  });
}

/// سجل أدوات الصيانة كاملًا (مطابق لأقسام لوحة التحكم).
class MaintenanceCatalog {
  static final List<MaintenanceSection> sections = [
    // ============ أدوات التشخيص ============
    MaintenanceSection(
      title: "أدوات التشخيص",
      icon: Icons.biotech_rounded,
      color: AppColors.blue,
      tools: [
        MaintenanceTool.cable(
          id: "cable_test",
          title: "فحص الكيبل",
          subtitle: "اختبار أزواج الإيثرنت وسرعة الاتصال",
          icon: Icons.cable_rounded,
          color: AppColors.teal,
        ),
        _diag(DiagnosticTool.ping, "Ping", "فحص الوصول لعنوان", Icons.wifi_tethering_rounded, const Color(0xFF1D4ED8)),
        _diag(DiagnosticTool.traceroute, "اختبار النطاق", "تتبع مسار الحزم", Icons.route_rounded, AppColors.warning),
        _diag(DiagnosticTool.torch, "Torch", "مراقبة حركة منفذ لحظيًا", Icons.bolt_rounded, AppColors.violet),
        _diag(DiagnosticTool.fetch, "Fetch", "تنزيل ملف إلى الراوتر", Icons.download_rounded, AppColors.tealDark),
        _diag(DiagnosticTool.sniffer, "تنقيط الحزم", "التقاط الحزم على منفذ", Icons.wifi_find_rounded, AppColors.pink),
        _diag(DiagnosticTool.logs, "سجل النظام", "أحداث الراوتر الأخيرة", Icons.receipt_long_rounded, AppColors.textSubtle),
      ],
    ),

    // ============ مراقبة الأداء ============
    MaintenanceSection(
      title: "مراقبة الأداء",
      icon: Icons.monitor_heart_rounded,
      color: AppColors.sky,
      countCommands: ["/ip/firewall/connection/print"],
      tools: [
        MaintenanceTool.list(
          id: "resource",
          title: "CPU والذاكرة",
          subtitle: "موارد النظام والإصدار",
          icon: Icons.memory_rounded,
          color: AppColors.warning,
          command: "/system/resource/print",
          fields: ".id,uptime,cpu-load,free-memory,total-memory,free-hdd-space,total-hdd-space,version,board-name,architecture-name",
        ),
        MaintenanceTool.list(
          id: "routerboard",
          title: "RouterBOARD",
          subtitle: "موديل الجهاز والرقم التسلسلي",
          icon: Icons.developer_board_rounded,
          color: AppColors.blue,
          command: "/system/routerboard/print",
          fields: ".id,model,serial-number,firmware-type,current-firmware,upgrade-firmware",
        ),
        MaintenanceTool.list(
          id: "connections",
          title: "الاتصالات النشطة",
          subtitle: "جلسات جدار الحماية (Conntrack)",
          icon: Icons.hub_rounded,
          color: AppColors.green,
          command: "/ip/firewall/connection/print",
          fields: ".id,protocol,src-address,dst-address,state,timeout",
        ),
        MaintenanceTool.list(
          id: "interfaces_count",
          title: "المنافذ",
          subtitle: "الواجهات وحالتها",
          icon: Icons.settings_ethernet_rounded,
          color: AppColors.violet,
          command: "/interface/print",
          fields: ".id,name,type,running,disabled,rx-byte,tx-byte",
        ),
        MaintenanceTool.list(
          id: "graphing",
          title: "الرسوم البيانية",
          subtitle: "مراقبة Graphing للمنافذ",
          icon: Icons.show_chart_rounded,
          color: AppColors.sky,
          command: "/tool/graphing/print",
          fields: ".id,name,interface,allow-address,disabled",
        ),
        MaintenanceTool.list(
          id: "neighbors",
          title: "أجهزة البث (Neighbor)",
          subtitle: "الأجهزة المجاورة المكتشفة",
          icon: Icons.radar_rounded,
          color: AppColors.danger,
          command: "/ip/neighbor/print",
          fields: ".id,address,mac-address,identity,platform,version,interface,board",
        ),
      ],
    ),

    // ============ إعدادات الشبكة (IP) ============
    MaintenanceSection(
      title: "إعدادات الشبكة (IP)",
      icon: Icons.lan_rounded,
      color: AppColors.green,
      countCommands: ["/ip/address/print", "/ip/dhcp-server/lease/print"],
      tools: [
        MaintenanceTool.list(
          id: "ip_addresses",
          title: "IP Addresses",
          subtitle: "عناوين الأجهزة والمنافذ",
          icon: Icons.alt_route_rounded,
          color: AppColors.green,
          command: "/ip/address/print",
          fields: ".id,address,network,interface,disabled,comment",
        ),
        MaintenanceTool.list(
          id: "dhcp_server",
          title: "خادم DHCP",
          subtitle: "إعدادات خوادم DHCP",
          icon: Icons.dns_rounded,
          color: AppColors.warning,
          command: "/ip/dhcp-server/print",
          fields: ".id,name,interface,address-pool,disabled,lease-time",
        ),
        MaintenanceTool.list(
          id: "dhcp_lease",
          title: "إيجارات DHCP",
          subtitle: "الأجهزة التي أخذت عنوانًا",
          icon: Icons.list_alt_rounded,
          color: AppColors.pink,
          command: "/ip/dhcp-server/lease/print",
          fields: ".id,address,mac-address,host-name,status,server,comment",
        ),
        MaintenanceTool.list(
          id: "dhcp_client",
          title: "عميل DHCP",
          subtitle: "المنافذ التي تستلم عنوانًا",
          icon: Icons.sync_alt_rounded,
          color: AppColors.violet,
          command: "/ip/dhcp-client/print",
          fields: ".id,interface,address,gateway,status,disabled",
        ),
        MaintenanceTool.list(
          id: "arp",
          title: "ARP",
          subtitle: "جدول عناوين MAC ↔ IP",
          icon: Icons.swap_horiz_rounded,
          color: AppColors.blue,
          command: "/ip/arp/print",
          fields: ".id,address,mac-address,interface,dynamic,disabled,comment",
        ),
        MaintenanceTool.list(
          id: "dns",
          title: "خادم DNS",
          subtitle: "إعدادات DNS والكاش",
          icon: Icons.dns_outlined,
          color: AppColors.sky,
          command: "/ip/dns/print",
          fields: ".id,servers,dynamic-servers,allow-remote-requests,cache-size,cache-used",
        ),
        MaintenanceTool.list(
          id: "address_lists",
          title: "مجموعات العناوين",
          subtitle: "قوائم العناوين (Address Lists)",
          icon: Icons.format_list_bulleted_rounded,
          color: AppColors.textMuted,
          command: "/ip/firewall/address-list/print",
          fields: ".id,list,address,dynamic,disabled,comment",
        ),
      ],
    ),

    // ============ جدار الحماية والقوائم ============
    MaintenanceSection(
      title: "جدار الحماية (Firewall)",
      icon: Icons.security_rounded,
      color: AppColors.danger,
      countCommands: ["/ip/firewall/filter/print"],
      tools: [
        MaintenanceTool.list(
          id: "filter",
          title: "قواعد التصفية",
          subtitle: "Firewall Filter Rules",
          icon: Icons.filter_alt_rounded,
          color: AppColors.danger,
          command: "/ip/firewall/filter/print",
          fields: ".id,chain,action,protocol,src-address,dst-address,comment,disabled",
        ),
        MaintenanceTool.list(
          id: "nat",
          title: "قواعد NAT",
          subtitle: "تحويل العناوين والمنافذ",
          icon: Icons.swap_calls_rounded,
          color: AppColors.warning,
          command: "/ip/firewall/nat/print",
          fields: ".id,chain,action,protocol,src-address,dst-address,to-addresses,comment,disabled",
        ),
        MaintenanceTool.list(
          id: "mangle",
          title: "قواعد Mangle",
          subtitle: "تعديل الحزم والتوجيه",
          icon: Icons.tune_rounded,
          color: AppColors.green,
          command: "/ip/firewall/mangle/print",
          fields: ".id,chain,action,protocol,src-address,dst-address,comment,disabled",
        ),
        MaintenanceTool.list(
          id: "layer7",
          title: "بروتوكولات Layer7",
          subtitle: "أنماط تصنيف التطبيقات",
          icon: Icons.layers_rounded,
          color: AppColors.violet,
          command: "/ip/firewall/layer7-protocol/print",
          fields: ".id,name,regexp,comment",
        ),
      ],
    ),

    // ============ إدارة النطاق الترددي ============
    MaintenanceSection(
      title: "إدارة النطاق الترددي (Queue)",
      icon: Icons.speed_rounded,
      color: AppColors.warning,
      countCommands: ["/queue/simple/print"],
      tools: [
        MaintenanceTool.list(
          id: "queue_simple",
          title: "قوائم Queue البسيطة",
          subtitle: "تحديد السرعة لكل مستخدم/شبكة",
          icon: Icons.speed_rounded,
          color: AppColors.warning,
          command: "/queue/simple/print",
          fields: ".id,name,target,max-limit,burst-limit,disabled,comment",
        ),
        MaintenanceTool.list(
          id: "queue_tree",
          title: "Queue الشجرية",
          subtitle: "توزيع النطاق هرميًا",
          icon: Icons.account_tree_rounded,
          color: AppColors.sky,
          command: "/queue/tree/print",
          fields: ".id,name,parent,max-limit,disabled",
        ),
        MaintenanceTool.list(
          id: "queue_types",
          title: "أنواع Queue",
          subtitle: "خوارزميات إدارة الازدحام",
          icon: Icons.category_rounded,
          color: AppColors.textMuted,
          command: "/queue/type/print",
          fields: ".id,name,kind,pcq-rate",
        ),
      ],
    ),
  ];

  static MaintenanceTool _diag(
    DiagnosticTool tool,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return MaintenanceTool(
      id: "diag_${tool.name}",
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      kind: ToolKind.diagnostics,
      diagnostic: tool,
    );
  }
}
