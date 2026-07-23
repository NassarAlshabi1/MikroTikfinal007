// ============================================================
// PriorityQueue not available — use List with sort
//  AsyncTaskManager — مدير مهام غير متزامن للتنفيذ المتوازي
//
//  يوفر:
//  - تنفيذ متوازي مع حد أقصى للمهام المتزامنة
//  - إيقاف مؤقت (pause) واستئناف (resume)
//  - إيقاف نهائي (stop)
//  - أولويات (priority)
//  - تتبع الحالة (pending, running, completed, failed)
//  - إحصائيات (عدد المكتمل، الفاشل، المعلّق)
// ============================================================

import 'dart:async';
import 'dart:collection';

/// حالة المهمة
enum TaskState { pending, running, completed, failed, cancelled }

/// أولوية المهمة
enum TaskPriority { low, normal, high, critical }

/// نتيجة المهمة
class TaskResult<T> {
  final T? data;
  final Object? error;
  final bool success;
  final Duration elapsed;

  const TaskResult({
    this.data,
    this.error,
    required this.success,
    required this.elapsed,
  });
}

/// مهمة فردية
class AsyncTask<T> {
  final String id;
  final String name;
  final TaskPriority priority;
  final Future<T> Function() executor;
  TaskState state;
  TaskResult<T>? result;
  Completer<TaskResult<T>>? _completer;

  AsyncTask({
    required this.id,
    required this.name,
    this.priority = TaskPriority.normal,
    required this.executor,
    this.state = TaskState.pending,
  });

  Future<TaskResult<T>> get future => _completer?.future ?? Future.value(null);

  void _start() {
    state = TaskState.running;
    _completer = Completer<TaskResult<T>>();
  }

  void _complete(TaskResult<T> res) {
    result = res;
    state = res.success ? TaskState.completed : TaskState.failed;
    _completer?.complete(res);
  }

  void _cancel() {
    state = TaskState.cancelled;
    _completer?.complete(TaskResult<T>(
      success: false,
      error: 'Task cancelled',
      elapsed: Duration.zero,
    ));
  }
}

/// إحصائيات المدير
class TaskManagerStats {
  final int total;
  final int pending;
  final int running;
  final int completed;
  final int failed;
  final int cancelled;

  const TaskManagerStats({
    required this.total,
    required this.pending,
    required this.running,
    required this.completed,
    required this.failed,
    required this.cancelled,
  });

  @override
  String toString() =>
      'TaskManagerStats(total=$total, pending=$pending, running=$running, '
      'completed=$completed, failed=$failed, cancelled=$cancelled)';
}

/// مدير مهام غير متزامن للتنفيذ المتوازي مع تحكم كامل
class AsyncTaskManager {
  final int _maxConcurrent;
  final List<AsyncTask> _queue = [];
  final List<AsyncTask> _allTasks = [];
  int _running = 0;
  bool _paused = false;
  bool _stopped = false;

  void _addToQueue(AsyncTask task) {
    _queue.add(task);
    _queue.sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }

  AsyncTask _removeFirst() {
    return _queue.removeAt(0);
  }

  final StreamController<AsyncTask> _taskCompletedController =
      StreamController<AsyncTask>.broadcast();

  /// يتدفّق عند اكتمال أي مهمة
  Stream<AsyncTask> get onTaskCompleted => _taskCompletedController.stream;

  AsyncTaskManager({int maxConcurrent = 3}) : _maxConcurrent = maxConcurrent;

  /// يضيف مهمة للطابور
  Future<TaskResult<T>> enqueue<T>({
    required String id,
    required String name,
    required Future<T> Function() executor,
    TaskPriority priority = TaskPriority.normal,
  }) {
    if (_stopped) {
      return Future.value(TaskResult<T>(
        success: false,
        error: 'Manager is stopped',
        elapsed: Duration.zero,
      ));
    }

    final task = AsyncTask<T>(
      id: id,
      name: name,
      priority: priority,
      executor: executor,
    );
    _addToQueue(task);
    _allTasks.add(task);

    _processQueue();
    return task.future;
  }

  /// يعالج الطابور — يشغّل المهام المتاحة
  void _processQueue() {
    if (_paused || _stopped) return;

    while (_running < _maxConcurrent && _queue.isNotEmpty) {
      final task = _removeFirst();
      _executeTask(task);
    }
  }

  /// ينفّذ مهمة واحدة
  Future<void> _executeTask(AsyncTask task) async {
    task._start();
    _running++;

    final stopwatch = Stopwatch()..start();
    try {
      final result = await task.executor();
      stopwatch.stop();
      task._complete(TaskResult(
        data: result,
        success: true,
        elapsed: stopwatch.elapsed,
      ));
    } catch (e) {
      stopwatch.stop();
      task._complete(TaskResult(
        error: e,
        success: false,
        elapsed: stopwatch.elapsed,
      ));
    } finally {
      _running--;
      _taskCompletedController.add(task);
      _processQueue(); // شغّل المهمة التالية
    }
  }

  /// إيقاف مؤقت
  void pause() {
    _paused = true;
  }

  /// استئناف
  void resume() {
    _paused = false;
    _processQueue();
  }

  /// إيقاف نهائي — يلغي كل المهام المعلّقة
  void stop() {
    _stopped = true;
    while (_queue.isNotEmpty) {
      final task = _removeFirst();
      task._cancel();
    }
  }

  /// ينتظر اكتمال كل المهام
  Future<void> waitAll() async {
    while (_running > 0 || _queue.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// إحصائيات
  TaskManagerStats get stats {
    var pending = 0, running = 0, completed = 0, failed = 0, cancelled = 0;
    for (final task in _allTasks) {
      switch (task.state) {
        case TaskState.pending:
          pending++;
          break;
        case TaskState.running:
          running++;
          break;
        case TaskState.completed:
          completed++;
          break;
        case TaskState.failed:
          failed++;
          break;
        case TaskState.cancelled:
          cancelled++;
          break;
      }
    }
    return TaskManagerStats(
      total: _allTasks.length,
      pending: pending,
      running: running,
      completed: completed,
      failed: failed,
      cancelled: cancelled,
    );
  }

  /// كل المهام
  List<AsyncTask> get tasks => List.unmodifiable(_allTasks);

  /// هل يعمل؟
  bool get isRunning => _running > 0;

  /// هل متوقف مؤقتاً؟
  bool get isPaused => _paused;

  /// هل متوقف نهائياً؟
  bool get isStopped => _stopped;

  /// تنظيف
  void dispose() {
    stop();
    _taskCompletedController.close();
    _allTasks.clear();
  }
}
