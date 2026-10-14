import UIKit

/// Public entry points of the SDK.
///
/// ```swift
/// let scanner = NewSDKScanner.makeNewCinScanner { result in
///     // `result` is a `KycResultViewModel` (nil if the flow produced nothing)
/// }
/// present(scanner, animated: true)
/// ```
///
/// The scan screens live in the SDK's own resource bundle, so host apps must use these
/// factories instead of loading a storyboard themselves. Cancellation and time-out do not call the
/// completion handler; read `fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.getIsCancel()` / `getTimeOut()` instead.
///
/// Host app requirements (Swift Package Manager cannot ship these for you):
/// - Other Linker Flags: `-ObjC -all_load` (ML Kit registers its models through static initialisers).
/// - Add `GoogleMVFaceDetectorResources.bundle` and `LatinOCRResources.bundle` to *Copy Bundle Resources*
///   (`scripts/download_mlkit_bundles.sh` downloads them).
/// - `NSCameraUsageDescription` in Info.plist.
public enum NewSDKScanner {

    /// ML Kit model bundles that must be in the host app's main bundle.
    static let requiredMLKitResourceBundles = ["GoogleMVFaceDetectorResources", "LatinOCRResources"]

    /// Names of the required ML Kit resource bundles that are missing from `bundle` (empty = all present).
    /// Call this before presenting a scanner to show a clear error instead of crashing inside ML Kit.
    ///
    /// - Parameter bundle: The bundle expected to contain the ML Kit resource bundles (the app's main bundle by default).
    /// - Returns: The file names (with the `.bundle` extension) of the missing resource bundles.
    public static func missingMLKitResourceBundles(in bundle: Bundle = .main) -> [String] {
        requiredMLKitResourceBundles
            .filter { bundle.path(forResource: $0, ofType: "bundle") == nil }
            .map { $0 + ".bundle" }
    }

    /// Scanner for the new CIN card (recto, verso, then face video).
    ///
    /// - Parameter didScanComplete: Called with the scan result once the flow finishes.
    /// - Returns: A full-screen view controller to present from the host app.
    public static func makeNewCinScanner(didScanComplete: @escaping (KycResultViewModel?) -> Void) -> UIViewController {
        makeScanner(storyboardID: "ViewControllerNewCin", didScanComplete: didScanComplete)
    }

    /// Scanner for the old CIN card (recto, verso, then face video).
    ///
    /// - Parameter didScanComplete: Called with the scan result once the flow finishes.
    /// - Returns: A full-screen view controller to present from the host app.
    public static func makeOldCinScanner(didScanComplete: @escaping (KycResultViewModel?) -> Void) -> UIViewController {
        makeScanner(storyboardID: "ViewController", didScanComplete: didScanComplete)
    }

    /// Instantiates a scan screen from the SDK's `Main` storyboard and configures it for presentation.
    ///
    /// Logs a warning (it does not fail) when the ML Kit resource bundles are missing from the host app.
    ///
    /// - Parameters:
    ///   - storyboardID: Storyboard identifier of the scan screen to instantiate.
    ///   - didScanComplete: Called with the scan result once the flow finishes.
    /// - Returns: A full-screen scan view controller, ready to be presented.
    private static func makeScanner(
        storyboardID: String,
        didScanComplete: @escaping (KycResultViewModel?) -> Void
    ) -> UIViewController {
        let missing = missingMLKitResourceBundles()
        if !missing.isEmpty {
            NSLog(
                "NewSDK: add %@ to the app's Copy Bundle Resources (see scripts/download_mlkit_bundles.sh); "
                    + "ML Kit cannot load its models without them.", missing.joined(separator: ", "))
        }
        let storyboard = UIStoryboard(name: "Main", bundle: .sdk)
        // swiftlint:disable:next force_cast
        let scanner = storyboard.instantiateViewController(withIdentifier: storyboardID) as! BaseVC
        scanner.didScanComplete = didScanComplete
        scanner.modalPresentationStyle = .fullScreen
        return scanner
    }
}
