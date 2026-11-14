import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_overlay/loading_overlay.dart';

import 'test_app.dart';

void main() {
  for (final seed in [31, 829, 74213]) {
    testWidgets('mixed control modes settle and restore input (seed $seed)',
        (tester) async {
      final random = Random(seed);
      final controllers = [
        LoadingOverlayController(),
        LoadingOverlayController(),
      ];
      for (final controller in controllers) {
        addTearDown(controller.dispose);
      }
      final tasks = <LoadingOverlayTask>[];
      final futures = <Completer<void>>[];
      Completer<void>? currentFuture;
      var mode = 0;
      var loading = false;
      var reduceMotion = false;
      var style = const LoadingOverlayStyle();
      var taps = 0;
      var mounts = 0;

      Widget app() {
        final child = _MountProbe(
          onMount: () => mounts++,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox.expand(),
          ),
        );
        final Widget overlay = switch (mode) {
          0 => LoadingOverlay(
              isLoading: loading,
              style: style,
              message: 'Boolean work',
              child: child,
            ),
          1 => LoadingOverlay.withFuture(
              future: currentFuture!.future,
              style: style,
              message: 'Future work',
              child: child,
            ),
          _ => LoadingOverlay.controlled(
              controller: controllers[mode - 2],
              style: style,
              child: child,
            ),
        };
        return TestApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: overlay,
          ),
        );
      }

      await tester.pumpWidget(app());
      for (var i = 0; i < 160; i++) {
        final controller = controllers[random.nextInt(controllers.length)];
        switch (random.nextInt(10)) {
          case 0:
            mode = random.nextInt(4);
            if (mode == 1) {
              currentFuture = Completer<void>();
              futures.add(currentFuture);
            }
          case 1:
            loading = !loading;
          case 2:
            tasks.add(controller.start(
                message: 'Operation $i', progress: random.nextDouble()));
          case 3:
            controller.show(message: 'Manual $i');
          case 4:
            controller.hide();
          case 5:
            controller.reset();
          case 6:
            if (tasks.isNotEmpty) {
              final task = tasks[random.nextInt(tasks.length)];
              task.update(message: 'Finishing $i', progress: 1);
              task.finish();
            }
          case 7:
            final pending = futures.where((future) => !future.isCompleted);
            if (pending.isNotEmpty) {
              final future = pending.elementAt(random.nextInt(pending.length));
              if (random.nextBool()) {
                future.complete();
              } else {
                future.completeError(StateError('Expected failure $i'));
              }
            }
          case 8:
            style = LoadingOverlayStyle(
              duration: Duration(milliseconds: random.nextInt(80)),
              reverseDuration: Duration(milliseconds: random.nextInt(80)),
              showDelay: Duration(milliseconds: random.nextInt(80)),
              minimumVisibleDuration:
                  Duration(milliseconds: random.nextInt(120)),
            );
          case 9:
            reduceMotion = !reduceMotion;
        }
        await tester.pumpWidget(app());
        await tester.pump(Duration(milliseconds: random.nextInt(90)));
        final expectedLoading = switch (mode) {
          0 => loading,
          1 => !currentFuture!.isCompleted,
          _ => controllers[mode - 2].isLoading,
        };
        if (expectedLoading) {
          final before = taps;
          await tester.tapAt(const Offset(10, 10));
          expect(taps, before, reason: 'Input escaped in mode $mode at $i');
        }
        expect(mounts, 1, reason: 'Child lost state in mode $mode at $i');
        expect(tester.takeException(), isNull, reason: 'Mode $mode at $i');
      }

      loading = false;
      for (final controller in controllers) {
        controller.reset();
      }
      for (final future in futures.where((future) => !future.isCompleted)) {
        future.complete();
      }
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(LoadingOverlayIndicator), findsNothing);
      final before = taps;
      await tester.tapAt(const Offset(10, 10));
      expect(taps, before + 1);
      expect(mounts, 1);
      expect(tester.takeException(), isNull);
    });
  }
}

class _MountProbe extends StatefulWidget {
  const _MountProbe({required this.onMount, required this.child});

  final VoidCallback onMount;
  final Widget child;

  @override
  State<_MountProbe> createState() => _MountProbeState();
}

class _MountProbeState extends State<_MountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
