# loading_overlay playground

From the repository’s `example/` directory, run on Flutter 3.50+ / Dart 3.14+:

```sh
flutter pub get
flutter run -d chrome
```

The example imports `material_ui`; the core library only depends on Flutter and
supports Flutter 3.27+.

Try seven scenarios: boolean loading, upload progress, overlapping requests,
error cleanup, following a Future, a fast operation that avoids flashing, and
app-wide loading. Toggle the theme and resize the window to explore both layouts.
All operations are simulated locally; the demo makes no API requests.

See `lib/recipes.dart` for compact, compiled integration patterns. The showcase
uses a custom loading card; omit `overlayBuilder` for the built-in ring/messages.

The widget tests are included in the published source. From `example/`, run
`flutter test` with Flutter 3.50. For platform builds, image generation, and demo
deployment from a repository checkout, see the [contributing guide](../CONTRIBUTING.md).
