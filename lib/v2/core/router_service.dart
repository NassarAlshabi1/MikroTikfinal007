import 'package:router_os_client/router_os_client.dart';

import '../../mikrotik_connector.dart';
import '../../services/router_os_query_executor.dart';

/// Compatibility facade for the v2 providers.
///
/// Connection ownership stays in [MikrotikConnector] so the v2 screens use the
/// app's saved SSL/port settings and share its single-flight connection pool.
class RouterService {
  int port = 8729;

  static final RouterService _instance = RouterService._internal();
  RouterService._internal();
  factory RouterService() => _instance;

  Future<void> ensureConnected() async {
    final client = await MikrotikConnector.connect();
    port = MikrotikConnector.currentPort;
    MikrotikConnector.release(client);
  }

  Future<List<Map<String, dynamic>>> talk(List<String> args) async {
    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      port = MikrotikConnector.currentPort;
      final response = await RouterOsQueryExecutor.talk(client, args)
          .timeout(const Duration(seconds: 10));
      return response.map((row) => Map<String, dynamic>.from(row)).toList();
    } finally {
      MikrotikConnector.release(client);
    }
  }

  Future<List<Map<String, dynamic>>> talkPaged({
    required String path,
    required String proplist,
    int limit = 20,
    int skip = 0,
  }) async {
    try {
      return await talk(
        [path, '=.proplist=$proplist', '=.limit=$limit', '=.skip=$skip'],
      );
    } catch (_) {
      return talk([path, '=.proplist=$proplist']);
    }
  }

  Future<void> reconnect() async {
    await close();
    await ensureConnected();
  }

  /// Explicit reconnect/close acts on the shared application connection.
  Future<void> close() async {
    MikrotikConnector.forceDisconnect();
  }
}
