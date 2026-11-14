import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'indicator.dart';
import 'style.dart';

/// Builds custom overlay content from a typed loading snapshot.
typedef LoadingOverlayWidgetBuilder = Widget Function(
  BuildContext context,
  LoadingOverlayData data,
);

enum _Control { boolean, future, controller }

/// Places an accessible loading overlay within its child's layout bounds.
///
/// Supports boolean, future, and controller-based ownership. The child keeps its
/// state throughout transitions. Pointer, focus, and semantics isolation begin
/// immediately, including during a configured show delay, and remain until the
/// overlay has fully faded out. Set [blockInteraction] to false for a non-modal
/// indicator.
///
/// [blockBack] protects an enclosing route using PopScope. Above a Navigator
/// (for example in an app builder), use LoadingOverlayBackGuard inside routes.
/// Programmatic Navigator.pop calls are not vetoed by Flutter's PopScope.
class LoadingOverlay extends StatefulWidget {
  /// Displays loading state supplied by your existing state management.
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.progress,
    this.progressIndicator,
    this.overlayBuilder,
    this.color,
    this.style,
    this.blockInteraction = true,
    this.blockBack = true,
    this.semanticsLabel = 'Loading',
  })  : _control = _Control.boolean,
        _future = null,
        controller = null,
        assert(progress == null || (progress >= 0 && progress <= 1)),
        assert(progressIndicator == null || overlayBuilder == null);

  /// Observes [future] until success or failure, preserving its original result.
  ///
  /// Create the future outside build. A replacement future starts a new cycle;
  /// older completions cannot hide it. The same completed future stays hidden.
  /// This subscription handles errors to dismiss the overlay; handle application
  /// errors separately by awaiting the original future. Futures of any result
  /// type can be supplied because this observer discards the result.
  const LoadingOverlay.withFuture({
    super.key,
    required Future<void> future,
    required this.child,
    this.message,
    this.progress,
    this.progressIndicator,
    this.overlayBuilder,
    this.color,
    this.style,
    this.blockInteraction = true,
    this.blockBack = true,
    this.semanticsLabel = 'Loading',
  })  : _control = _Control.future,
        _future = future,
        controller = null,
        isLoading = true,
        assert(progress == null || (progress >= 0 && progress <= 1)),
        assert(progressIndicator == null || overlayBuilder == null);

  /// Observes a caller-owned controller without disposing it.
  const LoadingOverlay.controlled({
    super.key,
    required LoadingOverlayController this.controller,
    required this.child,
    this.progressIndicator,
    this.overlayBuilder,
    this.color,
    this.style,
    this.blockInteraction = true,
    this.blockBack = true,
    this.semanticsLabel = 'Loading',
  })  : _control = _Control.controller,
        _future = null,
        isLoading = false,
        message = null,
        progress = null,
        assert(progressIndicator == null || overlayBuilder == null);

  /// Loading state for the boolean constructor only.
  final bool isLoading;

  /// Content whose layout bounds and state are preserved.
  final Widget child;

  /// Optional status text in boolean and future modes.
  final String? message;

  /// Progress fraction in boolean and future modes, or null for indeterminate.
  final double? progress;

  /// An optional replacement for the default ring; messages still appear below.
  final Widget? progressIndicator;

  /// Replaces the entire indicator/message content with a custom widget.
  ///
  /// The builder owns its status/progress semantics and any interactive controls.
  /// Its content is wrapped in a live region without an automatic label/value.
  final LoadingOverlayWidgetBuilder? overlayBuilder;

  /// Overrides the style's barrier color. Retained for migration from 0.x.
  final Color? color;

  /// Explicit presentation settings, otherwise inherited from LoadingOverlayTheme.
  final LoadingOverlayStyle? style;

  /// Blocks pointer, keyboard focus and underlying accessibility actions.
  final bool blockInteraction;

  /// Prevents user back navigation on an enclosing route while modal/loading.
  ///
  /// Independent of [blockInteraction]. Has no effect above a Navigator.
  final bool blockBack;

  /// Localizable screen reader fallback when no message is provided.
  final String semanticsLabel;

  /// Controller used by the controlled constructor; owned by the caller.
  final LoadingOverlayController? controller;

  final _Control _control;
  final Future<void>? _future;

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late LoadingOverlayStyle _style;
  late LoadingOverlayStyle _cycleStyle;
  final Set<int> _childPointers = {};
  LoadingOverlayData _data = const LoadingOverlayData();
  Timer? _delayTimer;
  Timer? _minimumTimer;
  Object? _futureIdentity;
  bool _initialized = false;
  bool _visible = false;
  bool _minimumElapsed = true;
  bool _reduceMotion = false;
  bool _refreshScheduled = false;
  bool _controllerUpdateScheduled = false;

  bool get _busy => _data.isLoading || _visible;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed && !_data.isLoading) {
          _visible = false;
          _refresh();
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
    if (!_initialized) {
      _initialized = true;
      _bind();
    }
  }

  void _configure() {
    _style = widget.style ?? LoadingOverlayTheme.of(context);
    assert(
        !_style.duration.isNegative &&
            !_style.reverseDuration.isNegative &&
            !_style.showDelay.isNegative &&
            !_style.minimumVisibleDuration.isNegative,
        'Loading overlay durations must not be negative.');
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion && _fade.isAnimating) {
      _fade.value = _data.isLoading || !_minimumElapsed ? 1 : 0;
    }
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configure();
    if (oldWidget._control != widget._control ||
        oldWidget.controller != widget.controller ||
        oldWidget._future != widget._future) {
      oldWidget.controller?.removeListener(_controllerChanged);
      _futureIdentity = null;
      _bind();
    } else if (widget._control != _Control.controller) {
      _setData(_widgetData(
        widget._control == _Control.boolean
            ? widget.isLoading
            : _data.isLoading,
      ));
    }
  }

  LoadingOverlayData _widgetData(bool loading) => LoadingOverlayData(
        activeTasks: loading ? 1 : 0,
        message: widget.message,
        progress: widget.progress,
      );

  void _bind() {
    switch (widget._control) {
      case _Control.boolean:
        _setData(_widgetData(widget.isLoading));
      case _Control.controller:
        widget.controller!.addListener(_controllerChanged);
        _setData(widget.controller!.value);
      case _Control.future:
        _setData(_widgetData(true));
        final identity = Object();
        _futureIdentity = identity;
        void complete() {
          if (!mounted || _futureIdentity != identity) return;
          _setData(_widgetData(false));
          _refresh();
        }
        widget._future!.then<void>(
          (_) => complete(),
          onError: (Object error, StackTrace stack) => complete(),
        );
    }
  }

  void _controllerChanged() {
    // A descendant may start work in initState. Defer widget updates during
    // build, but leave the controller's synchronous state immediately readable.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_controllerUpdateScheduled) return;
      _controllerUpdateScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controllerUpdateScheduled = false;
        if (mounted && widget._control == _Control.controller) {
          _controllerChanged();
        }
      });
      return;
    }
    _setData(widget.controller!.value);
    _refresh();
  }

  void _setData(LoadingOverlayData next) {
    final wasLoading = _data.isLoading;
    // Retain the last message/progress during minimum duration and fade-out.
    _data = next.isLoading
        ? next
        : LoadingOverlayData(
            message: _data.message,
            progress: _data.progress,
          );
    if (_busy && widget.blockInteraction) _cancelChildPointers();
    if (wasLoading == next.isLoading) return;
    if (next.isLoading) {
      if (_visible) {
        _fadeIn();
      } else {
        // Appearance can change immediately, but timing stays consistent from
        // the initial delay through the last frame of this visibility cycle.
        _cycleStyle = _style;
        _fade.duration = _cycleStyle.duration;
        _fade.reverseDuration = _cycleStyle.reverseDuration;
        if (_cycleStyle.showDelay == Duration.zero) {
          _show();
        } else {
          _delayTimer = Timer(_cycleStyle.showDelay, () {
            _delayTimer = null;
            if (!mounted || !_data.isLoading) return;
            _show();
            _refresh();
          });
        }
      }
    } else {
      _delayTimer?.cancel();
      _delayTimer = null;
      if (_visible && _minimumElapsed) _hide();
    }
  }

  void _show() {
    _visible = true;
    _minimumElapsed = _cycleStyle.minimumVisibleDuration == Duration.zero;
    _minimumTimer?.cancel();
    if (!_minimumElapsed) {
      _minimumTimer = Timer(_cycleStyle.minimumVisibleDuration, () {
        _minimumTimer = null;
        _minimumElapsed = true;
        if (mounted && !_data.isLoading) {
          _hide();
          _refresh();
        }
      });
    }
    _fadeIn();
  }

  void _fadeIn() {
    if (_reduceMotion || _cycleStyle.duration == Duration.zero) {
      _fade.value = 1;
    } else {
      _fade.forward();
    }
  }

  void _hide() {
    if (_reduceMotion ||
        _cycleStyle.reverseDuration == Duration.zero ||
        _fade.value == 0) {
      _fade.value = 0;
      _visible = false;
    } else {
      _fade.reverse();
    }
  }

  void _trackChildPointer(int pointer) {
    _childPointers.add(pointer);
    // Events reach descendants first. A child's pointer-down handler may have
    // already started loading before this listener receives the same event.
    if (_busy && widget.blockInteraction) _cancelChildPointers();
  }

  void _cancelChildPointers() {
    if (_childPointers.isEmpty) return;
    final pointers = _childPointers.toList();
    _childPointers.clear();
    for (final pointer in pointers) {
      WidgetsBinding.instance.cancelPointer(pointer);
    }
  }

  void _refresh() {
    if (!mounted) return;
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
    widget.controller?.removeListener(_controllerChanged);
    _futureIdentity = null;
    _delayTimer?.cancel();
    _minimumTimer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  Widget _content(BuildContext context) {
    if (widget.overlayBuilder case final builder?) {
      return builder(context, _data);
    }
    final progress = _data.progress;
    return ExcludeSemantics(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.progressIndicator ??
                LoadingOverlayIndicator(
                  value: progress,
                  color: _style.indicatorColor,
                ),
            if (_data.message != null) ...[
              const SizedBox(height: 16),
              Text(_data.message!,
                  textAlign: TextAlign.center, style: _style.messageStyle),
            ],
            if (progress != null) ...[
              const SizedBox(height: 8),
              Text('${(progress * 100).round()}%', style: _style.messageStyle),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocking = _busy && widget.blockInteraction;
    if (blocking) _cancelChildPointers();
    return PopScope<Object?>(
      canPop: !(_busy && widget.blockBack),
      // Contain ModalBarrier's BlockSemantics within this overlay's bounds;
      // otherwise a regional overlay can hide unrelated sibling semantics.
      child: Semantics(
        container: true,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            ExcludeFocus(
              excluding: blocking,
              child: ExcludeSemantics(
                excluding: blocking,
                child: AbsorbPointer(
                  absorbing: blocking,
                  child: Listener(
                    onPointerDown: (event) => _trackChildPointer(event.pointer),
                    onPointerUp: (event) =>
                        _childPointers.remove(event.pointer),
                    onPointerCancel: (event) =>
                        _childPointers.remove(event.pointer),
                    onPointerPanZoomStart: (event) =>
                        _trackChildPointer(event.pointer),
                    onPointerPanZoomEnd: (event) =>
                        _childPointers.remove(event.pointer),
                    child: widget.child,
                  ),
                ),
              ),
            ),
            if (_busy)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !widget.blockInteraction,
                  child: Stack(
                    children: [
                      if (widget.blockInteraction)
                        const Positioned.fill(
                          child: ModalBarrier(
                              dismissible: false,
                              barrierSemanticsDismissible: false),
                        ),
                      if (_visible)
                        Positioned.fill(
                          child: FadeTransition(
                            opacity: _fade,
                            alwaysIncludeSemantics: true,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRect(
                                    child: _style.blurSigma > 0
                                        ? BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: _style.blurSigma,
                                                sigmaY: _style.blurSigma),
                                            child: ColoredBox(
                                                color: widget.color ??
                                                    _style.barrierColor),
                                          )
                                        : ColoredBox(
                                            color: widget.color ??
                                                _style.barrierColor),
                                  ),
                                ),
                                Positioned.fill(
                                  child: SafeArea(
                                    child: Padding(
                                      padding: _style.padding,
                                      child: Align(
                                        alignment: _style.alignment,
                                        child: Semantics(
                                          container: true,
                                          liveRegion: true,
                                          label: widget.overlayBuilder != null
                                              ? null
                                              : _data.message ??
                                                  widget.semanticsLabel,
                                          value: widget.overlayBuilder !=
                                                      null ||
                                                  _data.progress == null
                                              ? null
                                              : '${(_data.progress! * 100).round()}%',
                                          child: TickerMode(
                                            enabled: !_reduceMotion,
                                            child: _content(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (!_visible)
                        Positioned.fill(
                          child: Semantics(
                            container: true,
                            liveRegion: true,
                            label: _data.message ?? widget.semanticsLabel,
                            child: const SizedBox.expand(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
