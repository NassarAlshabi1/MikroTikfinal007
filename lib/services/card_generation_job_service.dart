import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:isar/isar.dart';

import '../database/isar/card_generation_job.dart';
import '../database/isar_provider.dart';

class GenerationLockToken {
  GenerationLockToken._(this._release);

  final void Function() _release;
  bool _released = false;

  void release() {
    if (_released) return;
    _released = true;
    _release();
  }
}

class CardGenerationJobService {
  CardGenerationJobService._();

  static final Random _random = Random();
  static bool _lockHeld = false;

  static bool get isLocked => _lockHeld;

  static GenerationLockToken? tryAcquireLock() {
    if (_lockHeld) return null;
    _lockHeld = true;
    return GenerationLockToken._(() => _lockHeld = false);
  }

  static Future<CardGenerationJob> create({
    required String profileName,
    required String serviceMode,
    required int requestedCount,
    required Map<String, dynamic> parameters,
    String? routerAddress,
  }) async {
    final now = DateTime.now();
    final job = CardGenerationJob.fromData(
      jobId: _newJobId(),
      status: CardGenerationJobStatus.preparing,
      profileName: profileName.trim(),
      serviceMode: serviceMode,
      requestedCount: requestedCount,
      parametersJson: jsonEncode(parameters),
      routerAddress: routerAddress,
      configurationFingerprint: fingerprint(
        routerAddress: routerAddress,
        profileName: profileName,
        serviceMode: serviceMode,
        parameters: parameters,
      ),
      createdAt: now,
      updatedAt: now,
    );
    final isar = await IsarProvider().instance;
    await isar.writeTxn(() => isar.cardGenerationJobs.put(job));
    return job;
  }

  static String fingerprint({
    required String? routerAddress,
    required String profileName,
    required String serviceMode,
    required Map<String, dynamic> parameters,
  }) {
    final keys = parameters.keys.toList()..sort();
    final sortedParameters = Map.fromEntries(
      keys.map((key) => MapEntry(key, parameters[key])),
    );
    final canonical = <String, dynamic>{
      'routerAddress': routerAddress?.trim().toLowerCase() ?? '',
      'profileName': profileName.trim(),
      'serviceMode': serviceMode,
      ...sortedParameters,
    };
    return crypto.sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
  }

  static bool matchesFingerprint(
    CardGenerationJob job, {
    required String routerAddress,
    required Map<String, dynamic> parameters,
  }) {
    final stored = job.configurationFingerprint;
    if (stored == null || stored.isEmpty) {
      return job.routerAddress == null ||
          job.routerAddress!.trim().toLowerCase() ==
              routerAddress.trim().toLowerCase();
    }
    return stored ==
        fingerprint(
          routerAddress: routerAddress,
          profileName: job.profileName,
          serviceMode: job.serviceMode,
          parameters: parameters,
        );
  }

  static Future<CardGenerationJob?> find(String jobId) async {
    final isar = await IsarProvider().instance;
    return isar.cardGenerationJobs.getByJobId(jobId);
  }

  static Future<List<CardGenerationJob>> loadAll({int limit = 100}) async {
    final isar = await IsarProvider().instance;
    final jobs = await isar.cardGenerationJobs.where().findAll();
    jobs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return jobs.take(limit).toList(growable: false);
  }

  static Future<List<CardGenerationJob>> loadResumable() async {
    final isar = await IsarProvider().instance;
    final jobs = await isar.cardGenerationJobs.where().findAll();
    return jobs.where((job) => job.isResumable).toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<CardGenerationJob?> update(
    String jobId, {
    String? status,
    int? reservedCount,
    int? confirmedCount,
    int? failedCount,
    int? nextIndex,
    String? lastUsername,
    String? plannedUsersJson,
    String? lastError,
    bool clearError = false,
    bool complete = false,
  }) async {
    final isar = await IsarProvider().instance;
    return isar.writeTxn(() async {
      final job =
          await isar.cardGenerationJobs.where().jobIdEqualTo(jobId).findFirst();
      if (job == null) return null;
      if (job.isTerminal && status == CardGenerationJobStatus.running) {
        return job;
      }
      if (status != null) job.status = status;
      if (reservedCount != null) job.reservedCount = reservedCount;
      if (confirmedCount != null) job.confirmedCount = confirmedCount;
      if (failedCount != null) job.failedCount = failedCount;
      if (nextIndex != null) job.nextIndex = nextIndex;
      if (lastUsername != null) job.lastUsername = lastUsername;
      if (plannedUsersJson != null) job.plannedUsersJson = plannedUsersJson;
      if (clearError) job.lastError = null;
      if (lastError != null) job.lastError = lastError;
      job.updatedAt = DateTime.now();
      if (complete) job.completedAt = job.updatedAt;
      await isar.cardGenerationJobs.put(job);
      return job;
    });
  }

  static Future<CardGenerationJob?> markReady(
    String jobId, {
    required int reservedCount,
    required List<Map<String, String>> plannedUsers,
  }) {
    return update(
      jobId,
      status: CardGenerationJobStatus.ready,
      reservedCount: reservedCount,
      nextIndex: 0,
      plannedUsersJson: jsonEncode(
        plannedUsers
            .map((user) => {'username': user['username'] ?? ''})
            .toList(growable: false),
      ),
      clearError: true,
    );
  }

  static Future<CardGenerationJob?> markRunning(String jobId) {
    return update(
      jobId,
      status: CardGenerationJobStatus.running,
      clearError: true,
    );
  }

  static Future<CardGenerationJob?> markProgress(
    String jobId, {
    required int nextIndex,
    String? lastUsername,
  }) {
    return update(
      jobId,
      status: CardGenerationJobStatus.running,
      nextIndex: nextIndex,
      lastUsername: lastUsername,
    );
  }

  static Future<CardGenerationJob?> markCompleted(
    String jobId, {
    required int confirmedCount,
  }) {
    return update(
      jobId,
      status: CardGenerationJobStatus.completed,
      confirmedCount: confirmedCount,
      failedCount: 0,
      nextIndex: confirmedCount,
      complete: true,
      clearError: true,
    );
  }

  static Future<CardGenerationJob?> markPartialFailure(
    String jobId, {
    required int confirmedCount,
    required int failedCount,
    required String error,
  }) {
    return update(
      jobId,
      status: CardGenerationJobStatus.partial,
      confirmedCount: confirmedCount,
      failedCount: failedCount,
      lastError: error,
    );
  }

  static Future<CardGenerationJob?> markFailed(
    String jobId, {
    required String error,
    int? confirmedCount,
    int? failedCount,
  }) {
    return update(
      jobId,
      status: CardGenerationJobStatus.failed,
      confirmedCount: confirmedCount,
      failedCount: failedCount,
      lastError: error,
      complete: true,
    );
  }

  static Future<CardGenerationJob?> cancel(String jobId) {
    return update(
      jobId,
      status: CardGenerationJobStatus.cancelled,
      lastError: 'ألغى المستخدم عملية إنشاء الكروت.',
      complete: true,
    );
  }

  static Future<int> deleteOldTerminalJobs({
    Duration olderThan = const Duration(days: 30),
  }) async {
    final isar = await IsarProvider().instance;
    final cutoff = DateTime.now().subtract(olderThan);
    return isar.writeTxn(() async {
      final jobs = await isar.cardGenerationJobs.where().findAll();
      final ids = jobs
          .where((job) => job.isTerminal && job.updatedAt.isBefore(cutoff))
          .map((job) => job.id)
          .toList(growable: false);
      if (ids.isEmpty) return 0;
      return isar.cardGenerationJobs.deleteAll(ids);
    });
  }

  static String _newJobId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'job-$timestamp-${_random.nextInt(1000000).toString().padLeft(6, '0')}';
  }
}
