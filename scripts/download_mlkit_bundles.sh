#!/bin/bash
# Downloads the ML Kit resource bundles NewSDK needs (face detection + Latin text recognition).
#
# Swift Package Manager cannot ship these inside ML Kit's binary targets, so the *host app* must add
# them to its "Copy Bundle Resources" phase. Usage: scripts/download_mlkit_bundles.sh [destination-dir]
set -euo pipefail

VERSION="9.0.2"   # must match the google-mlkit-swiftpm version pinned in Package.swift
DEST="${1:-MLKitResources}"
BUNDLES=("GoogleMVFaceDetectorResources.bundle" "LatinOCRResources.bundle")

mkdir -p "$DEST"
for bundle in "${BUNDLES[@]}"; do
  echo "Downloading $bundle ..."
  curl -fsSL -o "/tmp/$bundle.zip" \
    "https://github.com/d-date/google-mlkit-swiftpm/releases/download/${VERSION}/${bundle}.zip"
  unzip -q -o "/tmp/$bundle.zip" -d "$DEST"
  rm -f "/tmp/$bundle.zip"
done
echo "Done. Add the .bundle folders in '$DEST' to your app target's Copy Bundle Resources."
