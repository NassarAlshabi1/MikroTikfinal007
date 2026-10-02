/// منطق تشخيص كيبل الإيثرنت — نقي بلا أي اتصال شبكة (قابل للاختبار مباشرة).
///
/// يعتمد على أمرَي RouterOS:
/// - `/interface/ethernet/cable-test` ⇒ حالة أزواج الكيبل (سليم/مقطوع/قصر).
/// - `/interface/ethernet/monitor once` ⇒ السرعة الفعلية وduplex وحالة الرابط.
///
/// ملاحظات توافق مهمة (v6 و v7):
/// - `cable-test` لا يعمل إلا على منافذ إيثرنت نحاسية في أجهزة RouterBOARD مدعومة،
///   ولا يعمل على SFP ولا على CHR/x86 (تُرجع رسالة "not supported").
/// - بعض إصدارات v7 لا تدعم الأمر إطلاقًا ⇒ تُعرض رسالة عربية واضحة بدل خطأ خام.
library;

/// حالة زوج واحد من أزواج الكيبل الأربعة.
enum CablePairStatus { ok, open, short, cross, unknown }

/// نتيجة زوج واحد.
class CablePairResult {
  /// رقم الزوج (1..4).
  final int index;

  final CablePairStatus status;

  /// النص الخام كما رجعه الراوتر (ok / open / short ...).
  final String rawStatus;

  const CablePairResult({
    required this.index,
    required this.status,
    required this.rawStatus,
  });

  bool get isOk => status == CablePairStatus.ok;

  /// التسمية العربية للحالة.
  String get label {
    switch (status) {
      case CablePairStatus.ok:
        return "سليم";
      case CablePairStatus.open:
        return "مقطوع";
      case CablePairStatus.short:
        return "قصر";
      case CablePairStatus.cross:
        return "معكوس";
      case CablePairStatus.unknown:
        return "غير معروف";
    }
  }

  /// شرح مختصر يظهر للمستخدم.
  String get description {
    switch (status) {
      case CablePairStatus.ok:
        return "الإشارة تصل بشكل صحيح";
      case CablePairStatus.open:
        return "لا توجد استمرارية — سلك مقطوع أو طرف غير مضغوط";
      case CablePairStatus.short:
        return "سلكان متلامسان — غالبًا طرف RJ45 مخرب";
      case CablePairStatus.cross:
        return "ترتيب الأسلاك معكوس — تأكد من ترتيب T568A/B في الطرفين";
      case CablePairStatus.unknown:
        return "لم يُرجِع الراوتر حالة مفهومة لهذا الزوج";
    }
  }

  /// تحويل نص الراوتر إلى حالة معروفة بأمان.
  static CablePairStatus parseStatus(String? raw) {
    final text = (raw ?? "").trim().toLowerCase().replaceAll('"', '');
    if (text.isEmpty) return CablePairStatus.unknown;
    if (text.contains('ok') || text.contains('good') || text.contains('normal')) {
      return CablePairStatus.ok;
    }
    if (text.contains('short')) return CablePairStatus.short;
    if (text.contains('cross') || text.contains('reverse') || text.contains('swap')) {
      return CablePairStatus.cross;
    }
    if (text.contains('open') || text.contains('break') || text.contains('cut')) {
      return CablePairStatus.open;
    }
    return CablePairStatus.unknown;
  }
}

/// درجة خطورة نتيجة التشخيص (تحدد لون الواجهة).
enum CableSeverity { ok, warning, fault, unknown }

/// نتيجة فحص الكيبل لمنفذ واحد.
class CableTestResult {
  final String interfaceName;

  /// الحالة العامة كما رجعها الراوتر (link-ok / no-link / open / short ...).
  final String status;

  final List<CablePairResult> pairs;

  /// النص الخام لأزواج الكيبل (مثال: `ok-ok-open-ok`).
  final String rawPairs;

  /// هل الراوتر يدعم فحص الكيبل؟ (false = CHR/x86 أو منفذ SFP أو v7 بلا دعم)
  final bool supported;

  /// رسالة توضيحية عند عدم الدعم أو فشل الفحص.
  final String errorMessage;

  const CableTestResult({
    required this.interfaceName,
    required this.status,
    required this.pairs,
    required this.rawPairs,
    this.supported = true,
    this.errorMessage = "",
  });

  /// حالة عدم الدعم/الفشل برسالة عربية واضحة.
  factory CableTestResult.unsupported(String interfaceName, String message) {
    return CableTestResult(
      interfaceName: interfaceName,
      status: "",
      pairs: const [],
      rawPairs: "",
      supported: false,
      errorMessage: message.isEmpty ? "فحص الكيبل غير مدعوم على هذا المنفذ أو هذا الراوتر" : message,
    );
  }

  /// أزواج بها عطل مؤكَّد (مقطوع/قصر/معكوس).
  bool get hasFaultPairs => pairs.any((pair) =>
      pair.status == CablePairStatus.open ||
      pair.status == CablePairStatus.short ||
      pair.status == CablePairStatus.cross);

  /// أزواج لم تُفهم حالتها (لا تُعدّ عطلًا ولا سلامة).
  bool get hasUnknownPairs => pairs.any((pair) => pair.status == CablePairStatus.unknown);

  /// أزواج معطوبة أو مجهولة (انتباه للمستخدم).
  List<CablePairResult> get faultyPairs =>
      pairs.where((pair) => !pair.isOk).toList();

  /// هل الرابط قائم حسب الراوتر؟
  bool get linkOk => status.toLowerCase().contains('link-ok');

  /// الحالة العامة بالعربية.
  String get statusLabel {
    if (!supported) return "غير مدعوم على هذا المنفذ";
    final text = status.toLowerCase();
    if (text.contains('link-ok')) return "الكيبل سليم والاتصال قائم";
    if (text.contains('no-link')) return "لا يوجد اتصال (لا جهاز في الطرف الآخر أو الكيبل غير موصول)";
    if (text.contains('short')) return "يوجد قصر (تلامس) في أسلاك الكيبل";
    if (text.contains('open') || text.contains('break')) return "يوجد قطع في أحد أسلاك الكيبل";
    if (hasFaultPairs) return "يوجد عطل في أحد أزواج الكيبل";
    if (status.trim().isEmpty && pairs.isEmpty) return "لم يُرجع الراوتر أي نتيجة";
    return "حالة غير معروفة ($status)";
  }

  CableSeverity get severity {
    if (!supported) return CableSeverity.unknown;

    // عطل مؤكَّد: من الأزواج أو من الحالة العامة
    final text = status.toLowerCase();
    if (hasFaultPairs) return CableSeverity.fault;
    if (text.contains('short') || text.contains('open') || text.contains('break')) {
      return CableSeverity.fault;
    }

    // رابط غير قائم مع أزواج سليمة ⇒ تحذير (لا عطل في الكيبل)
    if (text.contains('no-link')) return CableSeverity.warning;

    // سليم: كل الأزواج سليمة (وحالة الرابط قائمة أو غير مذكورة)
    if (pairs.isNotEmpty && pairs.every((pair) => pair.isOk)) return CableSeverity.ok;
    if (text.contains('link-ok') && !hasUnknownPairs) return CableSeverity.ok;

    // لا نخمّن: أي شيء غير مفهوم يبقى «غير محدد»
    return CableSeverity.unknown;
  }

  /// جملة ملخّص قصيرة للواجهة.
  String get summary {
    if (!supported) return errorMessage;
    if (pairs.isEmpty) return statusLabel;

    final faulty = pairs.where((pair) => !pair.isOk).map((pair) => pair.index).toList();
    if (faulty.isEmpty) {
      final count = pairs.length;
      return "${count == 4 ? "الأزواج الأربعة" : "الأزواج ($count)"} سليمة — ${statusLabel}";
    }
    if (hasFaultPairs) {
      return "الأزواج المتأثرة: ${faulty.join('، ')} — ${statusLabel}";
    }
    return "تعذّر تحديد حالة الأزواج: ${faulty.join('، ')} — ${statusLabel}";
  }

  /// تحليل نتيجة الراوتر الخام إلى نموذج واضح.
  ///
  /// يدعم شكلين للحمولة:
  /// 1. صف واحد فيه `cable-pairs` نصًّا (الشكل الشائع في v6).
  /// 2. عدة صفوف كل صف لزوج (`pair` + `status`).
  static CableTestResult parse({
    required String interfaceName,
    required List rows,
  }) {
    final maps = rows
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
        .toList();

    if (maps.isEmpty) {
      return CableTestResult.unsupported(
        interfaceName,
        "لم يُرجع الراوتر أي نتيجة — تأكد أن المنفذ إيثرنت نحاسي (cable-test لا يعمل على SFP)",
      );
    }

    // اختيار الصفوف الخاصة بالمنفذ المطلوب (وإلا نستخدم كل ما رجع)
    final named = maps
        .where((row) => (row["name"] ?? row["interface"] ?? "") == interfaceName)
        .toList();
    final pool = named.isNotEmpty ? named : maps;

    final status = _firstNonEmpty(pool, "status");
    final rawPairs = _firstNonEmpty(pool, "cable-pairs");

    var pairs = <CablePairResult>[];
    if (rawPairs.isNotEmpty) pairs = parsePairsString(rawPairs);
    if (pairs.isEmpty) pairs = _parsePairsFromRows(pool);

    // استنتاج الحالة العامة إن لم تُذكر صراحةً.
    var effectiveStatus = status;
    if (effectiveStatus.isEmpty && pairs.isNotEmpty) {
      effectiveStatus = pairs.every((pair) => pair.isOk) ? "link-ok" : "fault";
    }

    if (effectiveStatus.isEmpty && pairs.isEmpty) {
      return CableTestResult.unsupported(
        interfaceName,
        "لم تُفهم نتيجة الراوتر — قد لا يدعم هذا الجهاز فحص الكيبل",
      );
    }

    return CableTestResult(
      interfaceName: interfaceName,
      status: effectiveStatus,
      pairs: pairs,
      rawPairs: rawPairs.isNotEmpty ? rawPairs : pairs.map((p) => p.rawStatus).join("-"),
    );
  }

  /// تحويل نص الأزواج مثل `ok-ok-open-short` أو `[ok; ok; ok; ok]` إلى قائمة.
  static List<CablePairResult> parsePairsString(String raw) {
    final cleaned = raw
        .replaceAll('[', ' ')
        .replaceAll(']', ' ')
        .replaceAll('"', ' ')
        .replaceAll("'", ' ')
        .replaceAll(',', ' ')
        .replaceAll(';', ' ')
        .replaceAll(':', ' ')
        .trim();

    final tokens = cleaned
        .split(RegExp(r'[\s\-_]+'))
        .where((token) => token.trim().isNotEmpty)
        .toList();

    final result = <CablePairResult>[];
    for (var i = 0; i < tokens.length && result.length < 4; i++) {
      final token = tokens[i].trim();
      // تجاهل النصوص الوصفية غير حالات الأزواج
      if (RegExp(r'^\d+$').hasMatch(token)) continue;
      result.add(CablePairResult(
        index: result.length + 1,
        status: CablePairResult.parseStatus(token),
        rawStatus: token,
      ));
    }
    return result;
  }

  static List<CablePairResult> _parsePairsFromRows(List<Map<String, String>> rows) {
    final result = <CablePairResult>[];

    final pairRows = rows.where((row) {
      return row.keys.any((key) => key.contains('pair')) &&
          (row["status"] ?? "").isNotEmpty;
    }).toList();

    if (pairRows.isNotEmpty) {
      for (final row in pairRows) {
        final raw = row["status"] ?? "";
        result.add(CablePairResult(
          index: result.length + 1,
          status: CablePairResult.parseStatus(raw),
          rawStatus: raw,
        ));
      }
      return result;
    }

    // حقول مستقلة مثل pair2=ok
    final inline = <int, String>{};
    for (final row in rows) {
      for (final entry in row.entries) {
        final match = RegExp(r'pair[^0-9]*(\d)').firstMatch(entry.key.toLowerCase());
        if (match == null || entry.value.trim().isEmpty) continue;
        final index = int.tryParse(match.group(1) ?? "");
        if (index != null && index >= 1 && index <= 4) inline[index] = entry.value;
      }
    }
    if (inline.isEmpty) return result;

    for (var i = 1; i <= 4; i++) {
      final raw = inline[i] ?? "";
      result.add(CablePairResult(
        index: i,
        status: CablePairResult.parseStatus(raw),
        rawStatus: raw,
      ));
    }
    return result;
  }

  static String _firstNonEmpty(List<Map<String, String>> rows, String key) {
    for (final row in rows) {
      final value = row[key];
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return "";
  }
}

/// معلومات الاتصال الفعلية من `/interface/ethernet/monitor once`.
class EthernetLinkInfo {
  final String interfaceName;
  final String status;
  final String rawRate;

  /// السرعة الفعلية بالميغابت (1000 = جيجابت).
  final int? rateMbps;

  final bool? fullDuplex;
  final bool? autoNegotiation;
  final String comment;

  const EthernetLinkInfo({
    required this.interfaceName,
    required this.status,
    required this.rawRate,
    required this.rateMbps,
    required this.fullDuplex,
    required this.autoNegotiation,
    this.comment = "",
  });

  bool get hasLink => status.toLowerCase().contains('link-ok');

  bool get isGigabit => (rateMbps ?? 0) >= 1000;

  /// سرعة مخفّضة: الرابط قائم لكن أقل من جيجابت
  /// (دليل قوي على أن أحد أزواج الكيبل لا يعمل).
  bool get isDegraded => hasLink && rateMbps != null && rateMbps! < 1000;

  String get rateLabel {
    final rate = rateMbps;
    if (rate == null) return rawRate.isEmpty ? "غير معروف" : rawRate;
    if (rate >= 1000) {
      final gbps = rate / 1000;
      return gbps == gbps.roundToDouble()
          ? "${gbps.round()} Gbps"
          : "${gbps.toStringAsFixed(1)} Gbps";
    }
    return "$rate Mbps";
  }

  String get duplexLabel {
    if (fullDuplex == null) return "غير معروف";
    return fullDuplex! ? "كامل (Full Duplex)" : "نصف (Half Duplex)";
  }

  /// تحويل قيمة السرعة من RouterOS: `1Gbps`, `100Mbps`, `10Mbps`, `2.5Gbps`, أو رقم بالبت.
  static int? parseRateMbps(String? raw) {
    final text = (raw ?? "").trim().toLowerCase().replaceAll('"', '');
    if (text.isEmpty) return null;

    // رقم صريح: إما ميغابت أو بت/ثانية
    final plain = int.tryParse(text);
    if (plain != null) {
      if (plain >= 1000000) return (plain / 1000000).round();
      return plain;
    }

    final match = RegExp(r'([\d.]+)\s*([kmg])?').firstMatch(text);
    if (match == null) return null;
    final value = double.tryParse(match.group(1) ?? "");
    if (value == null) return null;

    switch ((match.group(2) ?? "").toLowerCase()) {
      case 'g':
        return (value * 1000).round();
      case 'm':
        return value.round();
      case 'k':
        return (value / 1000).round();
      default:
        return value.round();
    }
  }

  static bool? _parseBool(String? raw) {
    final text = (raw ?? "").trim().toLowerCase();
    if (text.isEmpty) return null;
    if (text == "true" || text == "yes" || text == "1") return true;
    if (text == "false" || text == "no" || text == "0") return false;
    return null;
  }

  static EthernetLinkInfo parse({required String interfaceName, required List rows}) {
    final maps = rows
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
        .toList();

    if (maps.isEmpty) {
      return EthernetLinkInfo(
        interfaceName: interfaceName,
        status: "",
        rawRate: "",
        rateMbps: null,
        fullDuplex: null,
        autoNegotiation: null,
      );
    }

    String pick(String key) {
      for (final row in maps) {
        final value = row[key];
        if (value != null && value.trim().isNotEmpty) return value.trim();
      }
      return "";
    }

    final rawRate = pick("rate");
    return EthernetLinkInfo(
      interfaceName: pick("name").isNotEmpty ? pick("name") : interfaceName,
      status: pick("status"),
      rawRate: rawRate,
      rateMbps: parseRateMbps(rawRate),
      fullDuplex: _parseBool(pick("full-duplex")),
      autoNegotiation: _parseBool(pick("auto-negotiation")),
      comment: pick("comment"),
    );
  }
}

/// تشخيص مجمّع يجمع نتيجة الكيبل مع معلومات الاتصال ويصوغ التوصيات.
class CableDiagnosis {
  final CableSeverity severity;
  final String headline;
  final String details;
  final List<String> recommendations;

  const CableDiagnosis({
    required this.severity,
    required this.headline,
    required this.details,
    required this.recommendations,
  });
}

class CableDiagnostics {
  /// أوامر فحص الكيبل المطلوبة تجربتها بالترتيب (تختلف صيغتها بين الإصدارات).
  static List<List<String>> cableTestCommandCandidates(String interfaceName) {
    return [
      ["/interface/ethernet/cable-test", "=interface=$interfaceName", "=duration=5"],
      ["/interface/ethernet/cable-test", "=interface=$interfaceName"],
      ["/interface/ethernet/cable-test", "=numbers=$interfaceName"],
    ];
  }

  /// أمر قراءة معلومات الاتصال (السرعة/duplex).
  static List<List<String>> monitorCommandCandidates(String interfaceName) {
    return [
      ["/interface/ethernet/monitor", "=interface=$interfaceName", "=once="],
      ["/interface/ethernet/monitor", "=numbers=$interfaceName", "=once="],
    ];
  }

  /// تحويل رسالة خطأ الراوتر إلى رسالة عربية واضحة.
  static String friendlyError(String rawError) {
    final text = rawError.toLowerCase();
    if (text.contains('not supported') || text.contains('unsupported')) {
      return "هذا المنفذ أو الجهاز لا يدعم فحص الكيبل (يعمل فقط على منافذ إيثرنت نحاسية في أجهزة RouterBOARD مدعومة، ولا يعمل على SFP ولا CHR/x86).";
    }
    if (text.contains('no such command') ||
        text.contains('unknown command') ||
        text.contains('bad command') ||
        text.contains('syntax error') ||
        text.contains('no such argument')) {
      return "إصدار RouterOS هذا لا يوفّر أمر فحص الكيبل.";
    }
    if (text.contains('sfp')) {
      return "منافذ SFP لا تدعم فحص الكيبل (الفحص للنحاس فقط).";
    }
    if (text.contains('timeout') || text.contains('timed out')) {
      return "انتهت مدة الفحص — أعد المحاولة بعد لحظات.";
    }
    return rawError.isEmpty ? "تعذّر تنفيذ الفحص" : rawError;
  }

  /// الجمع بين نتيجتَي الفحص وصياغة تشخيص + توصيات.
  static CableDiagnosis combine({
    CableTestResult? cable,
    EthernetLinkInfo? link,
  }) {
    // (1) غير مدعوم
    if (cable != null && !cable.supported) {
      return CableDiagnosis(
        severity: CableSeverity.unknown,
        headline: "تعذّر فحص الكيبل",
        details: cable.errorMessage,
        recommendations: const [
          "جرّب منفذًا آخر من منافذ الإيثرنت النحاسية.",
          "إن كان المنفذ SFP فيلزم فحص الكيبل بأداة فيزيائية.",
          "يمكن استخدام قراءة السرعة للمقارنة: سرعة مخفّضة (100Mbps بدل 1Gbps) تعني عطلًا في أحد الأزواج.",
        ],
      );
    }

    final faulty = cable?.pairs
            .where((pair) => pair.status == CablePairStatus.open ||
                pair.status == CablePairStatus.short ||
                pair.status == CablePairStatus.cross)
            .toList() ??
        const <CablePairResult>[];
    final unknownPairs = cable?.pairs
            .where((pair) => pair.status == CablePairStatus.unknown)
            .toList() ??
        const <CablePairResult>[];
    final degraded = link?.isDegraded ?? false;

    // (2) أعطال في الأزواج
    if (faulty.isNotEmpty) {
      final parts = faulty
          .map((pair) => "الزوج ${pair.index}: ${pair.label} (${pair.description})")
          .join('\n');
      return CableDiagnosis(
        severity: CableSeverity.fault,
        headline: "يوجد عطل في الكيبل — ${faulty.length} من أزواج الكيبل متأثرة",
        details: parts,
        recommendations: [
          "افحص طرفي RJ45: ترتيب الأسلاك (T568B) وأن الكرنش ضغط الأطراف للنهاية.",
          "أعد ضغط الأطراف أو غيّر الكيبل، فالكيبل المقطوع/المقصوف لا يُصلح بالبرمجة.",
          if (degraded) "الرابط هبط إلى ${link!.rateLabel} بدل 1Gbps — وهذا متوقع مع وجود عطل في الأزواج.",
          "بعد الإصلاح أعد الفحص وتأكد أن السرعة عادت إلى 1Gbps.",
        ],
      );
    }

    // (2.5) أزواج لم تُفهم حالتها ← لا نحكم بعطل ولا بسلامة
    if (unknownPairs.isNotEmpty && !degraded) {
      return CableDiagnosis(
        severity: CableSeverity.unknown,
        headline: "تعذّر تفسير حالة بعض أزواج الكيبل",
        details: "الأزواج ${unknownPairs.map((pair) => pair.index).join('، ')} "
            "أرجعت قيمًا غير معروفة (${unknownPairs.map((pair) => pair.rawStatus).join('، ')})، "
            "ولذلك لا يمكن تأكيد سلامة الكيبل ولا وجود عطل.\n"
            "أعِد الفحص، وإن تكرّرت النتيجة فافحص الكيبل بأداة فيزيائية.",
        recommendations: const [
          "أعِد تنفيذ الفحص (قد تكون القراءة الأولى غير مكتملة).",
          "راجع سرعة الاتصال: إن كانت 100Mbps بدل 1Gbps فهناك عطل في أحد الأزواج فعلًا.",
          "افحص طرفي RJ45 وأعد ضغطهما إن استمرت القيم غير المفهومة.",
        ],
      );
    }

    // (3) الرابط سليم لكن السرعة مخفّضة (دليل على عطل جزئي)
    if (degraded) {
      return CableDiagnosis(
        severity: CableSeverity.warning,
        headline: "الكيبل يعمل لكن بسرعة مخفّضة (${link!.rateLabel} بدل 1Gbps)",
        details: "غالبًا زوج أو أكثر لا يعمل والراوتر هبط للسرعة الأدنى، "
            "أو أن الكيبل غير مصنّف CAT5e/CAT6، أو الطرف الآخر (سويتش/جهاز) لا يدعم الجيجابت.",
        recommendations: const [
          "تأكد أن الكيبل من فئة CAT5e أو أعلى وأن الطول أقل من 100 متر.",
          "أعد ضغط أطراف RJ45 في الطرفين بترتيب T568B.",
          "جرّب كيبلًا آخر معروفًا أنه سليم: إن عادت السرعة إلى 1Gbps فالمشكلة في الكيبل.",
          "تحقق أن المنفذ في الطرف الآخر (سويتش/راوتر) يدعم الجيجابت وأن auto-negotiation مفعّل.",
        ],
      );
    }

    // (4) لا يوجد رابط
    if (cable != null && cable.status.toLowerCase().contains('no-link')) {
      return CableDiagnosis(
        severity: CableSeverity.warning,
        headline: "لا يوجد اتصال على هذا المنفذ",
        details: "الأزواج سليمة إن رجعت النتائج، لكن لا يوجد جهاز أو سويتش في الطرف الآخر، "
            "أو أن الطرف الآخر مغلق، أو الكيبل غير موصول.",
        recommendations: const [
          "تأكد أن الكيبل موصول بجهاز يعمل (سويتش/كمبيوتر) وأن مؤشر المنفذ مضيء.",
          "جرّب منفذًا آخر في الراوتر أو الكيبل نفسه في جهاز آخر.",
          "إن كان الطرف الآخر جهازًا يحتاج PoE فتأكد من تفعيله أو استخدام مُغذٍّ خارجي.",
        ],
      );
    }

    // (5) كل شيء سليم
    if (cable != null && cable.severity == CableSeverity.ok) {
      return CableDiagnosis(
        severity: CableSeverity.ok,
        headline: link != null && link.hasLink
            ? "الكيبل سليم — الاتصال قائم بسرعة ${link.rateLabel}"
            : "الكيبل سليم — الأزواج الأربعة تعمل",
        details: "جميع أزواج الكيبل الأربعة سليمة وترتيبها صحيح"
            "${link != null && link.fullDuplex == true ? " وduplex كامل" : ""}.",
        recommendations: const [
          "لا حاجة لأي إجراء — الكيبل بحالة جيدة.",
          "للمتابعة الدورية: أعد الفحص إذا لاحظت بطئًا أو انقطاعات متكررة.",
        ],
      );
    }

    // (6) نتيجة غير مكتملة
    return CableDiagnosis(
      severity: CableSeverity.unknown,
      headline: "نتيجة غير مكتملة",
      details: cable == null
          ? "لم يُنفَّذ فحص الكيبل بعد — اضغط «فحص الكيبل» للحصول على تحليل الأزواج."
          : cable.statusLabel,
      recommendations: const [
        "نفّذ فحص الكيبل ثم اقرأ سرعة الاتصال للحصول على تشخيص كامل.",
      ],
    );
  }
}

/// تسمية عربية لدرجة الخطورة (تظهر في شارات الواجهة).
extension CableSeverityLabel on CableSeverity {
  String get severityLabel {
    switch (this) {
      case CableSeverity.ok:
        return "سليم";
      case CableSeverity.warning:
        return "تحذير";
      case CableSeverity.fault:
        return "عطل";
      case CableSeverity.unknown:
        return "غير محدد";
    }
  }
}
