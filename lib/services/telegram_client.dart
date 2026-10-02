import 'dart:convert';
import 'dart:io';

import '../models/response.dart';

/// عميل بسيط لـ Telegram Bot API (بدون حزم إضافية).
///
/// يعمل على Android / iOS / Desktop لأن الاتصال يتم عبر dart:io.
class TelegramClient {
  static Future<Map<String, dynamic>> _call(
    String token,
    String method,
    Map<String, dynamic> payload,
  ) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final uri = Uri.parse('https://api.telegram.org/bot$token/$method');
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.add(utf8.encode(jsonEncode(payload)));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{"ok": false, "description": body};
    } finally {
      client.close(force: true);
    }
  }

  /// إرسال رسالة نصية (يدعم وسوم HTML البسيطة مثل <b> و <code>).
  static Future<AppResponse<void>> sendMessage({
    required String token,
    required String chatId,
    required String text,
  }) async {
    if (token.trim().isEmpty || chatId.trim().isEmpty) {
      return AppResponse(status: false, message: "لم يتم إعداد التوكن أو معرّف المحادثة");
    }

    try {
      final result = await _call(token.trim(), 'sendMessage', {
        'chat_id': chatId.trim(),
        'text': text,
        'parse_mode': 'HTML',
        'disable_web_page_preview': true,
      });

      if (result['ok'] == true) {
        return AppResponse(status: true, message: "تم إرسال الرسالة إلى Telegram");
      }
      return AppResponse(
        status: false,
        message: result['description']?.toString() ?? "فشل إرسال الرسالة",
      );
    } catch (e) {
      return AppResponse(status: false, message: _friendlyError(e));
    }
  }

  /// التحقق من التوكن وإرجاع اسم البوت.
  static Future<AppResponse<String>> testConnection(String token) async {
    if (token.trim().isEmpty) {
      return AppResponse(status: false, message: "أدخل توكن البوت أولًا");
    }

    try {
      final result = await _call(token.trim(), 'getMe', const {});
      if (result['ok'] == true && result['result'] is Map) {
        final username = (result['result'] as Map)['username']?.toString() ?? "";
        return AppResponse(
          status: true,
          message: "تم الاتصال بالبوت بنجاح",
          data: username,
        );
      }
      return AppResponse(
        status: false,
        message: result['description']?.toString() ?? "توكن غير صالح",
      );
    } catch (e) {
      return AppResponse(status: false, message: _friendlyError(e));
    }
  }

  static String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('Failed host lookup')) {
      return "تعذّر الاتصال بخوادم Telegram. تحقق من اتصال الإنترنت.";
    }
    return text;
  }
}
