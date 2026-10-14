# NewSDK Example

Minimal host app showing how to use NewSDK (Swift Package) to scan a Moroccan CIN and read the result.

## Run

1. Open `NewSDKExample.xcodeproj` (it references the SDK package at `..`; packages resolve automatically).
2. Select the **NewSDKExample** scheme, a simulator or an iPhone (iOS 15+) and Run. Set your signing team for a device.
   The simulator has no camera, so the scan screens only show their UI there; use a device to scan a card.

## What the app target is set up with (see the root README)

- Other Linker Flags `-ObjC -all_load`
- `GoogleMVFaceDetectorResources.bundle` and `LatinOCRResources.bundle` (in the repository's `MLKitResources/`) in Copy Bundle Resources
- `NSCameraUsageDescription` in `Info.plist`
- `CFBundleLocalizations` = `en`, `fr` in `Info.plist` (so the SDK's French texts are used on a French phone)

## Integration code (`HomeViewController.swift`)

1. `NewSDKScanner.missingMLKitResourceBundles()` – bail out with a clear message if the ML Kit bundles are missing.
2. Request camera access.
3. `NewSDKScanner.makeNewCinScanner { result in … }` (or `makeOldCinScanner`) and present it.
4. The closure receives a `KycResultViewModel`; cancel/time-out do not call it – check
   `fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.getIsCancel()` / `getTimeOut()` (done in `viewDidAppear`).
