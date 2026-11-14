#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compat_dir="$(mktemp -d "${TMPDIR:-/tmp}/loading-overlay-compat.XXXXXX")"

cleanup() {
  python3 -c 'import shutil, sys; shutil.rmtree(sys.argv[1])' "$compat_dir"
}
trap cleanup EXIT

# Test the actual library as a path dependency. A consumer does not resolve the
# library's newer lint tooling or its example, and ignores its checked-in lockfile.
python3 - "$project_root" "$compat_dir" <<'PY'
import json
from pathlib import Path
import shutil
import sys

root, target = map(Path, sys.argv[1:])
shutil.copytree(root / 'test', target / 'test')
(target / 'pubspec.yaml').write_text('''name: loading_overlay_compatibility
publish_to: none
environment:
  sdk: '>=2.12.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  loading_overlay:
    path: ''' + json.dumps(str(root)) + '''
dev_dependencies:
  flutter_test:
    sdk: flutter
''')
PY

cd "$compat_dir"
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
