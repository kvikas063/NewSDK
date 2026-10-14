import UIKit
import XCTest
import Zip

@testable import NewSDK

/// Tests that exercise the real SDK against its Swift Package resource bundle and third-party
/// libraries (TensorFlow Lite, ML Kit, Zip) — i.e. that the SPM wiring works.
final class SDKResourceAndIntegrationTests: XCTestCase {

    // MARK: Resource bundle

    func testStoryboardInstantiatesEveryScreenWithItsSDKClass() {
        let storyboard = UIStoryboard(name: "Main", bundle: .sdk)
        let expected: [(String, UIViewController.Type)] = [
            ("ViewController", ViewController.self),
            ("ViewControllerNewCin", ViewControllerNewCin.self),
            ("ViewControllerNewCinVerso", ViewControllerNewCinVerso.self),
            ("MainVideoViewController", MainVideoViewController.self),
            ("FaceController", FaceController.self),
        ]
        for (identifier, expectedType) in expected {
            let screen = storyboard.instantiateViewController(withIdentifier: identifier)
            XCTAssertTrue(
                type(of: screen) == expectedType,
                "\(identifier) resolved to \(type(of: screen)) instead of \(expectedType)")
        }
    }

    func testPublicScannerFactories() {
        let newCin = NewSDKScanner.makeNewCinScanner { _ in }
        let oldCin = NewSDKScanner.makeOldCinScanner { _ in }
        XCTAssertTrue(newCin is ViewControllerNewCin)
        XCTAssertTrue(oldCin is ViewController)
        XCTAssertEqual(newCin.modalPresentationStyle, .fullScreen)
        XCTAssertEqual(oldCin.modalPresentationStyle, .fullScreen)
        XCTAssertNotNil((newCin as? BaseVC)?.didScanComplete)
    }

    func testModelAndLabelFilesAreBundled() {
        XCTAssertNotNil(Bundle.sdk.url(forResource: "detect", withExtension: "tflite"))
        XCTAssertNotNil(Bundle.sdk.url(forResource: "labelmap", withExtension: "txt"))
    }

    func testAssetCatalogImagesAndGifLoad() {
        XCTAssertNotNil(UIImage(named: "emosuccess", in: .sdk, compatibleWith: nil))
        XCTAssertNotNil(UIImage.gif(asset: "emoclignement"))
    }

    func testSdkLocalizedReadsFromThePackageBundle() {
        // Depends on the simulator language; either way it must come from the translation table, not the key.
        XCTAssertTrue(["Cancel", "Annuler"].contains("common.cancel".sdkLocalized))
        XCTAssertTrue(
            ["Please use an original CIN card", "Veuillez utiliser une carte CIN originale"]
                .contains("alert.useOriginalCin".sdkLocalized))
    }

    // MARK: TensorFlow Lite

    func testTensorFlowLiteModelLoadsThroughModelDataHandler() {
        let handler = ModelDataHandler(modelFileInfo: MobileNetSSD.modelInfo, labelsFileInfo: MobileNetSSD.labelsInfo)
        XCTAssertNotNil(handler, "detect.tflite could not be loaded by TensorFlow Lite")
    }

    // MARK: ML Kit host requirements

    func testMissingMLKitResourceBundlesAreReported() {
        // The test process has no ML Kit resource bundles, so both must be reported.
        XCTAssertEqual(
            Set(NewSDKScanner.missingMLKitResourceBundles()),
            ["GoogleMVFaceDetectorResources.bundle", "LatinOCRResources.bundle"])
    }

    func testMLKitResourceBundleCheckPassesWhenBundlesExist() throws {
        let fake = FileManager.default.temporaryDirectory.appendingPathComponent("fake-host-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: fake) }
        for name in NewSDKScanner.requiredMLKitResourceBundles {
            try FileManager.default.createDirectory(
                at: fake.appendingPathComponent(name + ".bundle"),
                withIntermediateDirectories: true)
        }
        let bundle = try XCTUnwrap(Bundle(url: fake))
        XCTAssertEqual(NewSDKScanner.missingMLKitResourceBundles(in: bundle), [])
    }

    // MARK: Zip

    func testZipCompressFilesCreatesArchiveInDocuments() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("sdk-zip-test.txt")
        try "hello".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: file) }

        let archive = try Zip.compressFiles([file], fileName: "sdk-zip-test")
        defer { try? FileManager.default.removeItem(at: archive) }

        XCTAssertEqual(archive.lastPathComponent, "sdk-zip-test.zip")
        XCTAssertTrue(FileManager.default.fileExists(atPath: archive.path))
        let size = (try FileManager.default.attributesOfItem(atPath: archive.path)[.size] as? Int) ?? 0
        XCTAssertGreaterThan(size, 0)
    }
}
