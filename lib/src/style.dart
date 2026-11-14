import 'package:flutter/widgets.dart';

/// Immutable presentation settings shared by every loading control mode.
///
/// Delays are opt-in. The defaults preserve the immediate 300 ms fade of 0.x.
@immutable
class LoadingOverlayStyle {
  /// Creates a style. Timing changes apply to the next visibility cycle.
  const LoadingOverlayStyle({
    this.barrierColor = const Color(0x80000000),
    this.indicatorColor = const Color(0xFFFFFFFF),
    this.messageStyle = const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 16,
      decoration: TextDecoration.none,
    ),
    this.alignment = Alignment.center,
    this.padding = const EdgeInsets.all(24),
    this.blurSigma = 0,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration = const Duration(milliseconds: 300),
    this.showDelay = Duration.zero,
    this.minimumVisibleDuration = Duration.zero,
  }) : assert(blurSigma >= 0 && blurSigma < double.infinity);

  /// Backdrop color, including its alpha channel.
  final Color barrierColor;

  /// Color of the built-in progress ring.
  final Color indicatorColor;

  /// Text style for the default message and percentage.
  final TextStyle messageStyle;

  /// Position of the indicator or custom builder inside the overlay bounds.
  final AlignmentGeometry alignment;

  /// Space around the overlay content, resolved using the text direction.
  final EdgeInsetsGeometry padding;

  /// Backdrop blur radius. Zero avoids the cost of a BackdropFilter.
  final double blurSigma;

  /// Fade-in duration; bypassed when the system requests reduced motion.
  final Duration duration;

  /// Fade-out duration; bypassed when the system requests reduced motion.
  final Duration reverseDuration;

  /// Wait before showing visuals. Modal input blocking begins immediately.
  final Duration showDelay;

  /// Minimum time visuals remain mounted before fade-out starts.
  final Duration minimumVisibleDuration;
}

/// Supplies presentation defaults to descendant overlays and scopes.
///
/// A widget's explicit style replaces the inherited style in its entirety.
class LoadingOverlayTheme extends InheritedWidget {
  /// Creates an inherited loading overlay theme.
  const LoadingOverlayTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// Presentation defaults for descendants.
  final LoadingOverlayStyle data;

  /// Returns the closest style, or the package defaults.
  static LoadingOverlayStyle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LoadingOverlayTheme>()?.data ??
      const LoadingOverlayStyle();

  @override
  bool updateShouldNotify(LoadingOverlayTheme oldWidget) =>
      data != oldWidget.data;
}
