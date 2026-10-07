import '../models/response.dart';
import '../services/hotspot_logic.dart';
import '../services/mikrotik_client.dart';

/// إدارة **Hotspot** في RouterOS: المستخدمون، الجلسات النشطة، الباقات، الخوادم،
/// ورفع صفحة الدخول (HTML) إلى ذاكرة الراوتر.
///
/// الأوامر متطابقة في v6 و v7 لأن حزمة Hotspot مستقرة:
/// `/ip/hotspot/user` · `/ip/hotspot/active` · `/ip/hotspot/user/profile` · `/ip/hotspot`.
class HotspotApi {
  // ==================== المستخدمون ====================

  static const String _userMenu = "/ip/hotspot/user";
  static const String _users = "/ip/hotspot/user/print";

  static const List<String> _userFieldAttempts = [
    ".id,name,password,profile,server,mac-address,comment,disabled,"
        "limit-uptime,limit-bytes-total,uptime-used,bytes-in,bytes-out",
    ".id,name,password,profile,mac-address,disabled,limit-uptime,limit-bytes-total,uptime-used,bytes-in,bytes-out",
    ".id,name,password,profile,disabled,limit-uptime,limit-bytes-total",
    ".id,name,password,profile",
    ".id,name",
  ];

  /// قراءة كل مستخدمي Hotspot (مع تجربة حقول متدرجة لتوافق الإصدارات).
  static Future<AppResponse<List<HotspotUser>>> printUsers({String server = ""}) async {
    Object? lastError;

    for (final fields in _userFieldAttempts) {
      try {
        final rows = await MikrotikClient.printData(
          commands: [_users],
          conditions: server.isEmpty ? const [] : ["?server=$server"],
          fields: fields,
          tag: "hotspot_users",
        );
        final users = rows
            .whereType<Map>()
            .map(HotspotUser.parse)
            .where((user) => user.name.isNotEmpty)
            .toList();
        return AppResponse(status: true, message: "done", data: users);
      } catch (e) {
        lastError = e;
        final text = e.toString().toLowerCase();
        if (text.contains('no such command') ||
            text.contains('unknown command') ||
            text.contains('no such menu')) {
          break;
        }
      }
    }

    return AppResponse(
      status: false,
      message: _friendlyError(lastError, "تعذّر قراءة مستخدمي Hotspot"),
      data: const [],
    );
  }

  /// إضافة مستخدم (قسيمة) إلى Hotspot.
  static Future<AppResponse<void>> addUser({
    required String name,
    required String password,
    String profile = "default",
    String server = "all",
    String limitUptime = "",
    String limitBytes = "",
    String macAddress = "",
    String comment = "",
    bool disabled = false,
  }) async {
    try {
      await MikrotikClient.addData(
        command: "$_userMenu/add",
        data: {
          "name": name,
          "password": password,
          "profile": profile,
          "server": server,
          if (limitUptime.trim().isNotEmpty) "limit-uptime": limitUptime.trim(),
          if (limitBytes.trim().isNotEmpty) "limit-bytes-total": limitBytes.trim(),
          if (macAddress.trim().isNotEmpty) "mac-address": macAddress.trim(),
          if (comment.trim().isNotEmpty) "comment": comment.trim(),
          "disabled": disabled ? "yes" : "no",
        },
        tag: "hotspot_user_add",
      );
      return AppResponse(status: true, message: "done");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// تعديل مستخدم موجود (تُرسل الحقول المطلوبة فقط).
  static Future<AppResponse<void>> editUser({
    required String id,
    required Map<String, String> data,
  }) async {
    if (id.isEmpty) {
      return AppResponse(status: false, message: "معرّف المستخدم غير معروف");
    }
    try {
      await MikrotikClient.fetch(
        command: ["$_userMenu/set", "=.id=$id"],
        params: data,
        customTag: "hotspot_user_set",
      );
      return AppResponse(status: true, message: "done");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// تعطيل/تفعيل مجموعة مستخدمين.
  static Future<AppResponse<int>> setEnabled(List<String> ids, {required bool enabled}) async {
    if (ids.isEmpty) {
      return AppResponse(status: false, message: "لم يتم تحديد أي مستخدم", data: 0);
    }

    var done = 0;
    for (final id in ids) {
      final response = await editUser(id: id, data: {"disabled": enabled ? "no" : "yes"});
      if (response.status) done++;
    }

    return AppResponse(
      status: done > 0,
      message: done == ids.length
          ? "تم تحديث $done مستخدمًا"
          : "تم تحديث $done من ${ids.length}",
      data: done,
    );
  }

  /// حذف مستخدمين (دفعات + تراجع فردي).
  static Future<AppResponse<int>> removeUsers(List<HotspotUser> users) async {
    if (users.isEmpty) {
      return AppResponse(status: false, message: "لا يوجد مستخدمون محددون للحذف", data: 0);
    }

    final ids = users.map((user) => user.id).where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) {
      return AppResponse(status: false, message: "معرّفات المستخدمين غير متاحة", data: 0);
    }

    var deleted = 0;
    const chunkSize = 50;

    for (var start = 0; start < ids.length; start += chunkSize) {
      final chunk = ids.sublist(
        start,
        (start + chunkSize) > ids.length ? ids.length : start + chunkSize,
      );

      try {
        await MikrotikClient.fetch(
          command: ["$_userMenu/remove", '=numbers=${chunk.join(",")}'],
          customTag: "hotspot_users_remove",
        );
        deleted += chunk.length;
      } catch (_) {
        for (final id in chunk) {
          try {
            await MikrotikClient.removeById(command: "$_userMenu/remove", id: id);
            deleted++;
          } catch (_) {
            // نتخطى الفاشل ونكمل
          }
        }
      }
    }

    if (deleted == 0) {
      return AppResponse(
        status: false,
        message: "تعذّر حذف المستخدمين. تحقق من صلاحيات الحساب (policy: write).",
        data: 0,
      );
    }

    return AppResponse(status: true, message: "تم حذف $deleted مستخدمًا", data: deleted);
  }

  /// توليد قسائم وإضافتها دفعة واحدة إلى الراوتر.
  static Future<AppResponse<HotspotBulkResult>> addVouchers({
    required VoucherSpec spec,
    required List<HotspotVoucher> vouchers,
    void Function(int done, int total)? onProgress,
  }) async {
    if (vouchers.isEmpty) {
      return AppResponse(status: false, message: "لا توجد قسائم للإضافة");
    }

    final issues = spec.validate();
    if (issues.isNotEmpty) {
      return AppResponse(status: false, message: issues.first);
    }

    var added = 0;
    final failed = <String>[];

    for (var i = 0; i < vouchers.length; i++) {
      final voucher = vouchers[i];
      final response = await addUser(
        name: voucher.username,
        password: voucher.password,
        profile: spec.profile,
        server: spec.server,
        limitUptime: spec.limitUptime,
        limitBytes: spec.limitBytes,
        comment: spec.comment,
      );

      if (response.status) {
        added++;
      } else {
        failed.add(voucher.username);
      }

      onProgress?.call(i + 1, vouchers.length);
    }

    return AppResponse(
      status: added > 0,
      message: failed.isEmpty
          ? "تمت إضافة $added قسيمة"
          : "أُضيفت $added قسيمة وفشل ${failed.length}",
      data: HotspotBulkResult(added: added, failed: failed, total: vouchers.length),
    );
  }

  // ==================== الجلسات النشطة ====================

  static Future<AppResponse<List<HotspotActiveSession>>> printActive() async {
    const attempts = [
      ".id,user,address,mac-address,server,login-by,uptime,idle-time,bytes-in,bytes-out",
      ".id,user,address,mac-address,uptime,bytes-in,bytes-out",
      ".id,user,address",
    ];

    Object? lastError;
    for (final fields in attempts) {
      try {
        final rows = await MikrotikClient.printData(
          commands: ["/ip/hotspot/active/print"],
          fields: fields,
          tag: "hotspot_active",
        );
        final sessions = rows
            .whereType<Map>()
            .map(HotspotActiveSession.parse)
            .where((session) => session.user.isNotEmpty)
            .toList();
        return AppResponse(status: true, message: "done", data: sessions);
      } catch (e) {
        lastError = e;
      }
    }

    return AppResponse(
      status: false,
      message: _friendlyError(lastError, "تعذّر قراءة الجلسات النشطة"),
      data: const [],
    );
  }

  /// قطع جلسات محددة (يُخرج المستخدم من الشبكة فورًا).
  static Future<AppResponse<int>> disconnectSessions(List<HotspotActiveSession> sessions) async {
    if (sessions.isEmpty) {
      return AppResponse(status: false, message: "لم يتم تحديد أي جلسة", data: 0);
    }

    final ids = sessions.map((session) => session.id).where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) {
      return AppResponse(status: false, message: "معرّفات الجلسات غير متاحة", data: 0);
    }

    var removed = 0;
    try {
      await MikrotikClient.fetch(
        command: ["/ip/hotspot/active/remove", '=numbers=${ids.join(",")}'],
        customTag: "hotspot_active_remove",
      );
      removed = ids.length;
    } catch (_) {
      for (final id in ids) {
        try {
          await MikrotikClient.removeById(command: "/ip/hotspot/active/remove", id: id);
          removed++;
        } catch (_) {
          // نتخطى الفاشل
        }
      }
    }

    if (removed == 0) {
      return AppResponse(status: false, message: "تعذّر قطع الجلسات", data: 0);
    }
    return AppResponse(status: true, message: "تم قطع $removed جلسة", data: removed);
  }

  // ==================== الباقات والخوادم ====================

  static Future<AppResponse<List<HotspotProfile>>> printProfiles() async {
    const attempts = [
      ".id,name,shared-users,rate-limit,session-timeout,idle-timeout,keepalive-timeout,add-mac-cookie",
      ".id,name,shared-users,rate-limit,session-timeout",
      ".id,name",
    ];

    Object? lastError;
    for (final fields in attempts) {
      try {
        final rows = await MikrotikClient.printData(
          commands: ["/ip/hotspot/user/profile/print"],
          fields: fields,
          tag: "hotspot_profiles",
        );
        final profiles = rows
            .whereType<Map>()
            .map(HotspotProfile.parse)
            .where((profile) => profile.name.isNotEmpty)
            .toList();
        return AppResponse(status: true, message: "done", data: profiles);
      } catch (e) {
        lastError = e;
      }
    }

    return AppResponse(
      status: false,
      message: _friendlyError(lastError, "تعذّر قراءة باقات Hotspot"),
      data: const [],
    );
  }

  /// إنشاء باقة Hotspot جديدة (shared-users + تحديد سرعة).
  static Future<AppResponse<void>> addProfile({
    required String name,
    String sharedUsers = "1",
    String rateLimit = "",
    String sessionTimeout = "",
  }) async {
    try {
      await MikrotikClient.addData(
        command: "/ip/hotspot/user/profile/add",
        data: {
          "name": name,
          "shared-users": sharedUsers,
          if (rateLimit.trim().isNotEmpty) "rate-limit": rateLimit.trim(),
          if (sessionTimeout.trim().isNotEmpty) "session-timeout": sessionTimeout.trim(),
        },
        tag: "hotspot_profile_add",
      );
      return AppResponse(status: true, message: "done");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<List<HotspotServer>>> printServers() async {
    const attempts = [
      ".id,name,interface,address-pool,profile,html-directory,login-by,dns-name,addresses-per-mac,disabled",
      ".id,name,interface,address-pool,profile,html-directory,disabled",
      ".id,name,interface,profile",
    ];

    Object? lastError;
    for (final fields in attempts) {
      try {
        final rows = await MikrotikClient.printData(
          commands: ["/ip/hotspot/print"],
          fields: fields,
          tag: "hotspot_servers",
        );
        final servers = rows
            .whereType<Map>()
            .map(HotspotServer.parse)
            .where((server) => server.name.isNotEmpty)
            .toList();
        return AppResponse(status: true, message: "done", data: servers);
      } catch (e) {
        lastError = e;
      }
    }

    return AppResponse(
      status: false,
      message: _friendlyError(lastError, "تعذّر قراءة خوادم Hotspot"),
      data: const [],
    );
  }

  /// تعيين مجلد صفحة الدخول لخادم معيّن (`/ip/hotspot/set html-directory=`).
  static Future<AppResponse<void>> setHtmlDirectory({
    required String serverName,
    required String directory,
  }) async {
    if (serverName.isEmpty || directory.isEmpty) {
      return AppResponse(status: false, message: "بيانات ناقصة (اسم الخادم أو المجلد)");
    }
    try {
      await MikrotikClient.fetch(
        command: ["/ip/hotspot/set", "=numbers=$serverName", "=html-directory=$directory"],
        customTag: "hotspot_set_html_dir",
      );
      return AppResponse(status: true, message: "done");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // ==================== صفحة الدخول (رفع ملفات) ====================

  /// رفع ملفات صفحة الدخول إلى مجلد الراوتر عبر FTP.
  ///
  /// يتطلب تفعيل خدمة FTP على الراوتر (`/ip service enable ftp`).
  /// [directory] هو مجلد صفحة الدخول على الراوتر (افتراضيًا `hotspot`).
  static Future<AppResponse<LoginUploadResult>> uploadLoginPage({
    required List<HotspotLoginFile> files,
    String directory = "hotspot",
    void Function(int done, int total)? onProgress,
  }) async {
    if (files.isEmpty) {
      return AppResponse(status: false, message: "لم يتم تحديد أي ملف للرفع");
    }

    final folder = directory.trim().isEmpty ? "hotspot" : directory.trim().replaceAll('/', '');
    final uploaded = <String>[];
    final failed = <String, String>{};

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        await MikrotikClient.ftpUploadFile(
          fileName: "$folder/${file.fileName}",
          bytes: file.bytesForUpload,
        );
        uploaded.add(file.fileName);
      } catch (e) {
        failed[file.fileName] = _friendlyError(e, "فشل الرفع");
      }
      onProgress?.call(i + 1, files.length);
    }

    if (uploaded.isEmpty) {
      return AppResponse(
        status: false,
        message: "تعذّر رفع الملفات.\n"
            "تأكد من تفعيل خدمة FTP على الراوتر (/ip service enable ftp) "
            "ومن صلاحيات الحساب، ومن وجود مجلد $folder في ذاكرة الراوتر.",
        data: LoginUploadResult(uploaded: uploaded, failed: failed),
      );
    }

    return AppResponse(
      status: true,
      message: failed.isEmpty
          ? "تم رفع ${uploaded.length} ملفًا إلى مجلد $folder"
          : "تم رفع ${uploaded.length} ملفًا، وفشل ${failed.length}",
      data: LoginUploadResult(uploaded: uploaded, failed: failed),
    );
  }

  static String _friendlyError(Object? error, String fallback) {
    final text = error?.toString().toLowerCase() ?? "";
    if (text.isEmpty) return fallback;
    if (text.contains('no such command') || text.contains('no such menu')) {
      return "حزمة Hotspot غير مفعّلة على هذا الراوتر (Package: hotspot).";
    }
    if (text.contains('permission') || text.contains('not enough')) {
      return "صلاحيات الحساب لا تسمح بهذا الأمر (policy: write/read مطلوبة).";
    }
    if (text.contains('timeout') || text.contains('timed out')) {
      return "انتهت مدة الاتصال بالراوتر — أعد المحاولة.";
    }
    return error.toString();
  }
}

/// نتيجة إضافة دفعة قسائم.
class HotspotBulkResult {
  final int added;
  final List<String> failed;
  final int total;

  const HotspotBulkResult({
    required this.added,
    required this.failed,
    required this.total,
  });
}

/// نتيجة رفع ملفات صفحة الدخول.
class LoginUploadResult {
  final List<String> uploaded;
  final Map<String, String> failed;

  const LoginUploadResult({required this.uploaded, required this.failed});
}
