import 'package:flutter/material.dart';

/// Our custom fork of https://pub.dev/packages/modal_progress_hud adding a fading effect
///
/// wrapper around any widget that makes an async call to show a modal progress
/// indicator while the async call is in progress.
///
/// The progress indicator can be turned on or off using [isLoading]
///
/// The progress indicator defaults to a [CircularProgressIndicator] but can be
/// any kind of widget
///
/// The color of the modal barrier can be set using [color]
///
/// The opacity of the modal barrier can be set using color.withOpacity(0.5)
///
/// HUD=Heads Up Display
///
class LoadingOverlay extends StatefulWidget {
  final bool isLoading;
  final Color? color;
  final Widget progressIndicator;
  final Widget child;
  // When provided via the withFuture constructor, the overlay will remain
  // visible until this Future completes (successfully or with error).
  final Future<void>? _future;
  // Internal flag to know if visibility is managed by a Future.
  final bool _managedByFuture;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.progressIndicator = const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    ),
    this.color,
  })  : _future = null,
        _managedByFuture = false,
        super(key: key);

  /// Constructs a LoadingOverlay that is shown immediately and remains
  /// visible until [future] completes (success or error). This is a
  /// non-breaking alternative to controlling visibility with [isLoading].
  factory LoadingOverlay.withFuture({
    Key? key,
    required Future<void> future,
    required Widget child,
    Widget progressIndicator = const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    ),
    Color? color,
  }) {
    return LoadingOverlay(
      key: key,
      // Start visible and let the State hide when future completes.
      isLoading: true,
      child: child,
      progressIndicator: progressIndicator,
      color: color,
    )._withFuture(future);
  }

  // Private helper to attach a future to an instance created by the factory.
  LoadingOverlay _withFuture(Future<void> future) {
    return LoadingOverlay._internal(
      key: key,
      isLoading: isLoading,
      child: child,
      progressIndicator: progressIndicator,
      color: color,
      future: future,
      managedByFuture: true,
    );
  }

  // Private internal constructor used by the factory to carry the future.
  const LoadingOverlay._internal({
    Key? key,
    required this.isLoading,
    required this.child,
    required this.progressIndicator,
    this.color,
    required Future<void> future,
    required bool managedByFuture,
  })  : _future = future,
        _managedByFuture = managedByFuture,
        super(key: key);

  @override
  LoadingOverlayState createState() => LoadingOverlayState();
}

class LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool? _overlayVisible;

  LoadingOverlayState();

  @override
  void initState() {
    super.initState();
    _overlayVisible = false;
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _animation.addStatusListener((status) {
      // ignore: unnecessary_statements
      status == AnimationStatus.forward
          ? setState(() {
              _overlayVisible = true;
            })
          : null;
      // ignore: unnecessary_statements
      status == AnimationStatus.dismissed
          ? setState(() {
              _overlayVisible = false;
            })
          : null;
    });
    if (widget.isLoading) {
      _controller.forward();
    }

    // If managed by a Future, hide the overlay when the Future completes
    // regardless of success or error.
    if (widget._managedByFuture && widget._future != null) {
      widget._future!.whenComplete(() {
        if (!mounted) return;
        _controller.reverse();
      });
    }
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isLoading && widget.isLoading) {
      _controller.forward();
    }

    if (oldWidget.isLoading && !widget.isLoading) {
      _controller.reverse();
    }

    // If managed by Future and the Future instance changed, show overlay
    // and wire up completion to hide it again.
    if (widget._managedByFuture && oldWidget._future != widget._future) {
      _controller.forward();
      widget._future?.whenComplete(() {
        if (!mounted) return;
        _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[];
    widgets.add(widget.child);

    if (_overlayVisible == true) {
      final modal = FadeTransition(
        opacity: _animation,
        child: Stack(
          children: <Widget>[
            SizedBox.expand(
              child: ColoredBox(
                color: widget.color ?? Colors.black.withOpacity(0.5),
              ),
            ),
            Center(child: widget.progressIndicator),
          ],
        ),
      );
      widgets.add(modal);
    }

    return Stack(children: widgets);
  }
}
