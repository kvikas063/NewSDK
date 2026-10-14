# TensorFlow Lite 2.17.0 (vendored)

- `Sources/` – the Swift wrapper (`Interpreter`, `Tensor`, …) from the TensorFlow 2.17.0 release (Apache 2.0, see `LICENSE`).
- `TensorFlowLiteC.xcframework` – Google's official iOS C library. It is **not stored in git** (about 74 MB): `Package.swift`
  downloads it as a binary target from this repository's GitHub Release `tflite-2.17.0`.

To rebuild the release asset run `scripts/make_tflite_release_zip.sh` (it downloads Google's archive, adds the per-slice
`Info.plist` files SwiftPM requires, zips it and prints the checksum for `Package.swift`).
