import 'package:router_os_client/router_os_client.dart';

import '../mikrotik_connector.dart';
import 'mikrotik_service_mode.dart';
import 'router_os_card_gateway.dart';

class RouterOsPermissionSnapshot {
  final String username;
  final String group;
  final Set<String> policies;

  const RouterOsPermissionSnapshot({
    required this.username,
    required this.group,
    required this.policies,
  });

  bool get canRead => policies.contains('read');
  bool get canWrite => policies.contains('write');
  bool get canManageHotspot => canRead && canWrite;

  String get missingPolicies => <String>[
        if (!canRead) 'read',
        if (!canWrite) 'write',
      ].join('، ');
}

class RouterOsPermissionException implements Exception {
  final String message;
  final RouterOsPermissionSnapshot? snapshot;

  const RouterOsPermissionException(this.message, {this.snapshot});

  @override
  String toString() => message;
}

class RouterOsPermissionService {
  RouterOsPermissionService._();

  static Future<RouterOsPermissionSnapshot> preflight(
    MikrotikConnectionConfig config, {
    required MikrotikServiceMode mode,
  }) async {
    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connectWithConfig(config);
      final gateway = RouterOsPermissionReader(
        RouterOsClientTalker(client),
      );
      final snapshot = await gateway.inspect(config.user);
      if (!snapshot.canManageHotspot) {
        throw RouterOsPermissionException(
          'صلاحيات حساب MikroTik غير كافية لإدارة ${mode.name}: '
          'الصلاحيات الناقصة: ${snapshot.missingPolicies}.',
          snapshot: snapshot,
        );
      }
      return snapshot;
    } finally {
      MikrotikConnector.release(client);
    }
  }
}

class RouterOsPermissionReader {
  final RouterOsTalker talker;

  const RouterOsPermissionReader(this.talker);

  Future<RouterOsPermissionSnapshot> inspect(String username) async {
    final userRows = await talker.talk([
      '/user/print',
      '?name=$username',
      '=.proplist=name,group,policy',
    ]);
    if (userRows.isEmpty) {
      throw const RouterOsPermissionException(
        'تعذر العثور على حساب MikroTik الحالي للتحقق من الصلاحيات.',
      );
    }
    final user = userRows.first;
    final group = user['group']?.trim() ?? '';
    final directPolicies = _parsePolicies(user['policy']);
    final groupPolicies =
        group.isEmpty ? <String>{} : await _loadGroupPolicies(group);
    return RouterOsPermissionSnapshot(
      username: user['name']?.trim().isNotEmpty == true
          ? user['name']!.trim()
          : username,
      group: group,
      policies: {...directPolicies, ...groupPolicies},
    );
  }

  Future<Set<String>> _loadGroupPolicies(String group) async {
    final rows = await talker.talk([
      '/user/group/print',
      '?name=$group',
      '=.proplist=name,policy',
    ]);
    if (rows.isEmpty) return <String>{};
    return _parsePolicies(rows.first['policy']);
  }

  Set<String> _parsePolicies(String? value) {
    if (value == null || value.trim().isEmpty) return <String>{};
    return value
        .split(RegExp(r'[,;\s]+'))
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
  }
}
