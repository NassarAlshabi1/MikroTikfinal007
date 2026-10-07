import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// عميل FTP مبسّط (رفع ملفات فقط) للتعامل مع خدمة FTP في RouterOS.
///
/// يُستخدم لرفع ملف نسخة احتياطية من الهاتف إلى ذاكرة الراوتر ثم استعادته.
/// يجب تفعيل خدمة FTP على الراوتر: `/ip service enable ftp`
class FtpClient {
  static Future<void> upload({
    required String host,
    required String user,
    required String password,
    required String remoteName,
    required List<int> bytes,
    int port = 21,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    Socket? control;
    Socket? data;
    _FtpReader? reader;
    try {
      control = await Socket.connect(host, port, timeout: timeout);
      reader = _FtpReader(control);

      await reader.expect(const [220], timeout);
      await _command(control, reader, 'USER $user', const [331, 230], timeout);
      await _command(control, reader, 'PASS $password', const [230], timeout);
      await _command(control, reader, 'TYPE I', const [200], timeout);

      final pasvReply = await _command(control, reader, 'PASV', const [227], timeout);
      final passiveAddress = _parsePassiveAddress(pasvReply);
      data = await Socket.connect(passiveAddress.$1, passiveAddress.$2, timeout: timeout);

      await _command(control, reader, 'STOR $remoteName', const [125, 150], timeout);

      data.add(bytes);
      await data.flush();
      await data.close();
      data = null;

      await reader.expect(const [226, 250], timeout);
      try {
        await _command(control, reader, 'QUIT', const [221], timeout);
      } catch (_) {
        // لا يهم إن فشل QUIT
      }
    } finally {
      data?.destroy();
      control?.destroy();
      reader?.dispose();
    }
  }

  static Future<String> _command(
    Socket socket,
    _FtpReader reader,
    String command,
    List<int> expectedCodes,
    Duration timeout,
  ) async {
    socket.write('$command\r\n');
    await socket.flush();
    final reply = await reader.next(timeout);
    final code = int.tryParse(reply.length >= 3 ? reply.substring(0, 3) : '') ?? 0;
    if (!expectedCodes.contains(code)) {
      throw Exception('FTP ($command): $reply');
    }
    return reply;
  }

  static (String, int) _parsePassiveAddress(String reply) {
    final match = RegExp(r'\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)').firstMatch(reply);
    if (match == null) {
      throw Exception('FTP PASV غير مفهوم: $reply');
    }
    final host = '${match.group(1)}.${match.group(2)}.${match.group(3)}.${match.group(4)}';
    final port = (int.parse(match.group(5)!) << 8) + int.parse(match.group(6)!);
    return (host, port);
  }
}

/// قارئ ردود FTP: يجمع الأسطر حتى اكتمال الرد (سطر يبدأ بثلاثة أرقام ثم مسافة).
class _FtpReader {
  final List<String> _current = [];
  final List<String> _ready = [];
  Completer<String>? _waiter;
  StreamSubscription<String>? _subscription;
  String? _error;
  bool _closed = false;

  _FtpReader(Socket socket) {
    _subscription = socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      _onLine,
      onError: (Object error) {
        _error = error.toString();
        _failWaiting();
      },
      onDone: () {
        _closed = true;
        _failWaiting();
      },
      cancelOnError: false,
    );
  }

  void _onLine(String line) {
    _current.add(line);
    if (RegExp(r'^\d{3} ').hasMatch(line)) {
      final response = _current.join('\n');
      _current.clear();
      final waiter = _waiter;
      _waiter = null;
      if (waiter != null && !waiter.isCompleted) {
        waiter.complete(response);
      } else {
        _ready.add(response);
      }
    }
  }

  void _failWaiting() {
    final waiter = _waiter;
    _waiter = null;
    if (waiter != null && !waiter.isCompleted) {
      waiter.completeError(Exception(_error ?? 'انقطع الاتصال بخدمة FTP'));
    }
  }

  Future<String> next(Duration timeout) {
    if (_ready.isNotEmpty) {
      return Future.value(_ready.removeAt(0));
    }
    if (_error != null) {
      return Future.error(Exception(_error!));
    }
    if (_closed) {
      return Future.error(Exception('انقطع الاتصال بخدمة FTP'));
    }
    final completer = Completer<String>();
    _waiter = completer;
    return completer.future.timeout(timeout, onTimeout: () {
      if (identical(_waiter, completer)) _waiter = null;
      throw Exception('انتهت مهلة الرد من خدمة FTP');
    });
  }

  Future<String> expect(List<int> expectedCodes, Duration timeout) async {
    final reply = await next(timeout);
    final code = int.tryParse(reply.length >= 3 ? reply.substring(0, 3) : '') ?? 0;
    if (!expectedCodes.contains(code)) {
      throw Exception('FTP: $reply');
    }
    return reply;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
