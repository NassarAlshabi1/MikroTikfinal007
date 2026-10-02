import 'dart:convert';
import 'dart:math';

import 'mikrotik_duration.dart';

/// منطق إدارة **Hotspot** في RouterOS — نقي بلا أي اتصال شبكة (قابل للاختبار).
///
/// المسارات المدعومة (نفسها في v6 و v7 لأن Hotspot حزمة مستقرة الأوامر):
/// - المستخدمون: `/ip/hotspot/user`  (name, password, profile, limit-uptime, limit-bytes-total, ...)
/// - الجلسات النشطة: `/ip/hotspot/active`
/// - الباقات: `/ip/hotspot/user/profile`
/// - الخوادم: `/ip/hotspot`
/// - صفحة الدخول: ملفات في مجلد الراوتر (افتراضيًا `hotspot/`) تُرفع عبر FTP.

/// ============================ المستخدم ============================

class HotspotUser {
  final String id;
  final String name;
  final String password;
  final String profile;
  final String server;
  final String macAddress;
  final String comment;
  final bool disabled;

  /// الحدود الخام كما رجعها الراوتر (نُحلّلها بأمان).
  final String rawLimitUptime;
  final String rawLimitBytes;
  final String rawUptimeUsed;

  /// المدة المحددة للكرت (من limit-uptime) — null إن لم تُذكر أو لم تُفهم.
  final Duration? limitUptime;

  /// المدة المستهلكة فعليًا.
  final Duration usedUptime;

  /// حد البيانات الكلي بالبايت (limit-bytes-total) — null إن لم يُحدَّد.
  final int? limitBytes;

  final int bytesIn;
  final int bytesOut;

  const HotspotUser({
    required this.id,
    required this.name,
    required this.password,
    required this.profile,
    required this.server,
    required this.macAddress,
    required this.comment,
    required this.disabled,
    required this.rawLimitUptime,
    required this.rawLimitBytes,
    required this.rawUptimeUsed,
    required this.limitUptime,
    required this.usedUptime,
    required this.limitBytes,
    required this.bytesIn,
    required this.bytesOut,
  });

  int get usedBytes => bytesIn + bytesOut;

  bool get hasUptimeLimit => limitUptime != null && limitUptime! > Duration.zero;

  bool get hasBytesLimit => limitBytes != null && limitBytes! > 0;

  /// هل استهلك مدته كاملة؟
  bool get isUptimeExhausted =>
      hasUptimeLimit && usedUptime >= limitUptime!;

  /// هل استهلك بياناته كاملة؟
  bool get isBytesExhausted => hasBytesLimit && usedBytes >= limitBytes!;

  /// هل الكرت منتهٍ بأي من المعيارين؟ (لا يُحذف تلقائيًا — عرض فقط)
  bool get isExhausted => isUptimeExhausted || isBytesExhausted;

  /// نسبة استهلاك المدة (0..100+).
  int get uptimePercent {
    if (!hasUptimeLimit) return 0;
    return UptimeUsage(used: usedUptime, limit: limitUptime!).percent;
  }

  /// نسبة استهلاك البيانات (0..100+).
  int get bytesPercent {
    if (!hasBytesLimit) return 0;
    final percent = (usedBytes * 100 / limitBytes!).round();
    return percent < 0 ? 0 : percent;
  }

  /// المدة المتبقية (null إن لا حد).
  Duration? get remainingUptime {
    if (!hasUptimeLimit) return null;
    final remaining = limitUptime! - usedUptime;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// كرت يقارب على الانتهاء (افتراضيًا: بقي 20% أو أقل من المدة).
  bool isNearExpiry({int thresholdPercent = 20}) {
    if (!hasUptimeLimit || isUptimeExhausted) return false;
    return uptimePercent >= (100 - thresholdPercent);
  }

  String get usedLabel => MikrotikDuration.format(usedUptime);

  String get limitLabel => hasUptimeLimit ? MikrotikDuration.format(limitUptime!) : "بلا حد زمني";

  String get remainingLabel {
    final remaining = remainingUptime;
    if (remaining == null) return "—";
    return MikrotikDuration.format(remaining);
  }

  String get bytesLabel => readableBytes(usedBytes);

  String get limitBytesLabel => hasBytesLimit ? readableBytes(limitBytes!) : "بلا حد بيانات";

  /// حالة الكرت بالعربية (لون الشارة في الواجهة).
  String get stateLabel {
    if (disabled) return "معطّل";
    if (isExhausted) return "منتهي";
    if (isNearExpiry()) return "قارب على الانتهاء";
    return "فعال";
  }

  static String readableBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }

  static int _intOf(dynamic value) {
    if (value == null) return 0;
    final direct = int.tryParse(value.toString().trim());
    if (direct != null) return direct;
    final parsed = ExpiredBytesParser.parse(value.toString());
    return parsed ?? 0;
  }

  static bool _bool(dynamic value, {bool fallback = false}) {
    final text = (value ?? "").toString().trim().toLowerCase();
    if (text.isEmpty) return fallback;
    if (text == "true" || text == "yes") return true;
    if (text == "false" || text == "no") return false;
    return fallback;
  }

  static HotspotUser parse(Map user) {
    final rawLimit = (user["limit-uptime"] ?? "").toString();
    final rawUptime = (user["uptime-used"] ?? "").toString();
    final rawBytes = (user["limit-bytes-total"] ?? "").toString();

    return HotspotUser(
      id: (user[".id"] ?? "").toString(),
      name: (user["name"] ?? "").toString(),
      password: (user["password"] ?? "").toString(),
      profile: (user["profile"] ?? "default").toString(),
      server: (user["server"] ?? "all").toString(),
      macAddress: (user["mac-address"] ?? "").toString(),
      comment: (user["comment"] ?? "").toString(),
      disabled: _bool(user["disabled"]),
      rawLimitUptime: rawLimit,
      rawLimitBytes: rawBytes,
      rawUptimeUsed: rawUptime,
      limitUptime: MikrotikDuration.parse(rawLimit),
      usedUptime: MikrotikDuration.parse(rawUptime) ?? Duration.zero,
      limitBytes: ExpiredBytesParser.parse(rawBytes),
      bytesIn: _intOf(user["bytes-in"]),
      bytesOut: _intOf(user["bytes-out"]),
    );
  }
}

/// محلّل أحجام RouterOS (نفس منطق وحدة المنتهين لكن مستقل هنا لتقليل الترابط).
class ExpiredBytesParser {
  static int? parse(String? raw) {
    if (raw == null) return null;
    final text = raw.trim();
    if (text.isEmpty) return null;

    final direct = int.tryParse(text);
    if (direct != null) return direct;

    final match = RegExp(r'([\d.]+)\s*([KMGkmg]?)i?B?').firstMatch(text);
    if (match == null) return null;
    final value = double.tryParse(match.group(1) ?? "");
    if (value == null) return null;

    switch ((match.group(2) ?? "").toUpperCase()) {
      case 'K':
        return (value * 1024).round();
      case 'M':
        return (value * 1024 * 1024).round();
      case 'G':
        return (value * 1024 * 1024 * 1024).round();
      default:
        return value.round();
    }
  }
}

/// ============================ الجلسة النشطة ============================

class HotspotActiveSession {
  final String id;
  final String user;
  final String address;
  final String macAddress;
  final String server;
  final String loginBy;
  final Duration uptime;
  final String rawUptime;
  final Duration idleTime;
  final int bytesIn;
  final int bytesOut;

  const HotspotActiveSession({
    required this.id,
    required this.user,
    required this.address,
    required this.macAddress,
    required this.server,
    required this.loginBy,
    required this.uptime,
    required this.rawUptime,
    required this.idleTime,
    required this.bytesIn,
    required this.bytesOut,
  });

  int get usedBytes => bytesIn + bytesOut;

  String get usedLabel => HotspotUser.readableBytes(usedBytes);

  String get uptimeLabel => MikrotikDuration.format(uptime);

  String get idleLabel {
    if (idleTime == Duration.zero) return "لا خمول";
    return MikrotikDuration.format(idleTime);
  }

  /// نوع الدخول بالعربية (http / https / mac / cookie ...).
  String get loginByLabel {
    switch (loginBy.trim().toLowerCase()) {
      case "http":
        return "صفحة HTTP";
      case "https":
        return "صفحة HTTPS";
      case "mac":
        return "تلقائي بـ MAC";
      case "cookie":
        return "كوكي";
      case "trial":
        return "تجريبي";
      default:
        return loginBy.isEmpty ? "غير محدد" : loginBy;
    }
  }

  static int _intOf(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString().trim()) ??
        ExpiredBytesParser.parse(value.toString()) ??
        0;
  }

  static HotspotActiveSession parse(Map row) {
    final rawUptime = (row["uptime"] ?? "").toString();
    return HotspotActiveSession(
      id: (row[".id"] ?? "").toString(),
      user: (row["user"] ?? "").toString(),
      address: (row["address"] ?? "").toString(),
      macAddress: (row["mac-address"] ?? "").toString(),
      server: (row["server"] ?? "").toString(),
      loginBy: (row["login-by"] ?? "").toString(),
      uptime: MikrotikDuration.parse(rawUptime) ?? Duration.zero,
      rawUptime: rawUptime,
      idleTime: MikrotikDuration.parse((row["idle-time"] ?? "").toString()) ?? Duration.zero,
      bytesIn: _intOf(row["bytes-in"]),
      bytesOut: _intOf(row["bytes-out"]),
    );
  }
}

/// ============================ الباقة ============================

class HotspotProfile {
  final String name;
  final String sharedUsers;
  final String rateLimit;
  final String sessionTimeout;
  final String idleTimeout;
  final String keepaliveTimeout;
  final String addMacCookie;
  final String onLogin;

  const HotspotProfile({
    required this.name,
    required this.sharedUsers,
    required this.rateLimit,
    required this.sessionTimeout,
    required this.idleTimeout,
    required this.keepaliveTimeout,
    required this.addMacCookie,
    required this.onLogin,
  });

  String get rateLabel => rateLimit.isEmpty ? "بلا تحديد سرعة" : rateLimit;

  static HotspotProfile parse(Map row) {
    return HotspotProfile(
      name: (row["name"] ?? "").toString(),
      sharedUsers: (row["shared-users"] ?? "").toString(),
      rateLimit: (row["rate-limit"] ?? "").toString(),
      sessionTimeout: (row["session-timeout"] ?? "").toString(),
      idleTimeout: (row["idle-timeout"] ?? "").toString(),
      keepaliveTimeout: (row["keepalive-timeout"] ?? "").toString(),
      addMacCookie: (row["add-mac-cookie"] ?? "").toString(),
      onLogin: (row["on-login"] ?? "").toString(),
    );
  }
}

/// ============================ الخادم ============================

class HotspotServer {
  final String id;
  final String name;
  final String interfaceName;
  final String addressPool;
  final String profile;
  final String htmlDirectory;
  final String loginBy;
  final String dnsName;
  final String addressesPerMac;
  final bool disabled;

  const HotspotServer({
    required this.id,
    required this.name,
    required this.interfaceName,
    required this.addressPool,
    required this.profile,
    required this.htmlDirectory,
    required this.loginBy,
    required this.dnsName,
    required this.addressesPerMac,
    required this.disabled,
  });

  /// مجلد صفحة الدخول الفعّال (الافتراضي في RouterOS هو hotspot).
  String get effectiveHtmlDirectory =>
      htmlDirectory.trim().isEmpty ? "hotspot" : htmlDirectory.trim();

  static HotspotServer parse(Map row) {
    return HotspotServer(
      id: (row[".id"] ?? "").toString(),
      name: (row["name"] ?? "").toString(),
      interfaceName: (row["interface"] ?? "").toString(),
      addressPool: (row["address-pool"] ?? "").toString(),
      profile: (row["profile"] ?? "").toString(),
      htmlDirectory: (row["html-directory"] ?? "").toString(),
      loginBy: (row["login-by"] ?? "").toString(),
      dnsName: (row["dns-name"] ?? "").toString(),
      addressesPerMac: (row["addresses-per-mac"] ?? "").toString(),
      disabled: (row["disabled"] ?? "").toString().toLowerCase() == "true",
    );
  }
}

/// ============================ توليد القسائم ============================

/// مجموعات الأحرف المتاحة لتوليد بيانات القسائم.
enum VoucherCharset {
  /// أرقام فقط (الأسهل للكتابة على الكروت).
  digits,

  /// أحرف إنجليزية صغيرة.
  lower,

  /// أحرف وأرقام صغيرة.
  alnumLower,

  /// أحرف كبيرة وأرقام.
  alnumUpper,
}

extension VoucherCharsetChars on VoucherCharset {
  String get chars {
    switch (this) {
      case VoucherCharset.digits:
        return "0123456789";
      case VoucherCharset.lower:
        return "abcdefghijklmnopqrstuvwxyz";
      case VoucherCharset.alnumLower:
        return "abcdefghijkmnpqrstuvwxyz23456789";
      case VoucherCharset.alnumUpper:
        return "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    }
  }

  String get label {
    switch (this) {
      case VoucherCharset.digits:
        return "أرقام فقط";
      case VoucherCharset.lower:
        return "حروف صغيرة";
      case VoucherCharset.alnumLower:
        return "حروف وأرقام";
      case VoucherCharset.alnumUpper:
        return "حروف كبيرة وأرقام";
    }
  }
}

/// مواصفات توليد القسائم.
class VoucherSpec {
  final int count;
  final int usernameLength;
  final int passwordLength;
  final VoucherCharset charset;

  /// بادئة اختيارية لأسماء المستخدمين (مثل `m-`).
  final String prefix;

  final String profile;
  final String server;

  /// مدة الصلاحية بصيغة RouterOS (مثل `1w2d` أو `3h`).
  final String limitUptime;

  /// حد البيانات الكلي بصيغة RouterOS (مثل `2G` أو `1073741824`).
  final String limitBytes;

  final String comment;

  const VoucherSpec({
    required this.count,
    this.usernameLength = 8,
    this.passwordLength = 6,
    this.charset = VoucherCharset.digits,
    this.prefix = "",
    this.profile = "default",
    this.server = "all",
    this.limitUptime = "",
    this.limitBytes = "",
    this.comment = "",
  });

  /// تحقق من صحة المواصفات قبل التوليد (يُعرض للمستخدم بالعربية).
  List<String> validate() {
    final issues = <String>[];
    if (count < 1 || count > 1000) issues.add("عدد القسائم يجب أن يكون بين 1 و 1000");
    if (usernameLength < 4 || usernameLength > 32) {
      issues.add("طول اسم المستخدم يجب أن يكون بين 4 و 32");
    }
    if (passwordLength < 4 || passwordLength > 32) {
      issues.add("طول كلمة المرور يجب أن يكون بين 4 و 32");
    }
    if (prefix.isNotEmpty && !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(prefix)) {
      issues.add("البادئة يجب أن تكون أحرفًا وأرقامًا فقط (بلا مسافات)");
    }
    if (usernameLength + prefix.length > 40) {
      issues.add("الاسم مع البادئة أطول من المسموح (40 حرفًا)");
    }
    if (limitUptime.trim().isNotEmpty && MikrotikDuration.parse(limitUptime) == null) {
      issues.add("صيغة مدة الصلاحية غير مفهومة (أمثلة صحيحة: 1d · 12h · 1w2d · 30m)");
    }
    if (limitBytes.trim().isNotEmpty && ExpiredBytesParser.parse(limitBytes) == null) {
      issues.add("صيغة حد البيانات غير مفهومة (أمثلة صحيحة: 500M · 2G · 1073741824)");
    }
    return issues;
  }
}

/// قسيمة (كرت هوت سبوت) مولّدة.
class HotspotVoucher {
  final String username;
  final String password;

  const HotspotVoucher({required this.username, required this.password});
}

class HotspotVoucherGenerator {
  /// أحرف لا تُستخدم افتراضيًا لسهولة الخلط عند الكتابة اليدوية: 0/O و 1/I/l.
  static const String ambiguousChars = "0O1Il";

  /// توليد قسائم فريدة. [seed] يجعل النتيجة قابلة للتكرار (للاختبارات).
  static List<HotspotVoucher> generate(VoucherSpec spec, {int? seed}) {
    final random = seed == null ? Random.secure() : Random(seed);
    final baseChars = spec.charset.chars;
    final chars = baseChars
        .split('')
        .where((char) => !ambiguousChars.contains(char))
        .toList();
    final safeChars = chars.isEmpty ? baseChars.split('') : chars;

    final vouchers = <HotspotVoucher>[];
    final usedNames = <String>{};

    var guard = 0;
    final maxAttempts = spec.count * 50 + 500;

    while (vouchers.length < spec.count && guard < maxAttempts) {
      guard++;
      final username = "${spec.prefix}${_randomString(random, safeChars, spec.usernameLength)}";
      if (!usedNames.add(username)) continue;
      vouchers.add(HotspotVoucher(
        username: username,
        password: _randomString(random, safeChars, spec.passwordLength),
      ));
    }

    return vouchers;
  }

  static String _randomString(Random random, List<String> chars, int length) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }
}

/// عنصر جاهز للطباعة في PDF القسائم.
class VoucherPrintItem {
  final String username;
  final String password;
  final String profile;
  final String validity;
  final String dataLimit;
  final String note;

  const VoucherPrintItem({
    required this.username,
    required this.password,
    this.profile = "",
    this.validity = "",
    this.dataLimit = "",
    this.note = "",
  });
}

/// ============================ تصدير القسائم ============================

class VoucherExporter {
  /// تصدير CSV (متوافق مع Excel: BOM + سطر عناوين + تهريب الفواصل).
  static String toCsv(List<VoucherPrintItem> items) {
    final buffer = StringBuffer();
    buffer.write('username,password,profile,validity,data_limit,note\r\n');
    for (final item in items) {
      buffer.write([
        _escape(item.username),
        _escape(item.password),
        _escape(item.profile),
        _escape(item.validity),
        _escape(item.dataLimit),
        _escape(item.note),
      ].join(','));
      buffer.write('\r\n');
    }
    return buffer.toString();
  }

  static String _escape(String value) {
    final text = value.replaceAll('\r', ' ').replaceAll('\n', ' ');
    if (text.contains(',') || text.contains('"')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  /// أسطر أوامر RouterOS لإضافة القسائم (للاستخدام اليدوي في Terminal عند الحاجة).
  static String toRouterOsCommands(List<VoucherPrintItem> items, {String server = "all"}) {
    final buffer = StringBuffer();
    for (final item in items) {
      final parts = <String>[
        "/ip/hotspot/user/add",
        "name=${item.username}",
        "password=${item.password}",
        if (item.profile.isNotEmpty) "profile=${item.profile}",
        if (item.validity.isNotEmpty) "limit-uptime=${item.validity}",
        if (item.dataLimit.isNotEmpty) "limit-bytes-total=${item.dataLimit}",
        if (server.isNotEmpty) "server=$server",
      ];
      buffer.writeln(parts.join(' '));
    }
    return buffer.toString();
  }
}

/// ============================ التحقق من صفحة الدخول ============================

enum LoginIssueSeverity { error, warning, info }

class LoginPageIssue {
  final LoginIssueSeverity severity;
  final String message;

  const LoginPageIssue(this.severity, this.message);

  String get label {
    switch (severity) {
      case LoginIssueSeverity.error:
        return "خطأ";
      case LoginIssueSeverity.warning:
        return "تحذير";
      case LoginIssueSeverity.info:
        return "ملاحظة";
    }
  }
}

/// ملف صفحة دخول (اسم + محتوى نصي + بايتات الرفع).
class HotspotLoginFile {
  final String fileName;

  /// المحتوى النصي (يُستخدم للتحقق من الوسوم المطلوبة).
  final String content;

  /// البايتات الفعلية للرفع (تُقرأ من الملف المختار على الهاتف).
  final List<int> bytes;

  const HotspotLoginFile({
    required this.fileName,
    this.content = "",
    this.bytes = const [],
  });

  /// بايتات الرفع: البايتات المختارة إن وُجدت وإلا ترميز UTF-8 للمحتوى.
  List<int> get bytesForUpload => bytes.isNotEmpty ? bytes : utf8.encode(content);

  /// الحجم الفعلي بالبايت.
  int get effectiveSize => bytes.isNotEmpty ? bytes.length : utf8.encode(content).length;

  bool get isHtml =>
      fileName.toLowerCase().endsWith('.html') || fileName.toLowerCase().endsWith('.htm');
}

class HotspotLoginPageValidator {
  /// الملف الأساسي المطلوب إلزاميًا.
  static const String requiredFile = "login.html";

  /// ملفات موصى بها لتجربة كاملة (رسائل الخطأ، الحالة، الخروج).
  static const List<String> recommendedFiles = [
    "alogin.html",
    "error.html",
    "logout.html",
    "status.html",
    "redirect.html",
  ];

  /// وسوم RouterOS الأساسية التي يجب أن توجد في صفحة الدخول.
  static const String loginActionTag = r'$(link-login-only)';

  /// الحد الأقصى المعقول لحجم الملف (ذاكرة الراوتر محدودة).
  static const int maxFileSizeBytes = 512 * 1024;

  static List<LoginPageIssue> validate(List<HotspotLoginFile> files) {
    final issues = <LoginPageIssue>[];

    if (files.isEmpty) {
      return const [
        LoginPageIssue(LoginIssueSeverity.error, "لم تُحدَّد أي ملفات"),
      ];
    }

    final names = files.map((file) => file.fileName.toLowerCase()).toSet();

    if (!names.contains(requiredFile)) {
      issues.add(const LoginPageIssue(
        LoginIssueSeverity.error,
        "الملف الأساسي login.html مفقود — بدونه لن يعمل Hotspot",
      ));
    }

    final loginFile = files.where((file) => file.fileName.toLowerCase() == requiredFile);
    if (loginFile.isNotEmpty) {
      final content = loginFile.first.content;
      final lower = content.toLowerCase();

      if (!content.contains(loginActionTag)) {
        issues.add(LoginPageIssue(
          LoginIssueSeverity.error,
          "login.html لا يحتوي الوسم $loginActionTag — النموذج لن يُرسل بيانات الدخول للراوتر",
        ));
      }
      if (!lower.contains('<form')) {
        issues.add(const LoginPageIssue(
          LoginIssueSeverity.error,
          "login.html لا يحتوي نموذج <form> لإدخال بيانات الدخول",
        ));
      }
      if (!lower.contains('name="username"') && !lower.contains("name='username'")) {
        issues.add(const LoginPageIssue(
          LoginIssueSeverity.warning,
          'حقل الاسم name="username" غير موجود — لن يستطيع المستخدم إدخال اسمه',
        ));
      }
      if (!lower.contains('name="password"') && !lower.contains("name='password'")) {
        issues.add(const LoginPageIssue(
          LoginIssueSeverity.warning,
          'حقل كلمة المرور name="password" غير موجود',
        ));
      }
      if (!lower.contains('name="viewport"')) {
        issues.add(const LoginIssueIssuePlaceholder.viewportWarning);
      }
      if (!lower.contains('charset')) {
        issues.add(const LoginIssueIssuePlaceholder.charsetInfo);
      }
    }

    for (final file in files) {
      if (file.effectiveSize > maxFileSizeBytes) {
        issues.add(LoginPageIssue(
          LoginIssueSeverity.warning,
          "حجم ${file.fileName} كبير (${HotspotUser.readableBytes(file.effectiveSize)}) — "
          "ذاكرة الراوتر محدودة، يُفضّل أقل من 512 KB",
        ));
      }
    }

    final totalSize = files.fold<int>(0, (sum, file) => sum + file.effectiveSize);
    if (totalSize > 2 * 1024 * 1024) {
      issues.add(LoginPageIssue(
        LoginIssueSeverity.warning,
        "الحجم الإجمالي للملفات كبير (${HotspotUser.readableBytes(totalSize)})",
      ));
    }

    final missingRecommended =
        recommendedFiles.where((name) => !names.contains(name)).toList();
    if (missingRecommended.isNotEmpty) {
      issues.add(LoginPageIssue(
        LoginIssueSeverity.info,
        "ملفات موصى بها غير مرفوعة: ${missingRecommended.join('، ')} "
        "(تظهر عند نجاح الدخول أو انتهاء الجلسة)",
      ));
    }

    if (!issues.any((issue) => issue.severity == LoginIssueSeverity.error)) {
      issues.insert(0, const LoginPageIssue(
        LoginIssueSeverity.info,
        "صفحة الدخول تبدو صالحة للاستخدام",
      ));
    }

    return issues;
  }

  /// هل الملفات كافية للرفع؟ (بلا أخطاء مُفشِلة)
  static bool canUpload(List<HotspotLoginFile> files) {
    final issues = validate(files);
    return !issues.any((issue) => issue.severity == LoginIssueSeverity.error);
  }
}

/// رسائل جاهزة (const) لتفادي تكرار الإنشاء.
class LoginIssueIssuePlaceholder {
  static const viewportWarning = LoginPageIssue(
    LoginIssueSeverity.warning,
    'الوسم <meta name="viewport"> غير موجود — الصفحة قد تظهر بحجم غير مناسب على الهاتف',
  );

  static const charsetInfo = LoginPageIssue(
    LoginIssueSeverity.info,
    "ترميز الصفحة (charset) غير محدد — أضف <meta charset=\"utf-8\"> لدعم العربية",
  );
}
