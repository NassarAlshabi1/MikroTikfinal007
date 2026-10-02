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

import 'services/router_os_query_executor.dart';
import 'services/secure_credentials_storage.dart';

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
  const MikrotikLoginException(super.message, [super.original]);
}

/// استثناء: خطأ من RouterOS (trap error)
class MikrotikTrapException implements Exception {
  final String message;
  const MikrotikTrapException(this.message);

  @override
  String toString() => 'MikrotikTrapException: $message';
}

/// إعدادات اتصال مستقلة يمكن تمريرها إلى Isolate بأمان.
/// لا تحتوي على أي كائن Flutter أو Plugin.
class MikrotikConnectionConfig {
  final String address;
  final String user;
  final String password;
  final int port;
  final bool useSsl;

  const MikrotikConnectionConfig({
    required this.address,
    required this.user,
    required this.password,
    required this.port,
    required this.useSsl,
  });
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
  static DateTime? _lastHealthCheck;
  static String? _currentIp;
  static String? _currentUser;
  static int _currentPort = 8728;
  static bool _currentUseSsl = false;
  static const _maxIdle = Duration(minutes: 3);
  static const _healthCheckInterval = Duration(seconds: 15);
  static const _healthCheckTimeout = Duration(seconds: 3);
  // مهلة كافية للراوترات البعيدة عبر VPN/L2TP والبطيئة.
  static const _connectTimeout = Duration(seconds: 30);
  static Future<RouterOSClient>? _connectInFlight;
  static RouterOSClient? _connectingClient;
  static int _connectionGeneration = 0;

  /// معلومات الاتصال الحالي (للاستخدام في UI والتشخيص)
  static String? get currentIp => _currentIp;
  static String? get currentUser => _currentUser;
  static int get currentPort => _currentPort;
  static bool get currentUseSsl => _currentUseSsl;
  static bool get isCached => _cachedClient != null;

  /// قراءة إعدادات الاتصال من التخزين على الـ UI isolate فقط.
  /// بعد ذلك يمكن تمرير النتيجة إلى عمليات طويلة دون استدعاء Plugins داخلها.
  static Future<MikrotikConnectionConfig> loadConnectionConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('ip');
    final user = prefs.getString('user');
    final pass =
        await SecureCredentialsStorageContainer.instance.getMikrotikPassword();
    final useSsl = prefs.getString('use_ssl') == 'true';
    final portString = prefs.getString('port');
    final port = portString != null
        ? (int.tryParse(portString) ?? (useSsl ? 8729 : 8728))
        : (useSsl ? 8729 : 8728);

    if (ip == null ||
        ip.trim().isEmpty ||
        user == null ||
        user.trim().isEmpty) {
      throw const MikrotikCredentialsMissingException(
          'IP address or username is not set.');
    }
    if (pass == null) {
      throw const MikrotikCredentialsMissingException(
          'MikroTik password is not set.');
    }

    return MikrotikConnectionConfig(
      address: ip.trim(),
      user: user.trim(),
      password: pass,
      port: port,
      useSsl: useSsl,
    );
  }

  /// ينشئ اتصالاً مستقلاً من إعدادات جاهزة؛ مناسب للـ Isolate.
  static Future<RouterOSClient> connectWithConfig(
      MikrotikConnectionConfig config) async {
    final client = RouterOSClient(
      address: config.address,
      user: config.user,
      password: config.password,
      port: config.port,
      useSsl: config.useSsl,
      verbose: false,
      timeout: _connectTimeout,
    );

    try {
      final loggedIn = await client.login().timeout(_connectTimeout);
      if (!loggedIn) {
        throw const MikrotikLoginException(
            'Login failed - invalid credentials.');
      }
      return client;
    } on TimeoutException {
      try {
        client.close();
      } catch (_) {}
      throw const MikrotikConnectionException(
          'Connection timed out. Check IP/port and network.');
    } on LoginError catch (e) {
      try {
        client.close();
      } catch (_) {}
      throw MikrotikLoginException('Login failed: ${e.message}', e);
    } on CreateSocketError catch (e) {
      try {
        client.close();
      } catch (_) {}
      throw MikrotikConnectionException('Socket error: ${e.message}', e);
    } catch (_) {
      try {
        client.close();
      } catch (_) {}
      rethrow;
    }
  }

  /// الحصول على اتصال MikroTik.
  ///
  /// كل المستدعين أثناء تحميل الإعدادات وفحص الصحة والمصافحة يشتركون في
  /// المحاولة نفسها؛ لا يوجد polling ولا يمكن إنشاء sockets متنافسة.
  static Future<RouterOSClient> connect() {
    final inFlight = _connectInFlight;
    if (inFlight != null) return inFlight;

    final generation = _connectionGeneration;
    late final Future<RouterOSClient> attempt;
    attempt = _connectOnce(generation).then((client) {
      _ensureConnectionGeneration(generation);
      if (!identical(client, _cachedClient)) {
        throw const MikrotikConnectionException(
            'Connection was closed before it could be returned.');
      }
      return client;
    }).whenComplete(() {
      if (identical(_connectInFlight, attempt)) {
        _connectInFlight = null;
      }
    });
    _connectInFlight = attempt;
    return attempt;
  }

  static Future<RouterOSClient> _connectOnce(int generation) async {
    // أعد استخدام العميل بعد فترة الخمول القصيرة دون فحص شبكة عند كل شاشة.
    final cached = _cachedClient;
    final lastUsed = _lastUsed;
    if (cached != null && lastUsed != null) {
      final now = DateTime.now();
      final idleFor = now.difference(lastUsed);
      if (idleFor < _maxIdle) {
        final shouldCheckHealth = idleFor >= _healthCheckInterval &&
            (_lastHealthCheck == null ||
                now.difference(_lastHealthCheck!) >= _healthCheckInterval);
        if (!shouldCheckHealth) {
          _ensureConnectionGeneration(generation);
          if (identical(cached, _cachedClient)) {
            _lastUsed = now;
            return cached;
          }
        } else {
          final alive = await _isAlive(cached);
          _ensureConnectionGeneration(generation);
          if (alive && identical(cached, _cachedClient)) {
            _lastUsed = DateTime.now();
            return cached;
          }
          if (identical(cached, _cachedClient)) {
            _invalidateCachedClient();
          }
        }
      }
    }

    _ensureConnectionGeneration(generation);
    _invalidateCachedClient();

    // قراءة الإعدادات داخل المحاولة المشتركة تمنع طلبات متزامنة للتخزين.
    final config = await loadConnectionConfig();
    _ensureConnectionGeneration(generation);

    final client = RouterOSClient(
      address: config.address,
      user: config.user,
      password: config.password,
      port: config.port,
      useSsl: config.useSsl,
      verbose: false,
      timeout: _connectTimeout,
    );
    _connectingClient = client;

    try {
      final loggedIn = await client.login().timeout(_connectTimeout);
      _ensureConnectionGeneration(generation);
      if (!loggedIn) {
        throw const MikrotikLoginException(
            'Login failed - invalid credentials.');
      }

      _cachedClient = client;
      _lastUsed = DateTime.now();
      _lastHealthCheck = DateTime.now();
      _currentIp = config.address;
      _currentUser = config.user;
      _currentPort = config.port;
      _currentUseSsl = config.useSsl;
      debugPrint('MikroTik: New connection established to ${config.address}:'
          '${config.port}${config.useSsl ? " (SSL)" : ""}');
      return client;
    } on TimeoutException catch (e) {
      _closeClient(client);
      throw MikrotikConnectionException(
          'Connection timed out. Check IP/port and network.', e);
    } on LoginError catch (e) {
      _closeClient(client);
      throw MikrotikLoginException('Login failed: ${e.message}', e);
    } on CreateSocketError catch (e) {
      _closeClient(client);
      throw MikrotikConnectionException('Socket error: ${e.message}', e);
    } on MikrotikConnectionException {
      _closeClient(client);
      rethrow;
    } catch (e) {
      _closeClient(client);
      throw MikrotikConnectionException('An unexpected error occurred: $e', e);
    } finally {
      if (identical(_connectingClient, client)) {
        _connectingClient = null;
      }
    }
  }

  static void _ensureConnectionGeneration(int generation) {
    if (generation != _connectionGeneration) {
      throw const MikrotikConnectionException(
          'Connection attempt was cancelled.');
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

  /// يتحقق من الاتصال باستعلام RouterOS موسوم لا يتعارض مع أوامر socket أخرى.
  static Future<bool> isAlive() async {
    RouterOSClient? client;
    try {
      client = await connect();
      await RouterOsQueryExecutor.talk(
        client,
        ['/system/identity/print'],
        timeout: _healthCheckTimeout,
      );
      _lastUsed = DateTime.now();
      _lastHealthCheck = DateTime.now();
      return true;
    } catch (_) {
      if (client != null && identical(client, _cachedClient)) {
        _invalidateCachedClient();
      }
      return false;
    }
  }

  /// يحدد أخطاء العميل التي تعني أن Socket أُغلق ويجب إنشاء اتصال جديد.
  static bool isSocketClosedError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('socket is not open') ||
        message.contains('connection closed') ||
        message.contains('bad state');
  }

  /// تحرير اتصال مؤقت.
  ///
  /// العميل الذي ترجعه `connect()` مشترك بين الشاشات، لذلك لا يُغلق هنا.
  /// إغلاقه من شاشة واحدة كان يتسبب في `Bad state: Connection closed` داخل
  /// شاشة أخرى تعمل بمؤقت تحديث. تتم إدارة الخمول وفحص الحيوية في `connect()`.
  /// الاتصالات المستقلة التي تُنشأ عبر `connectWithConfig()` تُغلق كالمعتاد.
  static void release(RouterOSClient? client) {
    if (client == null) return;
    if (identical(client, _cachedClient)) {
      _lastUsed = DateTime.now();
      return;
    }
    try {
      client.close();
    } catch (_) {}
  }

  static Future<bool> _isAlive(RouterOSClient client) async {
    try {
      await RouterOsQueryExecutor.talk(
        client,
        ['/system/identity/print'],
        timeout: _healthCheckTimeout,
      );
      _lastHealthCheck = DateTime.now();
      return true;
    } catch (_) {
      return false;
    }
  }

  static void _closeClient(RouterOSClient? client) {
    try {
      client?.close();
    } catch (_) {}
  }

  static void _resetConnectionMetadata() {
    _currentIp = null;
    _currentUser = null;
    _currentPort = 8728;
    _currentUseSsl = false;
  }

  static void _invalidateCachedClient() {
    _closeClient(_cachedClient);
    _cachedClient = null;
    _lastUsed = null;
    _lastHealthCheck = null;
    _resetConnectionMetadata();
  }

  /// إغلاق الاتصال المخزّن بشكل صريح وإبطال أي مصافحة جارية.
  static void forceDisconnect() {
    _connectionGeneration++;
    _connectInFlight = null;

    final cached = _cachedClient;
    final connecting = _connectingClient;
    _cachedClient = null;
    _connectingClient = null;
    _closeClient(cached);
    if (!identical(connecting, cached)) {
      _closeClient(connecting);
    }

    _lastUsed = null;
    _lastHealthCheck = null;
    _resetConnectionMetadata();
    debugPrint('MikroTik: Connection forced closed.');
  }

  /// التحقق مما إذا كان هناك اتصال نشط
  static bool get hasActiveConnection =>
      _cachedClient != null && _connectInFlight == null;

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
class MikrotikConnectionNotifier
    extends StateNotifier<MikrotikConnectionStatus> {
  MikrotikConnectionNotifier() : super(const MikrotikConnectionStatus());

  Future<void> connect() async {
    state = const MikrotikConnectionStatus(
      state: MikrotikConnectionState.connecting,
    );

    try {
      await MikrotikConnector.connect();
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
