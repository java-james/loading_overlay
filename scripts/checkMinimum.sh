#!/usr/bin/env bash
set -euo pipefail
# Usage: ./scripts/checkMinimum.sh /absolute/path/to/flutter-3.27/bin/flutter
# Isolate the core package: the showcase intentionally uses Flutter 3.50 Material.
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flutter_bin="${1:-flutter}"
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/loading-overlay-compat.XXXXXX")"
trap 'rm -rf "$check_dir"' EXIT
cp "$project_root/pubspec.yaml" "$project_root/analysis_options.yaml" "$check_dir/"
# Keep screenshot paths in pubspec.yaml valid during package analysis.
cp -R "$project_root/lib" "$project_root/test" "$project_root/doc" "$check_dir/"
cd "$check_dir"
"$flutter_bin" pub get
"$flutter_bin" analyze --no-pub
"$flutter_bin" test --no-pub --reporter expanded
