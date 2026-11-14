import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:loading_overlay/loading_overlay.dart';

void main() {
  late LoadingOverlayController controller;
  setUp(() => controller = LoadingOverlayController());
  tearDown(() => controller.dispose());

  test('run returns values and cleans up synchronous and asynchronous work',
      () async {
    expect(await controller.run(() => 42), 42);
    expect(controller.isLoading, isFalse);
    final completer = Completer<String>();
    final result = controller.run(() => completer.future, message: 'Saving');
    expect(controller.value.message, 'Saving');
    expect(controller.value.activeTasks, 1);
    completer.complete('saved');
    expect(await result, 'saved');
    expect(controller.value, const LoadingOverlayData());
  });

  for (final asynchronous in [false, true]) {
    test('run preserves error and stack (asynchronous=$asynchronous)',
        () async {
      final error = StateError('failure');
      final stack = StackTrace.current;
      final result = controller.run<void>(() {
        if (asynchronous) return Future<void>.error(error, stack);
        Error.throwWithStackTrace(error, stack);
      });
      try {
        await result;
        fail('Expected failure');
      } catch (e, s) {
        expect(e, same(error));
        expect(s.toString(), stack.toString());
      }
      expect(controller.isLoading, isFalse);
    });
  }

  test('overlapping tasks finish independently in either order', () {
    final a = controller.start(message: 'First', progress: 0.1);
    final b = controller.start(message: 'Second', progress: 0.2);
    a.update(message: 'First updated', progress: 0.8);
    expect(controller.value.message, 'Second');
    expect(controller.value.activeTasks, 2);
    b.finish();
    expect(controller.value.message, 'First updated');
    expect(controller.value.progress, 0.8);
    b.finish();
    expect(controller.value.activeTasks, 1);
    a.finish();
    expect(controller.isLoading, isFalse);
    final c = controller.start();
    final d = controller.start(message: 'Latest');
    c.finish();
    expect(controller.value.message, 'Latest');
    d.finish();
    expect(controller.isLoading, isFalse);
  });

  test('concurrent run calls keep loading until the final completion',
      () async {
    final a = Completer<int>();
    final b = Completer<int>();
    final first = controller.run(() => a.future);
    final second = controller.run(() => b.future);
    a.complete(1);
    expect(await first, 1);
    expect(controller.value.activeTasks, 1);
    b.complete(2);
    expect(await second, 2);
    expect(controller.isLoading, isFalse);
  });

  test('show is idempotent and hide cannot dismiss independently owned work',
      () {
    controller.show(message: 'Manual');
    controller.show(message: 'Updated');
    expect(controller.value.activeTasks, 1);
    expect(controller.value.message, 'Updated');
    final task = controller.start(message: 'Independent');
    controller.hide();
    controller.hide();
    expect(controller.value.activeTasks, 1);
    expect(controller.value.message, 'Independent');
    task.finish();
  });

  test(
      'update nulls clear message and progress; unchanged state does not notify',
      () {
    var notifications = 0;
    controller.addListener(() => notifications++);
    final task = controller.start(message: 'Upload', progress: 0.4);
    task.update(message: 'Upload', progress: 0.4);
    expect(notifications, 1);
    task.update();
    expect(controller.value.message, isNull);
    expect(controller.value.progress, isNull);
    expect(notifications, 2);
    expect(controller.value.hashCode,
        const LoadingOverlayData(activeTasks: 1).hashCode);
  });

  test('reset invalidates old handles without affecting new work', () {
    final old = controller.start();
    controller.reset();
    final current = controller.start(message: 'New');
    old.update(message: 'Obsolete');
    old.finish();
    expect(old.isActive, isFalse);
    expect(current.isActive, isTrue);
    expect(controller.value.message, 'New');
  });

  test('disposal makes late task updates harmless and rejects new work',
      () async {
    final task = controller.start();
    final pending = Completer<int>();
    final result = controller.run(() => pending.future);
    controller.dispose();
    task.update(message: 'Late');
    task.finish();
    controller.hide();
    controller.reset();
    expect(task.isActive, isFalse);
    expect(controller.start, throwsStateError);
    expect(controller.show, throwsStateError);
    pending.complete(7);
    expect(await result, 7);
  });

  for (final progress in [-0.1, 1.1, double.nan, double.infinity]) {
    test('rejects invalid progress $progress without mutating state', () {
      expect(() => controller.start(progress: progress), throwsArgumentError);
      expect(() => controller.show(progress: progress), throwsArgumentError);
      expect(controller.isLoading, isFalse);
      final task = controller.start(progress: 0.5);
      expect(() => task.update(progress: progress), throwsArgumentError);
      expect(controller.value.progress, 0.5);
    });
  }
}
