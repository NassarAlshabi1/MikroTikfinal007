import '../models/response.dart';
import '../services/expired_users_classifier.dart';
import '../services/mikrotik_client.dart';
import '../services/mikrotik_duration.dart';

export '../services/expired_users_classifier.dart';

/// مسارات User Manager في RouterOS — تختلف جذريًا بين v6 و v7.
///
/// | العنصر | RouterOS v6 | RouterOS v7 |
/// | --- | --- | --- |
/// | المستخدمون | `/tool/user-manager/user` | `/user-manager/user` |
/// | الباقات | `/tool/user-manager/profile` | `/user-manager/profile` |
/// | القيود | `/tool/user-manager/profile/limitation` | `/user-manager/limitation` |
/// | ربط القيود | `/tool/user-manager/profile/profile-limitation` | `/user-manager/profile-limitation` |
/// | جلسات | `/tool/user-manager/session` | `/user-manager/session` |
/// | باقات المستخدم | (غير موجود) | `/user-manager/user-profile` |
class UserManagerPaths {
  final String users;
  final String usersRemove;
  final String profiles;
  final String limitations;
  final String profileLimitation;
  final String userProfiles;
  final String sessions;
  final String sessionsRemove;

  const UserManagerPaths({
    required this.users,
    required this.usersRemove,
    required this.profiles,
    required this.limitations,
    required this.profileLimitation,
    required this.userProfiles,
    required this.sessions,
    required this.sessionsRemove,
  });

  static const UserManagerPaths v6 = UserManagerPaths(
    users: "/tool/user-manager/user/print",
    usersRemove: "/tool/user-manager/user/remove",
    profiles: "/tool/user-manager/profile/print",
    limitations: "/tool/user-manager/profile/limitation/print",
    profileLimitation: "/tool/user-manager/profile/profile-limitation/print",
    userProfiles: "",
    sessions: "/tool/user-manager/session/print",
    sessionsRemove: "/tool/user-manager/session/remove",
  );

  static const UserManagerPaths v7 = UserManagerPaths(
    users: "/user-manager/user/print",
    usersRemove: "/user-manager/user/remove",
    profiles: "/user-manager/profile/print",
    limitations: "/user-manager/limitation/print",
    profileLimitation: "/user-manager/profile-limitation/print",
    userProfiles: "/user-manager/user-profile/print",
    sessions: "/user-manager/session/print",
    sessionsRemove: "/user-manager/session/remove",
  );

  bool get supportsUserProfiles => userProfiles.isNotEmpty;
}

/// الفحص الذكي وحذف المستخدمين المنتهين.
///
/// يقارن المدة المستهلكة (`uptime-used`) مع حد الباقة (`limit-uptime`) ويحذف فقط
/// من استهلك مدته كاملة، مع دعم إشارات الراوتر الأصلية:
/// - **v6**: `!actual-profile` مع `uptime-used > 0` (الباقة أُزيلت بعد الانتهاء).
/// - **v7**: `user-profile.state = used`.
class ExpiredUsersApi {
  /// المسارات التي نجحت فعليًا في آخر فحص (لتفادي الاعتماد على كشف الإصدار فقط).
  static UserManagerPaths? _workingPaths;

  static UserManagerPaths get activePaths =>
      _workingPaths ?? (MikrotikClient.version == 7 ? UserManagerPaths.v7 : UserManagerPaths.v6);

  /// ترتيب المحاولة: المسارات المتوافقة مع الإصدار المكتشف ثم الأخرى.
  static List<UserManagerPaths> get _pathsToTry {
    if (MikrotikClient.version == 7) {
      return [UserManagerPaths.v7, UserManagerPaths.v6];
    }
    return [UserManagerPaths.v6, UserManagerPaths.v7];
  }

  /// حقول المستخدم **مفصولة لكل إصدار** لأن الأسماء مختلفة:
  /// - v6: `username`, `actual-profile`, `customer`, `uptime-used` (لا يوجد `name`).
  /// - v7: `name`, `group`, `profile` (لا يوجد `username`/`uptime-used` غالبًا).
  ///
  /// الترتيب من الأغنى إلى الأبسط: لو رفض الراوتر أي حقل غير معروف ننزل للمحاولة التالية.
  static List<String> _userFieldsFor(UserManagerPaths paths) {
    if (paths.supportsUserProfiles) {
      // RouterOS v7
      return const [
        ".id,name,group,profile,uptime-used,download-used,upload-used,last-seen",
        ".id,name,group,profile",
        ".id,name,group",
        ".id,name",
      ];
    }
    // RouterOS v6
    return const [
      ".id,username,actual-profile,customer,uptime-used,download-used,upload-used,last-seen,limit-uptime,limit-bytes-total",
      ".id,username,actual-profile,customer,uptime-used,download-used,upload-used,last-seen",
      ".id,username,actual-profile,uptime-used",
      ".id,username",
      ".id",
    ];
  }

  // ================== الفحص ==================

  static Future<AppResponse<ExpiredUsersScanResult>> scan() async {
    try {
      final fetchResult = await _fetchUsers();
      if (!fetchResult.ok) {
        return AppResponse(status: false, message: fetchResult.message);
      }

      final users = fetchResult.rows;
      final paths = fetchResult.paths;

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
            routerVersion: MikrotikClient.version,
          ),
        );
      }

      _workingPaths = paths;

      final limitsByProfile = await _fetchProfileLimits(paths);
      final statesByUser = await _fetchUserProfileStates(paths);

      final result = ExpiredUsersClassifier.classify(
        users: users,
        limitsByProfile: limitsByProfile,
        statesByUser: statesByUser,
        routerVersion: MikrotikClient.version == 7 ? 7 : 6,
      );

      return AppResponse(status: true, message: "done", data: result);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // ================== الحذف ==================

  /// حذف المستخدمين المحددين مع تنظيف الجلسات وباقات المستخدم (كما في سكربتات MikroTik المعتمدة).
  static Future<AppResponse<int>> deleteUsers(List<ExpiredUserCandidate> users) async {
    if (users.isEmpty) {
      return AppResponse(status: false, message: "لا يوجد مستخدمون محددون للحذف");
    }

    final paths = activePaths;
    final usernames = users.map((user) => user.username).where((name) => name.isNotEmpty).toSet();
    var deleted = 0;
    final failed = <String>[];

    // (1) إزالة جلسات المستخدمين (يمنع بقاء جلسات معلّقة)
    await _removeRelated(
      listPath: paths.sessions,
      removePath: paths.sessionsRemove,
      usernames: usernames,
      userKey: "user",
    );

    // (2) v7: إزالة باقات المستخدم (user-profile) لتفادي بقايا معلّقة
    if (paths.supportsUserProfiles) {
      await _removeRelated(
        listPath: paths.userProfiles,
        removePath: paths.userProfiles.replaceAll("/print", "/remove"),
        usernames: usernames,
        userKey: "user",
      );
    }

    // (3) حذف المستخدمين أنفسهم — بثلاث طبقات متدرجة من الأمان
    const chunkSize = 50;
    for (var start = 0; start < users.length; start += chunkSize) {
      final chunk = users.sublist(
        start,
        (start + chunkSize) > users.length ? users.length : start + chunkSize,
      );
      final ids = chunk.map((user) => user.id).where((id) => id.isNotEmpty).toList();
      final names = chunk.map((user) => user.username).where((name) => name.isNotEmpty).toList();
      if (ids.isEmpty && names.isEmpty) continue;

      var removed = false;

      // (أ) numbers بقائمة `.id` مفصولة بفواصل — الطريقة المتحقَّق منها في v6 و v7
      if (ids.isNotEmpty) {
        try {
          await MikrotikClient.fetch(
            command: [paths.usersRemove, '=numbers=${ids.join(",")}'],
            customTag: "expired_remove_batch",
          );
          deleted += ids.length;
          removed = true;
        } catch (_) {
          removed = false;
        }
      }

      // (ب) numbers بقائمة أسماء المستخدمين — النمط المستخدم فعليًا في هذا التطبيق على v6
      if (!removed && names.isNotEmpty) {
        try {
          await MikrotikClient.fetch(
            command: [paths.usersRemove, '=numbers=${names.join(",")}'],
            customTag: "expired_remove_batch_names",
          );
          deleted += names.length;
          removed = true;
        } catch (_) {
          removed = false;
        }
      }

      // (ج) تراجع أخير: حذف فردي بالمعرّف (‎=.id=‎) — مدعوم أيضًا في v6
      if (!removed) {
        for (final user in chunk) {
          if (user.id.isEmpty) {
            failed.add(user.username);
            continue;
          }
          try {
            await MikrotikClient.removeById(command: paths.usersRemove, id: user.id);
            deleted++;
          } catch (_) {
            failed.add(user.username);
          }
        }
      }
    }

    if (deleted == 0) {
      return AppResponse(
        status: false,
        message: "تعذّر حذف المستخدمين. تحقق من أن حزمة user-manager مفعّلة وصلاحيات الحساب (policy: write).",
      );
    }

    return AppResponse(
      status: true,
      message: failed.isEmpty
          ? "تم حذف $deleted مستخدمًا منتهيًا"
          : "تم حذف $deleted مستخدمًا، وفشل حذف ${failed.length}",
      data: deleted,
    );
  }

  /// إزالة عناصر مرتبطة بمجموعة أسماء مستخدمين (جلسات / باقات مستخدم).
  static Future<void> _removeRelated({
    required String listPath,
    required String removePath,
    required Set<String> usernames,
    required String userKey,
  }) async {
    if (listPath.isEmpty || usernames.isEmpty) return;

    try {
      final rows = await MikrotikClient.printData(
        commands: [listPath],
        fields: ".id,$userKey",
        tag: "expired_related_list",
      );

      final ids = <String>[];
      for (final row in rows.whereType<Map>()) {
        final owner = row[userKey]?.toString() ?? "";
        final id = row[".id"]?.toString() ?? "";
        if (id.isNotEmpty && usernames.contains(owner)) ids.add(id);
      }

      const chunkSize = 50;
      for (var start = 0; start < ids.length; start += chunkSize) {
        final chunk = ids.sublist(
          start,
          (start + chunkSize) > ids.length ? ids.length : start + chunkSize,
        );
        try {
          await MikrotikClient.fetch(
            command: [removePath, '=numbers=${chunk.join(",")}'],
            customTag: "expired_remove_related",
          );
        } catch (_) {
          for (final id in chunk) {
            try {
              await MikrotikClient.removeById(command: removePath, id: id);
            } catch (_) {
              // نتجاهل فشل العنصر المرتبط ولا نُفشل عملية الحذف الأساسية
            }
          }
        }
      }
    } catch (_) {
      // بعض الإصدارات لا توفّر هذه القوائم — نكمل
    }
  }

  // ================== جلب البيانات ==================

  /// إرجاع نتيجة الجلب: نجاح؟ + رسالة الخطأ + الصفوف + المسارات المستخدمة فعليًا.
  static Future<({bool ok, String message, List<Map> rows, UserManagerPaths paths})>
      _fetchUsers() async {
    Object? lastError;
    var anyPathWorked = false;

    for (final paths in _pathsToTry) {
      for (final fields in _userFieldsFor(paths)) {
        try {
          final result = await MikrotikClient.printData(
            commands: [paths.users],
            fields: fields,
            tag: 'expired_users_scan',
          );
          anyPathWorked = true;
          return (ok: true, message: "", rows: result.whereType<Map>().toList(), paths: paths);
        } catch (e) {
          lastError = e;
          // خطأ "no such command" ← لا فائدة من تجربة حقول أخرى على نفس المسار
          final text = e.toString().toLowerCase();
          if (text.contains('no such command') ||
              text.contains('unknown command') ||
              text.contains('no such menu')) {
            break;
          }
        }
      }
      if (anyPathWorked) break;
    }

    return (
      ok: false,
      message: "تعذّر قراءة مستخدمي User Manager.\n"
          "تأكد من تفعيل حزمة user-manager على الراوتر وصلاحيات الحساب (read/write/api).\n"
          "(${lastError ?? "خطأ غير معروف"})",
      rows: <Map>[],
      paths: activePaths,
    );
  }

  /// حدود الباقات: من القيود وربطها بالباقات (v6: `profile/limitation`، v7: `limitation`).
  static Future<Map<String, ProfileLimit>> _fetchProfileLimits(UserManagerPaths paths) async {
    var profiles = <Map>[];
    var limitations = <Map>[];
    final links = <Map>[];

    try {
      profiles = (await MikrotikClient.printData(
        commands: [paths.profiles],
        fields: ".id,name,name-for-users,validity,price,limitation",
        tag: 'expired_profiles',
      ))
          .whereType<Map>()
          .toList();
    } catch (_) {
      try {
        profiles = (await MikrotikClient.printData(
          commands: [paths.profiles],
          tag: 'expired_profiles',
        ))
            .whereType<Map>()
            .toList();
      } catch (_) {
        profiles = [];
      }
    }

    try {
      limitations = (await MikrotikClient.printData(
        commands: [paths.limitations],
        fields: "name,owner,transfer-limit,uptime-limit,download-limit,upload-limit,group-name",
        tag: 'expired_limits',
      ))
          .whereType<Map>()
          .toList();
    } catch (_) {
      try {
        limitations = (await MikrotikClient.printData(
          commands: [paths.limitations],
          tag: 'expired_limits',
        ))
            .whereType<Map>()
            .toList();
      } catch (_) {
        limitations = [];
      }
    }

    try {
      links.addAll((await MikrotikClient.printData(
        commands: [paths.profileLimitation],
        fields: "profile,limitation",
        tag: 'expired_links',
      ))
          .whereType<Map>());
    } catch (_) {
      // جدول الربط غير متاح — يكفي القيد المباشر أو validity
    }

    return ExpiredUsersClassifier.buildProfileLimits(
      profiles: profiles,
      limitations: limitations,
      links: links,
    );
  }

  /// حالة الباقات لكل مستخدم (v7 فقط: `state=used` تعني انتهت).
  static Future<Map<String, String>> _fetchUserProfileStates(UserManagerPaths paths) async {
    final result = <String, String>{};
    if (!paths.supportsUserProfiles) return result;

    try {
      final rows = await MikrotikClient.printData(
        commands: [paths.userProfiles],
        fields: ".id,user,profile,state",
        tag: 'expired_states',
      );
      for (final row in rows.whereType<Map>()) {
        final user = row["user"]?.toString() ?? "";
        final state = row["state"]?.toString() ?? "";
        if (user.isNotEmpty && state.isNotEmpty) result[user] = state;
      }
    } catch (_) {
      // v6 أو إصدار لا يدعم user-profile
    }

    return result;
  }

  /// إعادة تعيين المسارات المخزّنة (يُستخدم عند تسجيل دخول راوتر آخر).
  static void resetPaths() => _workingPaths = null;
}

/// توافق خلفي بسيط: ملخّص نصي لعرضه في الواجهة.
extension ExpiredScanSummary on ExpiredUsersScanResult {
  String get versionLabel {
    switch (routerVersion) {
      case 7:
        return "RouterOS v7";
      case 6:
        return "RouterOS v6";
      default:
        return "إصدار غير محدد";
    }
  }

  String get summaryLabel {
    final buffer = StringBuffer("إجمالي: $totalUsers • مؤهل: ${exhausted.length} • لم يكمل: ${stillRunning.length}");
    if (unparsable > 0) buffer.write(" • غير قابل للتحليل: $unparsable");
    if (withoutLimits > 0) buffer.write(" • بلا حدود: $withoutLimits");
    return buffer.toString();
  }

  /// تنسيق مختصر للمدة لاستخدامه في الرسائل.
  static String durationLabel(Duration duration) => MikrotikDuration.format(duration);
}
