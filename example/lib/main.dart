import 'dart:async';

import 'package:loading_overlay/loading_overlay.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const MyApp());

const _accent = Color(0xFF007E72);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _global = LoadingOverlayController();
  bool _dark = false;

  @override
  void dispose() {
    _global.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'loading_overlay · A better wait',
    themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _accent),
      scaffoldBackgroundColor: const Color(0xFFF4F6F3),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accent,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    builder: (context, child) => LoadingOverlayScope(
      controller: _global,
      overlayBuilder: _loadingPanel,
      style: const LoadingOverlayStyle(blurSigma: 3),
      child: child!,
    ),
    home: ShowcasePage(onToggleTheme: () => setState(() => _dark = !_dark)),
  );
}

Widget _loadingPanel(BuildContext context, LoadingOverlayData data) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  // App-builder overlays sit above the route's Material and default text style.
  return DefaultTextStyle(
    style: theme.textTheme.bodyMedium!,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingOverlayIndicator(
            value: data.progress,
            color: colors.primary,
            size: 40,
          ),
          const SizedBox(height: 20),
          Text(
            data.message ?? 'Just a moment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.progress == null
                ? 'Your work is in good hands.'
                : '${(data.progress! * 100).round()}% complete',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    ),
  );
}

class ShowcasePage extends StatefulWidget {
  const ShowcasePage({super.key, required this.onToggleTheme});
  final VoidCallback onToggleTheme;

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> {
  final _loading = LoadingOverlayController();
  bool _running = false;
  bool _manual = false;
  Future<void>? _future;
  int _selected = 0;
  String _result = 'Ready when you are. Choose a scenario to try it.';

  static const _titles = [
    'Save changes',
    'Upload with progress',
    'Parallel requests',
    'Recover from an error',
    'Follow a Future',
    'Quick operation',
    'App-wide loading',
  ];
  static const _descriptions = [
    'Boolean state. One widget.',
    'A message and a real percentage.',
    'Each task owns its loading state.',
    'Cleanup happens even when work fails.',
    'Observe work you already started.',
    'No flash for a 40 ms operation.',
    'One scope, across your whole app.',
  ];
  static const _icons = [
    Icons.check_circle_outline,
    Icons.cloud_upload_outlined,
    Icons.layers_outlined,
    Icons.refresh,
    Icons.schedule,
    Icons.bolt_outlined,
    Icons.open_in_full,
  ];
  static const _style = LoadingOverlayStyle(
    barrierColor: Color(0x99182C30),
    blurSigma: 2,
    duration: Duration(milliseconds: 180),
    reverseDuration: Duration(milliseconds: 180),
    showDelay: Duration(milliseconds: 150),
    minimumVisibleDuration: Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    _loading.dispose();
    super.dispose();
  }

  Future<void> _run(int scenario) async {
    if (_running) return;
    setState(() {
      _selected = scenario;
      _running = true;
      _result = 'Working…';
    });
    try {
      switch (scenario) {
        case 0:
          setState(() => _manual = true);
          try {
            await Future<void>.delayed(const Duration(seconds: 2));
          } finally {
            if (mounted) setState(() => _manual = false);
          }
        case 1:
          final task = _loading.start(
            message: 'Uploading your files',
            progress: 0,
          );
          try {
            for (var step = 1; step <= 10; step++) {
              await Future<void>.delayed(const Duration(milliseconds: 180));
              task.update(message: 'Uploading your files', progress: step / 10);
            }
          } finally {
            task.finish();
          }
        case 2:
          await Future.wait([
            _loading.run(
              () => Future<void>.delayed(const Duration(seconds: 3)),
              message: 'Finishing the larger request',
            ),
            _loading.run(
              () => Future<void>.delayed(const Duration(milliseconds: 1300)),
              message: 'Two requests, one overlay',
            ),
          ]);
        case 3:
          await _loading.run<void>(() async {
            await Future<void>.delayed(const Duration(milliseconds: 1500));
            throw StateError('This is a simulated failure.');
          }, message: 'Testing error recovery');
        case 4:
          final future = Future<void>.delayed(const Duration(seconds: 2));
          setState(() {
            _future = future;
          });
          await future;
        case 5:
          await _loading.run(
            () => Future<void>.delayed(const Duration(milliseconds: 40)),
            message: 'That was quick',
          );
        case 6:
          await context.loadingOverlay.run(
            () => Future<void>.delayed(const Duration(seconds: 2)),
            message: 'Syncing your workspace',
          );
      }
      if (mounted) {
        setState(() => _result = 'Done. Everything is ready to use again.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _result = 'Error handled. The overlay cleaned up automatically.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _future = null;
        });
      }
    }
  }

  Widget _preview() {
    final colors = Theme.of(context).colorScheme;
    final dashboard = Container(
      padding: const EdgeInsets.all(28),
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE2F0E9),
                child: Icon(Icons.grid_view_rounded, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your workspace',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Icon(Icons.more_horiz, color: colors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'GOOD THINGS ARE TAKING SHAPE',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'A little progress,\nevery day.',
            style: TextStyle(
              fontSize: 32,
              height: 1.15,
              fontWeight: FontWeight.w600,
              letterSpacing: -1,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(child: _stat('24', 'Projects')),
              const SizedBox(width: 12),
              Expanded(child: _stat('86%', 'On track')),
            ],
          ),
          const SizedBox(height: 24),
          for (final title in [
            'Website refresh',
            'Product launch',
            'The next big idea',
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 14, color: colors.onSurface),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    Widget overlay;
    if (_selected == 0) {
      overlay = LoadingOverlay(
        isLoading: _manual,
        message: 'Saving your changes',
        style: _style,
        overlayBuilder: _loadingPanel,
        child: dashboard,
      );
    } else if (_selected == 4 && _future != null) {
      overlay = LoadingOverlay.withFuture(
        future: _future!,
        message: 'Following your Future',
        style: _style,
        overlayBuilder: _loadingPanel,
        child: dashboard,
      );
    } else {
      overlay = LoadingOverlay.controlled(
        controller: _loading,
        style: _style,
        overlayBuilder: _loadingPanel,
        child: dashboard,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'LIVE PLAYGROUND',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(borderRadius: BorderRadius.circular(24), child: overlay),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Text(
            _result,
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _stat(String value, String label) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < _titles.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: _running ? null : () => _run(index),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 17,
                ),
                alignment: Alignment.centerLeft,
                side: BorderSide(
                  color: _selected == index
                      ? colors.primary
                      : colors.outlineVariant,
                ),
                backgroundColor: _selected == index
                    ? colors.primaryContainer.withValues(alpha: 0.35)
                    : colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Icon(_icons[index], size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titles[index],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _descriptions[index],
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 17),
                ],
              ),
            ),
          ),
      ],
    );
    return LoadingOverlayBackGuard(
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.blur_circular,
                                color: _accent,
                                size: 30,
                              ),
                              const SizedBox(width: 10),
                              const Flexible(
                                child: Text(
                                  'loading_overlay',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '0.7.0',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Toggle theme',
                          onPressed: widget.onToggleTheme,
                          icon: const Icon(Icons.contrast),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    Text(
                      'Make waiting feel effortless.',
                      style: TextStyle(
                        fontSize: MediaQuery.sizeOf(context).width < 600
                            ? 36
                            : 52,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -2,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A small Flutter package for the moments between tap and done.',
                      style: TextStyle(
                        fontSize: 17,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final label in [
                          'Automatic cleanup',
                          'Concurrent tasks',
                          'Accessible by default',
                          'No extra dependencies',
                        ])
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.outlineVariant),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    LayoutBuilder(
                      builder: (context, constraints) =>
                          constraints.maxWidth >= 760
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: controls),
                                const SizedBox(width: 48),
                                Expanded(flex: 6, child: _preview()),
                              ],
                            )
                          : Column(
                              children: [
                                _preview(),
                                const SizedBox(height: 28),
                                controls,
                              ],
                            ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Flutter 3.27+  /  Android · iOS · Web · macOS · Windows · Linux',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
