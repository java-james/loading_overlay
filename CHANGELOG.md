## [Unreleased]

## [0.7.0]

* Add `LoadingOverlayController`, `LoadingOverlayScope`, and the
  `context.loadingOverlay` extension. Run async operations with automatic cleanup
  and original result/error propagation, without a global singleton.
* Add independent task handles and typed `LoadingOverlayData`. Concurrent tasks
  cannot dismiss each other; the latest unfinished task supplies progress/status.
* Add determinate progress, status messages, custom content builders, inherited
  styling, optional blur, show delay, and minimum visible duration.
* Block underlying pointer, keyboard focus, and accessibility interaction through
  fade-out. Add live announcements, localized labels, reduced-motion behavior,
  and `PopScope` back protection with an app-wide route guard.
* Cancel existing touch/trackpad gestures when blocking begins, preserve
  accessibility outside regional overlays, and retain custom builder semantics
  without duplicate announcements.
* Support loading started during descendant initialization. Keep timing settings
  stable through a visibility cycle while allowing appearance updates.
* **Breaking:** the default indicator is now a design-system-independent
  `LoadingOverlayIndicator`. Material indicator themes no longer apply. Supply
  `progressIndicator` to keep a Material/Cupertino spinner.
* **Breaking:** background keyboard/accessibility actions and user back navigation
  are blocked by default. `blockInteraction` and `blockBack` provide opt-outs.
* **Breaking:** the implementation State class is now private. Use boolean state
  or a controller instead of `LoadingOverlayState`.
* Remove the `material_ui` runtime dependency and support Flutter 3.27 / Dart 3.6
  onward. The example uses Flutter 3.50 and declares its own `material_ui` dependency.
* Retain boolean and Future constructors, custom indicators/colors, the default
  backdrop and 300 ms fade. Delay and minimum duration remain opt-in.
* Replace the example with a responsive interactive playground and compiled
  integration recipes. Add migration and agent guides, minimum/current SDK tests,
  web/Wasm builds, and package dry-run validation.

See [migration guidance](doc/migration.md) for the changed interaction defaults
and mappings from other loading packages.

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
