# Getting started

Add the package, complete the host-app setup, and present a scanner.

## Add the package

NewSDK is a Swift package. Add it by URL:

1. In Xcode choose **File ▸ Add Package Dependencies…** and enter the repository URL.
2. Use the dependency rule **Up to Next Major Version** from `1.0.0` and add the `NewSDK` product to your app target.
   The first time, Xcode needs internet to fetch Google ML Kit, Zip and the TensorFlow Lite framework.
3. Complete <doc:HostAppSetup>.

To use a local checkout instead, choose **Add Local…** and pick the cloned folder.

The package resolves these dependencies for you:

| Dependency | Source |
| --- | --- |
| Google ML Kit 9 (face detection, text recognition) | the community package `google-mlkit-swiftpm` 9.0.2 |
| Zip 2.1 | `marmelroy/Zip` |
| TensorFlow Lite 2.17.0 | Swift wrapper vendored in the package (`Vendor/`); the C library is downloaded as a binary target |
| PMAlertController 4.0.1 | vendored in the package (`Vendor/`) |

## Present a scanner

Check the ML Kit resources, then create the scanner with ``NewSDKScanner`` and present it:

```swift
import NewSDK

guard NewSDKScanner.missingMLKitResourceBundles().isEmpty else {
    // Show an error: the ML Kit model bundles were not added to the app.
    return
}

let scanner = NewSDKScanner.makeNewCinScanner { result in      // or makeOldCinScanner
    guard let result else { return }
    print(result.cin ?? "", result.firstName ?? "", result.lastName ?? "")
}
present(scanner, animated: true)
```

The scanner is already configured to be presented full screen. Request camera access before presenting it, as the
example app does.

> Important: The closure is called only when a scan completes. Cancelling, a time-out and a camera that cannot be
> started do not call it; see <doc:ReadingTheResult>.

## Try the example app

`Example/NewSDKExample.xcodeproj` is a complete host app. Run it on a device to scan with the camera; the simulator
has no camera, so it only shows the scan screens.
