import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../bulk_add_isolate.dart';
import '../mikrotik_connector.dart';
import '../database/isar/card_generation_job.dart';
import 'card_generation_job_service.dart';
import 'card_persistence_service.dart';
import 'mikrotik_service_mode.dart';
import 'router_os_permission_service.dart';

class GeneratedCard {
  final String username;
  final String password;
  final String? mikrotikUserId;

  const GeneratedCard({
    required this.username,
    this.password = '',
    this.mikrotikUserId,
  });

  factory GeneratedCard.fromMap(Map<dynamic, dynamic> value) {
    final username = value['username']?.toString().trim() ?? '';
    if (username.isEmpty) {
      throw const FormatException('اسم الكرت فارغ.');
    }
    final password = value['password']?.toString() ?? '';
    final mikrotikUserId = value['mikrotikUserId']?.toString().trim();
    return GeneratedCard(
      username: username,
      password: password,
      mikrotikUserId: mikrotikUserId == null || mikrotikUserId.isEmpty
          ? null
          : mikrotikUserId,
    );
  }

  Map<String, String> toMap() => {
        'username': username,
        'password': password,
        if (mikrotikUserId != null) 'mikrotikUserId': mikrotikUserId!,
      };
}

class BulkGenerationRequest {
  final int count;
  final int length;
  final String prefix;
  final String sharedUsers;
  final String profileName;
  final String charType;
  final String cardType;
  final bool linkPasswordToFirstUser;
  final bool isVersion7OrNewer;
  final MikrotikConnectionConfig connectionConfig;
  final String customer;
  final MikrotikServiceMode serviceMode;
  final List<GeneratedCard>? plannedCards;

  const BulkGenerationRequest({
    required this.count,
    required this.length,
    required this.prefix,
    required this.sharedUsers,
    required this.profileName,
    required this.charType,
    required this.cardType,
    required this.linkPasswordToFirstUser,
    required this.isVersion7OrNewer,
    required this.connectionConfig,
    required this.customer,
    required this.serviceMode,
    this.plannedCards,
  });

  Map<String, dynamic> toParameters() => {
        'count': count,
        'length': length,
        'prefix': prefix,
        'sharedUsers': sharedUsers,
        'profileName': profileName,
        'charType': charType,
        'cardType': cardType,
        'linkPasswordToFirstUser': linkPasswordToFirstUser,
        'isVersion7OrNewer': isVersion7OrNewer,
        'customer': customer,
        'serviceMode': serviceMode.name,
      };

  BulkGenerationRequest withPlannedCards(List<GeneratedCard> cards) {
    return BulkGenerationRequest(
      count: cards.length,
      length: length,
      prefix: prefix,
      sharedUsers: sharedUsers,
      profileName: profileName,
      charType: charType,
      cardType: cardType,
      linkPasswordToFirstUser: linkPasswordToFirstUser,
      isVersion7OrNewer: isVersion7OrNewer,
      connectionConfig: connectionConfig,
      customer: customer,
      serviceMode: serviceMode,
      plannedCards: List.unmodifiable(cards),
    );
  }
}

class GenerationEvent {
  final String type;
  final List<GeneratedCard> users;
  final double progress;
  final String status;
  final String message;
  final int count;
  final int failedCount;
  final String warning;
  final String address;
  final bool resumable;

  const GenerationEvent({
    required this.type,
    this.users = const [],
    this.progress = 0,
    this.status = '',
    this.message = '',
    this.count = 0,
    this.failedCount = 0,
    this.warning = '',
    this.address = '',
    this.resumable = false,
  });

  factory GenerationEvent.fromRaw(dynamic raw) {
    if (raw is! Map) {
      return const GenerationEvent(
        type: 'error',
        message: 'رسالة غير صالحة من عملية التوليد.',
      );
    }
    final users = <GeneratedCard>[];
    final rawUsers = raw['users'];
    if (rawUsers is List) {
      for (final value in rawUsers) {
        if (value is Map) {
          try {
            users.add(GeneratedCard.fromMap(value));
          } on FormatException {
            // ستتعامل الشاشة مع القائمة الصالحة فقط، بينما يبقى الخطأ في الرسالة.
          }
        }
      }
    }
    return GenerationEvent(
      type: raw['type']?.toString() ?? 'error',
      users: List.unmodifiable(users),
      progress: (raw['progress'] as num?)?.toDouble() ?? 0,
      status: raw['status']?.toString() ?? '',
      message: raw['message']?.toString() ?? '',
      count: (raw['count'] as num?)?.toInt() ?? users.length,
      failedCount: (raw['failedCount'] as num?)?.toInt() ?? 0,
      warning: raw['warning']?.toString() ?? '',
      address: raw['address']?.toString() ?? '',
      resumable: raw['resumable'] == true,
    );
  }
}

class BulkGenerationSession {
  BulkGenerationSession._({
    required this.jobId,
    required GenerationLockToken lock,
    required ReceivePort port,
  })  : _lock = lock,
        _port = port {
    _subscription = _port.listen((raw) {
      if (_events.isClosed) return;
      final event = GenerationEvent.fromRaw(raw);
      if (_events.hasListener) {
        _events.add(event);
      } else {
        _pendingEvents.add(event);
      }
    });
  }

  final String jobId;
  final GenerationLockToken _lock;
  final ReceivePort _port;
  final List<GenerationEvent> _pendingEvents = [];
  late final StreamController<GenerationEvent> _events =
      StreamController<GenerationEvent>.broadcast(
    onListen: () {
      for (final event in _pendingEvents) {
        _events.add(event);
      }
      _pendingEvents.clear();
    },
  );
  late final StreamSubscription<dynamic> _subscription;
  Isolate? _isolate;
  bool _closed = false;

  Stream<GenerationEvent> get events => _events.stream;
  bool get isClosed => _closed;

  void attach(Isolate isolate) => _isolate = isolate;

  void close() {
    if (_closed) return;
    _closed = true;
    _subscription.cancel();
    _port.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _lock.release();
    _events.close();
  }
}

class BulkCardGenerationService {
  BulkCardGenerationService._();

  static Future<BulkGenerationSession> startNew(
    BulkGenerationRequest request,
  ) async {
    final lock = CardGenerationJobService.tryAcquireLock();
    if (lock == null) {
      throw StateError('توجد عملية إنشاء كروت أخرى قيد التنفيذ.');
    }
    try {
      await RouterOsPermissionService.preflight(
        request.connectionConfig,
        mode: request.serviceMode,
      );
      final job = await CardGenerationJobService.create(
        profileName: request.profileName,
        serviceMode: request.serviceMode.name,
        requestedCount: request.count,
        routerAddress: request.connectionConfig.address,
        parameters: request.toParameters(),
      );
      return await _spawn(request: request, jobId: job.jobId, lock: lock);
    } catch (_) {
      lock.release();
      rethrow;
    }
  }

  static Future<BulkGenerationSession> resume(
    CardGenerationJob job, {
    required String fallbackCustomer,
  }) async {
    final lock = CardGenerationJobService.tryAcquireLock();
    if (lock == null) {
      throw StateError('توجد عملية إنشاء كروت أخرى قيد التنفيذ.');
    }
    try {
      final pending = await CardPersistenceService.loadPendingGeneratedCards(
        job.jobId,
      );
      if (pending.isEmpty) {
        throw StateError('لا توجد كروت معلقة قابلة للاستئناف.');
      }
      final connectionConfig = await MikrotikConnector.loadConnectionConfig();
      await RouterOsPermissionService.preflight(
        connectionConfig,
        mode: MikrotikServiceMode.values.firstWhere(
          (mode) => mode.name == job.serviceMode,
          orElse: () => MikrotikServiceMode.userManager,
        ),
      );
      final parameters = job.parameters;
      if (!CardGenerationJobService.matchesFingerprint(
        job,
        routerAddress: connectionConfig.address,
        parameters: parameters,
      )) {
        throw StateError(
          'تغير الراوتر أو إعدادات العملية؛ لا يمكن استئناف Job بأمان.',
        );
      }
      final serviceMode = MikrotikServiceMode.values.firstWhere(
        (mode) => mode.name == job.serviceMode,
        orElse: () => MikrotikServiceMode.userManager,
      );
      final request = BulkGenerationRequest(
        count: pending.length,
        length: (parameters['length'] as num?)?.toInt() ?? 8,
        prefix: parameters['prefix']?.toString() ?? '',
        sharedUsers: parameters['sharedUsers']?.toString() ?? '1',
        profileName: job.profileName,
        charType: parameters['charType']?.toString() ?? 'numbers',
        cardType: parameters['cardType']?.toString() ?? 'username_only',
        linkPasswordToFirstUser: parameters['linkPasswordToFirstUser'] == true,
        isVersion7OrNewer: parameters['isVersion7OrNewer'] == true,
        connectionConfig: connectionConfig,
        customer: parameters['customer']?.toString() ?? fallbackCustomer,
        serviceMode: serviceMode,
        plannedCards:
            pending.map(GeneratedCard.fromMap).toList(growable: false),
      );
      return await _spawn(request: request, jobId: job.jobId, lock: lock);
    } catch (_) {
      lock.release();
      rethrow;
    }
  }

  static Future<BulkGenerationSession> _spawn({
    required BulkGenerationRequest request,
    required String jobId,
    required GenerationLockToken lock,
  }) async {
    final isarDirectory =
        kIsWeb ? '' : (await getApplicationDocumentsDirectory()).path;
    final port = ReceivePort();
    final session = BulkGenerationSession._(
      jobId: jobId,
      lock: lock,
      port: port,
    );
    try {
      final isolate = await Isolate.spawn(
        bulkAddIsolate,
        BulkAddIsolateData(
          sendPort: port.sendPort,
          count: request.count,
          length: request.length,
          prefix: request.prefix,
          sharedUsers: request.sharedUsers,
          selectedProfile: request.profileName,
          charType: request.charType,
          cardType: request.cardType,
          linkPasswordToFirstUser: request.linkPasswordToFirstUser,
          isVersion7OrNewer: request.isVersion7OrNewer,
          connectionConfig: request.connectionConfig,
          customer: request.customer,
          serviceMode: request.serviceMode,
          isarDirectory: isarDirectory,
          generationJobId: jobId,
          plannedUsers:
              request.plannedCards?.map((card) => card.toMap()).toList(),
        ),
      );
      session.attach(isolate);
      return session;
    } catch (_) {
      session.close();
      await CardGenerationJobService.markFailed(
        jobId,
        error: 'تعذر بدء عملية التوليد داخل Isolate.',
      );
      rethrow;
    }
  }

  static Future<void> cancel(
    BulkGenerationSession session, {
    required List<GeneratedCard> pendingCards,
  }) async {
    await CardGenerationJobService.cancel(session.jobId);
    if (pendingCards.isNotEmpty) {
      await CardPersistenceService.removePendingGeneratedCards(
        pendingCards.map((card) => card.toMap()).toList(growable: false),
        generationJobId: session.jobId,
      );
    }
    session.close();
  }
}
