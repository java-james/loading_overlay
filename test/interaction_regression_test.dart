import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_overlay/loading_overlay.dart';

import 'test_app.dart';

const _instant = LoadingOverlayStyle(
  duration: Duration.zero,
  reverseDuration: Duration.zero,
);

void main() {
  testWidgets('route guard permits work started by a descendant initState',
      (tester) async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(TestApp(
      home: LoadingOverlayScope(
        controller: controller,
        style: _instant,
        child: LoadingOverlayBackGuard(
          child: _StartOnMount(controller: controller),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Started on mount'), findsOneWidget);
  });

  testWidgets('custom status text is announced once and cancel is usable',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final controller = LoadingOverlayController();
      addTearDown(controller.dispose);
      final task = controller.start(message: 'Uploading', progress: 0.64);
      await tester.pumpWidget(TestApp(
        home: LoadingOverlay.controlled(
          controller: controller,
          style: _instant,
          overlayBuilder: (_, data) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data.message!),
              Semantics(
                container: true,
                button: true,
                onTap: task.finish,
                child: GestureDetector(
                  excludeFromSemantics: true,
                  onTap: task.finish,
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
          child: const SizedBox.expand(),
        ),
      ));
      final status = tester.getSemantics(find.text('Uploading'));
      expect(status.getSemanticsData().label, 'Uploading');
      expect(find.bySemanticsLabel('Cancel'), findsOneWidget);
      final cancel = tester
          .getSemantics(find.bySemanticsLabel('Cancel'))
          .getSemanticsData();
      expect(cancel.hasAction(SemanticsAction.tap), isTrue);
      // Flutter 3.27 predates flagsCollection.
      // ignore: deprecated_member_use
      expect(cancel.hasFlag(SemanticsFlag.isButton), isTrue);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(controller.isLoading, isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('pointer begun before loading cannot activate background',
      (tester) async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    var taps = 0;
    await tester.pumpWidget(TestApp(
      home: LoadingOverlay.controlled(
        controller: controller,
        style: _instant,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox.expand(),
        ),
      ),
    ));
    final pointer = await tester.startGesture(const Offset(100, 100));
    controller.show();
    await tester.pump();
    await pointer.up();
    expect(taps, 0);
  });

  testWidgets('custom controls receive keyboard focus and activation',
      (tester) async {
    final background = FocusNode();
    final cancel = FocusNode();
    final controller = LoadingOverlayController();
    addTearDown(background.dispose);
    addTearDown(cancel.dispose);
    addTearDown(controller.dispose);
    var backgroundActivations = 0;
    await tester.pumpWidget(TestApp(
      home: LoadingOverlay.controlled(
        controller: controller,
        style: _instant,
        overlayBuilder: (_, __) => Focus(
          autofocus: true,
          focusNode: cancel,
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.enter) {
              controller.hide();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: const Text('Cancel'),
        ),
        child: Focus(
          focusNode: background,
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent) backgroundActivations++;
            return KeyEventResult.handled;
          },
          child: const SizedBox.expand(),
        ),
      ),
    ));
    background.requestFocus();
    await tester.pump();
    controller.show();
    await tester.pump();
    await tester.pump();
    expect(background.hasFocus, isFalse);
    expect(cancel.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(backgroundActivations, 0);
    expect(controller.isLoading, isFalse);
  });

  testWidgets('a regional overlay preserves outside accessibility',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      var outsideTaps = 0;
      await tester.pumpWidget(TestApp(
        home: Row(children: [
          Expanded(
            child: Semantics(
              button: true,
              onTap: () => outsideTaps++,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => outsideTaps++,
                child: const Center(child: Text('Outside action')),
              ),
            ),
          ),
          const Expanded(
            child: LoadingOverlay(
              isLoading: true,
              style: _instant,
              message: 'Regional loading',
              child: Center(child: Text('Inside action')),
            ),
          ),
        ]),
      ));
      await tester.tap(find.text('Outside action'));
      expect(outsideTaps, 1);
      expect(find.bySemanticsLabel('Outside action'), findsOneWidget);
      expect(find.bySemanticsLabel('Inside action'), findsNothing);
      expect(find.bySemanticsLabel('Regional loading'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('pointer triggering loading on down cannot complete a tap',
      (tester) async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    var taps = 0;
    await tester.pumpWidget(TestApp(
      home: LoadingOverlay.controlled(
        controller: controller,
        style: _instant,
        child: Listener(
          onPointerDown: (_) => controller.show(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ));
    final pointer = await tester.startGesture(const Offset(100, 100));
    await tester.pump();
    await pointer.up();
    expect(taps, 0);
  });

  testWidgets('default overflow content can be scrolled while modal',
      (tester) async {
    await tester.pumpWidget(const TestApp(
      home: Center(
        child: SizedBox(
          width: 200,
          height: 120,
          child: LoadingOverlay(
            isLoading: true,
            style: _instant,
            message: 'Preparing\nUploading\nSaving\nFinishing',
            progress: 0.75,
            child: SizedBox.expand(),
          ),
        ),
      ),
    ));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading cancels an existing trackpad pan sequence',
      (tester) async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    var pans = 0;
    await tester.pumpWidget(TestApp(
      home: LoadingOverlay.controlled(
        controller: controller,
        style: _instant,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (_) => pans++,
          child: const SizedBox.expand(),
        ),
      ),
    ));
    final pointer =
        await tester.createGesture(kind: PointerDeviceKind.trackpad);
    await pointer.panZoomStart(const Offset(100, 100));
    await pointer.panZoomUpdate(const Offset(100, 100),
        pan: const Offset(0, 30));
    await pointer.panZoomUpdate(const Offset(100, 100),
        pan: const Offset(0, 50));
    expect(pans, greaterThan(0));
    final pansBeforeLoading = pans;
    controller.show();
    await tester.pump();
    await pointer.panZoomUpdate(const Offset(100, 100),
        pan: const Offset(0, 90));
    await pointer.panZoomEnd();
    expect(pans, pansBeforeLoading);
  });

  testWidgets('non-modal loading preserves an existing pointer sequence',
      (tester) async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    var taps = 0;
    await tester.pumpWidget(TestApp(
      home: LoadingOverlay.controlled(
        controller: controller,
        style: _instant,
        blockInteraction: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox.expand(),
        ),
      ),
    ));
    final pointer = await tester.startGesture(const Offset(100, 100));
    controller.show();
    await tester.pump();
    await pointer.up();
    expect(taps, 1);
  });

  testWidgets('becoming modal during loading cancels existing pointer',
      (tester) async {
    var taps = 0;
    Widget app(bool block) => TestApp(
          home: LoadingOverlay(
            isLoading: true,
            blockInteraction: block,
            style: _instant,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox.expand(),
            ),
          ),
        );
    await tester.pumpWidget(app(false));
    final pointer = await tester.startGesture(const Offset(100, 100));
    await tester.pumpWidget(app(true));
    await pointer.up();
    expect(taps, 0);
  });

  testWidgets('show delay cancels existing pointer immediately',
      (tester) async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    var taps = 0;
    await tester.pumpWidget(TestApp(
      home: LoadingOverlay.controlled(
        controller: controller,
        style: const LoadingOverlayStyle(showDelay: Duration(seconds: 1)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox.expand(),
        ),
      ),
    ));
    final pointer = await tester.startGesture(const Offset(100, 100));
    controller.show();
    await tester.pump();
    await pointer.up();
    expect(taps, 0);
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
    controller.hide();
    await tester.pump();
  });

  testWidgets('default status updates preserve single announcement',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final controller = LoadingOverlayController();
      addTearDown(controller.dispose);
      final task = controller.start(message: 'Uploading', progress: 0.25);
      await tester.pumpWidget(TestApp(
        home: LoadingOverlay.controlled(
          controller: controller,
          style: _instant,
          child: const SizedBox.expand(),
        ),
      ));
      expect(find.bySemanticsLabel('Uploading'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Uploading'))
            .getSemanticsData()
            .value,
        '25%',
      );
      task.update(message: 'Finishing', progress: 1);
      await tester.pump();
      expect(find.bySemanticsLabel('Uploading'), findsNothing);
      final status = tester
          .getSemantics(find.bySemanticsLabel('Finishing'))
          .getSemanticsData();
      expect(status.value, '100%');
      // Flutter 3.27 predates flagsCollection.
      // ignore: deprecated_member_use
      expect(status.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('app builder scope hides route semantics through fade',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final controller = LoadingOverlayController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(TestApp(
        builder: (_, child) => LoadingOverlayScope(
          controller: controller,
          style: const LoadingOverlayStyle(
            showDelay: Duration(milliseconds: 100),
            duration: Duration.zero,
            reverseDuration: Duration(milliseconds: 100),
          ),
          child: child!,
        ),
        home: Semantics(
          button: true,
          onTap: () {},
          child: const Center(child: Text('Page action')),
        ),
      ));
      expect(find.bySemanticsLabel('Page action'), findsOneWidget);
      controller.show(message: 'Saving');
      await tester.pump();
      expect(_overlaySemanticsLabels(tester), isNot(contains('Page action')));
      expect(find.bySemanticsLabel('Saving'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      controller.hide();
      await tester.pump();
      expect(_overlaySemanticsLabels(tester), isNot(contains('Page action')));
      expect(find.bySemanticsLabel('Saving'), findsOneWidget);
      // AnimationController completes only after its exact duration boundary.
      await tester.pump(const Duration(milliseconds: 101));
      expect(_overlaySemanticsLabels(tester), contains('Page action'));
      expect(find.bySemanticsLabel('Saving'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('BackGuard switches explicit controllers without leaks',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    final first = LoadingOverlayController();
    final second = LoadingOverlayController();
    final selected = ValueNotifier(first);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    addTearDown(selected.dispose);
    await tester.pumpWidget(TestApp(
      navigatorKey: navigator,
      home: const Center(child: Text('Home')),
    ));
    navigator.currentState!.push(PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => ValueListenableBuilder(
        valueListenable: selected,
        builder: (_, controller, __) => LoadingOverlayBackGuard(
          controller: controller,
          child: const Center(child: Text('Guarded page')),
        ),
      ),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ));
    await tester.pumpAndSettle();
    first.show();
    await tester.pump();
    await navigator.currentState!.maybePop();
    await tester.pump();
    expect(find.text('Guarded page'), findsOneWidget);
    selected.value = second;
    await tester.pump();
    first.hide();
    first.show();
    await tester.pump();
    await navigator.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Guarded page'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    second.show();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Iterable<String> _overlaySemanticsLabels(WidgetTester tester) =>
    _semanticsNodes(tester.getSemantics(find.byType(LoadingOverlay)))
        .map((node) => node.label);

Iterable<SemanticsNode> _semanticsNodes(SemanticsNode root) sync* {
  yield root;
  final children = <SemanticsNode>[];
  root.visitChildren((child) {
    children.add(child);
    return true;
  });
  for (final child in children) {
    yield* _semanticsNodes(child);
  }
}

class _StartOnMount extends StatefulWidget {
  const _StartOnMount({required this.controller});

  final LoadingOverlayController controller;

  @override
  State<_StartOnMount> createState() => _StartOnMountState();
}

class _StartOnMountState extends State<_StartOnMount> {
  @override
  void initState() {
    super.initState();
    widget.controller.show(message: 'Started on mount');
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
