import 'dart:async';
import 'dart:io';

import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MikrotikCredentialsMissingException implements Exception {
  final String message;
  MikrotikCredentialsMissingException(this.message);

  @override
  String toString() => 'MikrotikCredentialsMissingException: $message';
}

class MikrotikConnectionException implements Exception {
  final String message;
  final dynamic originalException;
  MikrotikConnectionException(this.message, [this.originalException]);

  @override
  String toString() => 'MikrotikConnectionException: $message';
}

class MikrotikConnector {
  /// زمن المهلة للاتصال (15 ثانية بدلاً من 5)
  static const Duration _connectionTimeout = Duration(seconds: 15);

  /// الاتصال بجهاز MikroTik.
  ///
  /// يمكن تمرير بيانات الجلسة مباشرة من شاشة الدخول، أو تركها فارغة
  /// لاستخدام القيم المحفوظة في SharedPreferences للشاشات اللاحقة.
  static Future<RouterOSClient> connect({
    String? address,
    String? username,
    String? password,
    int? port,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ip = address ?? prefs.getString('ip');
    final user = username ?? prefs.getString('user');
    final pass = password ?? prefs.getString('pass');
    final savedPort = prefs.getString('port');
    final resolvedPort =
        port ?? (savedPort == null ? 8728 : int.tryParse(savedPort));

    if (resolvedPort == null) {
      throw MikrotikCredentialsMissingException(
        'رقم المنفذ غير صالح: $savedPort',
      );
    }

    // التحقق من وجود البيانات المطلوبة
    if (ip == null || ip.trim().isEmpty) {
      throw MikrotikCredentialsMissingException(
        'عنوان IP غير محدد. الرجاء إدخال عنوان الراوتر.',
      );
    }
    if (user == null || user.trim().isEmpty) {
      throw MikrotikCredentialsMissingException('اسم المستخدم غير محدد.');
    }
    if (pass == null) {
      throw MikrotikCredentialsMissingException('كلمة المرور غير محددة.');
    }

    // التحقق من صحة المنفذ
    if (resolvedPort < 1 || resolvedPort > 65535) {
      throw MikrotikCredentialsMissingException(
        'رقم المنفذ غير صالح: $resolvedPort',
      );
    }

    // تحديد ما إذا كان الاتصال يستخدم SSL/TLS (المنفذ 8729)
    final bool useSsl = (resolvedPort == 8729);

    final client = RouterOSClient(
      address: ip.trim(),
      user: user.trim(),
      password: pass,
      port: resolvedPort,
      verbose: false,
      useSsl: useSsl,
    );

    try {
      final bool loggedIn = await client.login().timeout(_connectionTimeout);
      if (loggedIn) {
        return client;
      }
      throw MikrotikConnectionException(
        'رفض الراوتر جلسة API. تحقق من اسم المستخدم وكلمة المرور، '
        'وتفعيل خدمة API والمنفذ $resolvedPort والسماح بعنوان جهازك.',
      );
    } on TimeoutException {
      client.close();
      throw MikrotikConnectionException(
        'انتهت مهلة الاتصال (${_connectionTimeout.inSeconds} ثانية).\n'
        'تأكد من:\n'
        '• أن الراوتر يعمل ومتوصل بالشبكة\n'
        '• أن المنفذ $resolvedPort مفتوح وصحيح\n'
        '• أن جهازك متصل بنفس الشبكة (اتصال محلي)',
      );
    } on SocketException catch (e) {
      client.close();
      throw MikrotikConnectionException(
        'تعذر الوصول إلى الراوتر على العنوان $ip:$resolvedPort.\n'
        'الخطأ: ${e.message}\n'
        'تأكد من أن الراوتر يعمل وأن المنفذ $resolvedPort مفتوح.',
        e,
      );
    } on HandshakeException catch (e) {
      client.close();
      throw MikrotikConnectionException(
        'فشل الاتصال الآمن (SSL/TLS).\n'
        'تأكد من أن الراوتر يدعم الاتصال المشفر على المنفذ $resolvedPort.',
        e,
      );
    } catch (e) {
      client.close();
      if (e is MikrotikCredentialsMissingException ||
          e is MikrotikConnectionException) {
        rethrow;
      }
      throw MikrotikConnectionException(
        'حدث خطأ غير متوقع أثناء الاتصال: ${e.toString()}',
        e,
      );
    }
  }
}
