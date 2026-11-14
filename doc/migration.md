# Migrating to loading_overlay 0.7

## From loading_overlay 0.6 / 0.5

Both `LoadingOverlay(isLoading: ..., child: ...)` and
`LoadingOverlay.withFuture(future: ..., child: ...)` remain. `color` and
`progressIndicator` remain supported. The black 50% backdrop, white ring, immediate
presentation, and 300 ms linear fade remain the defaults.

Changes to review:

- The default ring is now `LoadingOverlayIndicator`, not a Material
  `CircularProgressIndicator`. It deliberately does not inherit Material's
  progress indicator theme. Pass your own Material/Cupertino widget or configure
  `LoadingOverlayTheme`. Update tests that find the old widget type.
- `material_ui` is no longer a transitive dependency. Apps importing it must
  declare it directly. The library itself supports Flutter 3.27 / Dart 3.6 onward.
- Background keyboard focus and screen-reader actions are now blocked along with
  pointer input, including during fade-out. Focus is released at loading start.
- User back navigation is blocked by default when the overlay has an enclosing
  route. Set `blockBack: false` to opt out. Programmatic pops still work.
- The implementation state class is private. Code referring to
  `LoadingOverlayState` should use boolean state or `LoadingOverlayController`.
- `progressIndicator` is nullable: null selects the built-in ring. Supply either
  it or `overlayBuilder`, not both.
- System reduced motion now skips fades and pauses ticker-driven loading content.

No show delay or minimum visible duration is enabled by default. Opt in with a
style if you want to avoid flashing during short operations.

## From loader_overlay

| Existing pattern | loading_overlay 0.7 |
| --- | --- |
| `LoaderOverlay(child: page)` | `LoadingOverlayScope(child: page)` |
| `context.loaderOverlay.show()` | Prefer `await context.loadingOverlay.run(work)` |
| manual show / hide | `context.loadingOverlay.show()` / `.hide()` |
| dynamic progress | `start(message: ..., progress: fraction)` then `task.update(...)` |
| `overlayWidgetBuilder: (progress) => ...` | `overlayBuilder: (context, data) => ...` |
| `GlobalLoaderOverlay` outside app | `LoadingOverlayScope` around the app builder's child |

Unlike a single global flag, `run`/`start` operations are independent. Finish the
specific task handle; `hide()` only hides the manual `show()` task. Typed progress
is a finite fraction, not arbitrary data. Custom builders receive message,
progress, and active task count. Store domain-specific data in your app.

## From flutter_easyloading

Own a `LoadingOverlayController` in State or dependency injection and supply it to
`LoadingOverlayScope` in the app builder. Replace `show`/`dismiss` around an operation
with `await controller.run(operation)`. Use handles for live progress updates.
Dispose your controller when its owner is disposed.

There is intentionally no global singleton and no toast/success/error notification
API. Keep your notification solution for outcomes; use this package for ongoing
work. See the README for navigation protection at app scope.

## From modal_progress_hud_nsn

```dart
LoadingOverlay(
  isLoading: inAsyncCall,
  color: const Color(0x4D808080), // Color includes the desired opacity.
  progressIndicator: yourIndicator,
  child: yourPage,
)
```

Use style `alignment`, `padding` and `blurSigma` for placement and blur. There is
no barrier-tap dismissal: accidentally hiding a blocking operation does not stop
it. For cancellation, supply custom overlay content connected to your actual
cancellation mechanism, then finish the task when appropriate.
