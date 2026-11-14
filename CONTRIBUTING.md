# Contributing

Use Flutter 3.50 / Dart 3.14 for the interactive example and release checks.
The library and its widget-only tests must also work on Flutter 3.27 / Dart 3.6.
Android builds require a configured Android SDK and JDK 17 or newer.

## Checking the published source

The package includes core and example tests, integration recipes, and the two
scripts below. With Flutter 3.50, run the suites from the root of a writable
copy of the package:

```sh
flutter test
cd example
flutter test
```

Alternatively, `./scripts/runTests.sh` runs both suites and collects coverage.
For the Flutter 3.27 core check, use
`./scripts/checkMinimum.sh /absolute/path/to/flutter-3.27/bin/flutter`.
That script isolates the core from the newer example and preserves documentation
assets referenced by the package manifest.

Platform runners, CI workflows, and image-generation tools are excluded from the
published archive. Clone the repository for the builds, formatting, release, and
image-generation steps below.

## Repository development

```sh
flutter pub get
flutter analyze --no-pub
./scripts/runTests.sh
dart format --output=none --set-exit-if-changed lib test example/lib example/test example/tool
dart doc --output build/api
flutter pub publish --dry-run
cd example
flutter build web --release
flutter build web --wasm --release
flutter build apk --debug
```

Test compatibility using a separately installed SDK:

```sh
./scripts/checkMinimum.sh /absolute/path/to/flutter-3.27/bin/flutter
```

This copies the core package, tests, and documentation assets into a temporary
directory. It avoids resolving the intentionally newer showcase and does not
alter the main workspace's
lockfiles or SDK. CI runs both SDK checks, example tests, web/Wasm and Android builds.

## Behavior changes

Add regression coverage for observable behavior. In particular, preserve these
contracts: independent task ownership, original async results/errors, stale future
isolation, disposal safety, modal input through fade-out, bounded layout, and
accessible state. Use finite pumps for indeterminate indicators: `pumpAndSettle`
will not settle while a spinner is active. Reduced-motion tests should settle.

Run `./scripts/runTests.sh` for package and example coverage in `lcov.info`.
Avoid adding design-system dependencies to the core library. Do not widen SDK
constraints without executing tests at the advertised minimum.

Public APIs need dartdoc. Update README, CHANGELOG, migration guidance, and
`llms.txt` when contracts change. Keep code recipes in `example/lib/recipes.dart`
so they are checked by the analyzer.

## Releasing

Release commits use `chore(release): publish <version>`. Commit implementation
changes first, then create the release commit with an empty `## [Unreleased]`
section above the versioned changelog entry. Creating this commit does not publish
the package; publication is a separate manual step.

1. Run all checks above. Review the public API and migration guide.
2. Review the example on narrow/wide screens, in light/dark mode, and with reduced
   motion. Test TalkBack/VoiceOver and hardware keyboards on actual target devices;
   semantics tests cannot validate every screen reader's behavior.
3. Verify the dry-run package contents and package metadata. This repository does
   not automatically publish to pub.dev.
4. Publish from the reviewed release commit, tag it, and add release notes with
   migration links. Update public screenshots/demo references if changed.
5. For the playground, enable repository Settings → Pages → GitHub Actions, then
   manually run **Publish playground** from the release branch. Its base href is
   `/loading_overlay/`; adjust it if the repository name or hosting path changes.

## README images

The images are rendered from the actual library widgets, without the playground’s
scenario buttons or debug controls. From `example/`, run:

```sh
flutter test tool/capture_preview.dart --dart-define=FLUTTER_SDK=/absolute/path/to/flutter
```

This regenerates `doc/images/loading-overlay.png` and
`doc/images/overlay-styles.png` using the SDK’s bundled fonts. Inspect both images
before updating the README or `pubspec.yaml` screenshot list. The renderer and
publishing infrastructure stay in Git and are excluded from the pub.dev archive.
