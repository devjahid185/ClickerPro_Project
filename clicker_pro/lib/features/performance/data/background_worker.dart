import 'dart:async';
import 'dart:collection';

enum BackgroundTaskType { pdfGeneration, reminderSending, backup, export }

class BackgroundTask {
  BackgroundTask({
    required this.id,
    required this.type,
    required this.execute,
    this.description,
    this.createdAt,
  });

  final String id;
  final BackgroundTaskType type;
  final Future<void> Function() execute;
  final String? description;
  final DateTime? createdAt;

  @override
  String toString() =>
      'BackgroundTask(id: $id, type: ${type.name}, desc: $description)';
}

class BackgroundWorker {
  BackgroundWorker() {
    _processTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => processQueue(),
    );
  }

  final Queue<BackgroundTask> _queue = Queue<BackgroundTask>();
  final List<BackgroundTask> _completed = [];
  final StreamController<BackgroundTask> _taskController =
      StreamController<BackgroundTask>.broadcast();
  Timer? _processTimer;
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;
  int get pendingCount => _queue.length;
  List<BackgroundTask> get completed => List.unmodifiable(_completed);

  Stream<BackgroundTask> get onTaskCompleted => _taskController.stream;

  void enqueue(BackgroundTask task) {
    _queue.add(task);
  }

  Future<void> processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();
      try {
        await task.execute();
        _completed.add(task);
        if (!_taskController.isClosed) {
          _taskController.add(task);
        }
      } catch (e) {
        // Task failed — log and continue with next task.
        _completed.add(task);
        if (!_taskController.isClosed) {
          _taskController.add(task);
        }
      }
    }

    _isProcessing = false;
  }

  Future<void> cancelAll() async {
    _queue.clear();
  }

  void dispose() {
    _processTimer?.cancel();
    _taskController.close();
  }
}

/// Placeholder for Isolate-based heavy computation.
///
/// When compute-heavy tasks (PDF rendering, image processing) are added
/// to the queue, they should be dispatched through [Isolate.run] or a
/// long-lived Isolate pool to keep the main thread responsive.
class IsolateRunner {
  IsolateRunner._();

  static Future<T> compute<T>(Future<T> Function() task) async {
    return task();
  }
}
