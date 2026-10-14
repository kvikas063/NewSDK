# Publishing checklist (maintainers)

1. **Build the TensorFlow Lite release asset**

   ```bash
   scripts/make_tflite_release_zip.sh
   ```

   It writes `dist/TensorFlowLiteC.xcframework.zip` (about 34 MB) and prints its checksum.

2. **Point `Package.swift` at your repository**

   ```bash
   scripts/set_tflite_url.sh <github-user> <repository>
   ```

   This replaces the `<GITHUB_USER>/<REPO>` placeholders in `Package.swift` and writes the checksum.
   Also replace `<GITHUB_USER>/<REPO>` in `README.md`.

3. **Create the public GitHub repository** (no README / license, the repository already has them), then push:

   ```bash
   git add -A && git commit -m "NewSDK 1.0.0"
   git remote add origin https://github.com/<github-user>/<repository>.git
   git push -u origin main
   ```

4. **Create the release that hosts the framework.** On GitHub: *Releases ▸ Draft a new release*, tag `tflite-2.17.0`,
   attach `dist/TensorFlowLiteC.xcframework.zip`, publish. (The tag must exist before anyone resolves the package.)

5. **Tag the SDK version**

   ```bash
   git tag 1.0.0 && git push origin 1.0.0
   ```

6. **Verify like a customer**: in a new Xcode app use *Add Package Dependencies…* with the repository URL, add the
   `NewSDK` product, do the host-app setup from the README and run a scan.

Updating TensorFlow Lite later: change `VERSION` / `URL` in `scripts/make_tflite_release_zip.sh`, build a new zip, publish it under a
new release tag (for example `tflite-2.18.0`) and update the URL tag and checksum in `Package.swift`.
