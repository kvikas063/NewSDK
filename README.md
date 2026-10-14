# NewSDK

iOS SDK that scans a Moroccan national ID card (CIN) and returns the extracted data. A scan has two steps:

1. **Recto** – the front of the card is detected and its fields are read with on-device OCR.
2. **Verso** – the back of the card (parents, address, sex…).

When the verso is confirmed, the scanner closes and the extracted data and both card images are handed to your code.
(The package also contains a selfie / blink screen, `FaceController`, but the current scan flow does not present it.)

Both the **new CIN** and the **old CIN** layouts are supported. Everything runs on the device (TensorFlow Lite for
card detection, Google ML Kit for text and face recognition). The scan screens are in English and French and follow
the phone's language.

## Requirements

| | |
| --- | --- |
| iOS | 15.0 or later (ML Kit 9 and Xcode 27 both require it) |
| Xcode / Swift | Xcode 15 or later (Swift tools 5.9); developed with Xcode 27 |
| Distribution | Swift Package Manager only (CocoaPods is no longer used) |
| Device | A real iPhone for scanning; the simulator has no camera, so the scan screens only show their UI there |

## Add the package

NewSDK is a Swift package. Add it by URL:

1. In Xcode choose **File ▸ Add Package Dependencies…** and enter the repository URL
   (`https://github.com/kvikas063/NewSDK`).
2. Dependency rule **Up to Next Major Version** from `1.0.0`, then add the **NewSDK** product to your app target.
3. Do the setup steps below.

In a `Package.swift` of your own:

```swift
.package(url: "https://github.com/kvikas063/NewSDK", from: "1.0.0")
// target dependency:
.product(name: "NewSDK", package: "NewSDK")
```

To use a local checkout instead, choose **Add Local…** and pick the cloned folder.

Dependencies are resolved automatically:

| Dependency | Source |
| --- | --- |
| Google ML Kit 9 (face detection, text recognition) | community package [`google-mlkit-swiftpm`](https://github.com/d-date/google-mlkit-swiftpm) 9.0.2 (Google only publishes ML Kit through CocoaPods) |
| Zip 2.1 | [`marmelroy/Zip`](https://github.com/marmelroy/Zip) |
| TensorFlow Lite 2.17.0 | Swift wrapper vendored in `Vendor/`; Google's official iOS C library is downloaded as a binary target from this repository's GitHub Release |
| PMAlertController 4.0.1 | vendored in `Vendor/` (its upstream repository no longer exists) |

There is **no Firebase dependency**, and ML Kit now uses `GoogleDataTransport` 10.x, so the SDK can live next to
Firebase 12 in a host app. (Verified: a package depending on Firebase 12 and this SDK resolves without conflicts.)

## Setup the host app must do

Swift Package Manager cannot ship these for a binary dependency, so they are manual:

1. **Linker flags** – add `-ObjC` and `-all_load` to *Other Linker Flags* (ML Kit registers its models through static
   initialisers).
2. **ML Kit resource bundles** – add `GoogleMVFaceDetectorResources.bundle` and `LatinOCRResources.bundle` to the app
   target's *Copy Bundle Resources*. They are in this repository, in `MLKitResources/` (download the two folders, or run
   `scripts/download_mlkit_bundles.sh <dir>` from a clone).
3. **Camera permission** – add `NSCameraUsageDescription` to the app's Info.plist (and request camera access before
   presenting the scanner, as the example app does).

4. **Languages** – to get the French texts, the app must declare French as a supported language: add `fr` to the
   project's *Localizations* (or `CFBundleLocalizations` = `en`, `fr` in Info.plist). iOS only offers the languages the
   *app* declares; an app that declares only English always shows the SDK in English, whatever the phone's language.

`NewSDKScanner.missingMLKitResourceBundles()` returns the names of any missing bundle, so the app can show a clear
message instead of crashing inside ML Kit.

## Use it

```swift
import NewSDK

// 1. Make sure ML Kit's model bundles were added to the app.
guard NewSDKScanner.missingMLKitResourceBundles().isEmpty else { /* show an error */ return }

// 2. Create the scanner (new CIN: makeNewCinScanner, old CIN: makeOldCinScanner) and present it.
let scanner = NewSDKScanner.makeNewCinScanner { result in
    guard let result = result else { return }
    print(result.cin ?? "", result.firstName ?? "", result.lastName ?? "")
}
present(scanner, animated: true)
```

The scanner is a full-screen view controller. The closure runs once, after the whole flow has been dismissed, with a
`KycResultViewModel`:

| Property | Content |
| --- | --- |
| `cin` | CIN number |
| `firstName`, `lastName` | Holder's names |
| `birthDate`, `birthCity` | Birth date and place |
| `dateExpire` | Expiry date |
| `gender` | `"M"` or `"F"` |
| `fatherName`, `motherName` | Parents' names |
| `adress` | Address (verso) |
| `rectoImage`, `versoImage` | Pictures of both sides (`UIImage`) |

All properties are optional; a field that could not be read is `nil`.

### Cancel and time-out

Every scanner screen has a **Cancel** button at the top left. Cancelling, a time-out and a camera that cannot be
started do **not** call the closure. After the scanner is dismissed, read the flags on the session holder:

```swift
fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.getIsCancel()      // the user cancelled (or the camera was unavailable)
fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.getTimeOut()       // the scan timed out
```

(The example app does this in `HomeViewController.viewDidAppear`.)

## Migrating from the CocoaPods version

- Remove the `NewSDK` pod and the pods it pulled in; add the package as described above.
- The scan screens now live in the SDK's own resource bundle. Do **not** load `UIStoryboard(name: "Main", bundle: nil)`
  any more; use `NewSDKScanner.makeNewCinScanner` / `makeOldCinScanner`.
- The ML Kit bundles and the linker flags are no longer added by CocoaPods; add them yourself (see above).
- Minimum iOS is 15.0 (it was 11.0).
- `getVideoAccess()` (`RPIGTk10Z6Va7IDsKZCG5N34EDa2yEKA`) now returns `URL?` (it used to crash before the face zip
  existed); `gifImageWithURL` / `gifImageWithName`, the global `matches(for:in:)` and a few unused views were removed, and the helper
  extensions on UIKit / Zip types (`UIDevice.modelName`, `UIImage.gif…`, `Zip.compressFiles`) are no longer public.

## Documentation (DocC)

The API reference and the guides (getting started, host-app setup, reading the result, how a scan works,
localization, troubleshooting) are a DocC catalog in `NewSDK/NewSDK.docc`.

- In Xcode: **Product ▸ Build Documentation** (⌃⇧⌘D) on the package or the app that uses it.
- Prebuilt: open `Docs/NewSDK.doccarchive` in Xcode, or serve the static site in `Docs/NewSDK-html`:
  `python3 -m http.server --directory Docs/NewSDK-html 8000`, then open <http://localhost:8000/documentation/newsdk>.
- Rebuild both with `scripts/build_docs.sh`.

## Repository layout

| Path | Contents |
| --- | --- |
| `Package.swift` | The SDK package |
| `NewSDK/` | SDK sources and resources (storyboard, assets, ML model, translations) |
| `Vendor/` | TensorFlow Lite 2.17.0 (Swift wrapper; the C framework is a release asset) and PMAlertController 4.0.1 |
| `Tests/NewSDKTests/` | Unit tests (71) |
| `Example/` | Example app (`Example/NewSDKExample.xcodeproj`, see `Example/README.md`) |
| `NewSDK/NewSDK.docc/` | DocC catalog (landing page and guides) |
| `Docs/PUBLISHING.md` | Maintainer checklist: how to publish a release |
| `Docs/` | `NewSDK.doccarchive`, `NewSDK-html/` (built documentation) and `SwiftShieldMap.txt` (original ⇄ obfuscated names) |
| `scripts/` | `build_docs.sh` (documentation), `download_mlkit_bundles.sh`, `make_tflite_release_zip.sh` and `set_tflite_url.sh` (maintainers: TensorFlow Lite release asset) |
| `.swift-format` | Formatting rules |
| `MLKitResources/` | The two ML Kit model bundles the host app must add |

### Source layout (`NewSDK/`)

| Folder | Role |
| --- | --- |
| `NewSDK.swift` | Public entry point: `NewSDKScanner` |
| `ViewControllers/` | The scan screens: `ViewController` (old recto), `MainVideoViewController` (old verso), `ViewControllerNewCin` / `ViewControllerNewCinVerso` (new CIN), `FaceController` (selfie / blink screen, not presented by the current flow), and the shared `BaseVC` |
| `CameraFeed/` | Camera session and the views that turn recognised text into card fields (`DrawingView*`) |
| `ModelDataHandler/` | TensorFlow Lite card detector and the video capture helper |
| `Views/` | Alert, loading and selfie-overlay views |
| `Extensions/`, `Common/` | Validation (`Utils`), session state, result model, helpers |
| `Resources/` | `en.lproj` / `fr.lproj` strings |

## Development

```bash
# Unit tests (run against the real library on the simulator)
xcodebuild test -scheme NewSDK -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Format and lint (Apple swift-format, config in .swift-format)
xcrun swift-format format -i -r NewSDK Tests Example Package.swift --configuration .swift-format
xcrun swift-format lint   -r NewSDK Tests Example Package.swift --configuration .swift-format

# Example app (run on a device to scan with the camera)
open Example/NewSDKExample.xcodeproj
```

User-visible messages use short keys of the form `<group>.<name>` (for example `"common.cancel"`,
`"alert.useOriginalCin"`, `"face.hintBlink"`), looked up with `"key".sdkLocalized` and translated in
`NewSDK/Resources/{fr,en}.lproj/NewSDKLocalizable.strings`. To add a message: add the key to both files and use it in
code. Unit tests fail if a key used in code is missing from a table, if a table has an unused key, or if a key is not a
short `<group>.<name>` identifier.

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| Crash when the scanner opens, `MLKTextRecognizerInternalErrorCreationFailure` / "Invalid model path" | The two ML Kit bundles are not in the app's *Copy Bundle Resources* |
| Crash or "unrecognized selector" in ML Kit, or a screen that shows as a plain view | `-ObjC -all_load` missing from *Other Linker Flags* |
| "Framework … did not contain an Info.plist" | Use the release zip built by `scripts/make_tflite_release_zip.sh` (it adds the per-slice `Info.plist` files) |
| The SDK is always in English on a French phone | The host app does not declare French (`CFBundleLocalizations`) |
| Black scan screen and a "Camera unavailable" alert | No camera (simulator) or camera permission denied |
| Linker warning "built for newer iOS-simulator version (15.5)" | Comes from the ML Kit simulator binaries; harmless |

## Known limitations

- ML Kit comes from a community rebuild, not from Google: pin the version and review its releases before upgrading.
- The TensorFlow Lite framework is about 74 MB uncompressed (34 MB download); Xcode fetches it the first time the package is resolved.
- The scan flow has been verified in the simulator (screens, cancel, camera-failure paths) and by unit tests, but it
  still needs a run with real cards on a device; ML Kit 9 may read text slightly differently from the 2021 version.
- Parts of the parsing logic are tuned to the card layouts and have known quirks that were left unchanged because they
  cannot be checked without real cards: the "Fils de" parents block accepts an empty mother reading, the name regex
  accepts commas, and `Utils.jaroWinkler` is a plain Jaro distance (no Winkler boost).

## Identifier names

Many internal and public identifiers (for example `fKrUHvHJknyK3g7L2vSipDnasRUh8RKV`, the scan-session state holder)
were obfuscated with SwiftShield in 2020. They are kept as-is so existing integrations keep working; the doc comments
state each original name, and `Docs/SwiftShieldMap.txt` is the full `original ===> obfuscated` mapping.

## Licenses

- SDK code: MIT, see `LICENSE`.
- Files derived from TensorFlow's example code keep their Apache 2.0 headers; TensorFlow Lite is Apache 2.0
  (`Vendor/TensorFlowLite/LICENSE`).
- PMAlertController is MIT (`Vendor/PMAlertController/LICENSE`).
- Google ML Kit is subject to Google's ML Kit terms.
