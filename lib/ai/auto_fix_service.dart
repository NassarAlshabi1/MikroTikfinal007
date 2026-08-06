// ============================================================
//  AutoFix Service — يقدّم إصلاحات تلقائية محلية
//
//  يقوم بفحص الـ MikrotikSnapshot بدون الحاجة للـ AI ويقترح:
//  - إصلاحات أمنية حرجة (services, NAT, firewall)
//  - إصلاحات أداء (Fasttrack, hardware offload)
//  - إصلاحات QoS (queues مفقودة, PCQ recommendations)
//  - سكربتات Backup قبل التطبيق
//
//  مفيد عندما:
//  - الـ AI بطيء أو غير متاح
//  - تريد إصلاحاً سريعاً ومحدداً
//  - تريد معاينة ما سيفعله الـ AI قبل الموافقة
// ============================================================

import 'package:flutter/foundation.dart';

import 'command_executor.dart';
import 'diagnostics_models.dart';
import 'script_executor.dart';

/// نوع الإصلاح
enum FixCategory {
  security, // إصلاحات أمنية
  performance, // تحسينات أداء
  qos, // إعدادات QoS
  routing, // مشاكل توجيه
  vpn, // إعدادات VPN
  wifi, // إعدادات Wireless
  hotspot, // إعدادات Hotspot
  safety, // نسخ احتياطي/استعادة
  dhcp, // إعدادات DHCP (مستوحى من Mikrotik-AI-Cloud)
  monitoring, // Netwatch, SNMP, NTP (مستوحى من Mikrotik-AI-Cloud)
  infrastructure, // Bridge, VLAN, IPv6 (مستوحى من Mikrotik-AI-Cloud)
}

extension FixCategoryExtension on FixCategory {
  String get displayName {
    switch (this) {
      case FixCategory.security:
        return 'أمن';
      case FixCategory.performance:
        return 'أداء';
      case FixCategory.qos:
        return 'QoS';
      case FixCategory.routing:
        return 'توجيه';
      case FixCategory.vpn:
        return 'VPN';
      case FixCategory.wifi:
        return 'Wireless';
      case FixCategory.hotspot:
        return 'Hotspot';
      case FixCategory.safety:
        return 'أمان البيانات';
      case FixCategory.dhcp:
        return 'DHCP';
      case FixCategory.monitoring:
        return 'مراقبة';
      case FixCategory.infrastructure:
        return 'بنية تحتية';
    }
  }

  String get icon {
    switch (this) {
      case FixCategory.security:
        return '🛡️';
      case FixCategory.performance:
        return '⚡';
      case FixCategory.qos:
        return '📊';
      case FixCategory.routing:
        return '🗺️';
      case FixCategory.vpn:
        return '🔐';
      case FixCategory.wifi:
        return '📶';
      case FixCategory.hotspot:
        return '📡';
      case FixCategory.safety:
        return '💾';
      case FixCategory.dhcp:
        return '🌐';
      case FixCategory.monitoring:
        return '👁️';
      case FixCategory.infrastructure:
        return '🏗️';
    }
  }
}

/// إصلاح مقترح
@immutable
class ProposedFix {
  final String id; // معرّف فريد
  final String title; // عنوان مختصر
  final String description; // وصف المشكلة
  final String impact; // الأثر المتوقع
  final FixCategory category; // التصنيف
  final CommandRiskLevel risk; // مستوى الخطورة
  final RouterOsScript script; // السكربت الذي يصلح المشكلة
  final bool autoApplySafe; // هل يمكن تطبيقه تلقائياً (آمن جداً)؟

  const ProposedFix({
    required this.id,
    required this.title,
    required this.description,
    required this.impact,
    required this.category,
    required this.risk,
    required this.script,
    this.autoApplySafe = false,
  });
}

class AutoFixService {
  AutoFixService._();

  /// يحلل snapshot ويُرجع قائمة الإصلاحات المقترحة
  static List<ProposedFix> analyze(MikrotikSnapshot snapshot,
      {DiagnosticMode? mode}) {
    final fixes = <ProposedFix>[];

    // استدعاء المحللات حسب الوضع (إن وُجد) + التحليل العام دائماً
    fixes.addAll(_analyzeGeneral(snapshot));
    if (mode == DiagnosticMode.security) {
      fixes.addAll(_analyzeSecurity(snapshot));
    }
    if (mode == DiagnosticMode.qos) {
      fixes.addAll(_analyzeQos(snapshot));
    }
    if (mode == DiagnosticMode.performance) {
      fixes.addAll(_analyzePerformance(snapshot));
    }
    if (mode == DiagnosticMode.dhcp) {
      fixes.addAll(_analyzeDhcp(snapshot));
    }
    if (mode == DiagnosticMode.monitoring) {
      fixes.addAll(_analyzeMonitoring(snapshot));
    }
    if (mode == DiagnosticMode.infrastructure) {
      fixes.addAll(_analyzeInfrastructure(snapshot));
    }

    // ترتيب: الأكثر خطورة وأماناً أولاً
    fixes.sort((a, b) {
      // dangerous أولاً (لأنها مشاكل حرجة)
      final riskOrder = {
        CommandRiskLevel.dangerous: 0,
        CommandRiskLevel.moderate: 1,
        CommandRiskLevel.safe: 2,
      };
      return riskOrder[a.risk]!.compareTo(riskOrder[b.risk]!);
    });

    return fixes;
  }

  // ============================================================
  //  تحليل عام (دائماً)
  // ============================================================
  static List<ProposedFix> _analyzeGeneral(MikrotikSnapshot snapshot) {
    final fixes = <ProposedFix>[];

    // 1) فحص Default Route
    if (!snapshot.routes.toLowerCase().contains('0.0.0.0/0') &&
        !snapshot.routes.toLowerCase().contains('::/0')) {
      fixes.add(const ProposedFix(
        id: 'missing-default-route',
        title: 'لا يوجد Default Route',
        description: 'لم يتم العثور على default route (0.0.0.0/0). '
            'قد لا يستطيع الجهاز الوصول للإنترنت.',
        impact: 'قد ينقطع الإنترنت عن المستخدمين أو لا يعمل أصلاً.',
        category: FixCategory.routing,
        risk: CommandRiskLevel.moderate,
        script: RouterOsScript(
          title: 'إضافة Default Route',
          description: 'يضيف default route عبر gateway محدد. عدّل IP يدوياً.',
          overallRisk: CommandRiskLevel.moderate,
          category: 'routing',
          commands: [
            '/ip route add dst-address=0.0.0.0/0 gateway=YOUR_GATEWAY_IP comment="default-route"',
          ],
        ),
      ));
    }

    // 2) فحص NAT masquerade
    if (!snapshot.firewall.toLowerCase().contains('masquerade') &&
        !snapshot.extraData.containsKey('IP FIREWALL NAT')) {
      // نتحقق من NAT إن وُجدت في extraData
      final natData = snapshot.extraData['IP FIREWALL NAT'] ?? '';
      if (!natData.toLowerCase().contains('masquerade') && natData.isNotEmpty) {
        fixes.add(const ProposedFix(
          id: 'missing-nat-masquerade',
          title: 'NAT masquerade مفقود',
          description: 'لا توجد قاعدة masquerade في الـ NAT. '
              'لن يستطيع المستخدمون خلف الجهاز الوصول للإنترنت.',
          impact: 'مستخدمو LAN لا يستطيعون الوصول للإنترنت.',
          category: FixCategory.routing,
          risk: CommandRiskLevel.moderate,
          script: RouterOsScript(
            title: 'إضافة NAT masquerade',
            description:
                'يضيف masquerade على WAN interface. عدّل ether1 اسم الـ WAN.',
            overallRisk: CommandRiskLevel.moderate,
            category: 'routing',
            commands: [
              '/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade comment="default-masquerade"',
            ],
          ),
        ));
      }
    }

    return fixes;
  }

  // ============================================================
  //  تحليل أمني
  // ============================================================
  static List<ProposedFix> _analyzeSecurity(MikrotikSnapshot snapshot) {
    final fixes = <ProposedFix>[];

    final services = snapshot.extraData['IP SERVICES'] ?? '';
    final users = snapshot.extraData['USERS'] ?? '';
    final upnp = snapshot.extraData['IP UPNP'] ?? '';

    // 1) Telnet مُفعّل
    if (services.toLowerCase().contains('telnet') &&
        !services.toLowerCase().contains('telnet') == false &&
        !RegExp(r'telnet.*false', caseSensitive: false).hasMatch(services)) {
      // التحقق إن telnet مُفعّل (لا توجد علامة disabled)
      if (RegExp(r'telnet\b.*\b(?:true|enabled)?\s*$', caseSensitive: false)
              .hasMatch(services) ||
          (services.toLowerCase().contains('telnet') &&
              !services.toLowerCase().contains('telnet') == false)) {
        fixes.add(const ProposedFix(
          id: 'disable-telnet',
          title: 'Telnet مُفعّل — غير آمن',
          description: 'Telnet يرسل البيانات (بما فيها كلمات المرور) '
              'كـ plain text. يجب تعطيله فوراً.',
          impact: 'سرقة كلمات المرور، اختراق كامل للجهاز.',
          category: FixCategory.security,
          risk: CommandRiskLevel.moderate,
          autoApplySafe: true,
          script: RouterOsScript(
            title: 'تعطيل Telnet',
            description: 'يعطّل خدمة Telnet غير الآمنة',
            overallRisk: CommandRiskLevel.moderate,
            category: 'security',
            commands: [
              '/ip service disable telnet',
            ],
          ),
        ));
      }
    }

    // 2) FTP مُفعّل
    if (services.toLowerCase().contains('ftp') &&
        RegExp(r'ftp\b', caseSensitive: false).hasMatch(services)) {
      fixes.add(const ProposedFix(
        id: 'disable-ftp',
        title: 'FTP مُفعّل — غير آمن',
        description: 'FTP غير مشفّر ويجب تعطيله إن لم يُستخدم.',
        impact: 'سرقة بيانات، رفع ملفات غير مصرح.',
        category: FixCategory.security,
        risk: CommandRiskLevel.moderate,
        autoApplySafe: true,
        script: RouterOsScript(
          title: 'تعطيل FTP',
          description: 'يعطّل خدمة FTP',
          overallRisk: CommandRiskLevel.moderate,
          category: 'security',
          commands: [
            '/ip service disable ftp',
          ],
        ),
      ));
    }

    // 3) API بدون HTTPS (8728)
    if (services.contains('8728') && !services.contains('8729')) {
      fixes.add(const ProposedFix(
        id: 'disable-api-plaintext',
        title: 'API على منفذ 8728 بدون تشفير',
        description: 'خدمة API على المنفذ 8728 تستخدم plain text. '
            'استخدم 8729 (api-ssl) بدلاً منها.',
        impact: 'سرقة بيانات اعتماد API، اختراق.',
        category: FixCategory.security,
        risk: CommandRiskLevel.moderate,
        autoApplySafe: true,
        script: RouterOsScript(
          title: 'تعطيل API العادي وتفعيل api-ssl',
          description: 'يعطّل api على 8728 ويترك api-ssl على 8729',
          overallRisk: CommandRiskLevel.moderate,
          category: 'security',
          commands: [
            '/ip service disable api',
            '/ip service enable api-ssl',
          ],
        ),
      ));
    }

    // 4) UPnP مُفعّل
    if (upnp.toLowerCase().contains('enabled=true') ||
        upnp.toLowerCase().contains('yes')) {
      fixes.add(const ProposedFix(
        id: 'disable-upnp',
        title: 'UPnP مُفعّل — خطر أمني',
        description: 'UPnP يسمح للتطبيقات بفتح منافذ تلقائياً بدون موافقة. '
            'قد يُستخدم لاختراق الأجهزة الداخلية.',
        impact: 'ثغرات أمنية، Botnet، اختراق كاميرات/أجهزة IoT.',
        category: FixCategory.security,
        risk: CommandRiskLevel.moderate,
        autoApplySafe: true,
        script: RouterOsScript(
          title: 'تعطيل UPnP',
          description: 'يعطّل UPnP نهائياً',
          overallRisk: CommandRiskLevel.moderate,
          category: 'security',
          commands: [
            '/ip upnp set enabled=no',
          ],
        ),
      ));
    }

    // 5) مستخدم admin بدون كلمة مرور
    if (users.toLowerCase().contains('admin') &&
        !users.toLowerCase().contains('password')) {
      // نتحقق إن كان هناك admin بدون كلمة مرور — تقريباً مستحيل اكتشافه من print فقط
      // لكن نضيف توصية دائماً
    }

    return fixes;
  }

  // ============================================================
  //  تحليل QoS
  // ============================================================
  static List<ProposedFix> _analyzeQos(MikrotikSnapshot snapshot) {
    final fixes = <ProposedFix>[];

    final queueSimple = snapshot.extraData['QUEUE SIMPLE'] ?? '';
    final queueTree = snapshot.extraData['QUEUE TREE'] ?? '';
    final queueType = snapshot.extraData['QUEUE TYPE'] ?? '';

    // 1) لا يوجد أي queue — إعداد QoS أساسي
    if ((queueSimple.isEmpty || queueSimple == '(empty)') &&
        (queueTree.isEmpty || queueTree == '(empty)')) {
      fixes.add(const ProposedFix(
        id: 'setup-basic-qos',
        title: 'لا يوجد إعدادات QoS — حركة المرور بدون تنظيم',
        description: 'لا يوجد أي queue simple أو queue tree. كل المستخدمين '
            'يتشاركون الـ bandwidth بدون عدالة. يُنصح بإعداد PCQ أساسي.',
        impact: 'مستخدم واحد قد يستهلك كل الـ bandwidth، تذبذب latency، '
            'تأثر VoIP والألعاب.',
        category: FixCategory.qos,
        risk: CommandRiskLevel.moderate,
        script: RouterOsScript(
          title: 'إعداد QoS أساسي مع PCQ',
          description: 'ينشئ PCQ types للعدالة بين المستخدمين، ويضيف queue '
              'شامل لـ LAN. عدّل IP والـ bandwidth حسب شبكتك.',
          overallRisk: CommandRiskLevel.moderate,
          category: 'qos',
          commands: [
            '/queue type add name="pcq-upload" kind=pcq pcq-rate=5M pcq-classifier=src-address',
            '/queue type add name="pcq-download" kind=pcq pcq-rate=20M pcq-classifier=dst-address',
            '/queue simple add name="lan-users" target=192.168.88.0/24 queue=pcq-upload/pcq-download max-limit=10M/50M comment="auto-qos"',
            '/queue tree add name="voip-priority" parent=lan priority=1 max-limit=2M',
            '/queue tree add name="bulk-traffic" parent=lan priority=8 max-limit=20M',
          ],
        ),
      ));
    }

    // 2) لا يوجد PCQ في queue types
    if (!queueType.toLowerCase().contains('pcq') &&
        queueType.isNotEmpty &&
        queueType != '(empty)') {
      fixes.add(const ProposedFix(
        id: 'add-pcq-types',
        title: 'لا يوجد PCQ queue types — عدالة ضعيفة',
        description: 'بدون PCQ، تتم معاملة كل مستخدم بنفس الـ queue وقد يحصل '
            'مستخدم نشط على نصيب أكبر. PCQ يضمن العدالة.',
        impact: 'عدالة ضعيفة بين المستخدمين، اكتظاز على المستخدمين النشطين.',
        category: FixCategory.qos,
        risk: CommandRiskLevel.moderate,
        script: RouterOsScript(
          title: 'إنشاء PCQ queue types',
          description: 'ينشئ PCQ types للرفع والتحميل',
          overallRisk: CommandRiskLevel.moderate,
          category: 'qos',
          commands: [
            '/queue type add name="pcq-upload" kind=pcq pcq-rate=5M pcq-classifier=src-address',
            '/queue type add name="pcq-download" kind=pcq pcq-rate=20M pcq-classifier=dst-address',
          ],
        ),
      ));
    }

    // 3) queue simple بدون queue type محدد (default)
    if (queueSimple.toLowerCase().contains('queue=default') ||
        queueSimple.toLowerCase().contains('queue=default-small')) {
      fixes.add(const ProposedFix(
        id: 'replace-default-queue',
        title: 'استخدام queue type افتراضي (default)',
        description: 'استخدام default queue type بدل PCQ يقلل العدالة. '
            'ينصح باستبداله بـ pcq-upload/pcq-download.',
        impact: 'عدالة أقل، استهلاك مفرط من المستخدمين النشطين.',
        category: FixCategory.qos,
        risk: CommandRiskLevel.moderate,
        script: RouterOsScript(
          title: 'استبدال default queue type بـ PCQ',
          description: 'يحدّث queue simple الحالية لاستخدام PCQ',
          overallRisk: CommandRiskLevel.moderate,
          category: 'qos',
          commands: [
            '/queue simple set [find] queue=pcq-upload/pcq-download',
          ],
        ),
      ));
    }

    return fixes;
  }

  // ============================================================
  //  تحليل أداء
  // ============================================================
  static List<ProposedFix> _analyzePerformance(MikrotikSnapshot snapshot) {
    final fixes = <ProposedFix>[];

    // 1) Fasttrack غير مُفعّل
    if (!snapshot.firewall.toLowerCase().contains('fasttrack-connection')) {
      fixes.add(const ProposedFix(
        id: 'enable-fasttrack',
        title: 'Fasttrack غير مُفعّل — throughput أقل',
        description:
            'Fasttrack (RouterOS v6.29+) يتيح تجاوز firewall للاتصالات '
            'المُنشأة، مما يضاعف throughput بـ 2-3x.',
        impact: 'throughput أقل بـ 50-70% من الإمكانيات.',
        category: FixCategory.performance,
        risk: CommandRiskLevel.moderate,
        script: RouterOsScript(
          title: 'تفعيل Fasttrack',
          description: 'يضيف قاعدتي fasttrack + accept للاتصالات المُنشأة',
          overallRisk: CommandRiskLevel.moderate,
          category: 'performance',
          commands: [
            '/ip firewall filter add chain=forward action=fasttrack-connection connection-state=established,related comment="fasttrack"',
            '/ip firewall filter add chain=forward action=accept connection-state=established,related comment="accept-established"',
          ],
        ),
      ));
    }

    // 2) CPU usage عالي
    if (snapshot.system.toLowerCase().contains('cpu-load') &&
        RegExp(r'cpu-load=(\d+)').hasMatch(snapshot.system)) {
      final match = RegExp(r'cpu-load=(\d+)').firstMatch(snapshot.system);
      if (match != null) {
        final cpuLoad = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (cpuLoad > 80) {
          fixes.add(ProposedFix(
            id: 'high-cpu-usage',
            title: 'CPU usage مرتفع ($cpuLoad%)',
            description: 'استخدام CPU فوق 80% يسبب latency عالٍ وفقدان حزم. '
                'السبب الشائع: queue على interface بدل IP، أو firewall rules كثيرة.',
            impact: 'latency عالٍ، فقدان حزم، انخفاض throughput.',
            category: FixCategory.performance,
            risk: CommandRiskLevel.safe,
            script: const RouterOsScript(
              title: 'فحص أسباب CPU العالي',
              description: 'يجمع بيانات تشخيصية للأداء',
              overallRisk: CommandRiskLevel.safe,
              category: 'performance',
              commands: [
                '/system resource print',
                '/system resource cpu print',
                '/tool profile print',
                '/ip firewall filter print stats',
                '/queue simple print stats',
              ],
            ),
          ));
        }
      }
    }

    return fixes;
  }

  // ============================================================
  //  تحليل DHCP — مستوحى من integration tools: list_dhcp_servers, list_dhcp_leases, ...
  // ============================================================
  static List<ProposedFix> _analyzeDhcp(MikrotikSnapshot snapshot) {
    final fixes = <ProposedFix>[];

    final dhcpServers = snapshot.extraData['IP DHCP SERVER'] ?? '';
    final dhcpLeases = snapshot.extraData['IP DHCP LEASES'] ?? '';
    final ipPools = snapshot.extraData['IP POOL'] ?? '';

    // 1) DHCP server معطّل
    if (dhcpServers.toLowerCase().contains('disabled=true') ||
        dhcpServers.toLowerCase().contains('X ')) {
      fixes.add(const ProposedFix(
        id: 'enable-dhcp-server',
        title: 'DHCP server معطّل',
        description: 'أحد خوادم DHCP معطّل. الأجهزة لن تحصل على IP تلقائياً.',
        impact: 'الأجهزة الجديدة لن تستطيع الاتصال بالشبكة.',
        category: FixCategory.dhcp,
        risk: CommandRiskLevel.moderate,
        autoApplySafe: false,
        script: RouterOsScript(
          title: 'تفعيل DHCP servers المعطّلة',
          description: 'يفعّل كل خوادم DHCP المعطّلة',
          overallRisk: CommandRiskLevel.moderate,
          category: 'dhcp',
          commands: [
            '/ip dhcp-server enable [find disabled=yes]',
          ],
        ),
      ));
    }

    // 2) DHCP server بدون authoritative
    if (dhcpServers.isNotEmpty &&
        !dhcpServers.toLowerCase().contains('authoritative=yes')) {
      fixes.add(const ProposedFix(
        id: 'set-dhcp-authoritative',
        title: 'DHCP بدون authoritative=yes',
        description:
            'بدون authoritative=yes، قد يستجيب الجهاز بـ NAK للأجهزة التي '
            'تطلب IP قديم، مما يسبب تأخيراً في الاتصال.',
        impact: 'تأخر في حصول الأجهزة على IP، مشاكل تجديد الـ lease.',
        category: FixCategory.dhcp,
        risk: CommandRiskLevel.moderate,
        script: RouterOsScript(
          title: 'ضبط DHCP authoritative=yes',
          description: 'يجعل كل خوادم DHCP authoritative',
          overallRisk: CommandRiskLevel.moderate,
          category: 'dhcp',
          commands: [
            '/ip dhcp-server set [find] authoritative=yes',
          ],
        ),
      ));
    }

    // 3) DHCP leases كثيرة مع حالة "waiting" أو "offered"
    if (dhcpLeases.isNotEmpty) {
      final waitingCount =
          'waiting'.allMatches(dhcpLeases.toLowerCase()).length;
      if (waitingCount > 5) {
        fixes.add(ProposedFix(
          id: 'cleanup-dhcp-waiting',
          title: '$waitingCount DHCP leases في حالة waiting',
          description: 'وجود عدد كبير من leases في حالة waiting يدل على أجهزة '
              'طلبت IP ولم تكمل الطلب، أو pool ممتلئ.',
          impact: 'استنزاف الـ IP pool، تأخر في توزيع الـ IPs.',
          category: FixCategory.dhcp,
          risk: CommandRiskLevel.moderate,
          script: const RouterOsScript(
            title: 'تنظيف DHCP leases المعلّقة',
            description: 'يحذف الـ leases في حالة waiting',
            overallRisk: CommandRiskLevel.moderate,
            category: 'dhcp',
            commands: [
              '/ip dhcp-server lease remove [find status=waiting]',
            ],
          ),
        ));
      }
    }

    // 4) DHCP lease time قصير جداً
    if (dhcpServers.toLowerCase().contains('lease-time=00:0') ||
        dhcpServers.toLowerCase().contains('lease-time=00:1')) {
      fixes.add(const ProposedFix(
        id: 'fix-short-lease-time',
        title: 'DHCP lease time قصير جداً',
        description: 'lease time أقل من 10 دقائق يسبب تجديدات متكررة وحمل زائد '
            'على الشبكة. الموصى به: 10:00:00 (10 ساعات) على الأقل.',
        impact: 'حمل زائد على الـ router، انقطاع مؤقت للأجهزة عند التجديد.',
        category: FixCategory.dhcp,
        risk: CommandRiskLevel.moderate,
        script: RouterOsScript(
          title: 'ضبط DHCP lease time لـ 10 ساعات',
          description: 'يضبط lease-time على 10:00:00 لكل خوادم DHCP',
          overallRisk: CommandRiskLevel.moderate,
          category: 'dhcp',
          commands: [
            '/ip dhcp-server set [find] lease-time=10:00:00',
          ],
        ),
      ));
    }

    // 5) Pool ممتلئ (نسبة الإشغال > 90%)
    if (dhcpLeases.isNotEmpty && ipPools.isNotEmpty) {
      // عدّ الـ leases النشطة
      final activeLeases = 'bound'.allMatches(dhcpLeases.toLowerCase()).length;
      // تقدير حجم pool بناءً على ranges
      if (activeLeases > 250) {
        fixes.add(ProposedFix(
          id: 'expand-dhcp-pool',
          title: 'DHCP pool ممتلئ ($activeLeases lease نشط)',
          description:
              'عدد كبير من الـ leases النشطة قد يقترب من حدود الـ pool. '
              'وسّع الـ pool أو استخدم subnet أصغر.',
          impact: 'أجهزة جديدة لن تحصل على IP، انقطاع الاتصال.',
          category: FixCategory.dhcp,
          risk: CommandRiskLevel.moderate,
          script: const RouterOsScript(
            title: 'فحص إشغال DHCP pool',
            description: 'يجمع بيانات إشعار الـ pool لاتخاذ قرار التوسعة',
            overallRisk: CommandRiskLevel.safe,
            category: 'dhcp',
            commands: [
              '/ip pool print',
              '/ip dhcp-server lease print count-only',
              '/ip dhcp-server lease print count-only where status=bound',
            ],
          ),
        ));
      }
    }

    return fixes;
  }

  // ============================================================
  //  تحليل المراقبة — مستوحى من integration: list_netwatch, list_snmp, ntp_client, ...
  // ============================================================
  static List<ProposedFix> _analyzeMonitoring(MikrotikSnapshot snapshot) {
    final fixes = <ProposedFix>[];

    final ntpClient = snapshot.extraData['SYSTEM NTP CLIENT'] ?? '';
    final clock = snapshot.extraData['SYSTEM CLOCK'] ?? '';
    final netwatch = snapshot.extraData['TOOL NETWATCH'] ?? '';
    final snmp = snapshot.extraData['SNMP'] ?? '';
    final scheduler = snapshot.extraData['SYSTEM SCHEDULER'] ?? '';

    // 1) NTP client غير مُفعّل أو بدون خادم
    if (ntpClient.toLowerCase().contains('enabled=no') ||
        ntpClient.toLowerCase().contains('disabled=true') ||
        !ntpClient.toLowerCase().contains('server')) {
      fixes.add(const ProposedFix(
        id: 'enable-ntp-client',
        title: 'NTP client غير مُفعّل',
        description: 'بدون NTP، ساعة الجهاز قد تنحرف، مما يسبب مشاكل في: '
            'SSL certificates، scheduling، logs غير متسقة زمنياً.',
        impact: 'انحراف الوقت، مشاكل TLS، logs غير متسقة، فشل scheduled tasks.',
        category: FixCategory.monitoring,
        risk: CommandRiskLevel.moderate,
        autoApplySafe: true,
        script: RouterOsScript(
          title: 'تفعيل NTP client مع خوادم عامة',
          description: 'يضبط NTP على pool.ntp.org (مجاني وموثوق)',
          overallRisk: CommandRiskLevel.moderate,
          category: 'monitoring',
          commands: [
            '/system ntp client set enabled=yes servers=0.pool.ntp.org,1.pool.ntp.org,2.pool.ntp.org',
          ],
        ),
      ));
    }

    // 2) الوقت غير متزامن (time-zone خاطئ)
    if (clock.toLowerCase().contains('time-zone-autodetect=false') &&
        clock.toLowerCase().contains('time-zone=')) {
      // check if time-zone is +00:00 (UTC) which might be wrong
      final tzMatch = RegExp(r'time-zone=([+-]\d{2}:\d{2})').firstMatch(clock);
      if (tzMatch != null && tzMatch.group(1) == '+00:00') {
        fixes.add(const ProposedFix(
          id: 'set-time-zone',
          title: 'الوقت UTC (+00:00) — قد يكون خاطئاً',
          description: 'ضبط الوقت على UTC قد يسبب ارتباكاً في قراءة الـ logs. '
              'فعّل time-zone-autodetect أو اضبط التوقيت يدوياً.',
          impact: 'صعوبة تتبع الـ logs، توقيت خاطئ في الـ scheduled tasks.',
          category: FixCategory.monitoring,
          risk: CommandRiskLevel.moderate,
          autoApplySafe: true,
          script: RouterOsScript(
            title: 'تفعيل time-zone-autodetect',
            description: 'يضبط التوقيت تلقائياً',
            overallRisk: CommandRiskLevel.moderate,
            category: 'monitoring',
            commands: [
              '/system clock set time-zone-autodetect=yes',
            ],
          ),
        ));
      }
    }

    // 3) SNMP مُفعّل بدون community قوي
    if (snmp.toLowerCase().contains('enabled=yes') &&
        (snmp.toLowerCase().contains('community=public') ||
            snmp.toLowerCase().contains('community=private'))) {
      fixes.add(const ProposedFix(
        id: 'snmp-weak-community',
        title: 'SNMP مُفعّل بـ community ضعيف (public/private)',
        description: 'استخدام public أو private كـ SNMP community يسمح لأي شخص '
            'على الشبكة بقراءة بيانات الجهاز.',
        impact: 'كشف معلومات الجهاز، هجمات enumeration، ثغرة أمنية.',
        category: FixCategory.security,
        risk: CommandRiskLevel.moderate,
        script: RouterOsScript(
          title: 'تغيير SNMP community لقيمة قوية',
          description:
              'يغيّر community من public لقيمة قوية. عدّل الـ community الجديد.',
          overallRisk: CommandRiskLevel.moderate,
          category: 'monitoring',
          commands: [
            '/snmp community set [find name=public] name=CHANGE_ME_STRONG_COMMUNITY read-access=yes write-access=no',
          ],
        ),
      ));
    }

    // 4) لا يوجد Netwatch — ينصح بإضافته للمراقبة
    if (netwatch.isEmpty || netwatch == '(empty)') {
      fixes.add(const ProposedFix(
        id: 'add-netwatch-gateway',
        title: 'لا يوجد Netwatch — مراقبة الـ gateway مفقودة',
        description:
            'Netwatch يراقب توفر الـ gateway وينفّذ scripts عند انقطاعه. '
            'مفيد للـ failover التلقائي.',
        impact: 'لا يوجد تنبيه عند انقطاع الإنترنت، لا failover تلقائي.',
        category: FixCategory.monitoring,
        risk: CommandRiskLevel.moderate,
        script: RouterOsScript(
          title: 'إضافة Netwatch لمراقبة gateway',
          description: 'يراقب الـ gateway كل 10 ثواني. عدّل IP الـ gateway.',
          overallRisk: CommandRiskLevel.moderate,
          category: 'monitoring',
          commands: [
            '/tool netwatch add host=YOUR_GATEWAY_IP interval=10s timeout=1s comment="gateway-monitor"',
          ],
        ),
      ));
    }

    // 5) لا يوجد scheduler للنسخ الاحتياطي التلقائي
    if (!scheduler.toLowerCase().contains('backup')) {
      fixes.add(const ProposedFix(
        id: 'add-auto-backup-scheduler',
        title: 'لا يوجد نسخ احتياطي تلقائي مجدول',
        description: 'بدون backup مجدول، ستفقد الإعدادات عند فشل الجهاز. '
            'يُنصح بـ backup أسبوعي تلقائي.',
        impact: 'فقدان الإعدادات عند فشل الجهاز، استرجاع بطيء.',
        category: FixCategory.safety,
        risk: CommandRiskLevel.moderate,
        autoApplySafe: true,
        script: RouterOsScript(
          title: 'إضافة scheduler للنسخ الاحتياطي الأسبوعي',
          description: 'ينشئ backup كل يوم أحد الساعة 3 صباحاً',
          overallRisk: CommandRiskLevel.moderate,
          category: 'monitoring',
          commands: [
            '/system scheduler add name=auto-backup interval=7d start-time=03:00:00 on-event="/system backup save name=auto-weekly"',
          ],
        ),
      ));
    }

    return fixes;
  }

  // ============================================================
  //  تحليل البنية التحتية — مستوحى من integration: bridge, vlan, bonding, ipv6, ...
  // ============================================================
  static List<ProposedFix> _analyzeInfrastructure(MikrotikSnapshot snapshot) {
    final fixes = <ProposedFix>[];

    final bridge = snapshot.extraData['INTERFACE BRIDGE'] ?? '';
    final bridgePorts = snapshot.extraData['INTERFACE BRIDGE PORT'] ?? '';
    final vlans = snapshot.extraData['INTERFACE VLAN'] ?? '';
    final packages = snapshot.extraData['SYSTEM PACKAGES'] ?? '';
    final ipv6Addresses = snapshot.extraData['IPV6 ADDRESS'] ?? '';
    final eoip = snapshot.extraData['INTERFACE EOIP'] ?? '';
    final gre = snapshot.extraData['INTERFACE GRE'] ?? '';

    // 1) Bridge بدون vlan-filtering (إن كان يستخدم VLANs)
    if (bridge.isNotEmpty &&
        !bridge.toLowerCase().contains('vlan-filtering=true') &&
        vlans.isNotEmpty &&
        vlans != '(empty)') {
      fixes.add(const ProposedFix(
        id: 'enable-bridge-vlan-filtering',
        title: 'Bridge بدون vlan-filtering بالرغم من وجود VLANs',
        description:
            'عند استخدام VLANs مع bridge، يجب تفعيل vlan-filtering لمنع '
            'تسريب VLAN tags بين المنافذ.',
        impact: 'تسريب VLANs، مشاكل أمنية، عزل شبكي ضعيف.',
        category: FixCategory.infrastructure,
        risk: CommandRiskLevel.moderate,
        script: RouterOsScript(
          title: 'تفعيل vlan-filtering على الـ bridges',
          description: 'يفعّل vlan-filtering على كل الـ bridges',
          overallRisk: CommandRiskLevel.moderate,
          category: 'infrastructure',
          commands: [
            '/interface bridge set [find] vlan-filtering=yes',
          ],
        ),
      ));
    }

    // 2) Bridge port بدون PVID محدد
    if (bridgePorts.isNotEmpty &&
        !bridgePorts.toLowerCase().contains('pvid=') &&
        bridge.toLowerCase().contains('vlan-filtering=true')) {
      fixes.add(const ProposedFix(
        id: 'set-bridge-port-pvid',
        title: 'Bridge ports بدون PVID',
        description: 'عند تفعيل vlan-filtering، كل منفذ يجب أن يكون له PVID '
            '(native VLAN). بدون PVID قد تُرفض الحزم غير المُوسومة.',
        impact: 'فقدان الاتصال للأجهزة غير المُوسومة بـ VLAN.',
        category: FixCategory.infrastructure,
        risk: CommandRiskLevel.moderate,
        script: RouterOsScript(
          title: 'فحص bridge port PVIDs',
          description: 'يجمع بيانات الـ ports لاتخاذ قرار PVID',
          overallRisk: CommandRiskLevel.safe,
          category: 'infrastructure',
          commands: [
            '/interface bridge port print detail',
            '/interface bridge port print where pvid=1',
          ],
        ),
      ));
    }

    // 3) IPv6 مُفعّل بدون عنوان (قد يسبب مشاكل)
    if (ipv6Addresses.isEmpty ||
        ipv6Addresses == '(empty)' &&
            packages.toLowerCase().contains('ipv6') &&
            !packages.toLowerCase().contains('ipv6.*disabled')) {
      fixes.add(const ProposedFix(
        id: 'disable-ipv6-if-unused',
        title: 'IPv6 مُفعّل لكن غير مُستخدم',
        description: 'تفعيل IPv6 بدون إعداد عناوين قد يسبب مشاكل routing غريبة '
            'وقد يكشف الجهاز لهجمات IPv6. عطّله إن لم يكن مطلوباً.',
        impact: 'مشاكل routing غامضة، سطح هجوم إضافي.',
        category: FixCategory.infrastructure,
        risk: CommandRiskLevel.moderate,
        autoApplySafe: true,
        script: RouterOsScript(
          title: 'تعطيل IPv6 package إن لم يُستخدم',
          description: 'يعطّل حزمة IPv6 بالكامل',
          overallRisk: CommandRiskLevel.moderate,
          category: 'infrastructure',
          commands: [
            '/system package disable ipv6',
          ],
        ),
      ));
    }

    // 4) EoIP/GRE tunnels بدون keepalive (zombie tunnels)
    if (eoip.isNotEmpty && !eoip.toLowerCase().contains('keepalive')) {
      fixes.add(const ProposedFix(
        id: 'eoip-keepalive',
        title: 'EoIP tunnels بدون keepalive',
        description:
            'بدون keepalive، تبقى tunnels في حالة "up" حتى لو كان الطرف '
            'الآخر غير متاح، مما يسبب black holes.',
        impact: 'حركة مرور تُرسل لنفق ميت، مشاكل routing.',
        category: FixCategory.infrastructure,
        risk: CommandRiskLevel.moderate,
        script: RouterOsScript(
          title: 'تفعيل keepalive على EoIP tunnels',
          description: 'يضبط keepalive=10s على كل EoIP tunnels',
          overallRisk: CommandRiskLevel.moderate,
          category: 'infrastructure',
          commands: [
            '/interface eoip set [find] keepalive=10s,3',
          ],
        ),
      ));
    }

    if (gre.isNotEmpty && !gre.toLowerCase().contains('keepalive')) {
      fixes.add(const ProposedFix(
        id: 'gre-keepalive',
        title: 'GRE tunnels بدون keepalive',
        description: 'بدون keepalive، تبقى GRE tunnels في حالة "up" حتى لو كان '
            'الطرف الآخر غير متاح.',
        impact: 'black holes routing، حركة مرور مهدرة.',
        category: FixCategory.infrastructure,
        risk: CommandRiskLevel.moderate,
        script: RouterOsScript(
          title: 'تفعيل keepalive على GRE tunnels',
          description: 'يضبط keepalive=10s على كل GRE tunnels',
          overallRisk: CommandRiskLevel.moderate,
          category: 'infrastructure',
          commands: [
            '/interface gre set [find] keepalive=10s,3',
          ],
        ),
      ));
    }

    // 5) حزمة معطّلة من الحزم الأساسية
    if (packages.toLowerCase().contains('disabled=true')) {
      fixes.add(const ProposedFix(
        id: 'review-disabled-packages',
        title: 'بعض حزم RouterOS معطّلة',
        description:
            'وجود حزم معطّلة قد يكون مقصوداً (لتقليل الهجوم) أو غير مقصود. '
            'راجع القائمة لاتخاذ قرار.',
        impact: 'ميزات غير متاحة، مشاكل غير متوقعة.',
        category: FixCategory.infrastructure,
        risk: CommandRiskLevel.safe,
        script: RouterOsScript(
          title: 'عرض الحزم المعطّلة',
          description: 'يجمع قائمة بالحزم المعطّلة للمراجعة',
          overallRisk: CommandRiskLevel.safe,
          category: 'infrastructure',
          commands: [
            '/system package print where disabled=yes',
          ],
        ),
      ));
    }

    return fixes;
  }
}

// ============================================================
//  Plan / Apply Workflow — مستوحى من router diagnostics (plan_changes + apply_plan)
//
//  يضيف طبقة إدارة أعلى فوق AutoFixService:
//  1. planFixes: يأخذ قائمة fixes مقترحة ويولّد plan نصي للعرض
//  2. applyPlan: ينفذ كل الـ fixes دفعة واحدة مع snapshot موحّد
//  3. rollbackPlan: يستعيد snapshot عند فشل أي fix
//
//  الهدف: تنفيذ آمن لعدة إصلاحات كوحدة واحدة قابلة للاستعادة
// ============================================================

/// يمثل خطة إصلاح شاملة — تجمع عدة ProposedFix في وحدة واحدة
@immutable
class FixPlan {
  final String id; // معرّف فريد للخطة
  final String title; // عنوان الخطة
  final DateTime createdAt; // وقت الإنشاء
  final List<ProposedFix> fixes; // قائمة الإصلاحات
  final MikrotikSnapshot snapshot; // الـ snapshot الذي حلّلته الخطة

  const FixPlan({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.fixes,
    required this.snapshot,
  });

  /// عدد الإصلاحات الكلي
  int get length => fixes.length;

  /// عدد الإصلاحات الآمنة للتطبيق التلقائي
  int get autoApplySafeCount => fixes.where((f) => f.autoApplySafe).length;

  /// عدد الإصلاحات الخطرة
  int get dangerousCount =>
      fixes.where((f) => f.risk == CommandRiskLevel.dangerous).length;

  /// إجمالي عدد الأوامر في كل الإصلاحات
  int get totalCommands =>
      fixes.fold(0, (sum, f) => sum + f.script.commands.length);

  /// جميع الأوامر من كل الإصلاحات (مدموجة)
  List<String> get allCommands =>
      fixes.expand((f) => f.script.commands).toList();

  /// تصنيفات الإصلاحات الموجودة (للعرض)
  Set<FixCategory> get categoriesPresent =>
      fixes.map((f) => f.category).toSet();

  /// هل الخطة تحتاج snapshot قبل التنفيذ؟
  bool get needsSnapshot => fixes.any((f) => f.risk != CommandRiskLevel.safe);

  /// نص الخطة للعرض على المستخدم قبل التأكيد
  String get displayPlan {
    final buffer = StringBuffer()
      ..writeln('═══════════════════════════════════════════════════')
      ..writeln('📋 خطة الإصلاح: $title')
      ..writeln('🆔 $id')
      ..writeln('🕐 ${createdAt.toLocal()}')
      ..writeln('═══════════════════════════════════════════════════')
      ..writeln('📊 الإحصائيات:')
      ..writeln('   • عدد الإصلاحات: $length')
      ..writeln('   • أوامر إجمالية: $totalCommands')
      ..writeln('   • آمنة تلقائياً: $autoApplySafeCount')
      ..writeln('   • خطرة: $dangerousCount')
      ..writeln('   • يحتاج snapshot: ${needsSnapshot ? "✅ نعم" : "❌ لا"}')
      ..writeln(
          '   • الفئات: ${categoriesPresent.map((c) => "${c.icon} ${c.displayName}").join(", ")}')
      ..writeln('───────────────────────────────────────────────────')
      ..writeln();

    for (var i = 0; i < fixes.length; i++) {
      final fix = fixes[i];
      final riskIcon = fix.risk == CommandRiskLevel.dangerous
          ? '🚨'
          : fix.risk == CommandRiskLevel.moderate
              ? '⚠️'
              : '✅';
      final autoIcon = fix.autoApplySafe ? '🟢' : '🟡';
      buffer
        ..writeln(
            '${i + 1}. $riskIcon $autoIcon [${fix.category.icon} ${fix.category.displayName}] ${fix.title}')
        ..writeln('   📝 ${fix.description}')
        ..writeln('   💥 الأثر: ${fix.impact}')
        ..writeln('   📦 الأوامر (${fix.script.commands.length}):');
      for (final cmd in fix.script.commands) {
        buffer.writeln('      • $cmd');
      }
      buffer.writeln();
    }

    buffer.writeln('═══════════════════════════════════════════════════');
    if (needsSnapshot) {
      buffer.writeln('💾 سيُنشئ snapshot تلقائياً قبل التنفيذ.');
      buffer.writeln('↩️ في حال الفشل، سيُجهّز rollback script للاستعادة.');
    } else {
      buffer.writeln('✅ الخطة آمنة — أوامر قراءة فقط.');
    }
    buffer.writeln('═══════════════════════════════════════════════════');

    return buffer.toString();
  }
}

/// نتيجة تطبيق خطة إصلاح
@immutable
class PlanApplyResult {
  final FixPlan plan;
  final ChangeSnapshot? snapshot; // snapshot قبل التطبيق (إن وُجد)
  final List<ScriptExecutionResult> fixResults; // نتائج كل fix على حدة
  final RouterOsScript? rollbackScript; // سكربت الاستعادة (إن فشل البعض)
  final PlanApplyStatus status; // الحالة النهائية
  final String? errorMessage;

  const PlanApplyResult({
    required this.plan,
    required this.snapshot,
    required this.fixResults,
    required this.rollbackScript,
    required this.status,
    this.errorMessage,
  });

  /// عدد الإصلاحات الناجحة
  int get successCount => fixResults.where((r) => r.overallSuccess).length;

  /// عدد الإصلاحات الفاشلة
  int get failureCount => fixResults.where((r) => !r.overallSuccess).length;

  /// هل كل الإصلاحات نجحت
  bool get isSuccess => status == PlanApplyStatus.success;

  /// هل يمكن استعادة الحالة (rollback متاح)
  bool get canRollback => rollbackScript != null;
}

/// حالة تطبيق خطة
enum PlanApplyStatus {
  success, // نجحت كل الإصلاحات
  partialSuccess, // بعضها نجح وبعضها فشل
  failedWithRollbackReady, // فشل وsnapshot جاهز
  failedNoSnapshot, // فشل ولا snapshot
  snapshotFailed, // فشل إنشاء snapshot
  dryRunRejected, // رفض المستخدم بعد dry-run
}

extension PlanApplyStatusX on PlanApplyStatus {
  String get displayName {
    switch (this) {
      case PlanApplyStatus.success:
        return 'نجاح كامل';
      case PlanApplyStatus.partialSuccess:
        return 'نجاح جزئي';
      case PlanApplyStatus.failedWithRollbackReady:
        return 'فشل (rollback جاهز)';
      case PlanApplyStatus.failedNoSnapshot:
        return 'فشل (بدون snapshot)';
      case PlanApplyStatus.snapshotFailed:
        return 'فشل snapshot';
      case PlanApplyStatus.dryRunRejected:
        return 'مرفوض بعد dry-run';
    }
  }

  bool get isRecoverable => this == PlanApplyStatus.failedWithRollbackReady;
}

/// خدمة Plan/Apply — تنفّذ خطط إصلاح بأمان
class PlanService {
  PlanService._();

  /// يولّد خطة من قائمة إصلاحات مقترحة
  ///
  /// مثال:
  /// ```dart
  /// final fixes = AutoFixService.analyze(snapshot, mode: DiagnosticMode.security);
  /// final plan = PlanService.createPlan(
  ///   fixes: fixes,
  ///   snapshot: snapshot,
  ///   title: 'إصلاح أمني شامل',
  /// );
  /// print(plan.displayPlan);  // اعرض على المستخدم للتأكيد
  /// ```
  static FixPlan createPlan({
    required List<ProposedFix> fixes,
    required MikrotikSnapshot snapshot,
    required String title,
    String? id,
  }) {
    final planId = id ?? 'plan-${DateTime.now().millisecondsSinceEpoch}';
    return FixPlan(
      id: planId,
      title: title,
      createdAt: DateTime.now(),
      fixes: List.unmodifiable(fixes),
      snapshot: snapshot,
    );
  }

  /// ينفّذ خطة إصلاح بأمان — snapshot + apply all + rollback عند الفشل
  ///
  /// المنهجية:
  /// 1. إن كان needsSnapshot=true، ينشئ snapshot موحّد للخطة كلها
  /// 2. ينفّذ كل fix بالتسلسل مع stopOnError
  /// 3. عند فشل أي fix: يوقف التنفيذ ويُجهّز rollback script
  /// 4. يُرجِع PlanApplyResult شامل
  ///
  /// [onFixStart] يُستدعى قبل كل fix (لتحديث UI)
  /// [onFixComplete] يُستدعى بعد كل fix
  static Future<PlanApplyResult> applyPlan({
    required FixPlan plan,
    MikrotikConnectionMethod method = MikrotikConnectionMethod.routerOS,
    bool requireSnapshot = true,
    Duration perCommandTimeout = const Duration(seconds: 30),
    void Function(int index, int total, ProposedFix fix)? onFixStart,
    void Function(int index, int total, ScriptExecutionResult result)?
        onFixComplete,
  }) async {
    debugPrint('[PlanService] Applying plan ${plan.id} '
        '(${plan.length} fixes, snapshot=${plan.needsSnapshot})');

    // 1. إنشاء snapshot إن لزم
    ChangeSnapshot? snapshot;
    final shouldSnapshot = requireSnapshot && plan.needsSnapshot;
    if (shouldSnapshot) {
      try {
        snapshot = await ScriptExecutor.createSnapshot(
          method: method,
          label: 'plan-${plan.id}',
          correlationId: plan.id,
        );
      } catch (e) {
        return PlanApplyResult(
          plan: plan,
          snapshot: null,
          fixResults: const [],
          rollbackScript: null,
          status: PlanApplyStatus.snapshotFailed,
          errorMessage: 'فشل إنشاء snapshot: $e',
        );
      }
    }

    // 2. تنفيذ كل fix بالتسلسل
    final fixResults = <ScriptExecutionResult>[];
    var anyFailed = false;
    for (var i = 0; i < plan.fixes.length; i++) {
      final fix = plan.fixes[i];
      onFixStart?.call(i, plan.fixes.length, fix);

      final result = await ScriptExecutor.execute(
        script: fix.script,
        method: method,
        stopOnError: true,
        perCommandTimeout: perCommandTimeout,
      );
      fixResults.add(result);
      onFixComplete?.call(i, plan.fixes.length, result);

      if (!result.overallSuccess) {
        anyFailed = true;
        debugPrint('[PlanService] Fix ${i + 1} failed: ${fix.title}');
        break; // أوقف عند أول فشل
      }
    }

    // 3. تحديد الحالة النهائية
    PlanApplyStatus status;
    if (!anyFailed) {
      status = PlanApplyStatus.success;
    } else if (snapshot != null) {
      status = PlanApplyStatus.failedWithRollbackReady;
    } else {
      status = PlanApplyStatus.failedNoSnapshot;
    }

    // 4. تجهيز rollback script إن لزم
    RouterOsScript? rollbackScript;
    if (anyFailed && snapshot != null) {
      rollbackScript = snapshot.toRollbackScript();
    }

    return PlanApplyResult(
      plan: plan,
      snapshot: snapshot,
      fixResults: fixResults,
      rollbackScript: rollbackScript,
      status: status,
      errorMessage:
          anyFailed ? 'فشل تنفيذ خطة ${plan.id} — توقفت عند أول خطأ' : null,
    );
  }

  /// يولّد dry-run report لخطة كاملة (تحليل قبل التطبيق)
  ///
  /// يُرجِع تقرير مفصل لكل fix وكل أمر على حدة
  static String planDryRunReport(FixPlan plan) {
    final buffer = StringBuffer()
      ..writeln('═══════════════════════════════════════════════════')
      ..writeln('🔍 تقرير Dry-Run للخطة: ${plan.title}')
      ..writeln('🆔 ${plan.id}')
      ..writeln('═══════════════════════════════════════════════════')
      ..writeln('📊 الإحصائيات:')
      ..writeln('   • عدد الإصلاحات: ${plan.length}')
      ..writeln('   • أوامر إجمالية: ${plan.totalCommands}')
      ..writeln('   • يحتاج snapshot: ${plan.needsSnapshot ? "✅ نعم" : "❌ لا"}')
      ..writeln('───────────────────────────────────────────────────');

    for (var i = 0; i < plan.fixes.length; i++) {
      final fix = plan.fixes[i];
      final fixDryRun = ScriptExecutor.dryRun(fix.script);
      buffer
        ..writeln()
        ..writeln(
            '${i + 1}. 📦 [${fix.category.icon} ${fix.category.displayName}] ${fix.title}')
        ..writeln('   • أوامر: ${fix.script.commands.length}')
        ..writeln('   • خطرة: ${fixDryRun.dangerousCount}')
        ..writeln('   • غير idempotent: ${fixDryRun.nonIdempotentCount}')
        ..writeln(
            '   • يحتاج snapshot: ${fixDryRun.needsSnapshot ? "نعم" : "لا"}');

      // عرض تفاصيل كل أمر
      for (final cmd in fixDryRun.commandAnalysis) {
        final riskIcon = cmd.risk == CommandRiskLevel.dangerous
            ? '🚨'
            : cmd.risk == CommandRiskLevel.moderate
                ? '⚠️'
                : '✅';
        final idemIcon = cmd.isIdempotent ? '🔁' : '⚠️';
        buffer.writeln('      $riskIcon $idemIcon ${cmd.command}');
        if (cmd.validationError != null) {
          buffer.writeln('         ❌ خطأ: ${cmd.validationError}');
        }
      }
    }

    buffer
      ..writeln()
      ..writeln('═══════════════════════════════════════════════════');
    if (plan.needsSnapshot) {
      buffer.writeln('💾 قبل التنفيذ: سيُنشئ snapshot تلقائياً.');
      buffer.writeln('↩️ في حال الفشل: rollback script جاهز للاستعادة.');
    } else {
      buffer.writeln('✅ الخطة آمنة بالكامل — أوامر قراءة فقط.');
    }
    buffer.writeln('═══════════════════════════════════════════════════');

    return buffer.toString();
  }
}
