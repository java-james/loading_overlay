# Contributing

## Requirements

Development tooling and the example require Flutter 3.32 / Dart 3.8 or newer.
Use Flutter 3.50 for the formatting check to match CI. Android builds require
Flutter 3.50 and JDK 17 or newer; see the [example instructions](example/README.md).

The library supports Dart `>=2.12.0 <4.0.0`. Keep public API and runtime changes
compatible with that range. The SDK Material import is retained for older Flutter
apps; migrating to `material_ui` requires a separate breaking release.

## Checks

Run from the repository root:

```sh
flutter pub get
flutter analyze
./scripts/runTests.sh
dart format --output=none --set-exit-if-changed lib test example/lib example/test
```

CI runs tests and analysis on Flutter 3.32 and 3.50, checks formatting on 3.50,
builds the web and Android examples, and checks the library on Flutter 2.0 /
Dart 2.12.

To check an older SDK locally, put that Flutter SDK on your `PATH` and run:

```sh
./scripts/test-compatibility.sh
```

This script requires Python 3. It creates a temporary consumer package to test
the library without resolving its newer development-only lint dependency.

Include regression tests for behavior changes and describe the change in
[CHANGELOG.md](CHANGELOG.md).
