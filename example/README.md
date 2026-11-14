# loading_overlay example

This login form shows how to keep the form visible while blocking pointer taps
and preventing duplicate sign-ins during an asynchronous operation. It also
demonstrates safely disposing the form's controllers and leaving the page while
a request is pending.

Run from this directory:

```sh
flutter pub get
flutter run -d chrome
flutter test
```

The library and example require Flutter 3.50+ / Dart 3.14+ and use `material_ui`.

The Android project targets Flutter 3.50 with AGP 9.3.1, Gradle 9.5 and JDK 17 or
newer. It uses AGP's built-in Kotlin support. Build it with:

```sh
flutter build apk --debug
```
