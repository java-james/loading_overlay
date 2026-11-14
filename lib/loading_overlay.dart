// Retain the SDK Material library for consumers on Flutter 2.x and 3.x.
// Migrating to material_ui requires a separate breaking release.
// ignore: deprecated_member_use
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
/// The opacity of the modal barrier is the alpha channel of [color], for example
/// `const Color(0x80000000)` for a translucent black backdrop.
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
  ///
  /// Obtain the future before building this widget, so rebuilds do not restart
  /// the operation. Replacing it starts a new loading cycle; completion of a
  /// previous future does not hide the new cycle.
  ///
  /// This widget observes errors only to hide the overlay. Callers can still
  /// await or handle errors on the original future to display an error message.
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
      progressIndicator: progressIndicator,
      color: color,
      child: child,
    )._withFuture(future);
  }

  // Private helper to attach a future to an instance created by the factory.
  LoadingOverlay _withFuture(Future<void> future) {
    return LoadingOverlay._internal(
      key: key,
      isLoading: isLoading,
      progressIndicator: progressIndicator,
      color: color,
      future: future,
      managedByFuture: true,
      child: child,
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
  bool _overlayVisible = false;
  Object? _activeCallbackIdentity;

  LoadingOverlayState();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        setState(() {
          _overlayVisible = true;
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _overlayVisible = false;
        });
      }
    });
    if (widget.isLoading) {
      _controller.forward();
    }

    if (widget._managedByFuture) {
      _subscribeToFuture();
    }
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._managedByFuture) {
      if (!oldWidget._managedByFuture || oldWidget._future != widget._future) {
        _controller.forward();
        _subscribeToFuture();
      }
      return;
    }

    // A pending future no longer controls visibility after switching modes.
    _activeCallbackIdentity = null;
    if (oldWidget._managedByFuture || oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void _subscribeToFuture() {
    final callbackIdentity = Object();
    _activeCallbackIdentity = callbackIdentity;

    void onComplete() {
      if (!mounted || _activeCallbackIdentity != callbackIdentity) return;
      _activeCallbackIdentity = null;
      _controller.reverse();
    }

    // Handle both outcomes on this subscription. An ignored whenComplete()
    // future would otherwise propagate errors as uncaught asynchronous errors.
    widget._future!.then<void>(
      (_) => onComplete(),
      onError: (Object error, StackTrace stackTrace) => onComplete(),
    );
  }

  @override
  void dispose() {
    _activeCallbackIdentity = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[];
    widgets.add(widget.child);

    if (_overlayVisible) {
      final modal = FadeTransition(
        opacity: _animation,
        child: Stack(
          children: <Widget>[
            SizedBox.expand(
              child: ColoredBox(
                color: widget.color ?? const Color(0x80000000),
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
