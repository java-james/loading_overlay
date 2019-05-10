import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_overlay/loading_overlay.dart';

void main() {
  group('Modal Progress HUD', () {
    Widget sut(bool isLoading, Offset offset) {
      return MaterialApp(
        home: new LoadingOverlay(
          isLoading: isLoading,
          child: Text(''),
        ),
      );
    }

    testWidgets('should show progress indicator when loading',
        (tester) async {
      final inAsyncCall = true;
      await tester.pumpWidget(sut(inAsyncCall, null));

      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should not show progress indicator when not loading',
        (tester) async {
      final inAsyncCall = false;
      await tester.pumpWidget(sut(inAsyncCall, null));

      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should allow positioning of progress indicator',
        (tester) async {
      final isLoading = true;
      final offset = Offset(0.1, 0.1);
      await tester.pumpWidget(sut(isLoading, offset));

      expect(find.byType(Positioned), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
