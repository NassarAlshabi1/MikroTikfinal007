import 'package:flutter_test/flutter_test.dart';

import 'package:mikrotik_manager/services/bulk_card_generation_service.dart';
import 'package:mikrotik_manager/services/card_generation_job_service.dart';
import 'package:mikrotik_manager/services/router_os_card_gateway.dart';
import 'package:mikrotik_manager/services/router_os_permission_service.dart';

void main() {
  test('تحول GeneratedCard وGenerationEvent البيانات إلى عقد typed', () {
    final card = GeneratedCard.fromMap({
      'username': ' 10000001 ',
      'password': 'secret',
      'mikrotikUserId': '*1',
    });
    final event = GenerationEvent.fromRaw({
      'type': 'success',
      'users': [card.toMap()],
      'count': 1,
      'failedCount': 2,
      'warning': 'تعذر إكمال التحقق.',
      'address': '192.0.2.1',
    });

    expect(card.username, '10000001');
    expect(card.mikrotikUserId, '*1');
    expect(event.type, 'success');
    expect(event.users.single.username, '10000001');
    expect(event.count, 1);
    expect(event.failedCount, 2);
    expect(event.warning, 'تعذر إكمال التحقق.');
  });

  test('GenerationEvent يقرأ قيم failedCount و warning الافتراضية', () {
    final event = GenerationEvent.fromRaw({
      'type': 'success',
      'users': [],
    });

    expect(event.failedCount, 0);
    expect(event.warning, isEmpty);
  });

  test('بصمة Job ثابتة رغم اختلاف ترتيب parameters', () {
    final first = CardGenerationJobService.fingerprint(
      routerAddress: '192.0.2.1',
      profileName: 'default',
      serviceMode: 'hotspot',
      parameters: const {
        'length': 8,
        'prefix': '100',
        'charType': 'numbers',
      },
    );
    final second = CardGenerationJobService.fingerprint(
      routerAddress: '192.0.2.1',
      profileName: 'default',
      serviceMode: 'hotspot',
      parameters: const {
        'charType': 'numbers',
        'prefix': '100',
        'length': 8,
      },
    );
    final differentRouter = CardGenerationJobService.fingerprint(
      routerAddress: '198.51.100.1',
      profileName: 'default',
      serviceMode: 'hotspot',
      parameters: const {
        'length': 8,
        'prefix': '100',
        'charType': 'numbers',
      },
    );

    expect(first, second);
    expect(first, isNot(differentRouter));
  });

  test('يقرأ صلاحيات المستخدم ومجموعته دون تنفيذ أي أمر تعديل', () async {
    final reader = RouterOsPermissionReader(
      FakePermissionTalker({
        '/user/print': [
          {'name': 'admin', 'group': 'full'},
        ],
        '/user/group/print': [
          {'name': 'full', 'policy': 'local,read,write,policy,test'},
        ],
      }),
    );

    final snapshot = await reader.inspect('admin');

    expect(snapshot.canRead, isTrue);
    expect(snapshot.canWrite, isTrue);
    expect(snapshot.canManageHotspot, isTrue);
  });

  test('يحدد الصلاحية الناقصة بدقة', () async {
    final reader = RouterOsPermissionReader(
      FakePermissionTalker({
        '/user/print': [
          {'name': 'limited', 'group': 'read-only'},
        ],
        '/user/group/print': [
          {'name': 'read-only', 'policy': 'read'},
        ],
      }),
    );

    final snapshot = await reader.inspect('limited');

    expect(snapshot.canRead, isTrue);
    expect(snapshot.canWrite, isFalse);
    expect(snapshot.missingPolicies, 'write');
  });
}

class FakePermissionTalker implements RouterOsTalker {
  FakePermissionTalker(this.responses);

  final Map<String, List<Map<String, String>>> responses;

  @override
  String get address => 'permission-mock';

  @override
  Future<List<Map<String, String>>> talk(List<String> command) async {
    return responses[command.first] ?? const [];
  }
}
