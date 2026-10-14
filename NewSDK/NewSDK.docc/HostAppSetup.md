# Host app setup

Four manual steps the app must do, because Swift Package Manager cannot ship them for a binary dependency.

## Overview

### 1. Linker flags

Add `-ObjC` and `-all_load` to the app target's **Other Linker Flags**. ML Kit registers its models through static
initialisers, which the linker would otherwise drop.

### 2. ML Kit resource bundles

Add `GoogleMVFaceDetectorResources.bundle` and `LatinOCRResources.bundle` to the app target's **Copy Bundle Resources**.
They are in the repository, in `MLKitResources/`. `scripts/download_mlkit_bundles.sh <folder>` downloads them
again.

``NewSDKScanner/missingMLKitResourceBundles(in:)`` returns the names of any bundle that is missing, so the app can show
a message instead of crashing inside ML Kit.

### 3. Camera permission

Add `NSCameraUsageDescription` to the app's Info.plist and request camera access before presenting the scanner.

### 4. Languages

Declare French as a supported language so the SDK's French texts are used: add `fr` to the project's **Localizations**
(or set `CFBundleLocalizations` to `en` and `fr` in Info.plist). iOS only offers the languages the *app* declares, so an
app that declares only English always shows the SDK in English. See <doc:Localization>.
