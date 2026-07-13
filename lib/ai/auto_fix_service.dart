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
  security,     // إصلاحات أمنية
  performance,  // تحسينات أداء
  qos,         // إعدادات QoS
  routing,     // مشاكل توجيه
  vpn,         // إعدادات VPN
  wifi,        // إعدادات Wireless
  hotspot,     // إعدادات Hotspot
  safety,      // نسخ احتياطي/استعادة
}

extension FixCategoryExtension on FixCategory {
  String get displayName {
    switch (this) {
      case FixCategory.security:    return '🛡️ أمن';
      case FixCategory.performance: return '⚡ أداء';
      case FixCategory.qos:         return '📊 QoS';
      case FixCategory.routing:     return '🗺️ توجيه';
      case FixCategory.vpn:         return '🔐 VPN';
      case FixCategory.wifi:        return '📶 Wireless';
      case FixCategory.hotspot:     return '📡 Hotspot';
      case FixCategory.safety:      return '💾 أمان البيانات';
    }
  }

  String get icon {
    switch (this) {
      case FixCategory.security:    return '🛡️';
      case FixCategory.performance: return '⚡';
      case FixCategory.qos:         return '📊';
      case FixCategory.routing:     return '🗺️';
      case FixCategory.vpn:         return '🔐';
      case FixCategory.wifi:        return '📶';
      case FixCategory.hotspot:     return '📡';
      case FixCategory.safety:      return '💾';
    }
  }
}

/// إصلاح مقترح
@immutable
class ProposedFix {
  final String id;            // معرّف فريد
  final String title;         // عنوان مختصر
  final String description;   // وصف المشكلة
  final String impact;        // الأثر المتوقع
  final FixCategory category; // التصنيف
  final CommandRiskLevel risk; // مستوى الخطورة
  final RouterOsScript script; // السكربت الذي يصلح المشكلة
  final bool autoApplySafe;   // هل يمكن تطبيقه تلقائياً (آمن جداً)؟

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
  static List<ProposedFix> analyze(MikrotikSnapshot snapshot, {DiagnosticMode? mode}) {
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
      fixes.add(ProposedFix(
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
          commands: const [
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
      if (!natData.toLowerCase().contains('masquerade') &&
          natData.isNotEmpty) {
        fixes.add(ProposedFix(
          id: 'missing-nat-masquerade',
          title: 'NAT masquerade مفقود',
          description: 'لا توجد قاعدة masquerade في الـ NAT. '
              'لن يستطيع المستخدمون خلف الجهاز الوصول للإنترنت.',
          impact: 'مستخدمو LAN لا يستطيعون الوصول للإنترنت.',
          category: FixCategory.routing,
          risk: CommandRiskLevel.moderate,
          script: RouterOsScript(
            title: 'إضافة NAT masquerade',
            description: 'يضيف masquerade على WAN interface. عدّل ether1 اسم الـ WAN.',
            overallRisk: CommandRiskLevel.moderate,
            category: 'routing',
            commands: const [
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
        fixes.add(ProposedFix(
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
            commands: const [
              '/ip service disable telnet',
            ],
          ),
        ));
      }
    }

    // 2) FTP مُفعّل
    if (services.toLowerCase().contains('ftp') &&
        RegExp(r'ftp\b', caseSensitive: false).hasMatch(services)) {
      fixes.add(ProposedFix(
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
          commands: const [
            '/ip service disable ftp',
          ],
        ),
      ));
    }

    // 3) API بدون HTTPS (8728)
    if (services.contains('8728') &&
        !services.contains('8729')) {
      fixes.add(ProposedFix(
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
          commands: const [
            '/ip service disable api',
            '/ip service enable api-ssl',
          ],
        ),
      ));
    }

    // 4) UPnP مُفعّل
    if (upnp.toLowerCase().contains('enabled=true') ||
        upnp.toLowerCase().contains('yes')) {
      fixes.add(ProposedFix(
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
          commands: const [
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
      fixes.add(ProposedFix(
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
          commands: const [
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
      fixes.add(ProposedFix(
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
          commands: const [
            '/queue type add name="pcq-upload" kind=pcq pcq-rate=5M pcq-classifier=src-address',
            '/queue type add name="pcq-download" kind=pcq pcq-rate=20M pcq-classifier=dst-address',
          ],
        ),
      ));
    }

    // 3) queue simple بدون queue type محدد (default)
    if (queueSimple.toLowerCase().contains('queue=default') ||
        queueSimple.toLowerCase().contains('queue=default-small')) {
      fixes.add(ProposedFix(
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
          commands: const [
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
      fixes.add(ProposedFix(
        id: 'enable-fasttrack',
        title: 'Fasttrack غير مُفعّل — throughput أقل',
        description: 'Fasttrack (RouterOS v6.29+) يتيح تجاوز firewall للاتصالات '
            'المُنشأة، مما يضاعف throughput بـ 2-3x.',
        impact: 'throughput أقل بـ 50-70% من الإمكانيات.',
        category: FixCategory.performance,
        risk: CommandRiskLevel.moderate,
        script: RouterOsScript(
          title: 'تفعيل Fasttrack',
          description: 'يضيف قاعدتي fasttrack + accept للاتصالات المُنشأة',
          overallRisk: CommandRiskLevel.moderate,
          category: 'performance',
          commands: const [
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
            script: RouterOsScript(
              title: 'فحص أسباب CPU العالي',
              description: 'يجمع بيانات تشخيصية للأداء',
              overallRisk: CommandRiskLevel.safe,
              category: 'performance',
              commands: const [
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
}
