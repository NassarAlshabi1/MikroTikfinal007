import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/services.dart';

import 'package:router_os_client/router_os_client.dart';

import 'mikrotik_connector.dart';
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
  final RootIsolateToken rootIsolateToken;
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
    required this.rootIsolateToken,
    required this.customer,
    this.serviceMode = MikrotikServiceMode.hotspot,
  });
}

void bulkAddIsolate(BulkAddIsolateData data) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(data.rootIsolateToken);
  final sendPort = data.sendPort;
  int successCount = 0;
  final newlyCreatedUsers = <Map<String, String>>[];
  final generatedUsernames = <String>{};
  String firstGeneratedUsername = '';

  RouterOSClient? client;
  try {
    _validateInput(data);
    final profile = data.selectedProfile!.trim();
    client = await MikrotikConnector.connect();

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

      await client.talk(
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

      if (data.serviceMode == MikrotikServiceMode.userManager) {
        await client.talk(
          MikrotikCardCommands.userManagerActivateProfile(
            customer: data.customer,
            username: username,
            profile: profile,
          ),
        );
      }

      newlyCreatedUsers.add({'username': username, 'password': password});
      successCount++;
      sendPort.send({
        'type': 'progress',
        'progress': (i + 1) / data.count,
        'status': 'تم إنشاء الكرت ${i + 1} من ${data.count}',
      });
    }

    sendPort.send({
      'type': 'success',
      'users': newlyCreatedUsers,
      'count': successCount,
      'address': client.address,
    });
  } on MikrotikCredentialsMissingException catch (e) {
    _sendError(sendPort, 'خطأ في بيانات الدخول: ${e.message}', successCount);
  } on MikrotikConnectionException catch (e) {
    _sendError(sendPort, 'خطأ في الاتصال: ${e.message}', successCount);
  } on TimeoutException {
    _sendError(
        sendPort, 'فشل الاتصال بالراوتر (انتهت مهلة الاتصال).', successCount);
  } catch (e) {
    _sendError(sendPort, _friendlyError(e), successCount);
  } finally {
    MikrotikConnector.release(client);
  }
}

void _validateInput(BulkAddIsolateData data) {
  if (data.count < 1) {
    throw const FormatException('عدد الكروت يجب أن يكون أكبر من صفر.');
  }
  if (data.length < 1) {
    throw const FormatException('طول اسم المستخدم يجب أن يكون أكبر من صفر.');
  }
  if (data.prefix.length >= data.length) {
    throw const FormatException(
        'طول البادئة يجب أن يكون أقل من الطول الإجمالي للمستخدم.');
  }
  if (data.selectedProfile == null || data.selectedProfile!.trim().isEmpty) {
    throw const FormatException('يجب اختيار بروفايل Hotspot.');
  }
  if (int.tryParse(data.sharedUsers) == null ||
      int.parse(data.sharedUsers) < 1) {
    throw const FormatException('Shared Users يجب أن يكون رقماً موجباً.');
  }
}

String _generateUniqueUsername({
  required BulkAddIsolateData data,
  required Set<String> existingUsernames,
}) {
  const maxAttemptsPerCard = 1000;
  for (var attempt = 0; attempt < maxAttemptsPerCard; attempt++) {
    final randomPartLength = data.length - data.prefix.length;
    final username =
        data.prefix + _generateRandomString(randomPartLength, data.charType);
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
    return _generateRandomString(
      max(8, data.length - data.prefix.length),
      data.charType,
    );
  }
  return '';
}

final Random _random = Random.secure();

String _generateRandomString(int length, String type) {
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
        length, (_) => chars.codeUnitAt(_random.nextInt(chars.length))),
  );
}

void _sendError(SendPort sendPort, String message, int successCount) {
  sendPort.send({
    'type': 'error',
    'message': message,
    'count': successCount,
  });
}

String _friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('already have such name') ||
      text.contains('already exists')) {
    return 'يوجد كرت بنفس الاسم على الراوتر. غيّر البادئة أو أعد التوليد.';
  }
  return text;
}
