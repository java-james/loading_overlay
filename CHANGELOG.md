## [Unreleased]

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
