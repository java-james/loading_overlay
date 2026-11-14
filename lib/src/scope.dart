import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'overlay.dart';
import 'style.dart';

/// Hosts a loading overlay and provides its controller to descendants.
///
/// Use around one page, a bounded section, or the child of an app's builder.
/// Without an explicit [controller], the scope creates and disposes one. Nested
/// scopes are independent; context lookup always returns the nearest scope.
class LoadingOverlayScope extends StatefulWidget {
  /// Creates a scoped overlay.
  const LoadingOverlayScope({
    super.key,
    required this.child,
    this.controller,
    this.style,
    this.overlayBuilder,
    this.blockInteraction = true,
    this.blockBack = true,
    this.semanticsLabel = 'Loading',
  });

  /// The content inside this scope.
  final Widget child;

  /// Optional caller-owned controller, which this scope never disposes.
  final LoadingOverlayController? controller;

  /// Explicit style, otherwise inherited from LoadingOverlayTheme.
  final LoadingOverlayStyle? style;

  /// Optional custom content for the overlay.
  final LoadingOverlayWidgetBuilder? overlayBuilder;

  /// Whether the loading overlay blocks underlying user interaction.
  final bool blockInteraction;

  /// Whether to protect an enclosing route from user back navigation.
  final bool blockBack;

  /// Localizable default screen reader announcement.
  final String semanticsLabel;

  /// Finds the nearest controller, with an actionable error if none exists.
  ///
  /// Call from event handlers or lifecycle methods, not to watch loading state.
  /// To rebuild on state changes, use ValueListenableBuilder with the controller.
  static LoadingOverlayController of(BuildContext context) {
    final controller = maybeOf(context);
    if (controller == null) {
      throw FlutterError(
        'No LoadingOverlayScope found. Wrap this page or your app builder\'s '
        'child in LoadingOverlayScope, and use a BuildContext below that scope.',
      );
    }
    return controller;
  }

  /// Returns the nearest controller without subscribing, or null if absent.
  static LoadingOverlayController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_LoadingScope>()?.controller;

  @override
  State<LoadingOverlayScope> createState() => _LoadingOverlayScopeState();
}

class _LoadingOverlayScopeState extends State<LoadingOverlayScope> {
  LoadingOverlayController? _owned;

  LoadingOverlayController get _controller =>
      widget.controller ?? (_owned ??= LoadingOverlayController());

  @override
  void didUpdateWidget(LoadingOverlayScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && _owned != null) {
      // Retain the old owned controller until the child detaches its listener.
      final previous = _owned!;
      _owned = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _LoadingScope(
        controller: _controller,
        child: LoadingOverlay.controlled(
          controller: _controller,
          style: widget.style,
          overlayBuilder: widget.overlayBuilder,
          blockInteraction: widget.blockInteraction,
          blockBack: widget.blockBack,
          semanticsLabel: widget.semanticsLabel,
          child: widget.child,
        ),
      );
}

class _LoadingScope extends InheritedWidget {
  const _LoadingScope({required this.controller, required super.child});

  final LoadingOverlayController controller;

  @override
  bool updateShouldNotify(_LoadingScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Convenient access to the nearest scope from a descendant BuildContext.
extension LoadingOverlayContext on BuildContext {
  /// The nearest loading controller. Throws with setup instructions if missing.
  LoadingOverlayController get loadingOverlay => LoadingOverlayScope.of(this);
}

/// Protects a route when the overlay host sits above the Navigator.
///
/// Put this inside each route that must block user back navigation during work.
/// Uses an explicit controller or the nearest scope. Protection ends when work
/// completes; a scope's optional minimum duration/fade may still be visible.
/// Flutter's programmatic Navigator.pop bypasses PopScope by design.
class LoadingOverlayBackGuard extends StatefulWidget {
  /// Creates a route guard for a loading controller.
  const LoadingOverlayBackGuard({
    super.key,
    this.controller,
    required this.child,
  });

  /// Optional controller, otherwise resolved from the nearest scope.
  final LoadingOverlayController? controller;

  /// Route content to protect.
  final Widget child;

  @override
  State<LoadingOverlayBackGuard> createState() =>
      _LoadingOverlayBackGuardState();
}

class _LoadingOverlayBackGuardState extends State<LoadingOverlayBackGuard> {
  LoadingOverlayController? _controller;
  bool _refreshScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bind();
  }

  @override
  void didUpdateWidget(LoadingOverlayBackGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) _bind();
  }

  void _bind() {
    final source = widget.controller ??
        context
            .dependOnInheritedWidgetOfExactType<_LoadingScope>()
            ?.controller ??
        LoadingOverlayScope.of(context);
    if (identical(source, _controller)) return;
    _controller?.removeListener(_refresh);
    _controller = source..addListener(_refresh);
  }

  void _refresh() {
    // Work may start while a descendant is being built (for example initState).
    // Coalesce those notifications, then read the currently bound controller.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_refreshScheduled) return;
      _refreshScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshScheduled = false;
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
        canPop: !_controller!.isLoading,
        child: widget.child,
      );
}
