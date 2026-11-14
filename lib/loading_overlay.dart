/// Accessible, concurrency-safe loading overlays for Flutter.
///
/// Use [LoadingOverlay] for boolean state, [LoadingOverlay.withFuture] for an
/// existing future, or [LoadingOverlayScope] and [LoadingOverlayController.run]
/// for automatic cleanup of one or more operations.
library;

export 'src/controller.dart';
export 'src/indicator.dart';
export 'src/overlay.dart';
export 'src/scope.dart';
export 'src/style.dart';
