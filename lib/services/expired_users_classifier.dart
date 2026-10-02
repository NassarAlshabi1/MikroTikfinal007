import 'mikrotik_duration.dart';

/// حد باقة مستخرَج من الراوتر (مدة + بيانات).
class ProfileLimit {
  final Duration? uptime;
  final int? transfer;

  const ProfileLimit({this.uptime, this.transfer});
}

/// مستخدم (كرت) مع بيانات مدة الاستهلاك والحد.
///
/// أسماء الحقول تختلف بين الإصدارين:
/// - **RouterOS v6**: `username`, `actual-profile`, `uptime-used`, `download-used`, `customer`
/// - **RouterOS v7**: `name`, `group`, `user-profile.state = used`
class ExpiredUserCandidate {
  final String id;
  final String username;
  final String profile;
  final String customer;
  final String lastSeen;

  final String rawUptimeUsed;
  final String rawLimitUptime;

  /// المدة المستهلكة (من `uptime-used` أو `uptime`).
  final Duration usedUptime;

  /// الحد المسموح: من المستخدم نفسه أو من الباقة/القيد المرتبط.
  final Duration? limitUptime;

  final int usedBytes;
  final int? limitBytes;

  /// RouterOS v7: حالة الباقة في `user-profile` تساوي `used`.
  final bool profileStateUsed;

  /// RouterOS v6: الباقة مُزالة من المستخدم (`!actual-profile`) مع وجود استهلاك —
  /// وهذه هي الإشارة الأصلية للكروت المنتهية في v6.
  final bool profileCleared;

  ExpiredUserCandidate({
    required this.id,
    required this.username,
    required this.profile,
    required this.customer,
    required this.lastSeen,
    required this.rawUptimeUsed,
    required this.rawLimitUptime,
    required this.usedUptime,
    required this.limitUptime,
    required this.usedBytes,
    required this.limitBytes,
    required this.profileStateUsed,
    required this.profileCleared,
  });

  /// هل الحد معروف وقابل للاستخدام؟
  bool get limitKnown => limitUptime != null && limitUptime! > Duration.zero;

  /// هل صرّح الراوتر بحد لكن تعذّر تحليله؟
  bool get limitDeclaredButUnparsable =>
      !limitKnown && rawLimitUptime.trim().isNotEmpty;

  /// ⭐ المعيار الأساسي: استهلك مدته كاملة (uptime >= limit-uptime).
  bool get uptimeExhausted {
    if (!limitKnown) return false;
    return UptimeUsage(used: usedUptime, limit: limitUptime!).isExhausted;
  }

  /// إشارة إضافية من الراوتر نفسه بانتهاء الاشتراك (v6: الباقة مُزالة، v7: state=used).
  bool get isExpiredBySignal => profileCleared || profileStateUsed;

  /// معيار إضافي اختياري: استهلك رصيد البيانات كاملًا.
  bool get bytesExhausted {
    final limit = limitBytes;
    if (limit == null || limit <= 0) return false;
    return usedBytes >= limit;
  }

  bool get hasLimit => limitKnown;

  /// سبب الانتهاء المعروض في الواجهة.
  String get expiredReason {
    if (uptimeExhausted) return "انتهت المدة";
    if (profileCleared) return "الباقة مُزالة (v6)";
    if (profileStateUsed) return "الباقة مستهلكة (v7)";
    if (bytesExhausted) return "انتهى الرصيد";
    return "غير محدد";
  }

  int get percent {
    if (!limitKnown) return 0;
    return UptimeUsage(used: usedUptime, limit: limitUptime!).percent;
  }

  String get usedLabel => MikrotikDuration.format(usedUptime);

  String get limitLabel =>
      limitUptime == null ? "بلا حد" : MikrotikDuration.format(limitUptime!);

  String get readableUsedBytes => readableBytes(usedBytes);

  String get readableLimitBytes =>
      limitBytes == null || limitBytes! <= 0 ? "بلا حد" : readableBytes(limitBytes!);

  static String readableBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }
}

/// نتيجة الفحص الذكي.
class ExpiredUsersScanResult {
  /// المؤهلون للحذف (استهلكوا مدتهم كاملة أو أشار الراوتر لانتهائهم).
  final List<ExpiredUserCandidate> exhausted;

  /// لديهم حدود ولم يكملوها بعد.
  final List<ExpiredUserCandidate> stillRunning;

  /// صيغة مدة/حد غير مفهومة ← يُستبعدون من الحذف.
  final int unparsable;

  /// بلا حدود إطلاقًا ← لا يُحذفون.
  final int withoutLimits;

  final int totalUsers;

  /// الإصدار المكتشف من الراوتر (6 أو 7 أو 0 = غير محدد).
  final int routerVersion;

  ExpiredUsersScanResult({
    required this.exhausted,
    required this.stillRunning,
    required this.unparsable,
    required this.withoutLimits,
    required this.totalUsers,
    this.routerVersion = 0,
  });

  /// عدد من انتهوا بإشارة v6 (الباقة مُزالة).
  int get clearedProfileCount =>
      exhausted.where((user) => user.profileCleared).length;

  /// عدد من انتهوا بإشارة v7 (state=used).
  int get stateUsedCount =>
      exhausted.where((user) => user.profileStateUsed).length;
}

/// المنطق النقي للفحص (بدون أي اتصال بالشبكة) — قابل للاختبار مباشرة.
class ExpiredUsersClassifier {
  /// بناء خريطة حدود الباقات: اسم الباقة ← (المدة، البيانات).
  ///
  /// يدعم مسارين كما في RouterOS:
  /// 1. القيد مذكور مباشرة على الباقة (`limitation`) — شائع في v6.
  /// 2. جدول الربط `profile-limitation` (profile/limitation).
  /// ويستخدم `validity` كبديل عند غياب `uptime-limit`.
  static Map<String, ProfileLimit> buildProfileLimits({
    required List profiles,
    required List limitations,
    required List links,
  }) {
    final limitsByName = <String, Map>{};
    for (final item in limitations.whereType<Map>()) {
      final name = item["name"]?.toString() ?? "";
      if (name.isNotEmpty) limitsByName[name] = item;
    }

    final result = <String, ProfileLimit>{};

    for (final profile in profiles.whereType<Map>()) {
      final profileId = profile["name"]?.toString() ?? "";
      final displayName = (profile["name-for-users"] ?? profile["name"])?.toString() ?? "";
      if (profileId.isEmpty && displayName.isEmpty) continue;

      Map? limit;

      // (1) القيد مباشرة على الباقة
      final directLimitName = profile["limitation"]?.toString() ?? "";
      if (directLimitName.isNotEmpty) limit = limitsByName[directLimitName];

      // (2) عبر جدول الربط
      if (limit == null) {
        for (final link in links.whereType<Map>()) {
          if (link["profile"]?.toString() == profileId) {
            limit = limitsByName[link["limitation"]?.toString() ?? ""];
            if (limit != null) break;
          }
        }
      }

      final uptime = MikrotikDuration.parse(limit?["uptime-limit"]?.toString()) ??
          MikrotikDuration.parse(profile["validity"]?.toString());
      final transfer = parseBytes(limit?["transfer-limit"]?.toString());

      final entry = ProfileLimit(uptime: uptime, transfer: transfer);
      if (displayName.isNotEmpty) result[displayName] = entry;
      if (profileId.isNotEmpty) result[profileId] = entry;
    }

    return result;
  }

  /// تحليل أحجام RouterOS: `1024`, `1.5MiB`, `2GiB`, `500KiB`, `1048576`.
  static int? parseBytes(String? raw) {
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

  /// بناء مرشّح واحد من صف RouterOS.
  ///
  /// [useProfileClearedSignal]: يُفعَّل في v6 فقط (الباقة المُزالة إشارة انتهاء).
  static ExpiredUserCandidate buildCandidate(
    Map user,
    Map<String, ProfileLimit> limitsByProfile,
    Map<String, String> statesByUser, {
    bool useProfileClearedSignal = true,
  }) {
    final username = (user["username"] ?? user["name"] ?? "").toString();
    final profile =
        (user["actual-profile"] ?? user["profile"] ?? user["group"] ?? "default").toString();

    final rawUptime = (user["uptime-used"] ?? user["uptime"] ?? "").toString();
    final rawLimit = user["limit-uptime"]?.toString() ?? "";

    final usedUptime = MikrotikDuration.parse(rawUptime) ?? Duration.zero;
    var limitUptime = MikrotikDuration.parse(rawLimit);
    var limitBytes = parseBytes(user["limit-bytes-total"]?.toString());

    final fromProfile = limitsByProfile[profile];
    if (limitUptime == null && fromProfile != null) limitUptime = fromProfile.uptime;
    if (limitBytes == null && fromProfile != null) limitBytes = fromProfile.transfer;

    final download = parseBytes(user["download-used"]?.toString()) ?? 0;
    final upload = parseBytes(user["upload-used"]?.toString()) ?? 0;

    final state = statesByUser[username]?.toLowerCase() ?? "";

    // v6: غياب الحقل (أو كونه فارغًا) مع وجود استهلاك = الباقة أُزيلت بعد الانتهاء.
    final hasProfileField =
        user.containsKey("actual-profile") || user.containsKey("profile");
    final profileValue = (user["actual-profile"] ?? user["profile"])?.toString() ?? "";
    final profileCleared = useProfileClearedSignal &&
        (!hasProfileField || profileValue.trim().isEmpty) &&
        usedUptime > Duration.zero;

    return ExpiredUserCandidate(
      id: user[".id"]?.toString() ?? "",
      username: username,
      profile: profile,
      customer: (user["customer"] ?? user["group"] ?? "").toString(),
      lastSeen: (user["last-seen"] ?? "").toString(),
      rawUptimeUsed: rawUptime,
      rawLimitUptime: rawLimit,
      usedUptime: usedUptime,
      limitUptime: limitUptime,
      usedBytes: download + upload,
      limitBytes: limitBytes,
      profileStateUsed: state == "used" || state == "expired",
      profileCleared: profileCleared,
    );
  }

  /// تصنيف كل المستخدمين — القواعد مرتّبة بحيث لا يُحذف إلا من تأكد انتهاؤه.
  static ExpiredUsersScanResult classify({
    required List users,
    required Map<String, ProfileLimit> limitsByProfile,
    required Map<String, String> statesByUser,
    int routerVersion = 6,
  }) {
    final useProfileClearedSignal = routerVersion != 7;

    final exhausted = <ExpiredUserCandidate>[];
    final running = <ExpiredUserCandidate>[];
    var unparsable = 0;
    var withoutLimits = 0;

    for (final user in users.whereType<Map>()) {
      final candidate = buildCandidate(
        user,
        limitsByProfile,
        statesByUser,
        useProfileClearedSignal: useProfileClearedSignal,
      );

      // (1) مدة استهلاك غير مفهومة ← يُستبعد من الحذف مهما كان
      if (candidate.rawUptimeUsed.trim().isNotEmpty &&
          MikrotikDuration.parse(candidate.rawUptimeUsed) == null) {
        unparsable++;
        continue;
      }

      // (2) استهلك مدته كاملة (المعيار الأساسي)
      if (candidate.limitKnown && candidate.uptimeExhausted) {
        exhausted.add(candidate);
        continue;
      }

      // (3) إشارة الراوتر بانتهاء الاشتراك (v6: الباقة مُزالة / v7: state=used)
      if (candidate.isExpiredBySignal) {
        exhausted.add(candidate);
        continue;
      }

      // (4) لم يكمل مدته بعد
      if (candidate.limitKnown) {
        running.add(candidate);
        continue;
      }

      // (5) حد مذكور لكن غير مفهوم ← يُستبعد
      if (candidate.limitDeclaredButUnparsable) {
        unparsable++;
        continue;
      }

      // (6) بلا حدود إطلاقًا ← لا يُحذف
      withoutLimits++;
    }

    exhausted.sort((a, b) => b.percent.compareTo(a.percent));
    running.sort((a, b) => b.percent.compareTo(a.percent));

    return ExpiredUsersScanResult(
      exhausted: exhausted,
      stillRunning: running,
      unparsable: unparsable,
      withoutLimits: withoutLimits,
      totalUsers: users.whereType<Map>().length,
      routerVersion: routerVersion,
    );
  }
}
