import CoreVideo
import XCTest

@testable import NewSDK

/// Regression tests for crashes and leaks that used to exist: scanner dismissal, overlay redraws, delegate
/// retain cycles and unsupported camera pixel formats.
final class RobustnessTests: XCTestCase {

    // MARK: Dismissing the scan flow

    /// A bare scanner screen whose presenter can be stubbed (`BaseVC` has no storyboard dependencies).
    private final class FakeScreen: BaseVC {
        var stubbedPresenter: UIViewController?
        override var presentingViewController: UIViewController? { stubbedPresenter }
    }

    func testScanFlowPresenterIsTheHostWhateverScreenAsks() {
        let host = UIViewController()
        let recto = FakeScreen()
        let verso = FakeScreen()
        recto.stubbedPresenter = host
        verso.stubbedPresenter = recto

        XCTAssertTrue(recto.scanFlowPresenter === host)
        XCTAssertTrue(verso.scanFlowPresenter === host, "the verso must dismiss from the host, not from the recto")
    }

    func testScanFlowPresenterHandlesLongerChains() {
        let host = UIViewController()
        let first = FakeScreen()
        let second = FakeScreen()
        let third = FakeScreen()
        first.stubbedPresenter = host
        second.stubbedPresenter = first
        third.stubbedPresenter = second
        XCTAssertTrue(third.scanFlowPresenter === host)
    }

    func testScanFlowPresenterIsNilWhenNotPresented() {
        XCTAssertNil(FakeScreen().scanFlowPresenter)
    }

    // MARK: Views

    func testFaceViewRedrawDoesNotStackLayers() {
        let view = FaceView(rect: CGRect(x: 40, y: 80, width: 200, height: 260))
        view.draw(view.bounds)
        view.draw(view.bounds)
        view.draw(view.bounds)
        XCTAssertEqual(view.layer.sublayers?.count, 2)
    }

    private final class StubDelegate: FaceDetectionDelegate {
        func closeCamera() {}
    }

    func testFaceDetectionViewDoesNotRetainItsDelegate() {
        var delegate: StubDelegate? = StubDelegate()
        let view = FaceDetectionView(frame: CGRect(x: 0, y: 0, width: 300, height: 600), delegate: delegate!)
        XCTAssertNotNil(view.delegate)
        delegate = nil
        XCTAssertNil(view.delegate, "the delegate must be held weakly (the owning controller also holds the view)")
    }

    /// Starting the overlay adds the rotation / stroke animations to layers; Core Animation copies them through
    /// `init()`, which used to trap ("unimplemented initializer").
    func testFaceDetectionViewAnimationsCanBeStartedAndHintsChanged() {
        let delegate = StubDelegate()
        let view = FaceDetectionView(frame: CGRect(x: 0, y: 0, width: 300, height: 600), delegate: delegate)
        view.startAnimation()
        view.updateAssistanceMsg(.facePositioning)
        view.updateAssistanceMsg(.blink)
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        withExtendedLifetime(delegate) {}
    }

    // MARK: Pixel buffers

    private func makePixelBuffer(format: OSType, width: Int = 8, height: Int = 8) throws -> CVPixelBuffer {
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(nil, width, height, format, nil, &buffer)
        XCTAssertEqual(status, kCVReturnSuccess)
        return try XCTUnwrap(buffer)
    }

    func testResizeReturnsNilForUnsupportedPixelFormatInsteadOfAsserting() throws {
        let rgba = try makePixelBuffer(format: kCVPixelFormatType_24RGB)
        XCTAssertNil(rgba.GQ6vhImkYfaK9QUjzGk8mIxddotjfFaR(to: CGSize(width: 4, height: 4)))
    }

    func testResizeScalesBGRABuffers() throws {
        let bgra = try makePixelBuffer(format: kCVPixelFormatType_32BGRA, width: 16, height: 12)
        let scaled = try XCTUnwrap(bgra.GQ6vhImkYfaK9QUjzGk8mIxddotjfFaR(to: CGSize(width: 4, height: 6)))
        XCTAssertEqual(CVPixelBufferGetWidth(scaled), 4)
        XCTAssertEqual(CVPixelBufferGetHeight(scaled), 6)
    }

    func testRunModelRejectsUnsupportedPixelFormat() throws {
        let handler = try XCTUnwrap(
            ModelDataHandler(modelFileInfo: MobileNetSSD.modelInfo, labelsFileInfo: MobileNetSSD.labelsInfo))
        let rgba = try makePixelBuffer(format: kCVPixelFormatType_24RGB)
        XCTAssertNil(handler.runModel(onFrame: rgba))
    }

    func testRunModelOnABlankBGRAFrameFindsNoCard() throws {
        let handler = try XCTUnwrap(
            ModelDataHandler(modelFileInfo: MobileNetSSD.modelInfo, labelsFileInfo: MobileNetSSD.labelsInfo))
        let frame = try makePixelBuffer(format: kCVPixelFormatType_32BGRA, width: 640, height: 480)
        let result = try XCTUnwrap(handler.runModel(onFrame: frame))
        XCTAssertEqual(result.myArray2, ["", "", "", "", "", ""], "a blank frame must not produce any field")
    }
}
