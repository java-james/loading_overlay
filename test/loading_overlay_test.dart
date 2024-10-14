import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_overlay/loading_overlay.dart';

void main() {
  group('Modal Progress HUD', () {
    Widget sut(isLoading) => MaterialApp(
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

    testWidgets('should not show progress indicator when not loading', (tester) async {
      const inAsyncCall = false;
      await tester.pumpWidget(sut(inAsyncCall));

      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

  });
}
