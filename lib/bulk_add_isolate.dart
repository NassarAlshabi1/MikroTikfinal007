import 'dart:async';
import 'dart:io';
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

/// الحد الأقصى لعدد الكروت بين تحديثات التقدم في الدفعات الكبيرة؛ أما
/// الدفعات الصغيرة فتُحدّث الواجهة بعد كل كرت حتى لا يبدو الإنشاء متوقفاً.
const int _progressReportCardInterval = 25;

// ================================================================
//  SHARD WORKER — processes a chunk of cards on ONE connection, awaiting
//  each RouterOS command before moving to the next card.
//
//  تُحفظ أخطاء البطاقات والاتصال مع كل ما أُنجز قبله، فيبقى النجاح الجزئي
//  محفوظاً ولا تتسرب اتصالات أو تضيع نتائج مؤكدة.
// ================================================================
class _ShardOutcome {
  /// الكروت التي أكد الراوتر إضافتها (تحمل .id إن وُجد).
  final List<Map<String, String>> created;

  /// الكروت التي رفضها الراوتر (trap) — username + سبب الرفض.
  final List<Map<String, String>> failedAdds;

  /// تحذيرات منفصلة (مثل فشل تفعيل البروفايل لمستخدم أُضيف بنجاح).
  final List<String> activationWarnings;

  /// خطأ على مستوى الشارد نفسه (مهلة/انقطاع) إن حدث، وإلا null.
  final Object? error;

  const _ShardOutcome({
    required this.created,
    required this.failedAdds,
    required this.activationWarnings,
    this.error,
  });

  bool get isClean => error == null && failedAdds.isEmpty;
}

Future<_ShardOutcome> _processShard({
  required List<Map<String, String>> users,
  required RouterOSClient client,
  required MikrotikServiceMode serviceMode,
  required String profile,
  required BulkAddIsolateData data,
  required SendPort sendPort,
  required int cardsBefore,
  required int totalCards,
}) async {
  final created = <Map<String, String>>[];
  final failedAdds = <Map<String, String>>[];
  final activationWarnings = <String>[];
  final gateway = RouterOsCardGateway(RouterOsClientTalker(client));
  final progressInterval = _progressInterval(totalCards);
  var processedCards = 0;

  void reportProgress({bool force = false}) {
    if (!force && processedCards % progressInterval != 0) return;
    final completed = min(cardsBefore + processedCards, totalCards);
    sendPort.send({
      'type': 'progress',
      // لا نعرض 100% إلا بعد انتهاء جميع الشاردات والتحقق النهائي.
      'progress': totalCards == 0 ? 0.0 : min(completed / totalCards, 0.99),
      'status': 'تمت معالجة $completed من $totalCards كرت',
    });
  }

  for (var index = 0; index < users.length; index++) {
    final user = users[index];
    final username = user['username']!;
    Object? connectionError;

    try {
      // ننتظر اكتمال إضافة المستخدم قبل طلب تفعيل بروفايله. إرسال الأمرين
      // معاً عبر talkMultiple كان يسبب سباقاً في User Manager: قد يصل التفعيل
      // قبل أن ينتهي RouterOS من إنشاء المستخدم.
      final result = await gateway.createCardAndActivateProfile(
        mode: serviceMode,
        username: username,
        password: user['password']!,
        profile: profile,
        sharedUsers: data.sharedUsers,
        isVersion7OrNewer: data.isVersion7OrNewer,
        customer: data.customer,
      );
      created.add(result.card.toMap());
      final warning = result.activationWarning;
      if (warning != null) activationWarnings.add(warning);
    } on RouterOSTrapError catch (error) {
      failedAdds.add({'username': username, 'reason': _friendlyError(error)});
    } catch (error) {
      failedAdds.add({'username': username, 'reason': _friendlyError(error)});
      if (_isConnectionFailure(error)) connectionError = error;
    }

    processedCards++;
    reportProgress(
      force: connectionError != null || processedCards == users.length,
    );

    if (connectionError != null) {
      // لا نكرر محاولات طويلة على socket أُغلق بالفعل؛ علّم بقية هذه الشاردة
      // غير مكتملة حتى تظهر للمستخدم كجزء فاشل من العملية.
      for (var remaining = index + 1; remaining < users.length; remaining++) {
        failedAdds.add({
          'username': users[remaining]['username']!,
          'reason': 'توقف الاتصال قبل محاولة إضافة هذا الكرت.',
        });
      }
      return _ShardOutcome(
        created: created,
        failedAdds: failedAdds,
        activationWarnings: activationWarnings,
        error: connectionError,
      );
    }
  }

  return _ShardOutcome(
    created: created,
    failedAdds: failedAdds,
    activationWarnings: activationWarnings,
  );
}

int _progressInterval(int totalCards) {
  if (totalCards <= 100) return 1;
  return min(_progressReportCardInterval, (totalCards / 100).ceil());
}

bool _isConnectionFailure(Object error) {
  return error is TimeoutException ||
      error is MikrotikConnectionException ||
      error is SocketException ||
      MikrotikConnector.isSocketClosedError(error);
}

// ================================================================
//  MAIN ISOLATE ENTRY POINT
// ================================================================
void bulkAddIsolate(BulkAddIsolateData data) async {
  final sendPort = data.sendPort;
  final newlyCreatedUsers = <Map<String, String>>[];
  final failedAdds = <Map<String, String>>[];
  final warnings = <String>[];
  final shardClients = <RouterOSClient>[];
  Isar? localIsar;

  try {
    _validateInput(data);
    final plannedUsers = data.plannedUsers ?? _buildUsers(data);

    // ============================================================
    //  قاعدة بيانات الـ Isolate: تُفتح مرة واحدة وتُستخدم للحجز
    //  (للدُفعات الجديدة) ولتنظيف الكروت المرفوضة لاحقاً. لا يوجد
    //  Handshake مع Isolate الواجهة إطلاقاً — لا يتوقف أحدهما على
    //  الآخر ولا تنفذ الواجهة أي عمل Isar أثناء التوليد (لا تجمد).
    // ============================================================
    if (data.isarDirectory.isNotEmpty) {
      localIsar = await _openLocalIsar(data.isarDirectory);
    }

    if (data.plannedUsers == null && localIsar != null) {
      final preparation = await CardPersistenceService.prepareGeneratedCards(
        isar: localIsar,
        profileName: data.selectedProfile!.trim(),
        users: plannedUsers,
        sharedUsers:
            CardNumberPolicy.parseAsciiInteger(data.sharedUsers.trim()) ?? 1,
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
    }

    // إعلام الواجهة فقط (للعرض/السجل) — بدون انتظار أي رد.
    sendPort.send({
      'type': 'prepared',
      'users': plannedUsers,
      'resumable': data.plannedUsers != null,
    });

    final profile = data.selectedProfile!.trim();

    // ============================================================
    //  SHARDS: Hotspot uses a small number of independent connections;
    //  User Manager uses one connection to avoid concurrent add/activate
    //  operations against its database. Every shard is closed in finally.
    // ============================================================
    final shardCount = data.serviceMode == MikrotikServiceMode.userManager
        ? 1
        : min(4, plannedUsers.length);
    final shardSize = (plannedUsers.length / shardCount).ceil();
    final futures = <Future<_ShardOutcome>>[];

    try {
      for (var s = 0; s < shardCount; s++) {
        final start = s * shardSize;
        final end = min(start + shardSize, plannedUsers.length);
        if (start >= plannedUsers.length) break;
        final shardUsers = plannedUsers.sublist(start, end);

        final shardClient = await MikrotikConnector.connectWithConfig(
          data.connectionConfig,
        );
        shardClients.add(shardClient);
        futures.add(
          _processShard(
            users: shardUsers,
            client: shardClient,
            serviceMode: data.serviceMode,
            profile: profile,
            data: data,
            sendPort: sendPort,
            cardsBefore: start,
            totalCards: plannedUsers.length,
          ),
        );
      }

      final shardOutcomes = await Future.wait(futures);

      int completedCards = 0;
      for (final outcome in shardOutcomes) {
        newlyCreatedUsers.addAll(outcome.created);
        failedAdds.addAll(outcome.failedAdds);
        warnings.addAll(outcome.activationWarnings);
        if (outcome.error != null) {
          warnings.add(
            'تعذر إكمال جزء من الدفعة: ${_friendlyError(outcome.error!)}',
          );
        }
        completedCards += outcome.created.length;
      }

      // تقدم نهائي بعد دمج كل الشاردات (قد يختلف عن مجموع التقارير الجزئية).
      if (completedCards > 0) {
        sendPort.send({
          'type': 'progress',
          'progress': 1.0,
          'status': 'تم إنشاء $completedCards من ${plannedUsers.length} كرت',
        });
      }

      // تنظيف الكروت التي رفضها الراوتر من الحجز المحلي حتى لا تبقى
      // أسماء شبحية pending تظهر في قوائم الاستئناف.
      if (failedAdds.isNotEmpty && localIsar != null) {
        try {
          await CardPersistenceService.removePendingGeneratedCards(
            failedAdds,
            generationJobId: data.generationJobId,
            isar: localIsar,
          );
        } catch (error) {
          warnings.add('تعذر تنظيف الحجز المحلي للكروت المرفوضة: $error');
        }
      }
    } finally {
      // تُغلق الاتصالات في كل المسارات — نجاحاً أو خطأً — فلا تسريب.
      for (final client in shardClients) {
        MikrotikConnector.release(client);
      }
    }

    if (newlyCreatedUsers.isEmpty) {
      final reason = failedAdds.isEmpty
          ? 'لم يتم إنشاء أي كرت على الراوتر.'
          : 'فشل إنشاء ${failedAdds.length} كرت: '
                '${failedAdds.first['reason']}';
      throw FormatException(reason);
    }

    // نجاح RouterOSClient.talk (استجابة !done دون !trap) هو تأكيد الإضافة.
    // نتجنب طباعة جدول User Manager كاملاً للتحقق؛ فقد يضم آلاف الكروت ويجعل
    // العملية بطيئة أو تبدو وكأنها لا تنتهي. ويُحفظ .id عند توفره من الإضافة.
    sendPort.send({
      'type': 'success',
      'users': newlyCreatedUsers,
      'count': newlyCreatedUsers.length,
      'address': data.connectionConfig.address,
      'failedCount': failedAdds.length,
      'warning': _composeWarning(warnings),
    });
  } on MikrotikCredentialsMissingException catch (e) {
    _sendError(
      sendPort,
      'خطأ في بيانات الدخول: ${e.message}',
      newlyCreatedUsers.length,
      newlyCreatedUsers,
    );
  } on MikrotikConnectionException catch (e) {
    _sendError(
      sendPort,
      'خطأ في الاتصال: ${e.message}',
      newlyCreatedUsers.length,
      newlyCreatedUsers,
    );
  } on RouterOSTrapError catch (e) {
    _sendError(
      sendPort,
      _friendlyError(e.message),
      newlyCreatedUsers.length,
      newlyCreatedUsers,
    );
  } on TimeoutException {
    _sendError(
      sendPort,
      'فشل الاتصال بالراوتر (انتهت مهلة الاتصال).\n'
      'تأكد من اتصال الشبكة بالراوتر وصحة إعدادات API (المنفذ 8728/8729).',
      newlyCreatedUsers.length,
      newlyCreatedUsers,
    );
  } on FormatException catch (e) {
    _sendError(
      sendPort,
      e.message.toString(),
      newlyCreatedUsers.length,
      newlyCreatedUsers,
    );
  } catch (e) {
    _sendError(
      sendPort,
      _friendlyError(e),
      newlyCreatedUsers.length,
      newlyCreatedUsers,
    );
  } finally {
    await localIsar?.close();
  }
}

String _composeWarning(List<String> warnings) {
  if (warnings.isEmpty) return '';
  final unique = warnings.toSet().toList(growable: false);
  final visible = unique.length > 3 ? unique.sublist(0, 3) : unique;
  final suffix = unique.length > visible.length
      ? '\n...و${unique.length - visible.length} ملاحظات أخرى'
      : '';
  return visible.join('\n') + suffix;
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
        'طول البادئة يجب أن يكون أقل من الطول الإجمالي للمستخدم.',
      );
    }
  }
  if (data.selectedProfile == null || data.selectedProfile!.trim().isEmpty) {
    throw const FormatException('يجب اختيار فئة User Manager.');
  }
  final sharedUsers = CardNumberPolicy.parseAsciiInteger(
    data.sharedUsers.trim(),
  );
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
        'عدد الكروت أكبر من عدد الأسماء الممكنة؛ زد طول المستخدم أو غيّر نوع الأحرف.',
      );
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
    final username =
        normalizedPrefix +
        _generateRandomString(randomPartLength, data.charType);
    if (existingUsernames.add(username)) return username;
  }
  throw StateError(
    'تعذر توليد أسماء مستخدمين فريدة. زد الطول أو قلل عدد الكروت.',
  );
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
