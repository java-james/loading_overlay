import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_overlay/loading_overlay.dart';

import 'test_app.dart';

void main() {
  testWidgets('nested scopes are independent and lookups return nearest',
      (tester) async {
    late LoadingOverlayController outer;
    late LoadingOverlayController inner;
    await tester.pumpWidget(
        TestApp(home: LoadingOverlayScope(child: Builder(builder: (context) {
      outer = context.loadingOverlay;
      return LoadingOverlayScope(child: Builder(builder: (context) {
        inner = LoadingOverlayScope.of(context);
        return const SizedBox.expand();
      }));
    }))));
    expect(inner, isNot(same(outer)));
    inner.show(message: 'Inner');
    await tester.pump();
    expect(find.text('Inner'), findsOneWidget);
    expect(outer.isLoading, isFalse);
    inner.hide();
    outer.show(message: 'Outer');
    await tester.pump();
    expect(find.text('Outer'), findsOneWidget);
    expect(inner.isLoading, isFalse);
  });

  testWidgets('owned scope controller disposes without disrupting pending work',
      (tester) async {
    late LoadingOverlayController controller;
    await tester.pumpWidget(
        TestApp(home: LoadingOverlayScope(child: Builder(builder: (context) {
      controller = context.loadingOverlay;
      return const SizedBox.expand();
    }))));
    final completer = Completer<int>();
    final result = controller.run(() => completer.future);
    await tester.pumpWidget(const SizedBox());
    expect(controller.start, throwsStateError);
    completer.complete(42);
    expect(await result, 42);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'scope never disposes external controller and can replace ownership',
      (tester) async {
    final external = LoadingOverlayController();
    addTearDown(external.dispose);
    late LoadingOverlayController current;
    Widget app(LoadingOverlayController? controller) => TestApp(
            home: LoadingOverlayScope(
          controller: controller,
          child: Builder(builder: (context) {
            current = context.loadingOverlay;
            return const SizedBox.expand();
          }),
        ));
    await tester.pumpWidget(app(null));
    final first = current;
    await tester.pumpWidget(app(external));
    expect(current, same(external));
    expect(first.start, throwsStateError);
    await tester.pumpWidget(app(null));
    expect(current, isNot(same(external)));
    external.show();
    expect(external.isLoading, isTrue);
    await tester.pumpWidget(const SizedBox());
    external.hide();
    expect(current.start, throwsStateError);
  });

  testWidgets('missing scope gives actionable error and maybeOf returns null',
      (tester) async {
    await tester.pumpWidget(TestApp(home: Builder(builder: (context) {
      expect(LoadingOverlayScope.maybeOf(context), isNull);
      expect(
          () => context.loadingOverlay,
          throwsA(isA<FlutterError>().having(
            (error) => error.message,
            'message',
            contains('BuildContext below that scope'),
          )));
      return const SizedBox.expand();
    })));
  });

  testWidgets('starting work in a descendant initState is build-safe',
      (tester) async {
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(TestApp(
        home: LoadingOverlayScope(
      controller: controller,
      child: StartOnMount(controller: controller),
    )));
    await tester.pump();
    expect(find.text('Started in initState'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app builder scope covers routes and route guard blocks maybePop',
      (tester) async {
    final nav = GlobalKey<NavigatorState>();
    final controller = LoadingOverlayController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(TestApp(
      navigatorKey: nav,
      builder: (_, child) =>
          LoadingOverlayScope(controller: controller, child: child!),
      home: const Text('Home'),
    ));
    nav.currentState!.push(PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) =>
          const LoadingOverlayBackGuard(child: Text('Second route')),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ));
    await tester.pumpAndSettle();
    controller.show();
    await tester.pump();
    await nav.currentState!.maybePop();
    await tester.pump();
    expect(find.text('Second route'), findsOneWidget);
    controller.hide();
    await tester.pump();
    await nav.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}

class StartOnMount extends StatefulWidget {
  const StartOnMount({super.key, required this.controller});
  final LoadingOverlayController controller;
  @override
  State<StartOnMount> createState() => _StartOnMountState();
}

class _StartOnMountState extends State<StartOnMount> {
  @override
  void initState() {
    super.initState();
    widget.controller.show(message: 'Started in initState');
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
