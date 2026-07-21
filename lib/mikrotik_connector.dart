// ============================================================
//  MikrotikConnector — مُوصل MikroTik المحسّن
//
//  استفادة من router_os_client 2.0.1:
//  - استخدام الأخطاء المخصصة (LoginError, CreateSocketError, RouterOSTrapError)
//  - دعم useSsl للاتصال الآمن (8729)
//  - timeout مدمج في RouterOSClient
//  - دعم talkMultiple للتنفيذ المتوازي عبر socket واحد
//  - دعم streamData للمراقبة الحية (torch, listen)
//  - دعم cancelTagged لإلغاء العمليات الطويلة
// ============================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// استثناء: بيانات الاعتماد غير موجودة
class MikrotikCredentialsMissingException implements Exception {
  final String message;
  const MikrotikCredentialsMissingException(this.message);

  @override
  String toString() => 'MikrotikCredentialsMissingException: $message';
}

/// استثناء: فشل الاتصال (يشمل timeout, socket error, login error)
class MikrotikConnectionException implements Exception {
  final String message;
  final dynamic originalException;
  const MikrotikConnectionException(this.message, [this.originalException]);

  @override
  String toString() => 'MikrotikConnectionException: $message';
}

/// استثناء: فشل تسجيل الدخول (credentials خاطئة)
class MikrotikLoginException extends MikrotikConnectionException {
  const MikrotikLoginException(String message, [dynamic original])
      : super(message, original);
}

/// استثناء: خطأ من RouterOS (trap error)
class MikrotikTrapException implements Exception {
  final String message;
  const MikrotikTrapException(this.message);

  @override
  String toString() => 'MikrotikTrapException: $message';
}

/// مُوصل MikroTik مع تجمع اتصالات مستمر لتسريع العمليات
///
/// استفادة من router_os_client 2.0.1:
/// - دعم useSsl للاتصال الآمن
/// - timeout مدمج في RouterOSClient (بدل .timeout() اليدوي)
/// - الأخطاء المخصصة (LoginError, CreateSocketError, RouterOSTrapError)
class MikrotikConnector {
  static RouterOSClient? _cachedClient;
  static DateTime? _lastUsed;
  static String? _currentIp;
  static String? _currentUser;
  static int _currentPort = 8728;
  static bool _currentUseSsl = false;
  static const _maxIdle = Duration(minutes: 3);
  static const _connectTimeout = Duration(seconds: 10);
  static bool _isConnecting = false;

  /// معلومات الاتصال الحالي (للاستخدام في UI والتشخيص)
  static String? get currentIp => _currentIp;
  static String? get currentUser => _currentUser;
  static int get currentPort => _currentPort;
  static bool get currentUseSsl => _currentUseSsl;
  static bool get isCached => _cachedClient != null;

  /// الحصول على اتصال MikroTik - يعيد الاتصال المخزّن إذا كان نشطاً
  /// أو ينشئ اتصالاً جديداً عند الحاجة فقط
  static Future<RouterOSClient> connect() async {
    // التحقق مما إذا كان الاتصال المخزّن لا يزال صالحاً
    if (_cachedClient != null &&
        _lastUsed != null &&
        DateTime.now().difference(_lastUsed!) < _maxIdle &&
        !_isConnecting) {
      _lastUsed = DateTime.now();
      return _cachedClient!;
    }

    // إذا كان هناك اتصال قديم، أغلقه
    try {
      _cachedClient?.close();
    } catch (_) {}
    _cachedClient = null;

    // قراءة بيانات الاعتماد
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('ip');
    final user = prefs.getString('user');
    final pass = prefs.getString('pass');
    final portString = prefs.getString('port');
    final useSslString = prefs.getString('use_ssl');
    final useSsl = useSslString == 'true';
    // إن كان useSsl=true والمنفذ غير محدد، استخدم 8729 تلقائياً
    final port = portString != null
        ? (int.tryParse(portString) ?? (useSsl ? 8729 : 8728))
        : (useSsl ? 8729 : 8728);

    if (ip == null || user == null || pass == null) {
      throw const MikrotikCredentialsMissingException(
          'IP address, username, or password are not set.');
    }

    // تجنب إنشاء اتصال مكرر إذا كان جارياً بالفعل
    if (_isConnecting) {
      // انتظر حتى يكتمل الاتصال الحالي
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_cachedClient != null && !_isConnecting) {
          _lastUsed = DateTime.now();
          return _cachedClient!;
        }
      }
      throw const MikrotikConnectionException('Connection already in progress.');
    }

    _isConnecting = true;
    try {
      // 🔧 استفادة من router_os_client 2.0.1:
      // - useSsl للاتصال الآمن
      // - timeout مدمج (بدل .timeout() اليدوي)
      final client = RouterOSClient(
        address: ip,
        user: user,
        password: pass,
        port: port,
        useSsl: useSsl,
        verbose: false,
        timeout: _connectTimeout,
      );

      final bool loggedIn = await client.login().timeout(_connectTimeout);
      if (loggedIn) {
        _cachedClient = client;
        _lastUsed = DateTime.now();
        _currentIp = ip;
        _currentUser = user;
        _currentPort = port;
        _currentUseSsl = useSsl;
        debugPrint('MikroTik: New connection established to $ip:$port'
            '${useSsl ? " (SSL)" : ""}');
        return client;
      } else {
        throw const MikrotikLoginException('Login failed - invalid credentials.');
      }
    } on TimeoutException {
      throw const MikrotikConnectionException(
          'Connection timed out. Check IP/port and network.');
    } on LoginError catch (e) {
      // 🔧 استفادة من router_os_client: LoginError exception المخصص
      throw MikrotikLoginException('Login failed: ${e.message}', e);
    } on CreateSocketError catch (e) {
      // 🔧 استفادة من router_os_client: CreateSocketError exception المخصص
      throw MikrotikConnectionException('Socket error: ${e.message}', e);
    } on MikrotikConnectionException {
      rethrow;
    } on MikrotikCredentialsMissingException {
      rethrow;
    } catch (e) {
      _cachedClient = null;
      throw MikrotikConnectionException('An unexpected error occurred: $e', e);
    } finally {
      _isConnecting = false;
    }
  }

  /// ينفذ عدة أوامر بالتوازي عبر socket واحد
  /// 🔧 استفادة من router_os_client 2.0.1: talkMultiple + TaggedCommand
  ///
  /// [commands] قائمة بالأوامر مع parameters و tags اختيارية
  /// يُرجع Stream من TaggedResponse (واحد لكل أمر يكتمل)
  static Stream<TaggedResponse> talkMultiple(
      List<TaggedCommand> commands) async* {
    final client = await connect();
    yield* client.talkMultiple(commands);
  }

  /// يبث بيانات حية من RouterOS (مثل /tool/torch, /interface/listen)
  /// 🔧 استفادة من router_os_client 2.0.1: streamData
  static Stream<Map<String, String>> streamData(
    dynamic command, [
    Map<String, String>? params,
    String? tag,
  ]) async* {
    final client = await connect();
    yield* client.streamData(command, params, tag);
  }

  /// يلغي أمراً طويلاً عبر tag
  /// 🔧 استفادة من router_os_client 2.0.1: cancelTagged
  static Future<void> cancelTagged(String tag) async {
    final client = await connect();
    await client.cancelTagged(tag);
  }

  /// يتحقق من أن الاتصال لا يزال حياً
  /// 🔧 استفادة من router_os_client 2.0.1: isAlive
  static Future<bool> isAlive() async {
    try {
      final client = await connect();
      // isAlive يُرجع Future (talk() للتحقق من الـ socket)
      final result = client.isAlive();
      // تحقق من النتيجة — talk() يُرجع Future<List<Map<String, String>>>
      // إن نجح = الاتصال حي، إن رمى استثناء = الاتصال ميت
      await result;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// إغلاق الاتصال المخزّن بشكل صريح
  static void forceDisconnect() {
    try {
      _cachedClient?.close();
    } catch (_) {}
    _cachedClient = null;
    _lastUsed = null;
    _isConnecting = false;
    debugPrint('MikroTik: Connection forced closed.');
  }

  /// التحقق مما إذا كان هناك اتصال نشط
  static bool get hasActiveConnection =>
      _cachedClient != null && !_isConnecting;

  /// معلومات الاتصال كنص (للعرض في UI)
  static String get connectionInfo {
    if (_currentIp == null) return 'غير متصل';
    final ssl = _currentUseSsl ? ' (SSL)' : '';
    return '$_currentIp:$_currentPort$ssl';
  }
}

// ============================================================
//  Riverpod providers لحالة اتصال MikroTik
// ============================================================

/// حالة اتصال MikroTik
enum MikrotikConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// حالة اتصال MikroTik عبر Riverpod
class MikrotikConnectionStatus {
  final MikrotikConnectionState state;
  final String? errorMessage;
  final String? ip;
  final int? port;

  const MikrotikConnectionStatus({
    this.state = MikrotikConnectionState.disconnected,
    this.errorMessage,
    this.ip,
    this.port,
  });

  bool get isConnected => state == MikrotikConnectionState.connected;
  bool get isConnecting => state == MikrotikConnectionState.connecting;
}

/// StateNotifier لإدارة حالة اتصال MikroTik عبر Riverpod
class MikrotikConnectionNotifier extends StateNotifier<MikrotikConnectionStatus> {
  MikrotikConnectionNotifier() : super(const MikrotikConnectionStatus());

  Future<void> connect() async {
    state = MikrotikConnectionStatus(
      state: MikrotikConnectionState.connecting,
    );

    try {
      final client = await MikrotikConnector.connect();
      state = MikrotikConnectionStatus(
        state: MikrotikConnectionState.connected,
        ip: MikrotikConnector.currentIp,
        port: MikrotikConnector.currentPort,
      );
    } on MikrotikCredentialsMissingException catch (e) {
      state = MikrotikConnectionStatus(
        state: MikrotikConnectionState.error,
        errorMessage: e.message,
      );
    } on MikrotikConnectionException catch (e) {
      state = MikrotikConnectionStatus(
        state: MikrotikConnectionState.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = MikrotikConnectionStatus(
        state: MikrotikConnectionState.error,
        errorMessage: e.toString(),
      );
    }
  }

  void disconnect() {
    MikrotikConnector.forceDisconnect();
    state = const MikrotikConnectionStatus(
      state: MikrotikConnectionState.disconnected,
    );
  }

  void reset() {
    state = const MikrotikConnectionStatus(
      state: MikrotikConnectionState.disconnected,
    );
  }
}

/// Riverpod provider لحالة اتصال MikroTik
final mikrotikConnectionProvider =
    StateNotifierProvider<MikrotikConnectionNotifier, MikrotikConnectionStatus>(
  (ref) => MikrotikConnectionNotifier(),
);
