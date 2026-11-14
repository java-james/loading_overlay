import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_overlay/loading_overlay.dart';

import 'test_app.dart';

const _instant = LoadingOverlayStyle(
  duration: Duration.zero,
  reverseDuration: Duration.zero,
);

class _DuringBuild extends StatelessWidget {
  const _DuringBuild(this.callback);

  final VoidCallback callback;

  @override
  Widget build(BuildContext context) {
    callback();
    return const SizedBox.expand();
  }
}

void main() {
  testWidgets('synchronous future completion cancels delayed visuals',
      (tester) async {
    await tester.pumpWidget(TestApp(
      home: LoadingOverlay.withFuture(
        future: SynchronousFuture<void>(null),
        style: const LoadingOverlayStyle(
          duration: Duration.zero,
          reverseDuration: Duration.zero,
          showDelay: Duration(milliseconds: 10),
          minimumVisibleDuration: Duration(seconds: 1),
        ),
        child: const SizedBox.expand(),
      ),
    ));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reentrant reset and new task retain latest loading state',
      (tester) async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(TestApp(
      home: LoadingOverlay.controlled(
        controller: controller,
        style: _instant,
        child: const SizedBox.expand(),
      ),
    ));
    LoadingOverlayTask? replacement;
    controller.addListener(() {
      if (controller.value.message == 'First') {
        controller.reset();
        replacement = controller.start(message: 'Replacement');
      }
    });
    final obsolete = controller.start(message: 'First');
    await tester.pump();
    expect(obsolete.isActive, isFalse);
    expect(replacement!.isActive, isTrue);
    expect(find.text('Replacement'), findsOneWidget);
    obsolete.finish();
    await tester.pump();
    expect(find.text('Replacement'), findsOneWidget);
    replacement!.finish();
    await tester.pump();
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('queued controller update cannot override a new future',
      (tester) async {
    final controller = LoadingOverlayController();
    final future = Completer<void>();
    addTearDown(controller.dispose);
    Widget app(bool replace) => TestApp(
          home: Column(children: [
            SizedBox(
              height: 0,
              child: _DuringBuild(() {
                // This sibling builds before the existing overlay changes its
                // source, leaving an old-controller notification queued.
                if (replace) controller.show(message: 'Old controller');
              }),
            ),
            Expanded(
              child: replace
                  ? LoadingOverlay.withFuture(
                      future: future.future,
                      style: _instant,
                      message: 'New future',
                      child: const SizedBox.expand(),
                    )
                  : LoadingOverlay.controlled(
                      controller: controller,
                      style: _instant,
                      child: const SizedBox.expand(),
                    ),
            ),
          ]),
        );
    await tester.pumpWidget(app(false));
    await tester.pumpWidget(app(true));
    controller.hide();
    await tester.pump();
    expect(find.text('New future'), findsOneWidget);
    future.complete();
    await tester.pump();
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completing a future during build safely hides visuals',
      (tester) async {
    final completer = Completer<void>.sync();
    var finishInBuild = false;
    late StateSetter rebuild;
    await tester.pumpWidget(TestApp(
      home: StatefulBuilder(builder: (context, setState) {
        rebuild = setState;
        return LoadingOverlay.withFuture(
          future: completer.future,
          style: _instant,
          child: _DuringBuild(() {
            if (finishInBuild && !completer.isCompleted) completer.complete();
          }),
        );
      }),
    ));
    expect(find.byType(LoadingOverlayIndicator), findsOneWidget);
    rebuild(() => finishInBuild = true);
    await tester.pump();
    await tester.pump();
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing widget cancels deferred controller refresh',
      (tester) async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    Widget app(bool remove) => TestApp(
          home: Column(children: [
            SizedBox(
              height: 0,
              child: _DuringBuild(() {
                if (remove) controller.show();
              }),
            ),
            Expanded(
              child: remove
                  ? const SizedBox.expand()
                  : LoadingOverlay.controlled(
                      controller: controller,
                      style: _instant,
                      child: const SizedBox.expand(),
                    ),
            ),
          ]),
        );
    await tester.pumpWidget(app(false));
    await tester.pumpWidget(app(true));
    controller.reset();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('back guard binds current controller after queued update',
      (tester) async {
    final first = LoadingOverlayController();
    final second = LoadingOverlayController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    const guardKey = ValueKey('guard');
    Widget app(bool replace) => TestApp(
          home: Column(children: [
            SizedBox(
              height: 0,
              child: _DuringBuild(() {
                if (replace) first.show();
              }),
            ),
            Expanded(
              child: LoadingOverlayBackGuard(
                key: guardKey,
                controller: replace ? second : first,
                child: const SizedBox.expand(),
              ),
            ),
          ]),
        );
    bool canPop() => tester
        .widget<PopScope<Object?>>(find.descendant(
          of: find.byKey(guardKey),
          matching: find.byType(PopScope<Object?>),
        ))
        .canPop;
    await tester.pumpWidget(app(false));
    await tester.pumpWidget(app(true));
    await tester.pump();
    expect(canPop(), isTrue);
    second.show();
    await tester.pump();
    expect(canPop(), isFalse);
    first.hide();
    await tester.pump();
    expect(canPop(), isFalse);
    second.hide();
    await tester.pump();
    expect(canPop(), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing back guard cancels queued rebuild', (tester) async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    Widget app(bool remove) => TestApp(
          home: Column(children: [
            SizedBox(
              height: 0,
              child: _DuringBuild(() {
                if (remove) controller.show();
              }),
            ),
            Expanded(
              child: remove
                  ? const SizedBox.expand()
                  : LoadingOverlayBackGuard(
                      controller: controller,
                      child: const SizedBox.expand(),
                    ),
            ),
          ]),
        );
    await tester.pumpWidget(app(false));
    await tester.pumpWidget(app(true));
    controller.hide();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid interleaved tasks always unblock after settling',
      (tester) async {
    final random = Random(672319);
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    final tasks = <LoadingOverlayTask>[];
    var taps = 0;
    await tester.pumpWidget(TestApp(
      home: LoadingOverlay.controlled(
        controller: controller,
        style: const LoadingOverlayStyle(
          showDelay: Duration(milliseconds: 30),
          minimumVisibleDuration: Duration(milliseconds: 60),
          duration: Duration(milliseconds: 40),
          reverseDuration: Duration(milliseconds: 50),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox.expand(),
        ),
      ),
    ));
    for (var i = 0; i < 300; i++) {
      switch (random.nextInt(6)) {
        case 0:
          tasks.add(controller.start(message: 'Task $i'));
        case 1:
          controller.show(message: 'Manual $i');
        case 2:
          controller.hide();
        case 3:
          if (tasks.isNotEmpty) {
            tasks[random.nextInt(tasks.length)].finish();
          }
        case 4:
          controller.reset();
        case 5:
          if (tasks.isNotEmpty) {
            tasks[random.nextInt(tasks.length)]
                .update(message: 'Updated $i', progress: random.nextDouble());
          }
      }
      await tester.pump(Duration(milliseconds: random.nextInt(50)));
      if (controller.isLoading) {
        final before = taps;
        await tester.tapAt(const Offset(10, 10));
        expect(taps, before, reason: 'Input escaped at event $i');
      }
      expect(tester.takeException(), isNull, reason: 'Event $i');
    }
    controller.reset();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
    final before = taps;
    await tester.tapAt(const Offset(10, 10));
    expect(taps, before + 1);
  });

  testWidgets('style timing changes wait until the next cycle', (tester) async {
    Widget app(bool loading, LoadingOverlayStyle style) => TestApp(
          home: LoadingOverlay(
            isLoading: loading,
            style: style,
            child: const SizedBox.expand(),
          ),
        );
    const original = LoadingOverlayStyle(
      duration: Duration.zero,
      reverseDuration: Duration(milliseconds: 300),
    );
    await tester.pumpWidget(app(true, original));
    await tester.pumpWidget(app(true, _instant));
    await tester.pumpWidget(app(false, _instant));
    expect(find.byType(LoadingOverlayIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 301));
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
    await tester.pumpWidget(app(true, _instant));
    expect(find.byType(LoadingOverlayIndicator), findsOneWidget);
    await tester.pumpWidget(app(false, _instant));
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
  });

  test('disposed pending run preserves asynchronous failure', () async {
    final controller = LoadingOverlayController();
    final completer = Completer<void>();
    final error = StateError('failed after owner disposal');
    final stack = StackTrace.current;
    final result = controller.run(() => completer.future);
    Object? receivedError;
    StackTrace? receivedStack;
    final observed =
        result.then<void>((_) {}, onError: (Object e, StackTrace s) {
      receivedError = e;
      receivedStack = s;
    });
    controller.dispose();
    completer.completeError(error, stack);
    await observed;
    expect(receivedError, same(error));
    expect(receivedStack.toString(), stack.toString());
  });

  test('resetting pending run cannot clean up its replacement', () async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    final first = Completer<void>();
    final second = Completer<void>();
    final firstResult = controller.run(() => first.future, message: 'First');
    controller.reset();
    final secondResult = controller.run(() => second.future, message: 'Second');
    first.complete();
    await firstResult;
    expect(controller.value.activeTasks, 1);
    expect(controller.value.message, 'Second');
    second.complete();
    await secondResult;
    expect(controller.value, const LoadingOverlayData());
  });

  test('nested run restores outer presentation before finishing', () async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    final observed = <LoadingOverlayData>[];
    controller.addListener(() => observed.add(controller.value));
    final result = await controller.run(() async {
      return await controller.run(() => 17, message: 'Inner') + 1;
    }, message: 'Outer');
    expect(result, 18);
    expect(
      observed,
      const [
        LoadingOverlayData(activeTasks: 1, message: 'Outer'),
        LoadingOverlayData(activeTasks: 2, message: 'Inner'),
        LoadingOverlayData(activeTasks: 1, message: 'Outer'),
        LoadingOverlayData(),
      ],
    );
  });
}
