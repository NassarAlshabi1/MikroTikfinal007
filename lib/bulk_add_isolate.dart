import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:router_os_client/router_os_client.dart';

import 'mikrotik_connector.dart';

class BulkAddIsolateData {
  final SendPort sendPort;
  final int count;
  final int length;
  final String prefix;
  final String sharedUsers;
  final String? selectedProfile;
  final String charType;
  final String cardType;
  final bool linkPasswordToFirstUser;
  final bool isVersion7OrNewer;
  final RootIsolateToken rootIsolateToken;
  final String customer;

  BulkAddIsolateData({
    required this.sendPort,
    required this.count,
    required this.length,
    required this.prefix,
    required this.sharedUsers,
    required this.selectedProfile,
    required this.charType,
    required this.cardType,
    required this.linkPasswordToFirstUser,
    required this.isVersion7OrNewer,
    required this.rootIsolateToken,
    required this.customer,
  });
}

/// عدد الكروت في الموجة (batch) التي تُرسل عبر اتصال واحد قبل الانتظار
/// على الاستجابات.
///
/// RouterOS يُنفّذ الأوامر على اتصال واحد تسلسلياً حتى لو أرسلناها
/// مرة واحدة — الـ tags تُزيل الـ blocking على الـ socket لكن لا
/// تُعيد التشغيل المتوازي على الراوتر. إذنّاً الموجة الواحدة تُرسل
/// [_waveSize] أوامر مرة واحدة (pipelining الـ socket)، ثم تنتظر
/// الاستجابات قبل الموجة التالية. 50 كرتاً = التوافق الأمثل بين
/// السرعة (×4-6 أسرع من 1-by-1) والاستقرار على الأجهزة المدمجة.
const int _waveSize = 50;

/// كل كم كرت يتم الإبلاغ عن تقدم جزئي من داخل الشارد نفسه، حتى لا تقفز
/// الواجهة بين 0% و100% على دفعات كبيرة (كان التقدم يُرسل عند اكتمال كل
/// شارد فقط: 4 قفزات كحد أقصى).
const int _progressReportCardInterval = 25;

void bulkAddIsolate(BulkAddIsolateData data) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(data.rootIsolateToken);
  final sendPort = data.sendPort;

  final created = <Map<String, String>>[];
  final failedAdds = <Map<String, String>>[];

  // ── إنشاء MULTIPLE اتصالات بالتوازي ──
  // النسخة القديمة استخدمت اتصالاً واحداً واحدة تلو الأخرى.
  // الآن نفتح shardCount اتصالاً متوازياً لتوزيع الأحمال على الراوتر.
  final shardCount = min(4, max(1, data.count ~/ _waveSize));
  final shardUsers = _buildUsers(data);
  final shardSize = (shardUsers.length / shardCount).ceil();
  final allShardClients = <RouterOSClient>[];

  try {
    // إنشاء كل الاتصالات بالتوازي مرة واحدة — يوفر (shardCount-1) × login-latency.
    final clientFutures = <Future<RouterOSClient>>[
      for (var s = 0; s < shardCount; s++) MikrotikConnector.connect(),
    ];
    final shardClientsList = await Future.wait(
      clientFutures,
      cleanUp: (future) {
        future.then((client) => client.close()).catchError((_) {});
      },
    );
    allShardClients.addAll(shardClientsList);

    // توزيع المستخدمين على الشوارد.
    final futures = <Future<List<Map<String, String>>>>[];
    for (var s = 0; s < shardCount; s++) {
      final start = s * shardSize;
      final end = min(start + shardSize, shardUsers.length);
      if (start >= shardUsers.length) break;
      final chunk = shardUsers.sublist(start, end);
      futures.add(
        _processShard(
          users: chunk,
          client: shardClientsList[s],
          selectedProfile: data.selectedProfile!,
          sharedUsers: data.sharedUsers,
          isVersion7OrNewer: data.isVersion7OrNewer,
          customer: data.customer,
          charType: data.charType,
          linkPasswordToFirstUser: data.linkPasswordToFirstUser,
          sendPort: sendPort,
          cardsBefore: start,
          totalCards: shardUsers.length,
          failedAdds: failedAdds,
        ),
      );
    }

    final results = await Future.wait(futures);
    for (final shardCreated in results) {
      created.addAll(shardCreated);
    }
  } on MikrotikCredentialsMissingException catch (e) {
    sendPort.send({
      'type': 'error',
      'message': 'خطأ في بيانات الدخول: ${e.message}',
      'count': created.length,
    });
    return;
  } on MikrotikConnectionException catch (e) {
    sendPort.send({
      'type': 'error',
      'message': 'خطأ في الاتصال: ${e.message}',
      'count': created.length,
    });
    return;
  } on TimeoutException {
    sendPort.send({
      'type': 'error',
      'message': 'انتهت مهلة الاتصال بالراوتر.',
      'count': created.length,
    });
    return;
  } catch (e) {
    sendPort.send({
      'type': 'error',
      'message': e.toString(),
      'count': created.length,
    });
    return;
  } finally {
    for (final client in allShardClients) {
      try {
        client.close();
      } catch (_) {}
    }
  }

  if (created.isEmpty && failedAdds.isEmpty) {
    sendPort.send({
      'type': 'error',
      'message': 'فشل إنشاء أي كرت على الراوتر.',
      'count': 0,
    });
    return;
  }

  sendPort.send({
    'type': 'success',
    'users': created,
    'count': created.length,
    'failedCount': failedAdds.length,
    'address': allShardClients.first.address,
    'failed': failedAdds,
  });
}

/// معالجة شارد واحد — يرسل بطاقاته في موجات باستخدام talkMultiple.
Future<List<Map<String, String>>> _processShard({
  required List<Map<String, String>> users,
  required RouterOSClient client,
  required String selectedProfile,
  required String sharedUsers,
  required bool isVersion7OrNewer,
  required String customer,
  required String charType,
  required bool linkPasswordToFirstUser,
  required SendPort sendPort,
  required int cardsBefore,
  required int totalCards,
  required List<Map<String, String>> failedAdds,
}) async {
  final createdInShard = <Map<String, String>>[];
  var processed = 0;

  final waveSize = min(_waveSize, users.length);
  final perWaveTimeout = Duration(seconds: min(max(30, waveSize * 4), 1800));

  for (var waveStart = 0; waveStart < users.length; waveStart += waveSize) {
    final waveEnd = min(waveStart + waveSize, users.length);
    final waveUsers = users.sublist(waveStart, waveEnd);

    final taggedCommands = <TaggedCommand>[];
    for (var i = 0; i < waveUsers.length; i++) {
      final user = waveUsers[i];
      final username = user['username']!;
      final password = user['password']!;
      final globalIdx = waveStart + i;

      taggedCommands.add(
        TaggedCommand(
          command: _addUserCommand(
            username: username,
            password: password,
            sharedUsers: sharedUsers,
            isVersion7OrNewer: isVersion7OrNewer,
            customer: customer,
          ),
          tag: 'add_$globalIdx',
        ),
      );

      taggedCommands.add(
        TaggedCommand(
          command: _activateCommand(
            customer: customer,
            username: username,
            profile: selectedProfile,
          ),
          tag: 'act_$globalIdx',
        ),
      );
    }

    final responses = client
        .talkMultiple(taggedCommands)
        .timeout(perWaveTimeout);

    await for (final resp in responses) {
      final tag = resp.tag;
      if (tag != null && resp.isDone) {
        if (tag.startsWith('add_')) {
          final idx = int.parse(tag.substring(4));
          if (idx >= 0 && idx < users.length) {
            processed++;
            if (resp.isError) {
              failedAdds.add({
                'username': users[idx]['username']!,
                'reason': resp.errorMessage ?? 'فشل إضافة الكرت على الراوبر.',
              });
            } else {
              final userId = _extractUserId(resp.data);
              createdInShard.add({
                'username': users[idx]['username']!,
                'password': users[idx]['password']!,
                if (userId != null) 'id': userId,
              });
            }
            // تقدم مخفض لتفادي حمل القناة.
            if (processed % _progressReportCardInterval == 0) {
              final done = cardsBefore + processed;
              final createdHere = cardsBefore + createdInShard.length;
              sendPort.send({
                'type': 'progress',
                'progress': totalCards == 0 ? 1.0 : done / totalCards,
                'status':
                    'تمت معالجة $done من $totalCards كرت (أنشئ $createdHere)',
              });
            }
          }
        }
      }
    }
  }

  return createdInShard;
}

List<String> _addUserCommand({
  required String username,
  required String password,
  required String sharedUsers,
  required bool isVersion7OrNewer,
  required String customer,
}) {
  return [
    '/tool/user-manager/user/add',
    '=username=$username',
    '=password=$password',
    '=shared-users=$sharedUsers',
    if (!isVersion7OrNewer) '=customer=$customer',
  ];
}

List<String> _activateCommand({
  required String customer,
  required String username,
  required String profile,
}) => [
  '/tool/user-manager/user/create-and-activate-profile',
  '=customer=$customer',
  '=numbers=$username',
  '=profile=$profile',
];

String? _extractUserId(List<Map<String, String>> response) {
  for (final row in response) {
    final id = row['.id']?.trim();
    if (id != null && id.isNotEmpty) return id;
  }
  return null;
}

List<Map<String, String>> _buildUsers(BulkAddIsolateData data) {
  final users = <Map<String, String>>[];
  final generatedUsernames = <String>{};
  var firstGeneratedUsername = '';

  for (var i = 0; i < data.count; i++) {
    final username = _generateUniqueUsername(
      length: data.length,
      prefix: data.prefix,
      charType: data.charType,
      existingUsernames: generatedUsernames,
    );
    final password = _generatePassword(
      linkPasswordToFirstUser: data.linkPasswordToFirstUser,
      index: i,
      username: username,
      cardType: data.cardType,
      charType: data.charType,
      length: data.length,
      prefix: data.prefix,
      firstGeneratedUsername: firstGeneratedUsername,
    );
    if (data.linkPasswordToFirstUser && i == 0) {
      firstGeneratedUsername = username;
    }
    users.add({'username': username, 'password': password});
  }
  return users;
}

String _generateUniqueUsername({
  required int length,
  required String prefix,
  required String charType,
  required Set<String> existingUsernames,
}) {
  const maxAttempts = 1000;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final username =
        prefix + _generateRandomString(length - prefix.length, charType);
    if (existingUsernames.add(username)) return username;
  }
  throw StateError(
    'تعذر توليد أسماء مستخدمين فريدة. زد الطول أو قلل عدد الكروت.',
  );
}

String _generatePassword({
  required bool linkPasswordToFirstUser,
  required int index,
  required String username,
  required String cardType,
  required String charType,
  required int length,
  required String prefix,
  required String firstGeneratedUsername,
}) {
  if (linkPasswordToFirstUser) {
    return index == 0 ? username : firstGeneratedUsername;
  }
  if (cardType == 'username_and_password_equal') return username;
  if (cardType == 'username_and_password_different') {
    final passwordLength = max(8, length - prefix.length);
    return _generateRandomString(passwordLength, charType);
  }
  return username;
}

final Random _random = Random.secure();

String _generateRandomString(int length, String type) {
  if (length <= 0) return '';
  const charsMixed = 'abcdefghijklmnopqrstuvwxyz0123456789';
  const charsLetters = 'abcdefghijklmnopqrstuvwxyz';
  const charsNumbers = '0123456789';
  String chars;
  if (type == 'letters') {
    chars = charsLetters;
  } else if (type == 'numbers') {
    chars = charsNumbers;
  } else {
    chars = charsMixed;
  }
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
    ),
  );
}
