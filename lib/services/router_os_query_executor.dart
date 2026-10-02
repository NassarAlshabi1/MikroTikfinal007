import 'package:router_os_client/router_os_client.dart';

/// Executes RouterOS read commands with unique API tags.
///
/// `RouterOSClient.talk()` without an explicit tag is intended for legacy,
/// sequential use. Use this executor when requests may overlap on a shared
/// client so replies are correlated to the command that produced them.
class RouterOsQueryExecutor {
  const RouterOsQueryExecutor._();

  static Future<List<Map<String, String>>> talk(
    RouterOSClient client,
    dynamic command, {
    Map<String, String>? params,
    Duration? timeout,
  }) async {
    final taggedFuture = client.talkTagged(command, params);
    final response = timeout == null
        ? await taggedFuture
        : await taggedFuture.timeout(timeout);

    if (response.isError) {
      throw RouterOSTrapError(
        'Command: $command\nReturned an error: ${response.errorMessage}',
      );
    }
    return response.data;
  }
}
