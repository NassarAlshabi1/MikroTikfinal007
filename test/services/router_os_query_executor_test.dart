import 'package:flutter_test/flutter_test.dart';
import 'package:router_os_client/router_os_client.dart';

import 'package:mikrotik_manager/services/router_os_query_executor.dart';

class _FakeRouterOSClient extends RouterOSClient {
  _FakeRouterOSClient() : super(address: '127.0.0.1');

  dynamic lastCommand;
  Map<String, String>? lastParams;
  String? lastRequestedTag;
  TaggedResponse response = TaggedResponse(data: const [], isDone: true);

  @override
  Future<TaggedResponse> talkTagged(
    dynamic command, [
    Map<String, String>? params,
    String? tag,
  ]) async {
    lastCommand = command;
    lastParams = params;
    lastRequestedTag = tag;
    return response;
  }
}

void main() {
  group('RouterOsQueryExecutor', () {
    test('returns tagged response data and lets the client assign a unique tag',
        () async {
      final client = _FakeRouterOSClient()
        ..response = TaggedResponse(
          data: const [
            {'name': 'ether1'},
          ],
          tag: 'generated-tag',
          isDone: true,
        );

      final rows = await RouterOsQueryExecutor.talk(
        client,
        ['/interface/print'],
        params: const {'.proplist': 'name'},
      );

      expect(rows, const [
        {'name': 'ether1'},
      ]);
      expect(client.lastCommand, ['/interface/print']);
      expect(client.lastParams, const {'.proplist': 'name'});
      expect(client.lastRequestedTag, isNull);
    });

    test('converts RouterOS trap responses to RouterOSTrapError', () async {
      final client = _FakeRouterOSClient()
        ..response = TaggedResponse(
          data: const [],
          tag: 'generated-tag',
          isDone: true,
          isError: true,
          errorMessage: 'permission denied',
        );

      await expectLater(
        RouterOsQueryExecutor.talk(client, ['/system/resource/print']),
        throwsA(
          isA<RouterOSTrapError>().having(
            (error) => error.message,
            'message',
            contains('permission denied'),
          ),
        ),
      );
    });
  });
}
