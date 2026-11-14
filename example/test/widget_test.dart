import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
  }

  for (final title in [
    'Save changes',
    'Upload with progress',
    'Parallel requests',
    'Recover from an error',
    'Follow a Future',
    'App-wide loading',
  ]) {
    testWidgets('$title completes and restores the playground', (tester) async {
      await open(tester);
      await tester.tap(find.text(title));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 151));
      expect(find.byType(LoadingOverlayIndicator), findsOneWidget);
      if (title == 'App-wide loading') {
        // App builders sit above route-level Material/DefaultTextStyle widgets.
        // Verify the rendered text does not inherit WidgetsApp's yellow lines.
        for (final text in [
          'Syncing your workspace',
          'Your work is in good hands.',
        ]) {
          final rendered = tester.widget<RichText>(
            find.descendant(
              of: find.text(text),
              matching: find.byType(RichText),
            ),
          );
          expect(
            rendered.text.style?.decoration ?? TextDecoration.none,
            TextDecoration.none,
          );
        }
      }
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pumpAndSettle();
      expect(find.byType(LoadingOverlayIndicator), findsNothing);
      expect(
        find.text(
          title == 'Recover from an error'
              ? 'Error handled. The overlay cleaned up automatically.'
              : 'Done. Everything is ready to use again.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('quick operation never flashes and theme can change', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Quick operation'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(LoadingOverlayIndicator), findsNothing);
    await tester.tap(find.byTooltip('Toggle theme'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile layout and large text remain usable', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const MyApp());
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.text('Make waiting feel effortless.')),
      ).scale(10),
      20,
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Save changes'), 300);
    await tester.tap(find.text('Save changes'));
    await tester.pump(const Duration(milliseconds: 151));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
