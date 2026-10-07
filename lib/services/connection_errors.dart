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

  /// هل المنفذ هو المنفذ القياسي لـ api-ssl؟ (8729 ⇒ TLS افتراضيًا)
  ///
  /// ملاحظة: التطبيق يدعم **أي منفذ** (1300 مثلًا) عبر خيار SSL يدوي،
  /// فهذه الدالة تُستخدم فقط لاقتراح الوضع الافتراضي.
  static bool isSecurePort(int port) => port == securePort;

  /// يحلّل ما يكتبه المستخدم في خانة العنوان، ويدعم صيغة `IP:PORT` معًا.
  ///
  /// - `192.168.88.1`        ⇒ host=192.168.88.1 , port=null
  /// - `192.168.88.1:1300`   ⇒ host=192.168.88.1 , port=1300
  /// - `[fe80::1]:1300`      ⇒ host=fe80::1      , port=1300 (IPv6 بين قوسين)
  /// - `fe80::1`             ⇒ host=fe80::1      , port=null (IPv6 بلا قوسين)
  /// - أي جزء بعد `:` غير رقمي ⇒ يُعامَل كله كعنوان (بلا تخمين)
  static HostPort splitHostPort(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return const HostPort(host: '', port: null);

    // IPv6 بين قوسين مربعين: [::1] أو [::1]:1300
    if (text.startsWith('[')) {
      final close = text.indexOf(']');
      if (close > 0) {
        final host = text.substring(1, close);
        final rest = text.substring(close + 1);
        if (rest.startsWith(':')) {
          final port = parsePort(rest.substring(1));
          if (port != null) return HostPort(host: host, port: port);
        } else if (rest.isEmpty) {
          return HostPort(host: host, port: null);
        }
        return HostPort(host: text, port: null);
      }
      return HostPort(host: text, port: null);
    }

    // IPv6 بدون قوسين (أكثر من نقطتين) ⇒ بلا منفذ
    if (':'.allMatches(text).length > 1) {
      return HostPort(host: text, port: null);
    }

    final splitIndex = text.indexOf(':');
    if (splitIndex > 0) {
      final maybePort = parsePort(text.substring(splitIndex + 1));
      if (maybePort != null) {
        return HostPort(host: text.substring(0, splitIndex).trim(), port: maybePort);
      }
    }
    return HostPort(host: text, port: null);
  }

  /// رسالة عربية مفهومة لأي خطأ يظهر أثناء الدخول/الاتصال.
  ///
  /// [port] يُذكر في الرسالة ليسهل تشخيص المنافذ المخصّصة (مثل 1300).
  static String describe(Object? error, {int? port}) {
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
      final at = port == null ? '' : ' على المنفذ $port';
      final hint = port == null
          ? '/ip service enable api'
          : '/ip service set api port=$port disabled=no';
      return 'الراوتر رفض الاتصال$at. تأكد من أن خدمة API مفعّلة على هذا المنفذ '
          'في الراوتر ($hint) ومن صحة المنفذ في التطبيق.';
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
      final at = port == null ? 'المنفذ' : 'المنفذ $port';
      return 'انتهت مهلة الاتصال. تحقق من عنوان IP و$at، وأن الراوتر متصل بالكهرباء '
          'ومن أن خدمة API مفعّلة عليه.';
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

/// نتيجة تحليل خانة العنوان إلى مضيف ومنفذ اختياري.
class HostPort {
  final String host;
  final int? port;

  const HostPort({required this.host, this.port});

  @override
  String toString() => port == null ? host : '$host:$port';
}
