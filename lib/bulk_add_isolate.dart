import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:isar/isar.dart';
import 'package:router_os_client/router_os_client.dart';

import 'database/isar/ai_diagnostic_collection.dart';
import 'database/isar/card_collection.dart';
import 'database/isar/card_generation_job.dart';
import 'database/isar/executed_command_collection.dart';
import 'database/isar/profile_collection.dart';
import 'mikrotik_connector.dart';
import 'services/card_number_policy.dart';
import 'services/card_persistence_service.dart';
import 'services/mikrotik_service_mode.dart';
import 'services/mikrotik_card_commands.dart';
import 'services/router_os_card_gateway.dart';

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
  final MikrotikConnectionConfig connectionConfig;
  final String customer;
  final MikrotikServiceMode serviceMode;
  final List<Map<String, String>>? plannedUsers;

  /// مجلد قاعدة بيانات Isar (يُمرَّر حتى يفتح الـ Isolate نسخته الخاصة منها
  /// دون الاعتماد على قنوات المنصة في Isolate الخلفية).
  final String isarDirectory;

  /// معرّف Job التوليد الحالي؛ يُسجَّل على الكروت المحجوزة محلياً.
  final String generationJobId;

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
    required this.connectionConfig,
    required this.customer,
    required this.isarDirectory,
    required this.generationJobId,
    this.serviceMode = MikrotikServiceMode.userManager,
    this.plannedUsers,
  });
}

// ================================================================
//  SHARD WORKER — processes a chunk of cards on ONE connection
//  via talkMultiple, returning created users.
// ================================================================
Future<List<Map<String, String>>> _processShard({
  required List<Map<String, String>> users,
  required RouterOSClient client,
  required MikrotikServiceMode serviceMode,
  required String profile,
  required BulkAddIsolateData data,
}) async {
  final created = <Map<String, String>>[];

  // Build all tagged commands for this shard at once
  final taggedCommands = <TaggedCommand>[];
  for (var i = 0; i < users.length; i++) {
    final user = users[i];
    final username = user['username']!;
    final password = user['password']!;

    taggedCommands.add(TaggedCommand(
      command: MikrotikCardCommands.addUser(
        mode: serviceMode,
        username: username,
        password: password,
        profile: profile,
        sharedUsers: data.sharedUsers,
        isVersion7OrNewer: false,
        customer: data.customer,
      ),
      tag: 'add_$i',
    ));

    if (serviceMode == MikrotikServiceMode.userManager) {
      taggedCommands.add(TaggedCommand(
        command: MikrotikCardCommands.userManagerActivateProfile(
          customer: data.customer,
          username: username,
          profile: profile,
        ),
        tag: 'act_$i',
      ));
    }
  }

  // Fire all commands at once
  final timeout = Duration(seconds: max(60, users.length * 15));
  final responses = client.talkMultiple(taggedCommands).timeout(timeout);

  // Collect
  final addResults = <int, List<Map<String, String>>>{};
  await for (final resp in responses) {
    final tag = resp.tag;
    if (tag != null && tag.startsWith('add_')) {
      final idx = int.parse(tag.substring(4));
      addResults[idx] = resp.data;
    }
  }

  for (var i = 0; i < users.length; i++) {
    final result = addResults[i];
    if (result == null || result.isEmpty) continue;

    final userId = _extractUserId(result);
    created.add({
      'username': users[i]['username']!,
      'password': users[i]['password']!,
      if (userId != null) 'mikrotikUserId': userId,
    });
  }

  return created;
}

// ================================================================
//  MAIN ISOLATE ENTRY POINT
// ================================================================
void bulkAddIsolate(BulkAddIsolateData data) async {
  final sendPort = data.sendPort;
  int successCount = 0;
  final newlyCreatedUsers = <Map<String, String>>[];
  Isar? localIsar;

  try {
    _validateInput(data);
    final plannedUsers = data.plannedUsers ?? _buildUsers(data);

    // ============================================================
    //  حجز الأسماء محلياً داخل الـ Isolate قبل لمس الراوتر.
    //  لا يوجد Handshake مع Isolate الواجهة إطلاقاً:
    //  - الـ Isolate لا يتوقف منتظراً موافقة.
    //  - الواجهة لا تنفذ أي عمليات Isar أثناء التوليد (لا تجمد).
    //  - يُفتح مثيل Isar خاص بالـ Isolate من نفس ملف القاعدة، ويسحب
    //    تلقائياً أي تغييرات من وإلى مثيل الواجهة (Isar 3+).
    // ============================================================
    if (data.plannedUsers == null) {
      localIsar = await _openLocalIsar(data.isarDirectory);
      final preparation = await CardPersistenceService.prepareGeneratedCards(
        isar: localIsar,
        profileName: data.selectedProfile!.trim(),
        users: plannedUsers,
        sharedUsers: CardNumberPolicy.parseAsciiInteger(
              data.sharedUsers.trim(),
            ) ??
            1,
        generationJobId: data.generationJobId,
      );
      if (!preparation.canProceed) {
        final conflicts = preparation.conflicts.take(5).join('، ');
        throw FormatException(
          conflicts.isEmpty
              ? 'تعذر حجز الكروت في Isar.'
              : 'الأسماء موجودة محلياً: $conflicts',
        );
      }
      await localIsar.close();
      localIsar = null;
    }

    // إعلام الواجهة فقط (للعرض/السجل) — بدون انتظار أي رد.
    sendPort.send({
      'type': 'prepared',
      'users': plannedUsers,
      'resumable': data.plannedUsers != null,
    });

    final profile = data.selectedProfile!.trim();

    // ============================================================
    //  PARALLEL SHARDS: split cards across N independent connections
    //  Each shard runs talkMultiple on its own connection.
    //  True parallelism = N× speedup.
    //  Connections are closed immediately after each shard completes.
    // ============================================================
    final shardCount = min(4, plannedUsers.length); // 1-4 connections
    final shardSize = (plannedUsers.length / shardCount).ceil();
    final futures = <Future<List<Map<String, String>>>>[];
    final shardClients = <RouterOSClient>[];

    for (var s = 0; s < shardCount; s++) {
      final start = s * shardSize;
      final end = min(start + shardSize, plannedUsers.length);
      if (start >= plannedUsers.length) break;
      final shardUsers = plannedUsers.sublist(start, end);

      // Each shard gets its own connection — we track it to close later
      final shardClient =
          await MikrotikConnector.connectWithConfig(data.connectionConfig);
      shardClients.add(shardClient);
      futures.add(_processShard(
        users: shardUsers,
        client: shardClient,
        serviceMode: data.serviceMode,
        profile: profile,
        data: data,
      ));
    }

    // Run all shards in parallel and close connections as they complete
    int completedCards = 0;
    final shardResults = <List<Map<String, String>>>[];
    for (final future in futures) {
      final shardResult = await future;
      shardResults.add(shardResult);
      completedCards += shardResult.length;
      // Report progress after each shard completes
      sendPort.send({
        'type': 'progress',
        'progress': completedCards / plannedUsers.length,
        'status': 'تم إنشاء $completedCards من ${plannedUsers.length} كرت',
      });
    }

    // Close all shard connections
    for (final client in shardClients) {
      MikrotikConnector.release(client);
    }

    // Merge results in order
    for (final shardResult in shardResults) {
      for (final user in shardResult) {
        newlyCreatedUsers.add(user);
        successCount++;
      }
    }

    // Verify all created users (single API call, not per-user)
    RouterOSClient? verifyClient;
    try {
      verifyClient =
          await MikrotikConnector.connectWithConfig(data.connectionConfig);
      final gateway = RouterOsCardGateway(RouterOsClientTalker(verifyClient));
      final verifiedUsers = await gateway.verifyUsers(
        mode: data.serviceMode,
        users: newlyCreatedUsers,
      );

      sendPort.send({
        'type': 'success',
        'users': verifiedUsers,
        'count': verifiedUsers.length,
        'address': data.connectionConfig.address,
      });
    } finally {
      if (verifyClient != null) {
        MikrotikConnector.release(verifyClient);
      }
    }
  } on RouterOsVerificationException catch (e) {
    _sendError(sendPort, e.message, e.confirmedUsers.length, e.confirmedUsers);
  } on MikrotikCredentialsMissingException catch (e) {
    _sendError(sendPort, 'خطأ في بيانات الدخول: ${e.message}', successCount,
        newlyCreatedUsers);
  } on MikrotikConnectionException catch (e) {
    _sendError(sendPort, 'خطأ في الاتصال: ${e.message}', successCount,
        newlyCreatedUsers);
  } on RouterOSTrapError catch (e) {
    _sendError(
        sendPort, _friendlyError(e.message), successCount, newlyCreatedUsers);
  } on TimeoutException {
    _sendError(
      sendPort,
      'فشل الاتصال بالراوتر (انتهت مهلة الاتصال).\n'
      'تأكد من اتصال الشبكة بالراوتر وصحة إعدادات API (المنفذ 8728/8729).',
      successCount,
      newlyCreatedUsers,
    );
  } on FormatException catch (e) {
    _sendError(sendPort, e.message.toString(), successCount, newlyCreatedUsers);
  } catch (e) {
    _sendError(sendPort, _friendlyError(e), successCount, newlyCreatedUsers);
  } finally {
    await localIsar?.close();
  }
}

/// يفتح مثيل Isar خاصاً بالـ Isolate من نفس ملف قاعدة بيانات الواجهة.
///
/// - يُمرَّر مسار المجلد من الواجهة لتجنب استدعاء path_provider (قنوات المنصة)
///   من داخل الـ Isolate.
/// - يجب تمرير نفس مخططات الواجهة بالضبط (Isar يرفض المخططات المختلفة عند
///   إعادة فتح نفس القاعدة في Isolate آخر).
/// - تُفتح بمعرّف افتراضي ('default') مطابقاً لـ IsarProvider حتى يُعاد استخدام
///   نفس المثيل، وتُزامَن التغييرات تلقائياً بين الـ Isolates.
/// - يُفتح بـ inspector معطل تجنباً لأي تعارض مع مثيل الواجهة أثناء التطوير.
Future<Isar> _openLocalIsar(String directory) {
  return Isar.open(
    const [
      CardCollectionSchema,
      CardGenerationJobSchema,
      ProfileCollectionSchema,
      AiDiagnosticCollectionSchema,
      ExecutedCommandCollectionSchema,
    ],
    directory: directory,
    inspector: false,
  );
}

// ================================================================
//  HELPERS
// ================================================================

String? _extractUserId(List<Map<String, String>> response) {
  for (final row in response) {
    final id = row['.id']?.trim();
    if (id != null && id.isNotEmpty) return id;
  }
  return null;
}

void _validateInput(BulkAddIsolateData data) {
  if (data.count < 1 || data.count > 10000) {
    throw const FormatException('عدد الكروت يجب أن يكون بين 1 و10000.');
  }
  if (data.plannedUsers == null) {
    if (data.length < 1 || data.length > 64) {
      throw const FormatException('طول اسم المستخدم يجب أن يكون بين 1 و64.');
    }
    if (data.prefix.length >= data.length) {
      throw const FormatException(
          'طول البادئة يجب أن يكون أقل من الطول الإجمالي للمستخدم.');
    }
  }
  if (data.selectedProfile == null || data.selectedProfile!.trim().isEmpty) {
    throw const FormatException('يجب اختيار فئة User Manager.');
  }
  final sharedUsers =
      CardNumberPolicy.parseAsciiInteger(data.sharedUsers.trim());
  if (sharedUsers == null || sharedUsers < 1 || sharedUsers > 1000) {
    throw const FormatException('Shared Users يجب أن يكون رقماً بين 1 و1000.');
  }
  if (!const {'mixed', 'letters', 'numbers'}.contains(data.charType)) {
    throw const FormatException('نوع الأحرف غير مدعوم.');
  }
  if (!const {
    'username_only',
    'username_and_password_equal',
    'username_and_password_different',
  }.contains(data.cardType)) {
    throw const FormatException('نوع الكرت غير مدعوم.');
  }

  if (data.plannedUsers == null) {
    final normalizedPrefix = CardNumberPolicy.toAsciiDigits(data.prefix);
    final randomPartLength = data.length - normalizedPrefix.length;
    final combinations = _combinationCount(randomPartLength, data.charType);
    if (data.count > combinations) {
      throw const FormatException(
          'عدد الكروت أكبر من عدد الأسماء الممكنة؛ زد طول المستخدم أو غيّر نوع الأحرف.');
    }
  } else {
    if (data.plannedUsers!.isEmpty || data.plannedUsers!.length != data.count) {
      throw const FormatException('خطة الاستئناف غير صالحة أو فارغة.');
    }
    for (final user in data.plannedUsers!) {
      if ((user['username']?.trim() ?? '').isEmpty ||
          !user.containsKey('password')) {
        throw const FormatException('تحتوي خطة الاستئناف على كرت غير صالح.');
      }
    }
  }
}

List<Map<String, String>> _buildUsers(BulkAddIsolateData data) {
  final users = <Map<String, String>>[];
  final generatedUsernames = <String>{};
  var firstGeneratedUsername = '';

  for (var i = 0; i < data.count; i++) {
    final username = _generateUniqueUsername(
      data: data,
      existingUsernames: generatedUsernames,
    );
    final password = _generatePassword(
      data: data,
      username: username,
      index: i,
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
  required BulkAddIsolateData data,
  required Set<String> existingUsernames,
}) {
  const maxAttemptsPerCard = 1000;
  final normalizedPrefix = CardNumberPolicy.toAsciiDigits(data.prefix);
  final randomPartLength = data.length - normalizedPrefix.length;
  for (var attempt = 0; attempt < maxAttemptsPerCard; attempt++) {
    final username = normalizedPrefix +
        _generateRandomString(randomPartLength, data.charType);
    if (existingUsernames.add(username)) return username;
  }
  throw StateError(
      'تعذر توليد أسماء مستخدمين فريدة. زد الطول أو قلل عدد الكروت.');
}

String _generatePassword({
  required BulkAddIsolateData data,
  required String username,
  required int index,
  required String firstGeneratedUsername,
}) {
  if (data.linkPasswordToFirstUser) {
    return index == 0 ? username : firstGeneratedUsername;
  }
  if (data.cardType == 'username_and_password_equal') return username;
  if (data.cardType == 'username_and_password_different') {
    final passwordLength = max(8, data.length - data.prefix.length);
    var password = _generateRandomString(passwordLength, data.charType);
    for (var attempt = 0; attempt < 100 && password == username; attempt++) {
      password = _generateRandomString(passwordLength, data.charType);
    }
    if (password == username) {
      throw StateError('تعذر توليد كلمة مرور مختلفة عن اسم المستخدم.');
    }
    return password;
  }
  return '';
}

final Random _random = Random.secure();

String _generateRandomString(int length, String type) {
  if (length <= 0) return '';
  const charsMixed = 'abcdefghijklmnopqrstuvwxyz0123456789';
  const charsLetters = 'abcdefghijklmnopqrstuvwxyz';
  const charsNumbers = '0123456789';
  final chars = switch (type) {
    'letters' => charsLetters,
    'numbers' => charsNumbers,
    _ => charsMixed,
  };
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
    ),
  );
}

int _combinationCount(int length, String type) {
  final alphabetSize = switch (type) {
    'letters' => 26,
    'numbers' => 10,
    _ => 36,
  };
  var total = 1;
  for (var i = 0; i < length; i++) {
    if (total > 1000000000 ~/ alphabetSize) return 1000000000;
    total *= alphabetSize;
  }
  return total;
}

void _sendError(
  SendPort sendPort,
  String message,
  int successCount,
  List<Map<String, String>> users,
) {
  sendPort.send({
    'type': 'error',
    'message': message,
    'count': successCount,
    'users': users,
  });
}

String _friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('already have such name') ||
      text.contains('already exists') ||
      text.contains('such user')) {
    return 'يوجد كرت بنفس الاسم على الراوتر. غيّر البادئة أو أعد التوليد.';
  }
  return text;
}
