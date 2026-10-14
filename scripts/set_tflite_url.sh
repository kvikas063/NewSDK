#!/bin/bash
# Points Package.swift at your GitHub repository's TensorFlow Lite release asset, and (re)writes its checksum
# from dist/TensorFlowLiteC.xcframework.zip (run scripts/make_tflite_release_zip.sh first).
#
# Usage: scripts/set_tflite_url.sh <github-user> <repository>
set -euo pipefail

[ $# -eq 2 ] || { echo "Usage: $0 <github-user> <repository>" >&2; exit 1; }
cd "$(dirname "$0")/.."

ZIP="dist/TensorFlowLiteC.xcframework.zip"
[ -f "$ZIP" ] || { echo "$ZIP not found: run scripts/make_tflite_release_zip.sh first" >&2; exit 1; }
CHECKSUM="$(swift package compute-checksum "$ZIP")"

python3 - "$1" "$2" "$CHECKSUM" <<'PY'
import re, sys
user, repo, checksum = sys.argv[1:4]
p = "Package.swift"
s = open(p).read()
s = re.sub(r'url: "https://github.com/[^/]+/[^/]+/releases/download/tflite-2.17.0/TensorFlowLiteC.xcframework.zip"',
           f'url: "https://github.com/{user}/{repo}/releases/download/tflite-2.17.0/TensorFlowLiteC.xcframework.zip"', s)
s = re.sub(r'checksum: "[0-9a-f]{64}"', f'checksum: "{checksum}"', s)
open(p, "w").write(s)
PY
echo "Package.swift updated (checksum $CHECKSUM)."
