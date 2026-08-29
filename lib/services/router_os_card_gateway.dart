import 'dart:async';
import 'dart:io';

import 'package:router_os_client/router_os_client.dart';

import '../mikrotik_connector.dart';
import 'mikrotik_card_commands.dart';
import 'mikrotik_service_mode.dart';

abstract interface class RouterOsTalker {
  String get address;

  Future<List<Map<String, String>>> talk(List<String> command);
}

class RouterOsClientTalker implements RouterOsTalker {
  final RouterOSClient client;

  const RouterOsClientTalker(this.client);

  @override
  String get address => client.address;

  @override
  Future<List<Map<String, String>>> talk(List<String> command) {
    return client.talk(command);
  }
}

class RouterOsVerificationException implements Exception {
  final String message;
  final List<Map<String, String>> confirmedUsers;
  final List<String> missingUsernames;

  const RouterOsVerificationException({
    required this.message,
    required this.confirmedUsers,
    required this.missingUsernames,
  });

  @override
  String toString() => message;
}

class RouterOsCreatedCard {
  final String username;
  final String password;
  final String? mikrotikUserId;

  const RouterOsCreatedCard({
    required this.username,
    required this.password,
    this.mikrotikUserId,
  });

  Map<String, String> toMap() => {
        'username': username,
        'password': password,
        if (mikrotikUserId != null) 'mikrotikUserId': mikrotikUserId!,
      };
}

class RouterOsCardGateway {
  final RouterOsTalker talker;

  /// مهلة لكل أمر talk — وفيرة بما يكفي للراوترات البطيئة
  /// لكنها تمنع التعليق الدائم.
  static const _talkTimeout = Duration(seconds: 60);

  const RouterOsCardGateway(this.talker);

  Future<RouterOsCreatedCard> addCard({
    required MikrotikServiceMode mode,
    required String username,
    required String password,
    required String profile,
    required String sharedUsers,
    required bool isVersion7OrNewer,
    required String customer,
  }) async {
    final response = await talker.talk(
      MikrotikCardCommands.addUser(
        mode: mode,
        username: username,
        password: password,
        profile: profile,
        sharedUsers: sharedUsers,
        isVersion7OrNewer: isVersion7OrNewer,
        customer: customer,
      ),
    ).timeout(_talkTimeout, onTimeout: () {
      throw TimeoutException(
        'انتهت مهلة إنشاء الكرت "$username" على الراوتر. '
        'تحقق من اتصال الشبكة وإعدادات User Manager.',
      );
    });
    final userId = _extractUserId(response);
    return RouterOsCreatedCard(
      username: username,
      password: password,
      mikrotikUserId: userId,
    );
  }

  Future<void> activateUserManagerProfile({
    required String customer,
    required String username,
    required String profile,
  }) async {
    await talker.talk(
      MikrotikCardCommands.userManagerActivateProfile(
        customer: customer,
        username: username,
        profile: profile,
      ),
    ).timeout(_talkTimeout, onTimeout: () {
      throw TimeoutException(
        'انتهت مهلة تنشيط البروفايل "$profile" للمستخدم "$username".',
      );
    });
  }

  Future<List<Map<String, String>>> verifyUsers({
    required MikrotikServiceMode mode,
    required List<Map<String, String>> users,
  }) async {
    final confirmed = <Map<String, String>>[];
    final missing = <String>[];

    // ── استراتيجية التحقق الأسرع ──
    // بدلاً من talk() لكل مستخدم (N مكالمات متتالية)،
    // نجلب جميع المستخدمين في مكالمة واحدة ونتحقق محلياً.
    // هذا يُسرّع التحقق من ×10 إلى ×100.
    late final List<Map<String, String>> allRemoteUsers;
    try {
      allRemoteUsers = await _readWithRetry(_allUsersCommand(mode));
    } catch (error) {
      throw RouterOsVerificationException(
        message: 'انقطع الاتصال أثناء التحقق من كروت RouterOS: $error',
        confirmedUsers: [],
        missingUsernames: users
            .map((item) => item['username']?.trim() ?? '')
            .where((name) => name.isNotEmpty)
            .toList(growable: false),
      );
    }

    // بناء فهرس محلي للمستخدمين الموجودين
    final remoteIndex = <String, Map<String, String>>{};
    for (final row in allRemoteUsers) {
      final name = (row['username'] ?? row['name'] ?? '').trim();
      if (name.isNotEmpty) {
        remoteIndex[name] = row;
      }
    }

    for (final user in users) {
      final username = user['username']?.trim() ?? '';
      if (username.isEmpty) continue;

      final row = remoteIndex[username];
      if (row == null) {
        missing.add(username);
        continue;
      }
      confirmed.add({
        ...user,
        if ((row['.id']?.trim() ?? '').isNotEmpty)
          'mikrotikUserId': row['.id']!.trim(),
      });
    }

    if (missing.isNotEmpty) {
      throw RouterOsVerificationException(
        message: 'تعذر التحقق من ${missing.length} كرت على RouterOS.',
        confirmedUsers: confirmed,
        missingUsernames: missing,
      );
    }
    return confirmed;
  }

  Future<List<Map<String, String>>> _readWithRetry(
    List<String> command,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await talker.talk(command).timeout(_talkTimeout, onTimeout: () {
          throw TimeoutException(
            'انتهت مهلة التحقق من المستخدم على الراوتر.',
          );
        });
      } on SocketException catch (error) {
        lastError = error;
      } on TimeoutException catch (error) {
        lastError = error;
      } on MikrotikConnectionException catch (error) {
        lastError = error;
      }
      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }
    throw lastError ?? StateError('تعذر التحقق من كروت RouterOS.');
  }

  /// جلب جميع المستخدمين في مكالمة واحدة (للمقارنة المحلية السريعة)
  List<String> _allUsersCommand(MikrotikServiceMode mode) {
    return switch (mode) {
      MikrotikServiceMode.hotspot => [
          '/ip/hotspot/user/print',
          '=.proplist=.id,name',
        ],
      MikrotikServiceMode.userManager => [
          '/tool/user-manager/user/print',
          '=.proplist=.id,username',
        ],
    };
  }


  String? _extractUserId(List<Map<String, String>> response) {
    for (final row in response) {
      final id = row['.id']?.trim();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }
}
