import 'dart:convert';
import 'package:charset/charset.dart';
import 'router.dart';

class MikrotikClient {
  static RouterOSClient? _client; // القناة الأساسية السريعة (للباقات والإضافات)
  // static RouterOSClient? _heavyClient; // القناة الثقيلة (لجلب الكروت والجلسات فقط)
  static int version=0;

  // حفظ الإعدادات لإعادة الاتصال التلقائي الصامت في حال فصل الراوتر إحدى القنوات
  static String _address = "";
  static String _user = "";
  static String _password = "";
  static int _port = 8728;
  static int _timeout = 60;
  static bool _useSsl = true;
  static bool _verbose = true;

  static void init({
    required String address,
    required String user,
    required String password,
    required int port,
    int timeout = 60,
    bool useSsl = true,
    bool verbose = true,
  }) {
    _address = address;
    _user = user;
    _password = password;
    _port = port;
    _timeout = timeout;
    _useSsl = useSsl;
    _verbose = verbose;

    // تهيئة القناتين معاً من البداية!
    _client = RouterOSClient(
      address: address, user: user, password: password,
      port: port, timeout: Duration(seconds: timeout),
      useSsl: useSsl, verbose: verbose,
    );

    // _heavyClient = RouterOSClient(
    //   address: address, user: user, password: password,
    //   port: port, timeout: Duration(seconds: timeout),
    //   useSsl: useSsl, verbose: verbose,
    // );
  }

  static Future<bool> login() async {
    // الاتصال بالراوتر من القناتين في نفس اللحظة (توفير للوقت)
    var results = await _client!.login();
    // Future.wait([
    //   _client!.login(),
    //   // _heavyClient!.login(),
    // ]);
    version= await getVersion();
    // يرجع true إذا نجح الاتصال بالقناتين
    return results;
  }

  static void _checkConnection() {
    if (_client == null /* || _heavyClient == null */) {
      throw Exception("empty socket connection");
    }
  }

  // -------------------------------------

  static String decode(String text) {
    try {
      return utf8.decode(windows1256.encode(text), allowMalformed: false);
    } catch (e) {
      return text;
    }
  }

  static String encode(String text) {
    try {
      // return windows1256.decode(utf8.encode(text), allowInvalid: true);
      return windows1256.decode(utf8.encode(text), allowInvalid: true);
    } catch (e) {
      return text;
    }
  }

  // دالة مساعدة لفك تشفير النتائج
  static List _decodeResult(List rawResult) {
    List decodedResult = [];
    for (var item in rawResult) {
      if (item is Map) {
        Map<String, dynamic> decodedMap = {};
        item.forEach((key, value) {
          decodedMap[key] = value is String ? decode(value) : value;
        });
        decodedResult.add(decodedMap);
      } else if (item is String) {
        decodedResult.add(decode(item));
      } else {
        decodedResult.add(item);
      }
    }
    return decodedResult;
  }

  // التوجيه الذكي: فحص الأمر هل هو كروت/جلسات؟
  static bool _isHeavyCommand(dynamic command) {
    String cmdStr = command is List ? command.join(" ") : command.toString();
    return cmdStr.contains("user/print") || cmdStr.contains("session/print");
  }

  static Future<List> fetch({
    required dynamic command,
    Map<String, String>? params,
    String customTag="main_fetch_tage",
  }) async {
    _checkConnection();
    Map<String, String>? encodedParams;
    if (params != null) {
      encodedParams = {};
      params.forEach((key, value) {
        encodedParams![key] = encode(value); 
      });
    }

    try {
      List rawResult = await _client!.talk(
        command, 
        // encodedParams
        params: encodedParams,
        customTag: customTag
      );
      return _decodeResult(rawResult);
    } catch (e) {
      // إعادة الاتصال الصامت إذا حصل أي خطأ
      print("Socket error detected! Reconnecting... ($e)");
      init(
        address: _address, user: _user, password: _password, 
        port: _port, timeout: _timeout, useSsl: _useSsl, verbose: _verbose
      );
      await login();
      
      List rawResult = await _client!.talk(
        command,
        // encodedParams
        params: encodedParams,
        customTag: customTag
      );
      return _decodeResult(rawResult);
    }
  }
  
  // دالة الاستماع (Stream) تستخدم القناة الثقيلة دائماً
  static Stream<Map<String, dynamic>> fetchStream({
    required dynamic command,
    Map<String, String>? params,
    String customTag="main_fetch_stream_tage",
  }) async* {
    _checkConnection();
    // RouterOSClient activeClient = _heavyClient!;

    Map<String, String>? encodedParams;
    if (params != null) {
      encodedParams = {};
      params.forEach((key, value) {
        encodedParams![key] = encode(value); 
      });
    }

    try {
      await for (var item in _client!.streamData(
        command,
        // encodedParams
        params: encodedParams,
        customTag: customTag
      )) {
        Map<String, dynamic> decodedMap = {};
        item.forEach((key, value) {
          decodedMap[key] = decode(value);
        });
        yield decodedMap;
      }
    } catch (e) {
       print("Stream Error: $e");
       rethrow;
    }
  }

  static Future<List> printData({
    required List<String> commands,
    List<String> conditions = const [],
    String fields = "",
    String tag="print_tage",
  }) async {
    if (conditions.isNotEmpty) {
      commands.addAll(conditions);
    }
    Map<String, String> params = {};
    if (fields != "") {
      params = {".proplist": fields};
    }
    return await fetch(command: commands, params: params,customTag: tag);
  }

  static Future<List> addData({
    required String command, 
    required Map<String, String> data,
    String tag="add_tage",
  }) async {
    return await fetch(command: command, params: data,customTag: tag);
  }

  static Future<String> _getElementId(String setCmd, String cond) async {
    List cmd = setCmd.split("/");
    String printCmd = "";
    int loop = (cmd.length - 1);
    for (var i = 0; i < loop; i++) {
      printCmd += "${cmd[i]}/";
    }
    printCmd += "print";
    List result = await printData(commands: [printCmd], conditions: [cond], fields: ".id",tag: "get_id_tag");
    return result[0]['.id'];
  }

  static Future<List> editData({required String command, required Map<String, String> data, required String condition}) async {
    String userId = await _getElementId(command, condition);
    return await fetch(command: [command, "=.id=$userId"], params: data,customTag: "edit_tag");
  }

  static Future<List> deleteData({required String command, required String condition,String tag="delete_tage",}) async {
    String userId = await _getElementId(command, condition);
    return await fetch(command: [command, "=.id=$userId"],customTag: tag);
  }

  static Future<List> removeById({required String command, required String id,String tag="remove_by_id_tage",}) async {
    return await fetch(command: [command, "=.id=$id"],customTag: tag);
  }

  static Future<int> getVersion() async {
    _checkConnection();
    List result = await _client!.talk(
      "/system/resource/print",
      // customTag: 'get_version'
    );
    try {
      return int.parse(result[0]["version"].split('.')[0]);
    } catch (e) {
      return 0;
    }
  }

  static Future<void> cancelCommand(String tag)async{
    // await _client!.cancelCommand(tag);
  }

  static Future<void> cancel()async{
    _client!.close();
    await _client!.login();
  }

  static Future<void> close()async{
    _client!.close();
  }
}




