# Troubleshooting

Symptoms seen when integrating the SDK, and their causes.

## Overview

| Symptom | Cause and fix |
| --- | --- |
| Crash when the scanner opens: `MLKTextRecognizerInternalErrorCreationFailure` / "Invalid model path" | The two ML Kit bundles are not in the app's **Copy Bundle Resources**. Check ``NewSDKScanner/missingMLKitResourceBundles(in:)``. |
| Crash or "unrecognized selector" inside ML Kit, or a screen that shows as a plain view | `-ObjC -all_load` is missing from **Other Linker Flags**. |
| "Framework … did not contain an Info.plist" | Use the TensorFlow Lite release zip built by `scripts/make_tflite_release_zip.sh`, which adds the per-slice `Info.plist` files. |
| Black scan screen and a "Camera unavailable" alert | No camera (simulator) or camera permission denied. |
| The SDK is always in English on a French phone | The host app does not declare French (`CFBundleLocalizations`). |
| Linker warning "built for newer iOS-simulator version (15.5)" | Comes from the ML Kit simulator binaries; harmless. |
| `UIStoryboard(name: "Main", bundle: nil)` no longer finds the scan screens | The screens live in the SDK's resource bundle; use ``NewSDKScanner`` instead. |
