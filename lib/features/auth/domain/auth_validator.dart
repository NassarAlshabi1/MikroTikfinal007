class AuthValidator {
  AuthValidator._();

  static String? validateLocal({
    required String host,
    required String username,
    required String port,
  }) {
    if (host.trim().isEmpty || username.trim().isEmpty) {
      return 'الرجاء إدخال IP واسم المستخدم';
    }
    return _validatePort(port);
  }

  static String? validateRemote({
    required String host,
    required String username,
    required String password,
    required String port,
  }) {
    if (host.trim().isEmpty) return 'الرجاء إدخال عنوان الخادم البعيد';
    if (username.trim().isEmpty || password.isEmpty) {
      return 'الرجاء إدخال اسم المستخدم وكلمة المرور للاتصال البعيد';
    }
    if (RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(host.trim())) {
      return 'الرجاء إدخال اسم النطاق (Domain) وليس عنوان IP';
    }
    return _validatePort(port);
  }

  static String? _validatePort(String value) {
    final port = int.tryParse(value.trim());
    if (port == null || port < 1 || port > 65535) {
      return 'رقم المنفذ يجب أن يكون بين 1 و 65535';
    }
    return null;
  }
}
