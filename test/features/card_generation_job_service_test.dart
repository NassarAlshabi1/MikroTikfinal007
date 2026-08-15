import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:mikrotik_manager/database/isar/card_generation_job.dart';
import 'package:mikrotik_manager/database/isar_provider.dart';
import 'package:mikrotik_manager/services/card_generation_job_service.dart';

void main() {
  late Directory databaseDirectory;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    databaseDirectory = await Directory.systemTemp.createTemp('mikrotik_job_');
    final isar = await Isar.open(
      [CardGenerationJobSchema],
      directory: databaseDirectory.path,
      name: 'job_test',
      inspector: false,
    );
    IsarProvider().setTestInstance(isar);
  });

  tearDown(() async {
    await IsarProvider().close();
    if (databaseDirectory.existsSync()) {
      await databaseDirectory.delete(recursive: true);
    }
  });

  test('ينشئ Job ويحفظ خطة المستخدمين ثم يثبت الإكمال', () async {
    final job = await CardGenerationJobService.create(
      profileName: 'default',
      serviceMode: 'hotspot',
      requestedCount: 2,
      routerAddress: '192.0.2.1',
      parameters: const {'length': 8, 'charType': 'numbers'},
    );
    final users = [
      {'username': '10000001', 'password': ''},
      {'username': '10000002', 'password': '10000002'},
    ];

    await CardGenerationJobService.markReady(
      job.jobId,
      reservedCount: users.length,
      plannedUsers: users,
    );
    final ready = await CardGenerationJobService.find(job.jobId);
    expect(ready?.status, CardGenerationJobStatus.ready);
    expect(ready?.plannedUsersJson, contains('10000001'));

    await CardGenerationJobService.markRunning(job.jobId);
    await CardGenerationJobService.markProgress(
      job.jobId,
      nextIndex: 1,
      lastUsername: '10000001',
    );
    await CardGenerationJobService.markCompleted(
      job.jobId,
      confirmedCount: 2,
    );

    final completed = await CardGenerationJobService.find(job.jobId);
    expect(completed?.status, CardGenerationJobStatus.completed);
    expect(completed?.confirmedCount, 2);
    expect(completed?.completedAt, isNotNull);
    expect(completed?.isTerminal, isTrue);
  });

  test('يسجل partial ويدعم الإلغاء مع حالة نهائية', () async {
    final job = await CardGenerationJobService.create(
      profileName: 'default',
      serviceMode: 'hotspot',
      requestedCount: 10,
      parameters: const {},
    );

    await CardGenerationJobService.markPartialFailure(
      job.jobId,
      confirmedCount: 3,
      failedCount: 7,
      error: 'انقطع الاتصال',
    );
    expect(
        (await CardGenerationJobService.find(job.jobId))?.isResumable, isTrue);

    await CardGenerationJobService.cancel(job.jobId);
    final cancelled = await CardGenerationJobService.find(job.jobId);
    expect(cancelled?.status, CardGenerationJobStatus.cancelled);
    expect(cancelled?.isTerminal, isTrue);
  });

  test('يمنع تشغيل عمليتي توليد في الوقت نفسه', () {
    final first = CardGenerationJobService.tryAcquireLock();
    final second = CardGenerationJobService.tryAcquireLock();

    expect(first, isNotNull);
    expect(second, isNull);
    first!.release();

    final third = CardGenerationJobService.tryAcquireLock();
    expect(third, isNotNull);
    third!.release();
  });
}
