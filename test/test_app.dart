import 'package:flutter/widgets.dart';

/// Widget-only harness keeps the core testable on both sides of the Material split.
class TestApp extends StatelessWidget {
  const TestApp(
      {super.key, required this.home, this.builder, this.navigatorKey});

  final Widget home;
  final TransitionBuilder? builder;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) => WidgetsApp(
        color: const Color(0xFFFFFFFF),
        textStyle: const TextStyle(color: Color(0xFF000000), fontSize: 16),
        navigatorKey: navigatorKey,
        builder: builder,
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, __) => builder(context),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        home: home,
      );
}
