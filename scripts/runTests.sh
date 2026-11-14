#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: > "$project_root/lcov.info"

for package in . example; do
  (
    cd "$project_root/$package"
    echo "Running tests in $package ..."
    flutter test --coverage
    # Keep package and example coverage paths relative to the repository.
    sed "s|^SF:lib|SF:$package/lib|g" coverage/lcov.info >> "$project_root/lcov.info"
  )
done
