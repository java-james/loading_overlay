// Repository-only artwork renderer. Each scene uses the actual library widgets.
// Run from example/:
// flutter test tool/capture_preview.dart --dart-define=FLUTTER_SDK=/path/to/flutter
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:material_ui/material_ui.dart';

const _ink = Color(0xFF173B36);
const _muted = Color(0xFF657B73);
const _teal = Color(0xFF008577);
const _paper = Color(0xFFF3F6F1);
const _line = Color(0xFFDCE6DF);
const _navy = Color(0xFF132B2D);

Text _text(
  String value,
  double size, {
  Color color = _ink,
  FontWeight weight = FontWeight.w400,
  double? height,
  double? spacing,
}) => Text(
  value,
  style: TextStyle(
    color: color,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: spacing,
  ),
);

Widget _frame(Widget child, {Color color = Colors.white}) => DecoratedBox(
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(26),
    boxShadow: const [
      BoxShadow(
        color: Color(0x140E3829),
        blurRadius: 28,
        offset: Offset(0, 12),
      ),
    ],
  ),
  child: ClipRRect(borderRadius: BorderRadius.circular(26), child: child),
);

Widget _file(String name, String detail, IconData icon, {bool dark = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 44,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF284646) : const Color(0xFFEEF4EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: dark ? const Color(0xFFB5D6C9) : _teal,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _text(
                  name,
                  16,
                  color: dark ? const Color(0xFFE4EEE8) : _ink,
                  weight: FontWeight.w500,
                ),
                const SizedBox(height: 4),
                _text(
                  detail,
                  12,
                  color: dark ? const Color(0xFF94AFA7) : _muted,
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_horiz,
            color: dark ? const Color(0xFF94AFA7) : _muted,
            size: 18,
          ),
        ],
      ),
    );

Widget _workspace({bool dark = false, bool compact = false}) => Container(
  color: dark ? _navy : Colors.white,
  padding: EdgeInsets.all(compact ? 22 : 28),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(
            Icons.folder_open_rounded,
            color: dark ? const Color(0xFF9DDAC6) : _teal,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _text(
              'Workspace',
              19,
              color: dark ? Colors.white : _ink,
              weight: FontWeight.w600,
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF365850) : const Color(0xFFE7EEE3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: dark ? const Color(0xFFBFE4D6) : _teal,
              size: 18,
            ),
          ),
        ],
      ),
      if (!compact) ...[
        const SizedBox(height: 24),
        _text(
          'Project files',
          30,
          color: dark ? Colors.white : _ink,
          weight: FontWeight.w600,
          spacing: -0.6,
        ),
        const SizedBox(height: 7),
        _text(
          'Everything you need, in one place.',
          14,
          color: dark ? const Color(0xFF94AFA7) : _muted,
        ),
        const SizedBox(height: 16),
      ] else
        const SizedBox(height: 24),
      _file(
        'Brand guidelines.pdf',
        'Updated just now · 2.4 MB',
        Icons.description_outlined,
        dark: dark,
      ),
      _file(
        'Campaign assets.zip',
        '12 files · 18.6 MB',
        Icons.inventory_2_outlined,
        dark: dark,
      ),
      const Spacer(),
      Container(
        height: 44,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF367C6A) : _teal,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: _text(
          'Upload files',
          15,
          color: Colors.white,
          weight: FontWeight.w600,
        ),
      ),
    ],
  ),
);

Widget _progressCard(
  BuildContext context,
  LoadingOverlayData data, {
  bool dark = false,
}) => Container(
  width: dark ? 238 : 280,
  padding: EdgeInsets.symmetric(horizontal: 22, vertical: dark ? 26 : 30),
  decoration: BoxDecoration(
    color: dark ? const Color(0xFF1D3737) : const Color(0xFFFBFEFA),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: dark ? const Color(0xFF46615A) : Colors.white),
    boxShadow: const [
      BoxShadow(color: Color(0x16000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
  ),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      LoadingOverlayIndicator(
        value: data.progress,
        color: dark ? const Color(0xFF9DE3CC) : _teal,
        size: dark ? 48 : 56,
        strokeWidth: 4,
      ),
      const SizedBox(height: 22),
      _text(
        data.message!,
        dark ? 17 : 19,
        color: dark ? Colors.white : _ink,
        weight: FontWeight.w600,
      ),
      const SizedBox(height: 8),
      _text(
        '${(data.progress! * 100).round()}% complete',
        15,
        color: dark ? const Color(0xFFB6D4C8) : _muted,
      ),
    ],
  ),
);

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _paper,
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LoadingOverlayIndicator(
                value: 0.78,
                color: _teal,
                size: 26,
                strokeWidth: 3,
              ),
              const SizedBox(width: 12),
              _text(
                'loading_overlay',
                23,
                weight: FontWeight.w600,
                spacing: -0.5,
              ),
              const Spacer(),
              _text(
                'BUILT FOR FLUTTER',
                13,
                color: _muted,
                weight: FontWeight.w600,
                spacing: 1.5,
              ),
            ],
          ),
          const SizedBox(height: 36),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 10,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _text(
                        'Loading,\nhandled.',
                        76,
                        weight: FontWeight.w600,
                        height: 0.98,
                        spacing: -3,
                      ),
                      const SizedBox(height: 24),
                      _text(
                        'Clear feedback for the moments\nbetween tap and done.',
                        23,
                        color: _muted,
                        height: 1.4,
                      ),
                      const SizedBox(height: 32),
                      for (final label in [
                        'Automatic async cleanup',
                        'Safe concurrent tasks',
                        'Accessible by default',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 23,
                                color: _teal,
                              ),
                              const SizedBox(width: 12),
                              _text(label, 20, weight: FontWeight.w500),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 44),
                Expanded(
                  flex: 11,
                  child: SizedBox(
                    height: 474,
                    child: _frame(
                      LoadingOverlay(
                        isLoading: true,
                        message: 'Uploading your files',
                        progress: 0.64,
                        style: const LoadingOverlayStyle(
                          barrierColor: Color(0x701A3E36),
                          blurSigma: 2,
                          padding: EdgeInsets.all(20),
                        ),
                        overlayBuilder: _progressCard,
                        child: _workspace(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _text(
                'One small package. No extra runtime dependencies.',
                16,
                color: _muted,
              ),
              const Spacer(),
              _text('Android · iOS · Web · Desktop', 15, color: _muted),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _profile() => Container(
  padding: const EdgeInsets.all(24),
  color: Colors.white,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _text('Edit profile', 24, weight: FontWeight.w600),
      const SizedBox(height: 24),
      for (final field in [
        ('Display name', 'Alex Taylor'),
        ('Email', 'alex@example.com'),
      ]) ...[
        _text(field.$1, 13, color: _muted),
        const SizedBox(height: 8),
        Container(
          height: 44,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _text(field.$2, 15),
        ),
        const SizedBox(height: 20),
      ],
      const Spacer(),
      Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _teal,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _text(
          'Save changes',
          15,
          color: Colors.white,
          weight: FontWeight.w600,
        ),
      ),
    ],
  ),
);

Widget _section() => Container(
  padding: const EdgeInsets.all(22),
  color: Colors.white,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _text('Project overview', 23, weight: FontWeight.w600),
      const SizedBox(height: 8),
      _text('The rest of your page stays available.', 13, color: _muted),
      const SizedBox(height: 24),
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 176,
          child: LoadingOverlay(
            isLoading: true,
            message: 'Refreshing files…',
            style: const LoadingOverlayStyle(
              barrierColor: Color(0xE6E6F2E9),
              indicatorColor: _teal,
              messageStyle: TextStyle(
                fontSize: 16,
                color: _ink,
                decoration: TextDecoration.none,
              ),
              padding: EdgeInsets.all(12),
            ),
            child: Container(
              color: const Color(0xFFF7F9F5),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _file(
                    'Project brief.pdf',
                    'Today · 1.2 MB',
                    Icons.description_outlined,
                  ),
                  _file(
                    'Moodboard.zip',
                    'Today · 8.4 MB',
                    Icons.inventory_2_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const Spacer(),
      Row(
        children: [
          _text('View activity', 15, color: _teal, weight: FontWeight.w600),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, color: _teal, size: 18),
        ],
      ),
    ],
  ),
);

class _StylesArtwork extends StatelessWidget {
  const _StylesArtwork();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _paper,
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text(
            'One overlay. Your interface.',
            43,
            weight: FontWeight.w600,
            spacing: -1.3,
          ),
          const SizedBox(height: 12),
          _text(
            'Use the defaults, bring your design, or cover just one section.',
            20,
            color: _muted,
          ),
          const SizedBox(height: 38),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _scene(
                  'DEFAULT',
                  'Start simple.',
                  LoadingOverlay(
                    isLoading: true,
                    message: 'Saving changes…',
                    child: _profile(),
                  ),
                ),
                const SizedBox(width: 24),
                _scene(
                  'CUSTOM',
                  'Make it yours.',
                  LoadingOverlay(
                    isLoading: true,
                    progress: 0.72,
                    message: 'Syncing workspace',
                    style: const LoadingOverlayStyle(
                      barrierColor: Color(0x80101D1E),
                      blurSigma: 2,
                      padding: EdgeInsets.all(16),
                    ),
                    overlayBuilder: (context, data) =>
                        _progressCard(context, data, dark: true),
                    child: _workspace(dark: true, compact: true),
                  ),
                ),
                const SizedBox(width: 24),
                _scene('SCOPED', 'Cover one section.', _section()),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _scene(String label, String title, Widget child) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _text(label, 12, color: _teal, weight: FontWeight.w600, spacing: 1.5),
        const SizedBox(height: 8),
        _text(title, 25, weight: FontWeight.w500, spacing: -0.5),
        const SizedBox(height: 20),
        Expanded(child: _frame(child)),
      ],
    ),
  );
}

void main() {
  for (final artwork in [
    ('loading-overlay', const Size(1200, 720), const _HeroArtwork()),
    ('overlay-styles', const Size(1200, 650), const _StylesArtwork()),
  ]) {
    testWidgets('render ${artwork.$1}', (tester) async {
      const configuredSdk = String.fromEnvironment('FLUTTER_SDK');
      final sdk = configuredSdk.isNotEmpty
          ? configuredSdk
          : Platform.environment['FLUTTER_ROOT'];
      if (sdk == null) {
        throw StateError('Pass --dart-define=FLUTTER_SDK=/path/to/flutter');
      }
      await tester.runAsync(() async {
        final fonts = FontLoader('Roboto');
        for (final face in ['Regular', 'Medium', 'Bold']) {
          fonts.addFont(
            File('$sdk/bin/cache/artifacts/material_fonts/Roboto-$face.ttf')
                .readAsBytes()
                .then(ByteData.sublistView),
          );
        }
        await fonts.load();
        final icons = FontLoader('MaterialIcons');
        icons.addFont(
          File(
            '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        );
        await icons.load();
      });
      tester.view.physicalSize = artwork.$2;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'Roboto',
              colorScheme: ColorScheme.fromSeed(seedColor: _teal),
            ),
            home: Scaffold(body: artwork.$3),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // Layout failures must stop artifact generation, not become marketing images.
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        final file = File('../doc/images/${artwork.$1}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    });
  }
}
