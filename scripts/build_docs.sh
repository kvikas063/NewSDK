#!/bin/bash
# Builds the DocC documentation of NewSDK.
#
#   Docs/NewSDK.doccarchive   open with Xcode (double-click) or `open Docs/NewSDK.doccarchive`
#   Docs/NewSDK-html/         static website; serve it with a web server, for example:
#                             python3 -m http.server --directory Docs/NewSDK-html 8000
#                             then open http://localhost:8000/documentation/newsdk
#
# Usage: scripts/build_docs.sh [hosting-base-path]     (base path only when the site is hosted below a sub-path)
set -euo pipefail

cd "$(dirname "$0")/.."
DERIVED="$(mktemp -d)"
BASE_PATH="${1:-}"

xcodebuild docbuild -scheme NewSDK -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED" -quiet

ARCHIVE="$(find "$DERIVED/Build/Products" -name 'NewSDK.doccarchive' -maxdepth 3 | head -1)"
rm -rf Docs/NewSDK.doccarchive Docs/NewSDK-html
mkdir -p Docs
cp -R "$ARCHIVE" Docs/NewSDK.doccarchive

if [ -n "$BASE_PATH" ]; then
  xcrun docc process-archive transform-for-static-hosting Docs/NewSDK.doccarchive \
    --output-path Docs/NewSDK-html --hosting-base-path "$BASE_PATH"
else
  xcrun docc process-archive transform-for-static-hosting Docs/NewSDK.doccarchive --output-path Docs/NewSDK-html
fi
rm -rf "$DERIVED"
echo "Created Docs/NewSDK.doccarchive and Docs/NewSDK-html"
