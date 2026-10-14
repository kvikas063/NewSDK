#!/bin/bash
# Builds the TensorFlowLiteC.xcframework.zip that Package.swift downloads as a binary target.
#
# The framework is Google's official TensorFlow Lite 2.17.0 iOS build. SwiftPM needs every framework slice to
# contain an Info.plist, which Google's archive omits, so this script adds one before zipping.
#
# Usage: scripts/make_tflite_release_zip.sh
# Output: dist/TensorFlowLiteC.xcframework.zip  (+ the checksum to paste into Package.swift)
#
# Publish the zip as an asset of a GitHub Release (for example tag `tflite-2.17.0`).
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION="2.17.0"
URL="https://dl.google.com/tflite-release/ios/prod/tensorflow/lite/release/ios/release/32/20240729-115310/TensorFlowLiteC/${VERSION}/0c10b3543e01f547/TensorFlowLiteC-${VERSION}.tar.gz"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "Downloading TensorFlowLiteC ${VERSION} ..."
curl -fsSL -o "$WORK/tflite.tar.gz" "$URL"
tar xzf "$WORK/tflite.tar.gz" -C "$WORK"
XCF="$(find "$WORK" -type d -name 'TensorFlowLiteC.xcframework' | head -1)"
[ -n "$XCF" ] || { echo "TensorFlowLiteC.xcframework not found in the archive" >&2; exit 1; }

patch_slice() {   # $1 = slice directory, $2 = platform name
  cat > "$1/TensorFlowLiteC.framework/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>TensorFlowLiteC</string>
	<key>CFBundleIdentifier</key>
	<string>org.tensorflow.lite.TensorFlowLiteC</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>TensorFlowLiteC</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
	<key>CFBundleVersion</key>
	<string>${VERSION}</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>$2</string>
	</array>
	<key>MinimumOSVersion</key>
	<string>12.0</string>
</dict>
</plist>
PLIST
}
patch_slice "$XCF/ios-arm64" "iPhoneOS"
patch_slice "$XCF/ios-arm64_x86_64-simulator" "iPhoneSimulator"

mkdir -p dist
rm -f dist/TensorFlowLiteC.xcframework.zip
ZIP="$PWD/dist/TensorFlowLiteC.xcframework.zip"
(cd "$(dirname "$XCF")" && zip -qry "$ZIP" TensorFlowLiteC.xcframework)

echo
echo "Created dist/TensorFlowLiteC.xcframework.zip ($(du -h "$ZIP" | cut -f1))"
echo "Checksum: $(swift package compute-checksum "$ZIP")"
