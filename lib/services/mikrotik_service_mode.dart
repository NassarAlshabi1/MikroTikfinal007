/// نوع قاعدة المستخدمين التي يديرها التطبيق على جهاز MikroTik.
///
/// التطبيق موجّه افتراضياً إلى Hotspot المحلي في RouterOS v6؛ أبقينا
/// User Manager كخيار صريح للتوافق مع المشاريع القديمة التي تستخدم RADIUS.
enum MikrotikServiceMode {
  hotspot,
  userManager,
}

extension MikrotikServiceModeLabel on MikrotikServiceMode {
  String get displayName {
    switch (this) {
      case MikrotikServiceMode.hotspot:
        return 'Hotspot';
      case MikrotikServiceMode.userManager:
        return 'User Manager';
    }
  }
}
