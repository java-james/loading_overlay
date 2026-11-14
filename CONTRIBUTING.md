# Contributing

Use Flutter 3.50 / Dart 3.14 to match CI. Android builds also require JDK 17
or newer; see the [example instructions](example/README.md).

Run checks from the repository root:

```sh
flutter pub get
flutter analyze
./scripts/runTests.sh
dart format --output=none --set-exit-if-changed lib test example/lib example/test
```

CI runs these checks and builds the web and Android examples on Flutter 3.50.

Include regression tests for behavior changes and describe the change in
[CHANGELOG.md](CHANGELOG.md).
