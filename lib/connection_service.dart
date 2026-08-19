import 'dart:async';
import 'package:router_os_client/router_os_client.dart';
import 'mikrotik_connector.dart';

/// خدمة اتصال مركزية تدير اتصال MikroTik المشترك بين جميع الشاشات
/// تتجنب فتح وإغلاق الاتصال في كل عملية وتوفر إعادة اتصال تلقائية
class ConnectionService {
  static final ConnectionService _instance = ConnectionService._();
  static ConnectionService get instance => _instance;
  ConnectionService._();

  RouterOSClient? _client;
  DateTime? _lastUsed;
  bool _isConnecting = false;
  _ConnectionIdentity? _activeIdentity;

  /// مدة الخمول قبل قطع الاتصال تلقائياً
  static const _idleTimeout = Duration(minutes: 5);

  /// الحصول على اتصال نشط أو إنشاء واحد جديد.
  ///
  /// تمرير بيانات الاتصال مهم في شاشة الدخول؛ فلا نعتمد على SharedPreferences
  /// قبل نجاح المصادقة، ولا نفتح جلسة ثانية عند الانتقال إلى لوحة التحكم.
  Future<RouterOSClient> getClient({
    String? address,
    String? username,
    String? password,
    int? port,
  }) async {
    final requestedIdentity =
        address == null && username == null && password == null && port == null
            ? null
            : _ConnectionIdentity(address, username, password, port);

    while (_isConnecting) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final isReusable =
        _client != null &&
        _lastUsed != null &&
        DateTime.now().difference(_lastUsed!) < _idleTimeout &&
        (requestedIdentity == null || requestedIdentity == _activeIdentity);
    if (isReusable) {
      _lastUsed = DateTime.now();
      return _client!;
    }

    await _closeExistingClient();
    return _createNewClient(requestedIdentity);
  }

  Future<RouterOSClient> _createNewClient(_ConnectionIdentity? identity) async {
    _isConnecting = true;
    try {
      if (identity == null) {
        _client = await MikrotikConnector.connect();
      } else {
        final address = identity.address?.trim();
        final username = identity.username?.trim();
        final password = identity.password;
        if (address == null ||
            address.isEmpty ||
            username == null ||
            username.isEmpty ||
            password == null) {
          throw ArgumentError(
            'Complete MikroTik connection credentials are required.',
          );
        }

        _client = await MikrotikConnector.connectWithConfig(
          MikrotikConnectionConfig(
            address: address,
            user: username,
            password: password,
            port: identity.port ?? 8728,
            useSsl: identity.port == 8729,
          ),
        );
      }
      _activeIdentity = identity;
      _lastUsed = DateTime.now();
      return _client!;
    } catch (e) {
      _client = null;
      _lastUsed = null;
      _activeIdentity = null;
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _closeExistingClient() async {
    try {
      _client?.close();
    } catch (e) {
      // تجاهل أخطاء الإغلاق
    } finally {
      _client = null;
      _lastUsed = null;
      _activeIdentity = null;
    }
  }

  /// قطع الاتصال فوراً (عند تسجيل الخروج مثلاً)
  Future<void> disconnect() async {
    await _closeExistingClient();
  }

  /// تحديث وقت آخر استخدام لمنع الانتهاء التلقائي
  void keepAlive() {
    _lastUsed = DateTime.now();
  }

  /// التحقق مما إذا كان هناك اتصال نشط
  bool get isConnected =>
      _client != null &&
      _lastUsed != null &&
      DateTime.now().difference(_lastUsed!) < _idleTimeout;
}

class _ConnectionIdentity {
  final String? address;
  final String? username;
  final String? password;
  final int? port;

  const _ConnectionIdentity(
    this.address,
    this.username,
    this.password,
    this.port,
  );

  @override
  bool operator ==(Object other) =>
      other is _ConnectionIdentity &&
      other.address == address &&
      other.username == username &&
      other.password == password &&
      other.port == port;

  @override
  int get hashCode => Object.hash(address, username, password, port);
}
