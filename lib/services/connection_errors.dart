/// ترجمة أخطاء الاتصال بالراوتر إلى رسائل عربية واضحة + أدوات تحقق من مدخلات الدخول.
///
/// منطق نقي بالكامل (لا اتصال شبكة ولا واجهة) ⇒ قابل للاختبار مباشرة.
class ConnectionErrors {
  const ConnectionErrors._();

  /// المنفذ الافتراضي لواجهة API العادية في RouterOS.
  static const int defaultPort = 8728;

  /// منفذ واجهة API المشفّرة (api-ssl).
  static const int securePort = 8729;

  /// الأرقام العربية-الهندية (٠..٩) والفارسية الممتدة (۰..۹) ← أرقام لاتينية.
  static const int _arabicIndicStart = 0x0660;
  static const int _extendedArabicStart = 0x06F0;

  /// يحوّل المنفذ المكتوب إلى رقم صالح، ويدعم الأرقام العربية.
  ///
  /// يُرجع `null` إذا كانت الصيغة غير مفهومة أو خارج المدى 1..65535
  /// (لا تخمين — نفس منهج «استبعاد غير المفهوم» المعتمد في المشروع).
  static int? parsePort(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return null;

    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= _arabicIndicStart && rune <= _arabicIndicStart + 9) {
        buffer.writeCharCode(0x30 + (rune - _arabicIndicStart));
      } else if (rune >= _extendedArabicStart && rune <= _extendedArabicStart + 9) {
        buffer.writeCharCode(0x30 + (rune - _extendedArabicStart));
      } else {
        buffer.writeCharCode(rune);
      }
    }

    final value = int.tryParse(buffer.toString());
    if (value == null || value < 1 || value > 65535) return null;
    return value;
  }

  /// هل المنفذ منفذ api-ssl؟ (8729 ⇒ اتصال TLS)
  static bool isSecurePort(int port) => port == securePort;

  /// رسالة عربية مفهومة لأي خطأ يظهر أثناء الدخول/الاتصال.
  static String describe(Object? error) {
    final raw = (error ?? '').toString().trim();
    final text = raw.toLowerCase();

    if (text.isEmpty) {
      return 'فشل غير معروف أثناء الاتصال بالراوتر.';
    }

    // 1) صلاحية الشبكة (INTERNET) غير ممنوحة للتطبيق
    if (text.contains('permission denied') ||
        text.contains('eacces') ||
        text.contains('errno = 13') ||
        text.contains('access denied')) {
      return 'التطبيق لا يملك صلاحية الاتصال بالشبكة. أعد تثبيت أحدث إصدار من التطبيق، '
          'أو فعّل «الشبكة» من إعدادات صلاحيات التطبيق في الجوال.';
    }

    // 2) اسم المستخدم أو كلمة المرور
    if (text.contains('invalid user name or password') ||
        text.contains('invalid password') ||
        text.contains('invalid user')) {
      return 'اسم المستخدم أو كلمة المرور غير صحيحة.';
    }
    if (text.contains('legacy login failed')) {
      return 'فشل تسجيل الدخول (بروتوكول قديم). تحقق من اسم المستخدم وكلمة المرور، '
          'ومن أن الراوتر يسمح بالدخول من هذا الجهاز.';
    }

    // 3) الصلاحيات داخل الراوتر
    if (text.contains('not enough permissions') ||
        text.contains('no permission') ||
        text.contains('not permitted')) {
      return 'المستخدم متصل بنجاح لكن صلاحياته غير كافية. استخدم مستخدمًا بمجموعة full.';
    }

    // 4) رفض الاتصال (الخدمة مقفلة أو المنفذ خاطئ)
    if (text.contains('connection refused') || text.contains('errno = 111')) {
      return 'الراوتر رفض الاتصال. تأكد من تفعيل خدمة API في الراوتر '
          '(/ip service enable api) ومن صحة المنفذ (الافتراضي 8728).';
    }

    // 5) لا يمكن الوصول للشبكة/الراوتر
    if (text.contains('network is unreachable') ||
        text.contains('no route to host') ||
        text.contains('host unreachable') ||
        text.contains('failed host lookup') ||
        text.contains('errno = 101') ||
        text.contains('errno = 113')) {
      return 'لا يمكن الوصول إلى الراوتر. تأكد من أن الجوال متصل بشبكة الراوتر '
          'ومن صحة عنوان IP.';
    }

    // 6) انتهاء المهلة
    if (text.contains('timed out') || text.contains('timeout')) {
      return 'انتهت مهلة الاتصال. تحقق من عنوان IP والمنفذ، وأن الراوتر متصل بالكهرباء '
          'ومن أن خدمة API مفعّلة.';
    }

    // 7) مشاكل TLS/الشهادة
    if (text.contains('handshake') ||
        text.contains('certificate') ||
        text.contains('tls') ||
        text.contains('ssl')) {
      return 'فشل الاتصال المشفّر (SSL). جرّب المنفذ 8728 بدون تشفير، '
          'أو تأكد من تفعيل api-ssl على المنفذ 8729.';
    }

    // 8) انقطاع أثناء العملية
    if (text.contains('broken pipe') ||
        text.contains('connection reset') ||
        text.contains('socket is not open') ||
        text.contains('empty socket')) {
      return 'انقطع الاتصال بالراوتر أثناء العملية. أعد المحاولة.';
    }

    // 9) غير معروف ⇒ نُظهر النص الأصلي لتسهيل التشخيص
    return 'تعذّر الاتصال بالراوتر: $raw';
  }
}
