import 'mikrotik_service_mode.dart';

/// يبني أوامر إنشاء المستخدمين وفق نوع الخدمة بدلاً من تكرارها في الشاشات.
///
/// في Hotspot المحلي في RouterOS v6 يكون المسار `/ip/hotspot/user/add`،
/// واسم المستخدم هو `name` والبروفايل هو `profile`. أما `shared-users`
/// فهو خاص بـ Hotspot User Profile وليس خاصاً بالمستخدم نفسه، لذلك لا
/// يُرسل ضمن أمر إضافة المستخدم.
class MikrotikCardCommands {
  MikrotikCardCommands._();

  static List<String> addUser({
    required MikrotikServiceMode mode,
    required String username,
    required String password,
    required String profile,
    required String sharedUsers,
    required bool isVersion7OrNewer,
    required String customer,
  }) {
    switch (mode) {
      case MikrotikServiceMode.hotspot:
        return _hotspotUserAdd(
          username: username,
          password: password,
          profile: profile,
        );
      case MikrotikServiceMode.userManager:
        return _userManagerUserAdd(
          username: username,
          password: password,
          sharedUsers: sharedUsers,
          isVersion7OrNewer: isVersion7OrNewer,
          customer: customer,
        );
    }
  }

  static List<String> userManagerActivateProfile({
    required String customer,
    required String username,
    required String profile,
  }) =>
      [
        '/tool/user-manager/user/create-and-activate-profile',
        '=customer=$customer',
        '=numbers=$username',
        '=profile=$profile',
      ];

  static List<String> _hotspotUserAdd({
    required String username,
    required String password,
    required String profile,
  }) =>
      [
        '/ip/hotspot/user/add',
        '=name=$username',
        if (password.isNotEmpty) '=password=$password',
        '=profile=$profile',
      ];

  static List<String> _userManagerUserAdd({
    required String username,
    required String password,
    required String sharedUsers,
    required bool isVersion7OrNewer,
    required String customer,
  }) =>
      [
        '/tool/user-manager/user/add',
        '=username=$username',
        '=password=$password',
        '=shared-users=$sharedUsers',
        if (!isVersion7OrNewer) '=customer=$customer',
      ];
}
