import 'package:example/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('login blocks duplicate taps and restores the form', (
    tester,
  ) async {
    var signIns = 0;
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(onSignIn: () => signIns++)),
    );
    await tester.enterText(find.byType(TextField).first, 'james');
    await tester.enterText(find.byType(TextField).last, 'password');

    final loginPosition = tester.getCenter(find.text('Login'));
    await tester.tapAt(loginPosition);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tapAt(loginPosition);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(signIns, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'james',
    );

    await tester.tapAt(loginPosition);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(signIns, 2);
  });

  testWidgets('leaving the page during login does not update disposed state', (
    tester,
  ) async {
    var signIns = 0;
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(onSignIn: () => signIns++)),
    );
    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));

    expect(signIns, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login ignores repeated taps before the overlay is drawn', (
    tester,
  ) async {
    var signIns = 0;
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(onSignIn: () => signIns++)),
    );

    final loginPosition = tester.getCenter(find.text('Login'));
    await tester.tapAt(loginPosition);
    await tester.tapAt(loginPosition);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(signIns, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('login ignores repeated keyboard activation while loading', (
    tester,
  ) async {
    var signIns = 0;
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(onSignIn: () => signIns++)),
    );

    Focus.of(tester.element(find.text('Login'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(signIns, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
