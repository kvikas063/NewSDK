# Reading the result

What the completion closure receives, and how to detect a cancelled or timed-out scan.

## Overview

When the whole flow (recto, then verso) succeeds, the scanner is dismissed and the closure passed to
``NewSDKScanner`` is called once with a ``KycResultViewModel``:

| Property | Content |
| --- | --- |
| ``KycResultViewModel/cin`` | CIN number |
| ``KycResultViewModel/firstName``, ``KycResultViewModel/lastName`` | Holder's names |
| ``KycResultViewModel/birthDate``, ``KycResultViewModel/birthCity`` | Birth date and place |
| ``KycResultViewModel/dateExpire`` | Expiry date |
| ``KycResultViewModel/gender`` | `"M"` or `"F"` |
| ``KycResultViewModel/fatherName``, ``KycResultViewModel/motherName`` | Parents' names |
| ``KycResultViewModel/adress`` | Address (verso) |
| ``KycResultViewModel/rectoImage``, ``KycResultViewModel/versoImage`` | Pictures of both sides |

Every property is optional; a field that could not be read is `nil`.

## Cancel, time-out and camera failures

Every scanner screen has a **Cancel** button at the top left. Cancelling, a time-out and a camera that cannot be
started do **not** call the closure. After the scanner has been dismissed, read the flags on the session state holder
``fKrUHvHJknyK3g7L2vSipDnasRUh8RKV``:

```swift
fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.getIsCancel()   // the user cancelled, or the camera was unavailable
fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.getTimeOut()    // the scan timed out
```

The example app does this in `HomeViewController.viewDidAppear(_:)`.

> Note: Names such as `fKrUHvHJknyK3g7L2vSipDnasRUh8RKV` were obfuscated with SwiftShield in 2020. They are kept so
> existing integrations keep working; `Docs/SwiftShieldMap.txt` maps every obfuscated name back to its original.
