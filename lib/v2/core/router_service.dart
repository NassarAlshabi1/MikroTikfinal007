import 'dart:async';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/secure_credentials_storage.dart';

class RouterService {
  RouterOSClient? _client;
  AsyncMemoizer<void>? _lock = AsyncMemoizer<void>();
  int port = 8729;
  static final RouterService _instance = RouterService._internal();
  RouterService._internal();
  factory RouterService() => _instance;

  Future<void> ensureConnected() async {
    if (_client != null) return;
    final lock = _lock!;
    await lock.runOnce(() async {
      if (_client != null) return;
      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString('ip');
      final user = prefs.getString('user');
      final pass = await SecureCredentialsStorageContainer.instance.getMikrotikPassword();
      final p = int.tryParse(prefs.getString('port') ?? '') ?? 8729;
      port = p;
      if (ip == null || user == null || pass == null || pass.isEmpty) {
        throw Exception('Credentials missing');
      }
      final c = RouterOSClient(address: ip, user: user, password: pass, port: port, verbose: false);
      final ok = await c.login().timeout(const Duration(seconds: 5));
      if (!ok) throw Exception('Login failed');
      _client = c;
    });
  }

  Future<List<Map<String, dynamic>>> talk(List<String> args) async {
    await ensureConnected();
    return (await _client!.talk(args).timeout(const Duration(seconds: 10)))
        .map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> talkPaged({required String path, required String proplist, int limit=20, int skip=0}) async {
    try { return await talk([path,'=.proplist=$proplist','=.limit=$limit','=.skip=$skip']); }
    catch (_) { return await talk([path,'=.proplist=$proplist']); }
  }

  Future<void> reconnect() async { await close(); _lock=AsyncMemoizer<void>(); await ensureConnected(); }
  Future<void> close() async { _client?.close(); _client=null; }
}
class AsyncMemoizer<T> { Future<T>? _future; Future<T> runOnce(Future<T> Function() computation){ return _future ??= computation(); } Future<T> get future => _future ?? Future.error(StateError('No future')); }
