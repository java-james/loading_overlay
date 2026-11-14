import 'dart:async';

import 'package:flutter/foundation.dart';

/// An immutable snapshot supplied to overlay builders and controller listeners.
@immutable
class LoadingOverlayData {
  /// Creates a snapshot. A null [progress] means indeterminate progress.
  const LoadingOverlayData({
    this.activeTasks = 0,
    this.message,
    this.progress,
  })  : assert(activeTasks >= 0),
        assert(progress == null || (progress >= 0 && progress <= 1));

  /// Number of unfinished operations, including the optional manual operation.
  final int activeTasks;

  /// Message belonging to the most recently started unfinished operation.
  final String? message;

  /// Completion fraction from 0 to 1, or null for an indeterminate operation.
  final double? progress;

  /// Whether there is unfinished work. Presentation delays are not included.
  bool get isLoading => activeTasks > 0;

  @override
  bool operator ==(Object other) =>
      other is LoadingOverlayData &&
      activeTasks == other.activeTasks &&
      message == other.message &&
      progress == other.progress;

  @override
  int get hashCode => Object.hash(activeTasks, message, progress);
}

/// Owns loading operations without retaining a BuildContext or global state.
///
/// Prefer [run] to pair presentation and cleanup automatically. Overlapping
/// operations keep the overlay active until all finish. The newest unfinished
/// operation supplies the message and progress; finishing it restores the
/// previous operation's presentation.
///
/// Dispose controllers you create. A scope disposes only its own controller.
class LoadingOverlayController extends ChangeNotifier
    implements ValueListenable<LoadingOverlayData> {
  /// Creates an idle controller. Dispose it when its owner is removed.
  LoadingOverlayController();

  final Map<int, LoadingOverlayData> _tasks = {};
  int _nextId = 0;
  int? _manualId;
  bool _disposed = false;
  LoadingOverlayData _value = const LoadingOverlayData();

  /// The current immutable state. Listen with ValueListenableBuilder if needed.
  @override
  LoadingOverlayData get value => _value;

  /// Whether any operation is unfinished, independent of visual transitions.
  bool get isLoading => value.isLoading;

  /// Starts an independently owned operation. Always finish its returned handle.
  LoadingOverlayTask start({String? message, double? progress}) {
    _checkNotDisposed();
    _validateProgress(progress);
    final id = _nextId++;
    _tasks[id] = LoadingOverlayData(
      activeTasks: 1,
      message: message,
      progress: progress,
    );
    _publish();
    return LoadingOverlayTask._(this, id);
  }

  /// Runs [operation] and finishes its task on success or error.
  ///
  /// Returns the original result and propagates errors with their stack traces.
  /// Both synchronous exceptions and asynchronous failures trigger cleanup.
  /// Operations already running continue if this controller is disposed.
  Future<T> run<T>(
    FutureOr<T> Function() operation, {
    String? message,
    double? progress,
  }) async {
    final task = start(message: message, progress: progress);
    try {
      return await operation();
    } finally {
      task.finish();
    }
  }

  /// Shows or replaces a single manual operation. Repeated calls are idempotent.
  ///
  /// Pair with [hide]. Use [run] or [start] for independently owned operations.
  void show({String? message, double? progress}) {
    _checkNotDisposed();
    _validateProgress(progress);
    final id = _manualId ??= _nextId++;
    _tasks[id] = LoadingOverlayData(
      activeTasks: 1,
      message: message,
      progress: progress,
    );
    _publish();
  }

  /// Finishes only the manual operation created by [show].
  ///
  /// Work started by [run] and [start] stays visible. Safe to call repeatedly.
  void hide() {
    if (_manualId case final id?) {
      _manualId = null;
      _finish(id);
    }
  }

  /// Clears presentation for all tasks without cancelling their underlying work.
  ///
  /// Old handles become inert and cannot finish subsequently started tasks.
  void reset() {
    if (_disposed) return;
    _tasks.clear();
    _manualId = null;
    _publish();
  }

  void _update(int id, String? message, double? progress) {
    if (!_tasks.containsKey(id) || _disposed) return;
    _validateProgress(progress);
    _tasks[id] = LoadingOverlayData(
      activeTasks: 1,
      message: message,
      progress: progress,
    );
    _publish();
  }

  void _finish(int id) {
    if (_disposed || _tasks.remove(id) == null) return;
    _publish();
  }

  void _publish() {
    final latest = _tasks.isEmpty ? null : _tasks.values.last;
    final next = LoadingOverlayData(
      activeTasks: _tasks.length,
      message: latest?.message,
      progress: latest?.progress,
    );
    if (_value == next) return;
    _value = next;
    notifyListeners();
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('LoadingOverlayController is disposed.');
  }

  static void _validateProgress(double? progress) {
    if (progress != null &&
        (!progress.isFinite || progress < 0 || progress > 1)) {
      throw ArgumentError.value(
          progress, 'progress', 'Must be between 0 and 1.');
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _tasks.clear();
    _manualId = null;
    _value = const LoadingOverlayData();
    super.dispose();
  }
}

/// An independently owned loading operation returned by a controller's start.
///
/// Finishing, updating, or finishing again after disposal/reset is harmless.
/// This handle controls presentation; it never cancels application work.
class LoadingOverlayTask {
  LoadingOverlayTask._(this._controller, this._id);

  final LoadingOverlayController _controller;
  final int _id;

  /// Whether this task still belongs to its controller's unfinished work.
  bool get isActive => _controller._tasks.containsKey(_id);

  /// Replaces this task's presentation. Null clears the corresponding field.
  void update({String? message, double? progress}) =>
      _controller._update(_id, message, progress);

  /// Finishes only this operation. Safe to invoke more than once.
  void finish() => _controller._finish(_id);
}
