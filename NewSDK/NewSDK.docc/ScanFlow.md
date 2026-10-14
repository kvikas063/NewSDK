# How a scan works

The screens that make up a scan, and how they hand over to each other.

## Overview

``NewSDKScanner`` creates the first screen of the flow and gives it your completion closure. Each screen passes the
closure on to the next one, so it is called once, at the very end.

**New CIN**

1. ``ViewControllerNewCin`` – the front. The camera frames are analysed with ML Kit text recognition; the card fields
   are parsed from the recognised text blocks.
2. ``ViewControllerNewCinVerso`` – the back. When the user confirms, the flow ends and the result is delivered.

**Old CIN**

1. ``ViewController`` – the front. A TensorFlow Lite detector finds the six field regions on the card; each region is
   cropped and read with ML Kit.
2. ``MainVideoViewController`` – the back. When the user confirms, the flow ends and the result is delivered.

> Note: The package also contains a selfie / blink screen (`FaceController` with ``FaceDetectionView``), but the
> current flow does not present it.

All scanner screens derive from ``BaseVC``, which provides the Cancel button, the scan-bar animation, the alert
helpers and `dismissScanFlow(animated:completion:)`. Dismissing the flow always closes every stacked scanner
screen, whichever screen the user is on.

### Camera frames

Frames are delivered on a background queue by ``VideoCapture`` (or, for the old CIN front, by the camera feed manager).
A thread-safe flag makes sure only one frame at a time is being recognised; the rest are dropped.

### Time-outs

The recto screens time out after about 27 seconds (90 seconds on iPhone 6 / 7 class devices) and the new CIN verso
after 27 seconds; the old CIN verso has no time-out. The new CIN front also asks the user to use an original card when
no valid card has been recognised after 7 seconds.
