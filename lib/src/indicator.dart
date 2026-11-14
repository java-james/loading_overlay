import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A design-system-independent progress ring with no third-party dependencies.
///
/// Set [value] to a fraction for determinate progress. A null value rotates the
/// ring unless reduced motion is requested. Overlays supply their own semantics;
/// when used alone, wrap this widget in a labeled Semantics widget.
class LoadingOverlayIndicator extends StatefulWidget {
  /// Creates a progress ring.
  const LoadingOverlayIndicator({
    super.key,
    this.value,
    this.color = const Color(0xFFFFFFFF),
    this.size = 36,
    this.strokeWidth = 3,
  })  : assert(value == null || (value >= 0 && value <= 1)),
        assert(size > 0 && size < double.infinity),
        assert(strokeWidth > 0 && strokeWidth <= size);

  /// Progress fraction, or null for indeterminate progress.
  final double? value;

  /// Foreground color. The track uses a translucent version of this color.
  final Color color;

  /// Preferred width and height in logical pixels.
  final double size;

  /// Width of the progress stroke.
  final double strokeWidth;

  @override
  State<LoadingOverlayIndicator> createState() =>
      _LoadingOverlayIndicatorState();
}

class _LoadingOverlayIndicatorState extends State<LoadingOverlayIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(LoadingOverlayIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final animate = widget.value == null &&
        !MediaQuery.disableAnimationsOf(context) &&
        // Keep compatibility with Flutter 3.27, before TickerMode.valuesOf.
        // ignore: deprecated_member_use
        TickerMode.of(context);
    if (animate && !_rotation.isAnimating) {
      _rotation.repeat();
    } else if (!animate) {
      _rotation.stop();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              rotation: _rotation,
              value: widget.value,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.rotation,
    required this.value,
    required this.color,
    required this.strokeWidth,
  }) : super(repaint: rotation);

  final Animation<double> rotation;
  final double? value;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = math.max(0.0, (size.shortestSide - strokeWidth) / 2);
    final bounds = Rect.fromCircle(center: rect.center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color.withAlpha((color.a * 255 * 0.18).round());
    canvas.drawCircle(rect.center, radius, paint);
    paint.color = color;
    final fraction = value ?? 0.72;
    if (fraction == 0) return;
    if (fraction == 1) {
      canvas.drawCircle(rect.center, radius, paint);
    } else {
      canvas.drawArc(
        bounds,
        -math.pi / 2 + (value == null ? rotation.value * 2 * math.pi : 0),
        fraction * 2 * math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      value != oldDelegate.value ||
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      rotation != oldDelegate.rotation;
}
