import '../models/response.dart';
import '../services/mikrotik_client.dart';
import '../services/mikrotik_duration.dart';

/// مستخدم (كرت) مع بيانات مدة الاستهلاك والحد.
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

  /// حالة الباقة في RouterOS v7 (`used` تعني انتهت الباقة).
  final bool profileStateUsed;

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
  });

  /// ⭐ المعيار الأساسي: استهلك مدته كاملة (uptime >= limit-uptime).
  bool get uptimeExhausted {
    final limit = limitUptime;
    if (limit == null) return false;
    return UptimeUsage(used: usedUptime, limit: limit).isExhausted;
  }

  /// معيار إضافي اختياري: استهلك رصيد البيانات كاملًا.
  bool get bytesExhausted {
    final limit = limitBytes;
    if (limit == null || limit <= 0) return false;
    return usedBytes >= limit;
  }

  bool get hasLimit => limitUptime != null && limitUptime! > Duration.zero;

  /// هل عُلِّمت الباقة كمنتهية في RouterOS v7؟
  bool get isStateUsed => profileStateUsed;

  int get percent {
    final limit = limitUptime;
    if (limit == null || limit <= Duration.zero) return 0;
    return UptimeUsage(used: usedUptime, limit: limit).percent;
  }

  String get usedLabel => MikrotikDuration.format(usedUptime);

  String get limitLabel =>
      limitUptime == null ? "بلا حد" : MikrotikDuration.format(limitUptime!);

  String get readableUsedBytes => _readableBytes(usedBytes);

  String get readableLimitBytes =>
      limitBytes == null || limitBytes! <= 0 ? "بلا حد" : _readableBytes(limitBytes!);

  static String _readableBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }
}

/// نتيجة الفحص الذكي.
class ExpiredUsersScanResult {
  /// المستخدمون المؤهلون للحذف (استهلكوا مدتهم كاملة).
  final List<ExpiredUserCandidate> exhausted;

  /// مستخدمون لديهم حدود لكن لم يكملوها بعد.
  final List<ExpiredUserCandidate> stillRunning;

  /// عدد المستخدمين الذين لم نتمكن من تحليل مدتهم/حدّهم (يُستبعدون من الحذف).
  final int unparsable;

  /// عدد المستخدمين بلا حدود إطلاقًا.
  final int withoutLimits;

  final int totalUsers;

  ExpiredUsersScanResult({
    required this.exhausted,
    required this.stillRunning,
    required this.unparsable,
    required this.withoutLimits,
    required this.totalUsers,
  });
}

/// الفحص الذكي وحذف المستخدمين المنتهين.
///
/// يقارن `uptime-used` مع `limit-uptime` ولا يحذف إلا من استهلك مدته كاملة،
/// مع رفض أي صيغة مدة غير مفهومة (يُستبعد صاحبها بدل تخمينه).
class ExpiredUsersApi {
  // ================== عناوين User Manager حسب الإصدار ==================
  static String get _usersPath =>
      MikrotikClient.version == 7 ? "/user-manager/user/print" : "/tool/user-manager/user/print";

  static String get _usersRemovePath =>
      MikrotikClient.version == 7 ? "/user-manager/user/remove" : "/tool/user-manager/user/remove";

  static String get _profilesPath =>
      MikrotikClient.version == 7 ? "/user-manager/profile/print" : "/tool/user-manager/profile/print";

  static String get _limitationsPath =>
      MikrotikClient.version == 7 ? "/user-manager/limitation/print" : "/tool/user-manager/profile/limitation/print";

  static String get _profileLimitationPath => MikrotikClient.version == 7
      ? "/user-manager/profile-limitation/print"
      : "/tool/user-manager/profile/profile-limitation/print";

  static String get _userProfilesPath =>
      MikrotikClient.version == 7 ? "/user-manager/user-profile/print" : "";

  // ================== الفحص ==================

  /// فحص كل المستخدمين وتصنيفهم.
  static Future<AppResponse<ExpiredUsersScanResult>> scan() async {
    try {
      final users = await _fetchUsers();
      if (users.isEmpty) {
        return AppResponse(
          status: true,
          message: "لا يوجد مستخدمون على الراوتر",
          data: ExpiredUsersScanResult(
            exhausted: const [],
            stillRunning: const [],
            unparsable: 0,
            withoutLimits: 0,
            totalUsers: 0,
          ),
        );
      }

      final limitsByProfile = await _fetchProfileLimits();
      final statesByUser = await _fetchUserProfileStates();

      final exhausted = <ExpiredUserCandidate>[];
      final running = <ExpiredUserCandidate>[];
      var unparsable = 0;
      var withoutLimits = 0;

      for (final user in users) {
        final candidate = _buildCandidate(user, limitsByProfile, statesByUser);

        if (!candidate.hasLimit && !candidate.isStateUsed) {
          withoutLimits++;
          continue;
        }
        if (!candidate.hasLimit && candidate.isStateUsed) {
          // v7: الباقة منتهية حسب حالة User Manager
          exhausted.add(candidate);
          continue;
        }
        if (candidate.limitUptime == null) {
          unparsable++;
          continue;
        }
        if (candidate.uptimeExhausted) {
          exhausted.add(candidate);
        } else {
          running.add(candidate);
        }
      }

      // الأطول استهلاكًا أولًا
      exhausted.sort((a, b) => b.percent.compareTo(a.percent));
      running.sort((a, b) => b.percent.compareTo(a.percent));

      return AppResponse(
        status: true,
        message: "done",
        data: ExpiredUsersScanResult(
          exhausted: exhausted,
          stillRunning: running,
          unparsable: unparsable,
          withoutLimits: withoutLimits,
          totalUsers: users.length,
        ),
      );
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // ================== الحذف ==================

  /// حذف المستخدمين المحددين (بمجاميع من 50 مع تراجع للحذف الفردي).
  static Future<AppResponse<int>> deleteUsers(List<ExpiredUserCandidate> users) async {
    if (users.isEmpty) {
      return AppResponse(status: false, message: "لا يوجد مستخدمون محددون للحذف");
    }

    var deleted = 0;
    final failed = <String>[];

    const chunkSize = 50;
    for (var start = 0; start < users.length; start += chunkSize) {
      final chunk = users.sublist(
        start,
        (start + chunkSize) > users.length ? users.length : start + chunkSize,
      );
      final ids = chunk.map((user) => user.id).where((id) => id.isNotEmpty).toList();
      if (ids.isEmpty) continue;

      try {
        await MikrotikClient.fetch(
          command: [_usersRemovePath, '=numbers=${ids.join(",")}'],
          customTag: "expired_remove_batch",
        );
        deleted += ids.length;
      } catch (_) {
        // تراجع: حذف فردي بالمعرّف
        for (final id in ids) {
          try {
            await MikrotikClient.removeById(command: _usersRemovePath, id: id);
            deleted++;
          } catch (_) {
            failed.add(id);
          }
        }
      }
    }

    if (deleted == 0) {
      return AppResponse(status: false, message: "تعذّر حذف المستخدمين. تحقق من صلاحيات الحساب.");
    }

    return AppResponse(
      status: true,
      message: failed.isEmpty
          ? "تم حذف $deleted مستخدمًا منتهيًا"
          : "تم حذف $deleted مستخدمًا، وفشل حذف ${failed.length}",
      data: deleted,
    );
  }

  // ================== جلب البيانات ==================

  static Future<List<Map>> _fetchUsers() async {
    // نحاول أولًا بحقول المدد، وعند فشلها نرجع لحقول أساسية
    final attempts = <String>[
      ".id,username,name,actual-profile,profile,uptime-used,uptime,last-seen,customer,group,disabled",
      ".id,username,name,uptime-used,last-seen",
      ".id,username,name",
    ];

    Object? lastError;
    for (final fields in attempts) {
      try {
        final result = await MikrotikClient.printData(
          commands: [_usersPath],
          fields: fields,
          tag: 'expired_users_scan',
        );
        return result.whereType<Map>().toList();
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception(lastError?.toString() ?? "تعذّر جلب المستخدمين");
  }

  /// خريطة: اسم الباقة ← (حد المدة، حد البيانات)
  static Future<Map<String, ({Duration? uptime, int? transfer})>> _fetchProfileLimits() async {
    final result = <String, ({Duration? uptime, int? transfer})>{};

    try {
      final limitations = await MikrotikClient.printData(
        commands: [_limitationsPath],
        fields: "name,uptime-limit,transfer-limit,group-name",
        tag: 'expired_limits',
      );
      final links = await MikrotikClient.printData(
        commands: [_profileLimitationPath],
        fields: "profile,limitation",
        tag: 'expired_links',
      );
      final profiles = await MikrotikClient.printData(
        commands: [_profilesPath],
        fields: ".id,name,name-for-users,validity,price",
        tag: 'expired_profiles',
      );

      final limitsByName = <String, Map>{};
      for (final item in limitations.whereType<Map>()) {
        final name = item["name"]?.toString() ?? "";
        if (name.isNotEmpty) limitsByName[name] = item;
      }

      for (final profile in profiles.whereType<Map>()) {
        final profileName = (profile["name-for-users"] ?? profile["name"])?.toString() ?? "";
        if (profileName.isEmpty) continue;

        Map? limit;
        for (final link in links.whereType<Map>()) {
          if (link["profile"]?.toString() == profile["name"]?.toString()) {
            limit = limitsByName[link["limitation"]?.toString() ?? ""];
            if (limit != null) break;
          }
        }

        final uptime = MikrotikDuration.parse(limit?["uptime-limit"]?.toString()) ??
            MikrotikDuration.parse(profile["validity"]?.toString());
        final transfer = _parseBytes(limit?["transfer-limit"]?.toString());

        result[profileName] = (uptime: uptime, transfer: transfer);
        result[profile["name"]?.toString() ?? profileName] = (uptime: uptime, transfer: transfer);
      }
    } catch (_) {
      // بعض الإصدارات لا توفّر قيودًا — نُكمل بحقول المستخدم نفسه
    }

    return result;
  }

  /// حالة الباقة لكل مستخدم (RouterOS v7 فقط).
  static Future<Map<String, String>> _fetchUserProfileStates() async {
    final result = <String, String>{};
    if (_userProfilesPath.isEmpty) return result;

    try {
      final rows = await MikrotikClient.printData(
        commands: [_userProfilesPath],
        fields: ".id,user,profile,state",
        tag: 'expired_states',
      );
      for (final row in rows.whereType<Map>()) {
        final user = row["user"]?.toString() ?? "";
        final state = row["state"]?.toString() ?? "";
        if (user.isNotEmpty && state.isNotEmpty) result[user] = state;
      }
    } catch (_) {
      // غير مدعوم في هذا الإصدار
    }

    return result;
  }

  static ExpiredUserCandidate _buildCandidate(
    Map user,
    Map<String, ({Duration? uptime, int? transfer})> limitsByProfile,
    Map<String, String> statesByUser,
  ) {
    final username = (user["username"] ?? user["name"] ?? "").toString();
    final profile =
        (user["actual-profile"] ?? user["profile"] ?? user["group"] ?? "default").toString();

    final rawUptime = (user["uptime-used"] ?? user["uptime"] ?? "").toString();
    final rawLimit = user["limit-uptime"]?.toString() ?? "";

    final usedUptime = MikrotikDuration.parse(rawUptime) ?? Duration.zero;
    var limitUptime = MikrotikDuration.parse(rawLimit);
    var limitBytes = _parseBytes(user["limit-bytes-total"]?.toString());

    // إن لم يكن الحد على المستخدم نفسه، نقرأه من الباقة/القيد
    final fromProfile = limitsByProfile[profile];
    if (limitUptime == null && fromProfile != null) limitUptime = fromProfile.uptime;
    if (limitBytes == null && fromProfile != null) limitBytes = fromProfile.transfer;

    final usedBytes = _parseBytes(user["download-used"]) ?? 0;
    final uploadBytes = _parseBytes(user["upload-used"]) ?? 0;

    final state = statesByUser[username]?.toLowerCase() ?? "";

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
      usedBytes: usedBytes + uploadBytes,
      limitBytes: limitBytes,
      profileStateUsed: state == "used" || state == "expired",
    );
  }

  /// تحليل أحجام RouterOS: `1024`, `1.5MiB`, `2GiB`, `500KiB`.
  static int? _parseBytes(String? raw) {
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
