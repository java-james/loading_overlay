import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_overlay/loading_overlay.dart';

import 'test_app.dart';

const instant = LoadingOverlayStyle(
    duration: Duration.zero, reverseDuration: Duration.zero);

Future<void> finishFade(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 301));
  await tester.pump();
}

void main() {
  testWidgets('delay blocks input immediately and short work never flashes',
      (tester) async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    var taps = 0;
    await tester.pumpWidget(TestApp(
        home: LoadingOverlay.controlled(
      controller: controller,
      style: const LoadingOverlayStyle(showDelay: Duration(milliseconds: 150)),
      child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox.expand()),
    )));
    controller.show();
    await tester.pump();
    await tester.tapAt(const Offset(50, 50));
    expect(taps, 0);
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    controller.hide();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
    await tester.tapAt(const Offset(50, 50));
    expect(taps, 1);
  });

  testWidgets('minimum duration starts when visible and retains final progress',
      (tester) async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(TestApp(
        home: LoadingOverlay.controlled(
      controller: controller,
      style: const LoadingOverlayStyle(
        showDelay: Duration(milliseconds: 100),
        minimumVisibleDuration: Duration(milliseconds: 500),
        duration: Duration.zero,
        reverseDuration: Duration.zero,
      ),
      child: const SizedBox.expand(),
    )));
    final task = controller.start(message: 'Uploading', progress: 0.75);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('75%'), findsOneWidget);
    task.finish();
    await tester.pump(const Duration(milliseconds: 499));
    expect(find.text('Uploading'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
  });

  testWidgets('new work during minimum duration is never hidden by old timer',
      (tester) async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(TestApp(
        home: LoadingOverlay.controlled(
      controller: controller,
      style: const LoadingOverlayStyle(
          minimumVisibleDuration: Duration(milliseconds: 200)),
      child: const SizedBox.expand(),
    )));
    controller.show();
    await tester.pump(const Duration(milliseconds: 50));
    controller.hide();
    await tester.pump(const Duration(milliseconds: 50));
    controller.show(message: 'New');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('New'), findsOneWidget);
    controller.hide();
    await finishFade(tester);
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
  });

  testWidgets('controller replacement disconnects stale notifications',
      (tester) async {
    final a = LoadingOverlayController();
    final b = LoadingOverlayController();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    Widget app(LoadingOverlayController c) => TestApp(
            home: LoadingOverlay.controlled(
          controller: c,
          style: instant,
          child: const SizedBox.expand(),
        ));
    a.show(message: 'First');
    b.show(message: 'Second');
    await tester.pumpWidget(app(a));
    await tester.pumpWidget(app(b));
    a.hide();
    await tester.pump();
    expect(find.text('Second'), findsOneWidget);
    b.hide();
    await tester.pump();
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
    a.show();
    await tester.pump();
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
  });

  testWidgets('switching controller, future and boolean ignores old owners',
      (tester) async {
    final controller = LoadingOverlayController()..show();
    final completer = Completer<void>();
    addTearDown(controller.dispose);
    await tester.pumpWidget(TestApp(
        home: LoadingOverlay.controlled(
      controller: controller,
      style: instant,
      child: const SizedBox.expand(),
    )));
    await tester.pumpWidget(TestApp(
        home: LoadingOverlay.withFuture(
      future: completer.future,
      style: instant,
      child: const SizedBox.expand(),
    )));
    controller.hide();
    await tester.pump();
    expect(find.byType(LoadingOverlayIndicator), findsOneWidget);
    await tester.pumpWidget(const TestApp(
        home: LoadingOverlay(
      isLoading: true,
      style: instant,
      child: SizedBox.expand(),
    )));
    completer.complete();
    await tester.pump();
    expect(find.byType(LoadingOverlayIndicator), findsOneWidget);
  });

  testWidgets('withFuture accepts a typed result and does not consume it',
      (tester) async {
    final completer = Completer<int>();
    await tester.pumpWidget(TestApp(
        home: LoadingOverlay.withFuture(
      future: completer.future,
      style: instant,
      child: const SizedBox.expand(),
    )));
    completer.complete(42);
    await tester.pump();
    expect(await completer.future, 42);
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
  });

  testWidgets('removing widget cancels delay and minimum timers',
      (tester) async {
    for (final delay in [Duration.zero, const Duration(seconds: 1)]) {
      await tester.pumpWidget(TestApp(
          home: LoadingOverlay(
        isLoading: true,
        style: LoadingOverlayStyle(
            showDelay: delay,
            minimumVisibleDuration: const Duration(seconds: 2)),
        child: const SizedBox.expand(),
      )));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('reduced motion disables fade and indeterminate animation',
      (tester) async {
    Widget app(bool loading) => TestApp(
            home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: LoadingOverlay(
              isLoading: loading, child: const SizedBox.expand()),
        ));
    await tester.pumpWidget(app(true));
    final fade =
        tester.widget<FadeTransition>(find.byType(FadeTransition).last);
    expect(fade.opacity.value, 1);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(app(false));
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
  });

  testWidgets('changing reduced motion during fade out removes overlay',
      (tester) async {
    Widget app(bool loading, bool reduce) => TestApp(
            home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: LoadingOverlay(
              isLoading: loading, child: const SizedBox.expand()),
        ));
    await tester.pumpWidget(app(true, false));
    await finishFade(tester);
    await tester.pumpWidget(app(false, false));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(app(false, true));
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
  });

  testWidgets('excludes focused background from keyboard input while loading',
      (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var activations = 0;
    Widget app(bool loading) => TestApp(
            home: LoadingOverlay(
          isLoading: loading,
          style: instant,
          child: Focus(
            focusNode: focus,
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.enter) {
                activations++;
              }
              return KeyEventResult.handled;
            },
            child: const SizedBox.expand(),
          ),
        ));
    await tester.pumpWidget(app(false));
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activations, 1);
    await tester.pumpWidget(app(true));
    await tester.pump();
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activations, 1);
    await tester.pumpWidget(app(false));
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('semantics hides background actions and announces status once',
      (tester) async {
    final semantics = tester.ensureSemantics();

    Widget app(bool loading) => TestApp(
            home: LoadingOverlay(
          isLoading: loading,
          message: 'Uploading',
          progress: 0.5,
          style: instant,
          child: Semantics(
              label: 'Submit payment',
              button: true,
              onTap: () {},
              child: const SizedBox.expand()),
        ));
    await tester.pumpWidget(app(true));
    expect(find.bySemanticsLabel('Submit payment'), findsNothing);
    final status = tester.getSemantics(find.bySemanticsLabel('Uploading'));
    expect(status.getSemanticsData().value, '50%');
    expect(
        // Flutter 3.27 predates flagsCollection.
        // ignore: deprecated_member_use
        status.getSemanticsData().hasFlag(SemanticsFlag.isLiveRegion),
        isTrue);
    await tester.pumpWidget(app(false));
    expect(find.bySemanticsLabel('Submit payment'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('localized fallback is available even during show delay',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(const TestApp(
        home: LoadingOverlay(
      isLoading: true,
      semanticsLabel: 'Chargement',
      style: LoadingOverlayStyle(showDelay: Duration(seconds: 1)),
      child: SizedBox.expand(),
    )));
    expect(find.bySemanticsLabel('Chargement'), findsOneWidget);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('non-modal overlay allows pointer, keyboard and semantics access',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final focus = FocusNode();

    addTearDown(focus.dispose);
    var taps = 0;
    await tester.pumpWidget(TestApp(
        home: LoadingOverlay(
      isLoading: true,
      blockInteraction: false,
      blockBack: false,
      style: instant,
      child: Focus(
          focusNode: focus,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child:
                Semantics(label: 'Background', child: const SizedBox.expand()),
          )),
    )));
    await tester.tapAt(const Offset(50, 50));
    expect(taps, 1);
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    expect(find.bySemanticsLabel('Background'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('custom content remains interactive and receives typed progress',
      (tester) async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    final task = controller.start(message: 'Export', progress: 0.25);
    await tester.pumpWidget(TestApp(
        home: LoadingOverlay.controlled(
      controller: controller,
      style: instant,
      overlayBuilder: (context, data) => GestureDetector(
        onTap: task.finish,
        child: Text('${data.message}: ${data.activeTasks} / ${data.progress}',
            key: const Key('cancel')),
      ),
      child: const SizedBox.expand(),
    )));
    expect(find.text('Export: 1 / 0.25'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancel')));
    await tester.pump();
    expect(controller.isLoading, isFalse);
  });

  testWidgets(
      'small regional overlay supports RTL, blur and large text without overflow',
      (tester) async {
    await tester.pumpWidget(TestApp(
        home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(3)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
            child: SizedBox(
                width: 170,
                height: 100,
                child: LoadingOverlay(
                  isLoading: true,
                  message: 'A long message that must fit a small region',
                  progress: 0.75,
                  style: const LoadingOverlayStyle(
                      blurSigma: 3, alignment: AlignmentDirectional.centerEnd),
                  child: const SizedBox.expand(),
                ))),
      ),
    )));
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(LoadingOverlay)), const Size(170, 100));
  });

  testWidgets('route cannot pop until loading and fade-out complete',
      (tester) async {
    final nav = GlobalKey<NavigatorState>();
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    await tester
        .pumpWidget(TestApp(navigatorKey: nav, home: const Text('Home')));
    nav.currentState!.push(PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => LoadingOverlay.controlled(
          controller: controller, child: const Text('Protected')),
      transitionDuration: Duration.zero,
    ));
    await tester.pumpAndSettle();
    controller.show();
    await finishFade(tester);
    await nav.currentState!.maybePop();
    await tester.pump();
    expect(find.text('Protected'), findsOneWidget);
    controller.hide();
    await tester.pump();
    await nav.currentState!.maybePop();
    await tester.pump();
    expect(find.text('Protected'), findsOneWidget);
    await finishFade(tester);
    await nav.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}
