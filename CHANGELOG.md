## [0.6.0]

* **Breaking:** require Flutter 3.50+ and Dart `^3.14.0`.
  Apps on older Flutter versions can continue using 0.5.x.
* **Breaking:** the default spinner now uses `material_ui` and no longer reads
  themes from `package:flutter/material.dart`. To retain legacy spinner styling,
  pass your own `progressIndicator` or
  [migrate your Material theme](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui).
  `material_ui` is installed transitively; apps only need to declare it directly
  if they import it.

* Fix stale future completions hiding newer loading operations or overriding
  manually controlled visibility.
* Fix switching from future-controlled loading to `isLoading: true` after the
  future has completed.
* Handle future errors without creating unhandled errors on an ignored completion
  future, and ignore callbacks after disposal. The original future's result is
  preserved for callers.
* Preserve both constructors, default colours and the 300 ms fade.
  Replace deprecated `withOpacity` usage with the equivalent constant colour.
* Expand widget coverage for animation, interaction, customisation, future
  replacement, errors, disposal and switching visibility controls.
* Update example lint tooling, remove unused Cupertino icons, refresh lockfiles,
  add login tests, prevent duplicate sign-ins and dispose the example's
  controllers safely.
* Replace obsolete Travis CI with GitHub Actions using Flutter 3.50 for tests
  and web/Android example builds. Update the Android example to
  AGP 9.3.1, Gradle 9.5 and built-in Kotlin with Java 17.
* Simplify the README and document future ownership, migration requirements and
  keyboard/accessibility interaction limitations.

## [0.5.0]
* New: `LoadingOverlay.withFuture` constructor to display the overlay until a
	provided `Future` completes.
	- Starts visible immediately and hides automatically on completion (success
		or error) using the existing fade-out animation.
	- Works alongside the existing boolean `isLoading` constructor — no breaking
		changes to the public API.
	- If the `future` instance changes during rebuilds, the overlay will show
		again and re-wire to the new `Future`'s completion.
* Documentation: README updated with usage examples for both boolean and
	future-driven patterns.
* Tests: Added widget tests covering the new `withFuture` behavior.

## [0.4.3]
* Upgrade dev lint dependency

## [0.4.2]
* Dart formatting across files

## [0.4.1]
* Update readme

## [0.4.0]
* Fix iOS opacity issue
* explicit SDK 3.x support

## [0.3.0]
* Added null-safety

## [0.2.1]
* Fix isLoading true on init

## [0.2.0]
* Add fading effect
* Rename to loading_overlay
* Remove optional offset
* Rename isInAsyncCall to isLoading

## [0.1.3]
* Performance optimization
* Improved docs

## [0.1.2]
* Added option to dismiss modal
* Refactored example

## [0.1.1]
* Added option to position progress indicator
* Refactored example

## [0.1.0]
* Added support for Dart 2.0

## [0.0.6]
* Pass any progress indicator
* Added tests and code coverage
* Refactoring for tests

## [0.0.5]
* Changed layout of README and corrected spelling

## [0.0.4]
* Updated README

## [0.0.3]
* Fixed location of demo gif file

## [0.0.2]
* Added example of use of modal progress hud with login screen, form and async calls.

## [0.0.1] - July 10, 2018

* Simple countainer widget to enable modal progress hud (progress indicator)
