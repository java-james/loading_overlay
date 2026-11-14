import 'dart:async';

// Keep testing the SDK Material widgets supported by Flutter 2.x.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_overlay/loading_overlay.dart';

Widget manualOverlay(bool isLoading) => MaterialApp(
      home: LoadingOverlay(
        isLoading: isLoading,
        child: const Text('child'),
      ),
    );

Widget futureOverlay(Future<void> future) => MaterialApp(
      home: LoadingOverlay.withFuture(
        future: future,
        child: const Text('child'),
      ),
    );

Future<void> finishFade(WidgetTester tester) async {
  // Process future callbacks, start the animation's first frame, then finish it.
  await tester.pump();
  await tester.pump();
  // Allow the frame after the exact endpoint to deliver AnimationStatus.dismissed.
  await tester.pump(const Duration(milliseconds: 301));
}

void main() {
  group('Modal Progress HUD', () {
    Widget sut(bool isLoading) => MaterialApp(
          home: LoadingOverlay(
            isLoading: isLoading,
            child: const Text(''),
          ),
        );

    testWidgets('should show progress indicator when loading', (tester) async {
      const inAsyncCall = true;
      await tester.pumpWidget(sut(inAsyncCall));

      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should not show progress indicator when not loading',
        (tester) async {
      const inAsyncCall = false;
      await tester.pumpWidget(sut(inAsyncCall));

      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('LoadingOverlay.withFuture', () {
    testWidgets('shows progress indicator immediately', (tester) async {
      final completer = Completer<void>();
      final widget = MaterialApp(
        home: LoadingOverlay.withFuture(
          future: completer.future,
          child: const Text('child'),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides progress indicator when future completes',
        (tester) async {
      final completer = Completer<void>();
      final widget = MaterialApp(
        home: LoadingOverlay.withFuture(
          future: completer.future,
          child: const Text('child'),
        ),
      );

      await tester.pumpWidget(widget);
      await finishFade(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future and allow reverse animation to finish
      completer.complete();
      await finishFade(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    for (final fail in [false, true]) {
      testWidgets('ignores obsolete future ${fail ? 'errors' : 'completion'}',
          (tester) async {
        final first = Completer<void>();
        final second = Completer<void>();
        await tester.pumpWidget(futureOverlay(first.future));
        await finishFade(tester);
        await tester.pumpWidget(futureOverlay(second.future));

        if (fail) {
          first.completeError(StateError('obsolete operation'));
        } else {
          first.complete();
        }
        await finishFade(tester);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        second.complete();
        await finishFade(tester);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('ignores ${fail ? 'errors' : 'completion'} after disposal',
          (tester) async {
        final operation = Completer<void>();
        await tester.pumpWidget(futureOverlay(operation.future));
        await finishFade(tester);
        await tester.pumpWidget(const SizedBox());
        if (fail) {
          operation.completeError(StateError('disposed operation'));
        } else {
          operation.complete();
        }
        await finishFade(tester);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('handles errors without changing the caller future',
        (tester) async {
      final operation = Completer<void>();
      final error = StateError('save failed');
      final stackTrace = StackTrace.current;
      Object? receivedError;
      StackTrace? receivedStackTrace;
      operation.future.then<void>((_) {}, onError: (Object e, StackTrace s) {
        receivedError = e;
        receivedStackTrace = s;
      });
      await tester.pumpWidget(futureOverlay(operation.future));
      await finishFade(tester);
      operation.completeError(error, stackTrace);
      await finishFade(tester);

      expect(receivedError, same(error));
      expect(receivedStackTrace, same(stackTrace));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hides on error without a separate error listener',
        (tester) async {
      final operation = Completer<void>();
      await tester.pumpWidget(futureOverlay(operation.future));
      await finishFade(tester);
      operation.completeError(StateError('save failed'));
      await finishFade(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not restart a completed future on rebuild',
        (tester) async {
      final operation = Completer<void>();
      await tester.pumpWidget(futureOverlay(operation.future));
      await finishFade(tester);
      await tester.pumpWidget(futureOverlay(operation.future));
      operation.complete();
      await finishFade(tester);
      await tester.pumpWidget(futureOverlay(operation.future));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await finishFade(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows for a new future after the previous future completed',
        (tester) async {
      final first = Completer<void>();
      final second = Completer<void>();
      await tester.pumpWidget(futureOverlay(first.future));
      first.complete();
      await finishFade(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pumpWidget(futureOverlay(second.future));
      await finishFade(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      second.complete();
      await finishFade(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('handles synchronous completion', (tester) async {
      await tester.pumpWidget(futureOverlay(SynchronousFuture<void>(null)));
      await finishFade(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles synchronous completion when replacing a future',
        (tester) async {
      final operation = Completer<void>();
      await tester.pumpWidget(futureOverlay(operation.future));
      await finishFade(tester);

      await tester.pumpWidget(futureOverlay(SynchronousFuture<void>(null)));
      await finishFade(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      operation.complete();
      await finishFade(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows for a new future during the previous fade-out',
        (tester) async {
      final first = Completer<void>();
      final second = Completer<void>();
      await tester.pumpWidget(futureOverlay(first.future));
      await finishFade(tester);

      first.complete();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(
          tester
              .widget<FadeTransition>(find.byType(FadeTransition).last)
              .opacity
              .value,
          closeTo(0.5, 0.01));

      await tester.pumpWidget(futureOverlay(second.future));
      await finishFade(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      second.complete();
      await finishFade(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('handles completion before the first fade finishes',
        (tester) async {
      final operation = Completer<void>();
      await tester.pumpWidget(futureOverlay(operation.future));
      await tester.pump(const Duration(milliseconds: 150));
      operation.complete();
      await finishFade(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('switching visibility controls', () {
    for (final isLoading in [false, true]) {
      for (final completed in [false, true]) {
        testWidgets(
            'switches from ${completed ? 'completed' : 'pending'} future to isLoading=$isLoading',
            (tester) async {
          final operation = Completer<void>();
          await tester.pumpWidget(futureOverlay(operation.future));
          await finishFade(tester);
          if (completed) {
            operation.complete();
            await finishFade(tester);
          }
          await tester.pumpWidget(manualOverlay(isLoading));
          await finishFade(tester);
          expect(find.byType(CircularProgressIndicator),
              isLoading ? findsOneWidget : findsNothing);

          if (!completed) {
            operation.complete();
            await finishFade(tester);
            expect(find.byType(CircularProgressIndicator),
                isLoading ? findsOneWidget : findsNothing);
          }
        });
      }

      testWidgets('switches from isLoading=$isLoading to a future',
          (tester) async {
        final operation = Completer<void>();
        await tester.pumpWidget(manualOverlay(isLoading));
        await finishFade(tester);
        await tester.pumpWidget(futureOverlay(operation.future));
        await finishFade(tester);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        operation.complete();
        await finishFade(tester);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    }
  });

  group('existing overlay behaviour', () {
    testWidgets('fades in and out over 300 milliseconds', (tester) async {
      await tester.pumpWidget(manualOverlay(false));
      await tester.pumpWidget(manualOverlay(true));
      double opacity() => tester
          .widget<FadeTransition>(find.byType(FadeTransition).last)
          .opacity
          .value;
      expect(opacity(), 0);
      await tester.pump(const Duration(milliseconds: 150));
      expect(opacity(), closeTo(0.5, 0.01));
      await tester.pump(const Duration(milliseconds: 150));
      expect(opacity(), 1);

      await tester.pumpWidget(manualOverlay(false));
      await tester.pump(const Duration(milliseconds: 150));
      expect(opacity(), closeTo(0.5, 0.01));
      await tester.pump(const Duration(milliseconds: 150));
      expect(opacity(), closeTo(0, 0.01));
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
        'blocks child taps through fade-out and restores them afterwards',
        (tester) async {
      var taps = 0;
      Widget app(bool loading) => MaterialApp(
            home: LoadingOverlay(
              isLoading: loading,
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => taps++,
                  child: const SizedBox(
                    key: Key('tap-target'),
                    width: 100,
                    height: 100,
                    child: ColoredBox(color: Colors.red),
                  ),
                ),
              ),
            ),
          );
      await tester.pumpWidget(app(false));
      final position = tester.getCenter(find.byKey(const Key('tap-target')));
      await tester.tapAt(position);
      expect(taps, 1);
      await tester.pumpWidget(app(true));
      await tester.tapAt(position);
      expect(taps, 1);
      await finishFade(tester);
      await tester.tapAt(position);
      expect(taps, 1);
      await tester.pumpWidget(app(false));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tapAt(position);
      expect(taps, 1);
      await tester.pump(const Duration(milliseconds: 151));
      await tester.tapAt(position);
      expect(taps, 2);
    });

    testWidgets('preserves child state across rapid loading changes',
        (tester) async {
      Widget app(bool loading) => MaterialApp(
            home: LoadingOverlay(
              isLoading: loading,
              child: Form(child: const Text('form')),
            ),
          );
      await tester.pumpWidget(app(false));
      final childState = tester.state<FormState>(find.byType(Form));
      await tester.pumpWidget(app(true));
      expect(tester.state<FormState>(find.byType(Form)), same(childState));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(app(false));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(app(true));
      await finishFade(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.state<FormState>(find.byType(Form)), same(childState));
      await tester.pumpWidget(app(false));
      await finishFade(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.state<FormState>(find.byType(Form)), same(childState));
    });

    for (final useFuture in [false, true]) {
      testWidgets('honours custom colour and indicator (future=$useFuture)',
          (tester) async {
        const indicator = Text('custom progress');
        const color = Color(0x40800000);
        final operation = Completer<void>();
        await tester.pumpWidget(MaterialApp(
          home: useFuture
              ? LoadingOverlay.withFuture(
                  future: operation.future,
                  color: color,
                  progressIndicator: indicator,
                  child: const Text('child'),
                )
              : const LoadingOverlay(
                  isLoading: true,
                  color: color,
                  progressIndicator: indicator,
                  child: Text('child'),
                ),
        ));
        expect(find.text('custom progress'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
            find.byWidgetPredicate(
                (widget) => widget is ColoredBox && widget.color == color),
            findsOneWidget);
      });
    }

    testWidgets('preserves the default backdrop and white indicator',
        (tester) async {
      await tester.pumpWidget(manualOverlay(true));
      expect(
          find.byWidgetPredicate((widget) =>
              widget is ColoredBox && widget.color == const Color(0x80000000)),
          findsOneWidget);
      final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator));
      expect(indicator.valueColor!.value, Colors.white);
    });
  });
}
