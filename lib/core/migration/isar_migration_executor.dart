// ============================================================
//  IsarMigrationExecutor — تنفيذ مباشر لعملية الهجرة التدريجية
//  يستخدم IsarMigrationStrategy لتنفيذ عملية الانتقال من Drift إلى Isar
// ============================================================

import 'dart:async';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../database/app_database.dart' show AppDatabase;
import '../database/isar/isar_migration_strategy.dart';

/// واجهة المستخدم لعملية الهجرة (للعرض)
class IsarMigrationProgress {
  final String title;
  final String description;
  final double progress;
  final String? error;
  final bool completed;

  IsarMigrationProgress({
    required this.title,
    required this.description,
    this.progress = 0.0,
    this.error,
    this.completed = false,
  });

  /// إنشاء حالة التقدم عند البدء
  factory IsarMigrationProgress.initial() => IsarMigrationProgress(
    title: 'بدء الهجرة من Drift إلى Isar',
    description: 'تهيئة عملية الترحيل...',
    progress: 0.0,
  );

  /// إنشاء حالة التقدم بعد الانتهاء بنجاح
  factory IsarMigrationProgress.success() => IsarMigrationProgress(
    title: 'اكتمال الهجرة بنجاح',
    description: 'تمت عملية الترحيل بنجاح إلى Isar',
    progress: 1.0,
    completed: true,
  );

  /// إنشاء حالة التقدم بعد حدوث خطأ
  factory IsarMigrationProgress.error(String error) => IsarMigrationProgress(
    title: 'فشلت عملية الهجرة',
    description: 'حدث خطأ أثناء عملية الترحيل',
    progress: 0.0,
    error: error,
    completed: false,
  );
}

/// مستمع لواجهة المستخدم لعملية الهجرة
class IsarMigrationListener {
  final void Function(IsarMigrationProgress progress) onProgress;
  final VoidCallback? onComplete;
  final VoidCallback? onError;

  IsarMigrationListener({
    required this.onProgress,
    this.onComplete,
    this.onError,
  });

  /// تحديث التقدم
  void updateProgress(double progress, String description) {
    final p = progress.clamp(0.0, 1.0);
    onProgress(IsarMigrationProgress(
      title: p >= 1.0 ? 'تمت عملية الهجرة بنجاح' : 'جاري الهجرة...',
      description: description,
      progress: p,
      completed: p >= 1.0,
    ));
  }

  /// معالجة اكتمال العملية
  void complete() {
    onComplete?.call();
  }

  /// معالجة الخطأ
  void handleError(Object error) {
    onError?.call();
  }
}

/// منفذ عملية الهجرة مع واجهة المستخدم
class IsarMigrationExecutor {
  final Logger _logger = Logger(name: 'IsarMigrationExecutor');

  /// Listeners لعملية الهجرة
  final List<IsarMigrationListener> _listeners = [];

  /// حالة عملية الهجرة
  bool _isExecuting = false;
  MigrationResult? _currentResult;

  /// تسجيل listener لعملية الهجرة
  void addListener(IsarMigrationListener listener) {
    _listeners.add(listener);
  }

  /// إزالة listener لعملية الهجرة
  void removeListener(IsarMigrationListener listener) {
    _listeners.remove(listener);
  }

  /// بدء عملية الهجرة
  Future<MigrationResult> executeMigration({
    MigrationConfig? config,
    bool enableHybridMode = true,
    bool validateBeforeMigration = true,
  }) async {
    if (_isExecuting) {
      throw StateError('عملية الهجرة بالفعل قيد التنفيذ');
    }

    _isExecuting = true;
    _currentResult = null;

    try {
      _notifyProgress('بدء عملية الهجرة...');

      // إذا كانت validateBeforeMigration مفعلة، قم بالتحقق من البيانات أولاً
      if (validateBeforeMigration) {
        _notifyProgress('التحقق من اتساق البيانات...');
        // TODO: تنفيذ التحقق من البيانات هنا
      }

      // إنشاء استراتيجية الهجرة
      final strategy = IsarMigrationStrategy(
        migrationConfig: config,
        driftDb: AppDatabase(),
        isarService: null, // سيتم إنشاؤه لاحقاً
      );

      // تنفيذ عملية الهجرة
      _notifyProgress('بدء عملية الترحيل...');
      final result = await strategy.migrate();

      _currentResult = result;

      if (result.success) {
        _notifyProgress('اكتملت عملية الهجرة بنجاح', completed: true);
        _logger.info('تمت عملية الهجرة بنجاح: ${result.toString()}');

        // إبلاغ المستمعين باكتمال العملية
        for (final listener in _listeners) {
          listener.complete();
        }
      } else {
        final error = result.error?.toString() ?? 'عملية الهجرة غير معروفة';
        _notifyProgress(error, completed: false);
        _logger.error('فشلت عملية الهجرة: $error');

        // إبلاغ المستمعين بحدوث خطأ
        for (final listener in _listeners) {
          listener.handleError(error);
        }

        rethrow;
      }
    } catch (e, stackTrace) {
      final error = 'خطأ في عملية الهجرة: \${e}';
      _notifyProgress(error, completed: false);
      _logger.error(error, error: e, stackTrace: stackTrace);

      // إبلاغ المستمعين بحدوث خطأ
      for (final listener in _listeners) {
        listener.handleError(e);
      }

      rethrow;
    } finally {
      _isExecuting = false;
    }

    return _currentResult!;
  }

  /// إعلام جميع المستمعين بالتقدم
  void _notifyProgress(String description, {bool completed = false}) {
    final progress = completed ? 1.0 : (_currentResult?.cardsMigrated ?? 0) / 100.0;

    for (final listener in _listeners) {
      listener.updateProgress(progress, description);
    }
  }

  /// التحقق مما إذا كانت عملية الهجرة قيد التنفيذ
  bool get isExecuting => _isExecuting;

  /// الحصول على نتيجة عملية الهجرة الحالية
  MigrationResult? get currentResult => _currentResult;

  /// إيقاف عملية الهجرة (إذا كانت قيد التنفيذ)
  Future<void> stopMigration() async {
    if (!_isExecuting) return;

    _logger.info('طلب إيقاف عملية الهجرة');
    // TODO: تنفيذ آلية الإيقاف
  }
}
