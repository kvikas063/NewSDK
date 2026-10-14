# Localization

The SDK is localized in English and French and follows the language of the host app.

## Overview

All messages use short keys of the form `<group>.<name>`, for example `common.cancel`, `alert.useOriginalCin` or
`face.hintBlink`. They are looked up with `"key".sdkLocalized` and translated in
`NewSDK/Resources/en.lproj/NewSDKLocalizable.strings` and `fr.lproj/NewSDKLocalizable.strings` (inside the SDK's own
resource bundle). A language other than French falls back to English.

### Changing the language

The SDK has no language setting of its own; it uses the language of the host app:

- On the device: *Settings ▸ General ▸ Language & Region*, or *Settings ▸ [your app] ▸ Language* to change one app.
- The host app must declare the language: add `fr` to the project's **Localizations** or `CFBundleLocalizations` in
  Info.plist. Without it the SDK stays in English on a French phone.
- When testing: *Edit Scheme ▸ Run ▸ Options ▸ App Language*, or launch with
  `-AppleLanguages "(fr)" -AppleLocale fr_FR`.

### Adding or changing a message

Add the key to both `.strings` files and use `"group.name".sdkLocalized` in code. Unit tests fail if a key used in
code is missing from a table, if a table has an unused key, or if a key is not a short `<group>.<name>` identifier.
