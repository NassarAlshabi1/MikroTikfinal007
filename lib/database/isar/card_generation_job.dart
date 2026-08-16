import 'dart:convert';

import 'package:isar/isar.dart';

part 'card_generation_job.g.dart';

class CardGenerationJobStatus {
  CardGenerationJobStatus._();

  static const preparing = 'preparing';
  static const ready = 'ready';
  static const running = 'running';
  static const partial = 'partial';
  static const completed = 'completed';
  static const failed = 'failed';
  static const cancelled = 'cancelled';

  static const resumable = {ready, running, partial};
  static const terminal = {completed, failed, cancelled};
}

@collection
class CardGenerationJob {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String jobId;

  @Index()
  late String status;

  late String profileName;
  late String serviceMode;
  late int requestedCount;
  late int reservedCount;
  late int confirmedCount;
  late int failedCount;
  late int nextIndex;
  late String parametersJson;
  String? plannedUsersJson;
  String? lastUsername;
  String? lastError;
  String? routerAddress;
  String? configurationFingerprint;
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? completedAt;

  CardGenerationJob();

  CardGenerationJob.fromData({
    required this.jobId,
    required this.status,
    required this.profileName,
    required this.serviceMode,
    required this.requestedCount,
    this.reservedCount = 0,
    this.confirmedCount = 0,
    this.failedCount = 0,
    this.nextIndex = 0,
    required this.parametersJson,
    this.plannedUsersJson,
    this.lastUsername,
    this.lastError,
    this.routerAddress,
    this.configurationFingerprint,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  bool get isResumable => CardGenerationJobStatus.resumable.contains(status);
  bool get isTerminal => CardGenerationJobStatus.terminal.contains(status);

  @ignore
  Map<String, dynamic> get parameters {
    final decoded = jsonDecode(parametersJson);
    if (decoded is! Map) {
      throw const FormatException('بيانات Job غير صالحة.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'job_id': jobId,
        'status': status,
        'profile_name': profileName,
        'service_mode': serviceMode,
        'requested_count': requestedCount,
        'reserved_count': reservedCount,
        'confirmed_count': confirmedCount,
        'failed_count': failedCount,
        'next_index': nextIndex,
        'parameters_json': parametersJson,
        'planned_users_json': plannedUsersJson,
        'last_username': lastUsername,
        'last_error': lastError,
        'router_address': routerAddress,
        'configuration_fingerprint': configurationFingerprint,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };
}
