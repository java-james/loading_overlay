# loading_overlay

A Flutter loading overlay with a dimmed backdrop and a 300 ms fade.
Control it with a boolean or let it follow a `Future`.

[pub.dev](https://pub.dev/packages/loading_overlay) ·
[API reference](https://pub.dev/documentation/loading_overlay/latest/)

![Loading overlay on a login form](https://raw.githubusercontent.com/java-james/loading_overlay/master/loading_overlay.gif)

## Install

Add to your `pubspec.yaml`, then run `flutter pub get`:

```yaml
dependencies:
  loading_overlay: ^0.6.0
  material_ui: ^1.11.0
```

## Usage

Import the package:

```dart
import 'package:loading_overlay/loading_overlay.dart';
import 'package:material_ui/material_ui.dart';
```

Wrap your content and rebuild when your `isSaving` boolean changes:

```dart
return Scaffold(
  body: LoadingOverlay(
    isLoading: isSaving,
    child: const Center(child: Text('Your content')),
  ),
);
```

### Follow a future

Create and retain `saveFuture` (`Future<void>`) before `build`, for example in
`initState` or an event handler:

```dart
return LoadingOverlay.withFuture(
  future: saveFuture,
  child: const Center(child: Text('Your content')),
);
```

Success and failure both dismiss the overlay. Handle errors on the original
future. Only the latest future controls visibility; rebuilding with the same
completed future keeps the overlay hidden.

### Interaction

The overlay blocks pointer taps, including during fade-out. Keyboard and
accessibility actions remain available, so guard async handlers against duplicate
submissions. The [login example](example/lib/main.dart) shows how.

## Customize

Both constructors accept these optional parameters:

| Parameter | Default |
| --- | --- |
| `color` | Translucent black: `const Color(0x80000000)` |
| `progressIndicator` | White `CircularProgressIndicator` |

## Compatibility

Requires Flutter 3.50+ and Dart `^3.14.0`.

**Upgrading from 0.5.x:** migrate your app's Material imports, themes, and
localization delegates to `material_ui`. See the
[Flutter migration guide](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui).

See [Contributing](CONTRIBUTING.md) for development requirements and checks.

[Changelog](CHANGELOG.md) ·
[Report an issue](https://github.com/java-james/loading_overlay/issues)

[MIT licensed](LICENSE). Forked from
[modal_progress_hud](https://pub.dev/packages/modal_progress_hud).

