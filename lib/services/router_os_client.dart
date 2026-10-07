import 'dart:async';
// import 'dart:convert'; for utf8
import 'dart:io';

import 'package:charset/charset.dart';
import 'package:crypto/crypto.dart'; // مطلوبة من أجل Legacy Login (MD5)
import 'package:logger/logger.dart';

/// The `RouterOSClient` class handles the connection to a RouterOS device via a socket.
class RouterOSClient {
  final String address;
  String user;
  String password;
  bool useSsl;
  int port;
  bool verbose;
  SecurityContext? context;
  Duration? timeout;

  var logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  Socket? _socket;
  SecureSocket? _secureSocket;
  
  // تحسين 1: إدارة الـ Buffer بشكل آمن
  final List<int> _buffer = [];
  
  // تحسين 2: وحدة تحكم داخلية لنشر الجمل المكتملة فقط بدلاً من تعدد المستمعين
  late StreamController<List<String>> _sentenceController;
  StreamSubscription? _socketSubscription;

  RouterOSClient({
    required this.address,
    this.user = 'admin',
    this.password = '',
    this.useSsl = false,
    int? port,
    this.verbose = false,
    this.context,
    this.timeout,
  }) : port = port ?? (useSsl ? 8729 : 8728);

  Future<void> _openSocket() async {
    try {
      if (!verbose) {
        Logger.level = Level.off;
      }
      
      _sentenceController = StreamController<List<String>>.broadcast();
      _buffer.clear();

      // تطبيق الـ Timeout على الاتصال الأولي
      if (useSsl) {
        _secureSocket = await SecureSocket.connect(address, port, context: context, timeout: timeout);
        _socket = _secureSocket;
      } else {
        _socket = await Socket.connect(address, port, timeout: timeout);
      }
      
      _socket?.setOption(SocketOption.tcpNoDelay, true);
      logger.i("RouterOSClient socket connection opened.");

      // مستمع واحد دائم يعالج البيانات ويغذي الـ StreamController
      _socketSubscription = _socket!.listen(
        _handleIncomingData,
        onError: (e) {
          logger.e('Socket error: $e');
          close();
        },
        onDone: () {
          logger.i('Socket closed by remote host.');
          close();
        },
      );
    } on SocketException catch (e) {
      throw CreateSocketError(
        'Failed to connect to socket. Host: $address, port: $port. Error: ${e.message}',
      );
    }
  }

  /// يقرأ البيانات الخام ويحولها إلى جمل كاملة
  void _handleIncomingData(List<int> data) {
    _buffer.addAll(data);
    while (true) {
      var sentence = _tryReadSentence();
      if (sentence == null) break; // البيانات غير مكتملة، ننتظر الدفعة القادمة
      _sentenceController.add(sentence);
    }
  }

  /// يحاول قراءة جملة كاملة بدون العبث بالـ Buffer إلا إذا اكتملت
  List<String>? _tryReadSentence() {
    int offset = 0;
    List<String> sentence = [];

    while (true) {
      var lengthInfo = _decodeLength(_buffer, offset);
      if (lengthInfo == null) return null; // ليس هناك بايتات كافية لمعرفة الطول

      int length = lengthInfo.length;
      int bytesUsedForLength = lengthInfo.bytesUsed;

      if (length == 0) {
        // وصلنا لنهاية الجملة، الآن فقط نحذف ما قرأناه من الـ Buffer
        _buffer.removeRange(0, offset + bytesUsedForLength);
        return sentence;
      }

      if (_buffer.length < offset + bytesUsedForLength + length) {
        return null; // الكلمة لم تصل كاملة بعد
      }

      String word = windows1256.decode(
        _buffer.sublist(offset + bytesUsedForLength, offset + bytesUsedForLength + length),allowInvalid: true
      );
      sentence.add(word);
      offset += bytesUsedForLength + length;
    }
  }

  /// يفك تشفير طول الكلمة بأمان
  _LengthResult? _decodeLength(List<int> buffer, int offset) {
    if (buffer.length <= offset) return null;
    int b1 = buffer[offset];

    if (b1 < 0x80) {
      return _LengthResult(b1, 1);
    } else if (b1 < 0xC0) {
      if (buffer.length < offset + 2) return null;
      int b2 = buffer[offset + 1];
      return _LengthResult(((b1 << 8) | b2) - 0x8000, 2);
    } else if (b1 < 0xE0) {
      if (buffer.length < offset + 3) return null;
      int b2 = buffer[offset + 1];
      int b3 = buffer[offset + 2];
      return _LengthResult(((b1 << 16) | (b2 << 8) | b3) - 0xC00000, 3);
    } else if (b1 < 0xF0) {
      if (buffer.length < offset + 4) return null;
      int b2 = buffer[offset + 1];
      int b3 = buffer[offset + 2];
      int b4 = buffer[offset + 3];
      return _LengthResult(((b1 << 24) | (b2 << 16) | (b3 << 8) | b4) - 0xE0000000, 4);
    } else if (b1 == 0xF0) {
      if (buffer.length < offset + 5) return null;
      int b2 = buffer[offset + 1];
      int b3 = buffer[offset + 2];
      int b4 = buffer[offset + 3];
      int b5 = buffer[offset + 4];
      return _LengthResult((b2 << 24) | (b3 << 16) | (b4 << 8) | b5, 5);
    } else {
      throw WordTooLong('Received word is too long.');
    }
  }

  Future<bool> login() async {
    try {
      await _openSocket();
      var sentence = ['/login', '=name=$user', '=password=$password'];
      var reply = await _communicate(sentence);
      await _checkLoginReply(reply);
      return true;
    } catch (e) {
      logger.e('Login failed: $e');
      rethrow;
    }
  }

  Future<void> _checkLoginReply(List<List<String>> reply) async {
    if (reply.isNotEmpty && reply[0].isNotEmpty && reply[0][0] == '!done') {
      // الرد الطبيعي للإصدارات الحديثة
      if (reply[0].length == 2 && reply[0][1].startsWith('=ret=')) {
        // دعم Legacy Login (ما قبل v6.43)
        logger.w('Using legacy login process.');
        String retStr = reply[0][1].substring(5);
        List<int> challenge = _hexToBytes(retStr);
        
        // حساب الـ MD5 : 0x00 + password + challenge
        var md5Hash = md5.convert([0, ...windows1256.encode(password), ...challenge]);
        String responseHash = '00${md5Hash.toString()}';

        var legacyReply = await _communicate(['/login', '=name=$user', '=response=$responseHash']);
        if (legacyReply.isEmpty || legacyReply[0][0] != '!done') {
          throw LoginError('Legacy login failed: $legacyReply');
        }
      }
      logger.i('Login successful!');
    } else if (reply.isNotEmpty && reply[0].isNotEmpty && reply[0][0] == '!trap') {
      throw LoginError('Login error: ${reply[0].length > 1 ? reply[0][1] : reply[0]}');
    } else {
      throw LoginError('Unexpected login reply: $reply');
    }
  }

  Future<List<Map<String, String>>> talk(dynamic command, [Map<String, String>? params]) async {
    List<String> sentence = _buildCommand(command, params);
    return await _send(sentence);
  }

  Stream<Map<String, String>> streamData(dynamic command, [Map<String, String>? params]) async* {
    List<String> sentence = _buildCommand(command, params);

    var socket = _socket;
    if (socket == null) throw StateError('Socket is not open.');

    for (var word in sentence) {
      _sendLength(socket, word.length);
      socket.add(windows1256.encode(word));
      logger.d('>>> $word');
    }
    _sendLength(socket, 0); // End of sentence indicator

    await for (var sentenceReply in _sentenceController.stream) {
      if (sentenceReply.isNotEmpty) {
        if (sentenceReply.contains('!done') || sentenceReply.contains('!trap')) {
          return;
        }
        var parsedData = _parseSentence(sentenceReply);
        if (parsedData.isNotEmpty) yield parsedData;
      }
    }
  }

  Future<List<List<String>>> _communicate(List<String> sentenceToSend) async {
    var socket = _socket;
    if (socket == null) throw StateError('Socket is not open.');

    for (var word in sentenceToSend) {
      _sendLength(socket, word.length);
      socket.add(windows1256.encode(word));
      logger.d('>>> $word');
    }
    _sendLength(socket, 0); // End of sentence

    return await _receiveData();
  }

  Future<List<List<String>>> _receiveData() async {
    var receivedData = <List<String>>[];
    var completer = Completer<List<List<String>>>();

    // نستخدم المستمع المؤقت للرد الواحد، ونغلقه فور الانتهاء لتجنب تسرب الذاكرة
    late StreamSubscription sub;
    sub = _sentenceController.stream.listen((sentence) {
      receivedData.add(sentence);
      if (sentence.isNotEmpty && (sentence[0] == '!done' || sentence[0] == '!fatal')) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete(receivedData);
      }
    });

    return completer.future;
  }

  List<String> _buildCommand(dynamic command, Map<String, String>? params) {
    List<String> sentence = [];
    if (command is String) {
      sentence.add(command);
    } else if (command is List<String>) {
      sentence.addAll(command);
    } else {
      throw ArgumentError('Invalid command type: $command');
    }

    if (params != null) {
      params.forEach((key, value) => sentence.add('=$key=$value'));
    }
    return sentence;
  }

  void _sendLength(Socket socket, int length) {
    if (length < 0x80) {
      socket.add([length]);
    } else if (length < 0x4000) {
      length += 0x8000;
      socket.add(length.toBytes(2));
    } else if (length < 0x200000) {
      length += 0xC00000;
      socket.add(length.toBytes(3));
    } else if (length < 0x10000000) {
      length += 0xE0000000;
      socket.add(length.toBytes(4));
    } else if (length < 0x100000000) {
      socket.add([0xF0]);
      socket.add(length.toBytes(4));
    } else {
      throw WordTooLong('Word is too long. Max length is 4294967295.');
    }
  }

  Map<String, String> _parseSentence(List<String> sentence) {
    var parsedData = <String, String>{};
    for (var word in sentence) {
      if (word.startsWith('!')) continue;
      if (word.startsWith('=')) {
        // البحث عن أول '=' فقط لتجنب ضياع البيانات
        int idx = word.indexOf('=', 1);
        if (idx != -1) {
          String key = word.substring(1, idx);
          String value = word.substring(idx + 1);
          parsedData[key] = value;
        }
      }
    }
    return parsedData;
  }

  Future<List<Map<String, String>>> _send(List<String> sentence) async {
    var reply = await _communicate(sentence);
    if (reply.isNotEmpty && reply[0].isNotEmpty && reply[0][0] == '!trap') {
      logger.e('Command: $sentence\nReturned an error: $reply');
      throw RouterOSTrapError("Command: $sentence\nReturned an error: $reply");
    }
    
    var parsedReplies = <Map<String, String>>[];
    for (var s in reply) {
      var parsed = _parseSentence(s);
      if (parsed.isNotEmpty) parsedReplies.add(parsed);
    }
    return parsedReplies;
  }

  /// تم تحويل الدالة إلى async واستخدام await للرد
  Future<bool> isAlive() async {
    if (_socket == null) {
      logger.w('Socket is not open.');
      return false;
    }

    try {
      final result = await talk(['/system/identity/print']).timeout(const Duration(seconds: 3));
      return result.isNotEmpty;
    } catch (e) {
      logger.e('Socket is closed or router does not respond: $e');
      close();
      return false;
    }
  }

  void close() {
    _socketSubscription?.cancel();
    if (!_sentenceController.isClosed) {
      _sentenceController.close();
    }
    _socket?.destroy();
    _socket = null;
    _secureSocket = null;
    logger.i('RouterOSClient socket connection closed.');
  }
  
  // دالة مساعدة لتحويل السلسلة النصية للـ Hex إلى مصفوفة بايتات
  List<int> _hexToBytes(String hex) {
    var result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}

// كلاس مساعد لنتائج قراءة الطول
class _LengthResult {
  final int length;
  final int bytesUsed;
  _LengthResult(this.length, this.bytesUsed);
}

// Exceptions (كما هي لديك)
class LoginError implements Exception {
  final String message;
  LoginError(this.message);
  @override String toString() => message;
}

class WordTooLong implements Exception {
  final String message;
  WordTooLong(this.message);
  @override String toString() => message;
}

class CreateSocketError implements Exception {
  final String message;
  CreateSocketError(this.message);
  @override String toString() => message;
}

class RouterOSTrapError implements Exception {
  final String message;
  RouterOSTrapError(this.message);
  @override String toString() => message;
}

extension on int {
  List<int> toBytes(int byteCount) {
    var result = <int>[];
    for (var i = 0; i < byteCount; i++) {
      result.add((this >> (8 * (byteCount - i - 1))) & 0xFF);
    }
    return result;
  }
}
