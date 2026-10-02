import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:charset/charset.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
// تأكد من استيراد مكتبة الترميز التي تستخدمها، مثال:
// import 'package:charset/charset.dart'; 

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
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  Socket? _socket;
  SecureSocket? _secureSocket;
  
  final List<int> _buffer = [];
  late StreamController<List<String>> _sentenceController;
  StreamSubscription? _socketSubscription;

  // إدارة العلامات (Tags) لتمييز الطلبات المتزامنة
  int _tagCounter = 0;
  String _generateTag() => 'req_${++_tagCounter}';

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
      if (!verbose) Logger.level = Level.off;
      
      _sentenceController = StreamController<List<String>>.broadcast();
      _buffer.clear();

      if (useSsl) {
        _secureSocket = await SecureSocket.connect(address, port, context: context, timeout: timeout);
        _socket = _secureSocket;
      } else {
        _socket = await Socket.connect(address, port, timeout: timeout);
      }
      
      _socket?.setOption(SocketOption.tcpNoDelay, true);
      logger.i("Socket connection opened.");

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
      throw CreateSocketError('Failed to connect: ${e.message}');
    }
  }

  void _handleIncomingData(List<int> data) {
    _buffer.addAll(data);
    while (true) {
      var sentence = _tryReadSentence();
      if (sentence == null) break; 
      _sentenceController.add(sentence);
    }
  }

  List<String>? _tryReadSentence() {
    int offset = 0;
    List<String> sentence = [];

    while (true) {
      var lengthInfo = _decodeLength(_buffer, offset);
      if (lengthInfo == null) return null; 

      int length = lengthInfo.length;
      int bytesUsedForLength = lengthInfo.bytesUsed;

      if (length == 0) {
        _buffer.removeRange(0, offset + bytesUsedForLength);
        return sentence;
      }

      if (_buffer.length < offset + bytesUsedForLength + length) {
        return null; 
      }

      // تطبيق ترميز Windows-1256 الخاص بك مع تجنب الأخطاء
      String word = windows1256.decode(
        _buffer.sublist(offset + bytesUsedForLength, offset + bytesUsedForLength + length),
        allowInvalid: true, 
      );
      sentence.add(word);
      offset += bytesUsedForLength + length;
    }
  }

  _LengthResult? _decodeLength(List<int> buffer, int offset) {
    if (buffer.length <= offset) return null;
    int b1 = buffer[offset];

    if (b1 < 0x80) return _LengthResult(b1, 1);
    if (b1 < 0xC0) return buffer.length < offset + 2 ? null : _LengthResult(((b1 << 8) | buffer[offset + 1]) - 0x8000, 2);
    if (b1 < 0xE0) return buffer.length < offset + 3 ? null : _LengthResult(((b1 << 16) | (buffer[offset + 1] << 8) | buffer[offset + 2]) - 0xC00000, 3);
    if (b1 < 0xF0) return buffer.length < offset + 4 ? null : _LengthResult(((b1 << 24) | (buffer[offset + 1] << 16) | (buffer[offset + 2] << 8) | buffer[offset + 3]) - 0xE0000000, 4);
    if (b1 == 0xF0) return buffer.length < offset + 5 ? null : _LengthResult((buffer[offset + 1] << 24) | (buffer[offset + 2] << 16) | (buffer[offset + 3] << 8) | buffer[offset + 4], 5);
    throw WordTooLong('Word is too long.');
  }

  // استخراج التاج من الرد لتوجيهه للمكان الصحيح
  String? _extractTag(List<String> sentence) {
    for (var word in sentence) {
      if (word.startsWith('.tag=')) { // أزلنا علامة اليساوي من البداية
        return word.substring(5); // غيرناها من 6 إلى 5
      }
    }
    return null;
  }

  Future<bool> login() async {
    try {
      await _openSocket();
      var sentence = ['/login', '=name=$user', '=password=$password'];
      var reply = await _communicate(sentence, 'sys_login');
      await _checkLoginReply(reply);
      return true;
    } catch (e) {
      logger.e('Login failed: $e');
      rethrow;
    }
  }

  Future<void> _checkLoginReply(List<List<String>> reply) async {
    if (reply.isNotEmpty && reply[0].isNotEmpty && reply[0][0] == '!done') {
      if (reply[0].length >= 2 && reply[0].any((w) => w.startsWith('=ret='))) {
        logger.w('Using legacy login process.');
        String retWord = reply[0].firstWhere((w) => w.startsWith('=ret='));
        String retStr = retWord.substring(5);
        List<int> challenge = _hexToBytes(retStr);
        
        // تطبيق ترميز Windows-1256 الخاص بك في حساب كلمة المرور
        var md5Hash = md5.convert([0, ...windows1256.encode(password), ...challenge]);
        String responseHash = '00${md5Hash.toString()}';

        var legacyReply = await _communicate(['/login', '=name=$user', '=response=$responseHash'], 'sys_login_legacy');
        if (legacyReply.isEmpty || legacyReply[0][0] != '!done') {
          throw LoginError('Legacy login failed');
        }
      }
      logger.i('Login successful!');
    } else if (reply.isNotEmpty && reply[0].isNotEmpty && reply[0][0] == '!trap') {
      throw LoginError('Login error: ${reply[0].length > 1 ? reply[0][1] : reply[0]}');
    } else {
      throw LoginError('Unexpected login reply: $reply');
    }
  }

  Future<List<Map<String, String>>> talk(dynamic command, {Map<String, String>? params, String? customTag}) async {
    String tag = customTag ?? _generateTag();
    List<String> sentence = _buildCommand(command, params);
    
    // التعديل هنا: استخدام .tag مباشرة بدون =
    sentence.add('.tag=$tag'); 

    var reply = await _communicate(sentence, tag);
    
    if (reply.isNotEmpty && reply[0].isNotEmpty && reply[0][0] == '!trap') {
      logger.e('Command Error: $reply');
      throw RouterOSTrapError("Returned an error: $reply");
    }
    
    var parsedReplies = <Map<String, String>>[];
    for (var s in reply) {
      var parsed = _parseSentence(s);
      if (parsed.isNotEmpty) parsedReplies.add(parsed);
    }
    return parsedReplies;
  }

  Stream<Map<String, String>> streamData(dynamic command, {Map<String, String>? params, String? customTag}) async* {
    String tag = customTag ?? _generateTag();
    List<String> sentence = _buildCommand(command, params);
    
    // التعديل هنا أيضاً
    sentence.add('.tag=$tag');

    var socket = _socket;
    if (socket == null) throw StateError('Socket is not open.');

    for (var word in sentence) {
      // حماية إضافية للغة العربية: نحسب طول البايتات وليس طول النص
      var encodedWord = windows1256.encode(word);
      _sendLength(socket, encodedWord.length);
      socket.add(encodedWord); 
    }
    _sendLength(socket, 0); 

    await for (var sentenceReply in _sentenceController.stream) {
      if (sentenceReply.isEmpty) continue;

      String? replyTag = _extractTag(sentenceReply);
      if (replyTag != tag) continue;

      if (sentenceReply[0] == '!done' || sentenceReply[0] == '!fatal') {
        break; 
      }

      var parsedData = _parseSentence(sentenceReply);
      if (parsedData.isNotEmpty) yield parsedData;
    }
  }

  // دالة الإلغاء لإيقاف الطلبات المعلقة
  Future<void> cancelCommand(String tagToCancel) async {
    if (_socket == null) return;
    logger.w('Canceling command with tag: $tagToCancel');
    
    List<String> sentence = ['/cancel', '=tag=$tagToCancel'];
    
    for (var word in sentence) {
      _sendLength(_socket!, word.length);
      _socket!.add(windows1256.encode(word)); // استخدام windows1256
    }
    _sendLength(_socket!, 0);
  }

  Future<List<List<String>>> _communicate(List<String> sentenceToSend, String tag) async {
    var socket = _socket;
    if (socket == null) throw StateError('Socket is not open.');

    for (var word in sentenceToSend) {
      var encodedWord = windows1256.encode(word);
      _sendLength(socket, encodedWord.length); // حساب طول البايتات بدقة
      socket.add(encodedWord); 
    }
    _sendLength(socket, 0);

    return await _receiveData(tag);
  }

  Future<List<List<String>>> _receiveData(String tag) async {
    var receivedData = <List<String>>[];
    var completer = Completer<List<List<String>>>();

    late StreamSubscription sub;
    sub = _sentenceController.stream.listen((sentence) {
      if (sentence.isEmpty) return;

      String? replyTag = _extractTag(sentence);
      if (replyTag != null && replyTag != tag) return; 

      receivedData.add(sentence);

      if (sentence[0] == '!done' || sentence[0] == '!fatal') {
        sub.cancel();
        if (!completer.isCompleted) completer.complete(receivedData);
      }
    });

    return completer.future;
  }

  List<String> _buildCommand(dynamic command, Map<String, String>? params) {
    List<String> sentence = [];
    if (command is String) sentence.add(command);
    else if (command is List<String>) sentence.addAll(command);
    else throw ArgumentError('Invalid command type');

    if (params != null) params.forEach((key, value) => sentence.add('=$key=$value'));
    return sentence;
  }

  void _sendLength(Socket socket, int length) {
    if (length < 0x80) socket.add([length]);
    else if (length < 0x4000) socket.add((length + 0x8000).toBytes(2));
    else if (length < 0x200000) socket.add((length + 0xC00000).toBytes(3));
    else if (length < 0x10000000) socket.add((length + 0xE0000000).toBytes(4));
    else if (length < 0x100000000) { socket.add([0xF0]); socket.add(length.toBytes(4)); }
    else throw WordTooLong('Word is too long.');
  }

  Map<String, String> _parseSentence(List<String> sentence) {
    var parsedData = <String, String>{};
    for (var word in sentence) {
      // تجاهل التاج ورسائل النظام
      if (word.startsWith('!') || word.startsWith('.tag=')) continue; 
      
      if (word.startsWith('=')) {
        int idx = word.indexOf('=', 1);
        if (idx != -1) {
          String key = word.substring(1, idx);
          parsedData[key] = word.substring(idx + 1);
        }
      }
    }
    return parsedData;
  }

  Future<bool> isAlive() async {
    if (_socket == null) return false;
    try {
      final result = await talk(['/system/identity/print'], customTag: 'sys_alive').timeout(const Duration(seconds: 3));
      return result.isNotEmpty;
    } catch (e) {
      close();
      return false;
    }
  }

  void close() {
    _socketSubscription?.cancel();
    if (!_sentenceController.isClosed) _sentenceController.close();
    _socket?.destroy();
    _socket = null;
    _secureSocket = null;
    logger.i('Socket connection closed.');
  }
  
  List<int> _hexToBytes(String hex) {
    var result = <int>[];
    for (int i = 0; i < hex.length; i += 2) result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    return result;
  }
}

class _LengthResult {
  final int length;
  final int bytesUsed;
  _LengthResult(this.length, this.bytesUsed);
}

class LoginError implements Exception { final String message; LoginError(this.message); @override String toString() => message; }
class WordTooLong implements Exception { final String message; WordTooLong(this.message); @override String toString() => message; }
class CreateSocketError implements Exception { final String message; CreateSocketError(this.message); @override String toString() => message; }
class RouterOSTrapError implements Exception { final String message; RouterOSTrapError(this.message); @override String toString() => message; }

extension on int {
  List<int> toBytes(int byteCount) {
    var result = <int>[];
    for (var i = 0; i < byteCount; i++) result.add((this >> (8 * (byteCount - i - 1))) & 0xFF);
    return result;
  }
}


class UsersScreen extends StatefulWidget {
  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // 1. تعريف تاج مميز لهذه الشاشة وهذا الطلب
  final String myTaskTag = "fetch_all_users_123"; 
  
  List<Map<String, String>> usersList = [];
  bool isLoading = true;
  late RouterOSClient mikrotik;

  @override
  void initState() {
    super.initState();
    mikrotik=RouterOSClient(
      address: 'localhost',
      user: 'user',
      password: 'userpass',
      port: 8727,
      verbose: true,
      useSsl: true,
      timeout: Duration(seconds: 40),
    );
    _fetchUsers();
  }

  void _fetchUsers() async {
    try {
      await mikrotik.login();
      // 2. تمرير التاج عند استدعاء البيانات
      // يمكنك استخدام talk أو streamData، كلاهما يدعم customTag الآن
      var data = await mikrotik.talk(
        ['/tool/user-manager/user/print'], 
        customTag: myTaskTag // <--- السحر هنا
      );
      
      if (mounted) {
        setState(() {
          usersList = data;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error or Canceled: $e");
    }
  }

  @override
  void dispose() {
    // 3. إذا خرج المستخدم من الشاشة قبل انتهاء التحميل
    if (isLoading) {
      // نرسل أمر قتل هذه العملية المحددة فقط للراوتر!
      mikrotik.cancelCommand(myTaskTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("الكروت")),
      body: isLoading 
          ? Center(child: CircularProgressIndicator()) 
          : ListView.builder(
              itemCount: usersList.length,
              itemBuilder: (c, i) => ListTile(title: Text(usersList[i]['username'] ?? 'No Name')),
            ),
    );
  }
}