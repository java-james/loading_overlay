import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_overlay/loading_overlay.dart';

import 'test_app.dart';

void main() {
  testWidgets('a delay retains its cycle minimum when style changes',
      (tester) async {
    var loading = true;
    var style = const LoadingOverlayStyle(
      duration: Duration.zero,
      reverseDuration: Duration.zero,
      showDelay: Duration(milliseconds: 200),
      minimumVisibleDuration: Duration(milliseconds: 500),
    );
    late StateSetter rebuild;
    await tester.pumpWidget(TestApp(
      home: StatefulBuilder(builder: (context, setState) {
        rebuild = setState;
        return LoadingOverlay(
          isLoading: loading,
          style: style,
          child: const SizedBox.expand(),
        );
      }),
    ));
    await tester.pump(const Duration(milliseconds: 50));
    rebuild(() {
      style = const LoadingOverlayStyle(
        duration: Duration.zero,
        reverseDuration: Duration.zero,
      );
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(LoadingOverlayIndicator), findsOneWidget);
    rebuild(() => loading = false);
    await tester.pump();
    expect(find.byType(LoadingOverlayIndicator), findsOneWidget,
        reason: 'Current cycle must retain its 500ms minimum visibility.');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LoadingOverlayIndicator), findsNothing);

    rebuild(() => loading = true);
    await tester.pump();
    expect(find.byType(LoadingOverlayIndicator), findsOneWidget,
        reason: 'The next cycle uses the new zero show delay.');
    rebuild(() => loading = false);
    await tester.pump();
    expect(find.byType(LoadingOverlayIndicator), findsNothing,
        reason: 'The next cycle uses the new zero minimum duration.');
  });
}
