# ``NewSDK``

Scan a Moroccan national ID card (CIN) on the device and get the extracted identity data back.

## Overview

NewSDK presents a ready-made, full-screen scanner. A scan has two steps:

1. **Recto** – the front of the card is detected and its fields are read with on-device OCR.
2. **Verso** – the back of the card (parents, address, sex…).

When the verso is confirmed, the scanner closes and the data and both card images are handed to your code.

The new CIN and the old CIN layouts are both supported. Card detection runs with TensorFlow Lite and text and face
recognition with Google ML Kit, all on the device. The screens are localized in English and French.

```swift
import NewSDK

let scanner = NewSDKScanner.makeNewCinScanner { result in
    guard let result else { return }
    print(result.cin ?? "", result.firstName ?? "", result.lastName ?? "")
}
present(scanner, animated: true)
```

The SDK is a Swift package for iOS 15 and later. It has no Firebase dependency.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:HostAppSetup>
- ``NewSDKScanner``

### Reading the outcome

- <doc:ReadingTheResult>
- ``KycResultViewModel``
- ``CinType``

### How a scan works

- <doc:ScanFlow>
- ``BaseVC``
- ``ViewControllerNewCin``
- ``ViewControllerNewCinVerso``
- ``ViewController``
- ``MainVideoViewController``

### Localization and troubleshooting

- <doc:Localization>
- <doc:Troubleshooting>

### Scan session state

- ``fKrUHvHJknyK3g7L2vSipDnasRUh8RKV``

### Device, enums and helpers

- ``DeviceModel``
- ``SelfieAssistance``
- ``Utils``
- ``VideoCapture``
- ``VideoCaptureDelegate``
- ``FaceDetectionView``
- ``CustomAlert``
- ``GradientBtn``
