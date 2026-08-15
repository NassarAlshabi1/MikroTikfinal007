import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:router_os_client/router_os_client.dart';

import 'mikrotik_connector.dart';
import 'services/card_number_policy.dart';
import 'services/mikrotik_card_commands.dart';
import 'services/mikrotik_service_mode.dart';

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
    this.serviceMode = MikrotikServiceMode.hotspot,
  });
}

void bulkAddIsolate(BulkAddIsolateData data) async {
  final sendPort = data.sendPort;
  final approvalPort = ReceivePort();
  int successCount = 0;
  final newlyCreatedUsers = <Map<String, String>>[];
  RouterOSClient? client;

  try {
    _validateInput(data);
    final plannedUsers = _buildUsers(data);

    // لا يتم الاتصال أو إرسال أي أمر قبل أن تحفظ الشاشة الخطة في Isar.
    sendPort.send({
      'type': 'prepared',
      'users': plannedUsers,
      'approvalPort': approvalPort.sendPort,
    });
    final approval = await approvalPort.first.timeout(
      const Duration(minutes: 5),
      onTimeout: () => <String, dynamic>{
        'approved': false,
        'reason': 'انتهت مهلة تجهيز الكروت محلياً.',
      },
    );
    if (approval is! Map || approval['approved'] != true) {
      throw FormatException(
        approval is Map
            ? approval['reason']?.toString() ?? 'تم إلغاء العملية.'
            : 'تعذر اعتماد خطة إنشاء الكروت.',
      );
    }

    client = await MikrotikConnector.connectWithConfig(data.connectionConfig);
    final profile = data.selectedProfile!.trim();

    for (var i = 0; i < plannedUsers.length; i++) {
      final user = plannedUsers[i];
      final username = user['username']!;
      final password = user['password']!;

      final addResponse = await client.talk(
        MikrotikCardCommands.addUser(
          mode: data.serviceMode,
          username: username,
          password: password,
          profile: profile,
          sharedUsers: data.sharedUsers,
          isVersion7OrNewer: data.isVersion7OrNewer,
          customer: data.customer,
        ),
      );
      final mikrotikUserId = _extractMikrotikUserId(addResponse);

      if (data.serviceMode == MikrotikServiceMode.userManager) {
        await client.talk(
          MikrotikCardCommands.userManagerActivateProfile(
            customer: data.customer,
            username: username,
            profile: profile,
          ),
        );
      }

      final confirmedUser = <String, String>{
        'username': username,
        'password': password,
        if (mikrotikUserId != null) 'mikrotikUserId': mikrotikUserId,
      };
      newlyCreatedUsers.add(confirmedUser);
      successCount++;
      sendPort.send({
        'type': 'progress',
        'progress': (i + 1) / plannedUsers.length,
        'status': 'تم إنشاء الكرت ${i + 1} من ${plannedUsers.length}',
      });
    }

    sendPort.send({
      'type': 'success',
      'users': newlyCreatedUsers,
      'count': successCount,
      'address': client.address,
    });
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
      'فشل الاتصال بالراوتر (انتهت مهلة الاتصال).',
      successCount,
      newlyCreatedUsers,
    );
  } on FormatException catch (e) {
    _sendError(sendPort, e.message.toString(), successCount, newlyCreatedUsers);
  } catch (e) {
    _sendError(sendPort, _friendlyError(e), successCount, newlyCreatedUsers);
  } finally {
    approvalPort.close();
    MikrotikConnector.release(client);
  }
}

void _validateInput(BulkAddIsolateData data) {
  if (data.count < 1 || data.count > 10000) {
    throw const FormatException('عدد الكروت يجب أن يكون بين 1 و10000.');
  }
  if (data.length < 1 || data.length > 64) {
    throw const FormatException('طول اسم المستخدم يجب أن يكون بين 1 و64.');
  }
  if (data.prefix.length >= data.length) {
    throw const FormatException(
        'طول البادئة يجب أن يكون أقل من الطول الإجمالي للمستخدم.');
  }
  if (data.selectedProfile == null || data.selectedProfile!.trim().isEmpty) {
    throw const FormatException('يجب اختيار بروفايل Hotspot.');
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

  final normalizedPrefix = CardNumberPolicy.toAsciiDigits(data.prefix);
  final randomPartLength = data.length - normalizedPrefix.length;
  final combinations = _combinationCount(randomPartLength, data.charType);
  if (data.count > combinations) {
    throw const FormatException(
        'عدد الكروت أكبر من عدد الأسماء الممكنة؛ زد طول المستخدم أو غيّر نوع الأحرف.');
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

String? _extractMikrotikUserId(List<Map<String, String>> response) {
  for (final row in response) {
    final id = row['.id']?.trim();
    if (id != null && id.isNotEmpty) return id;
  }
  return null;
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
