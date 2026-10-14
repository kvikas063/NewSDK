import CoreImage
import CoreMedia
import MLKitTextRecognition
import MLKitVision
import UIKit

/// Verso (back) scanning screen of the old-CIN flow, presented after ``ViewController`` (recto).
///
/// Camera frames are recognised on-device with ML Kit text recognition and analysed by
/// `DrawingView` (`lU2YDSwO...`); once all expected fields have been found the verso image is stored
/// in the session and a ``CustomAlert`` lets the user finish. Confirming builds a
/// ``KycResultViewModel`` and returns it through `didScanComplete` after dismissing the whole flow.
public class MainVideoViewController: BaseVC {

    // MARK: - UI Properties

    /// Container in which the camera preview layer is shown.
    @IBOutlet weak var videoPreview: UIView!

    /// "VERSO" caption, rotated by 90° in `viewDidLoad()`.
    @IBOutlet weak var label: UILabel!

    /// View (`DrawingView`) that analyses the recognised text and highlights the matched fields.
    @IBOutlet weak var drawingView: lU2YDSwONUtfxobLtCD8q5d8c31YE09r!

    /// Scan bar animated by ``BaseVC/startScanBarAnimation(_:)``.
    @IBOutlet weak var upDown: Shadow!

    /// Time (ms) to wait after the camera started before the first frame is analysed.
    private let delayBetweenInferencesMs: Double = 2500

    /// Timestamp (ms since 1970) at which the camera was started.
    private var startTimeMs: Double!

    // MARK: - ML Kit Vision Property

    /// ML Kit on-device text recognizer.
    lazy var textRecognizer = TextRecognizer.textRecognizer(options: TextRecognizerOptions())

    /// Written from the camera queue and the main thread, hence atomic.
    private let inferenceFlag = AtomicFlag()

    /// `true` while a frame is being recognised, so that frames arriving meanwhile are dropped.
    var isInference: Bool {
        get { inferenceFlag.value }
        set { inferenceFlag.value = newValue }
    }

    // MARK: - AV Property

    /// Camera capture wrapper delivering frames to `KNiUazUE6x9Mux2PXav7mgjbUbGFuj18(_:didCaptureVideoFrame:timestamp:)`.
    var videoCapture: VideoCapture!

    // MARK: - View lifecycle

    /// Sets up the camera, adds the cancel button and resets the cancel flag.
    public override func viewDidLoad() {
        super.viewDidLoad()

        setUpCamera()

        label?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        label?.text = "scan.verso".sdkLocalized.uppercased()

        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isCancel = false

        addScannerCancelButton()
    }

    /// Starts the scan-bar animation and the camera.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        startScanBarAnimation(upDown)

        self.videoCapture.start()

    }

    /// Stops the camera.
    ///
    /// - Parameter animated: Whether the disappearance is animated.
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCapture.stop()
    }

    /// Makes the preview layer follow the layout.
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }

    // MARK: - SetUp Video

    /// Creates the `VideoCapture`, adds its preview layer to `videoPreview` and starts it.
    ///
    /// If the camera cannot be started the user is told through ``BaseVC/presentCameraUnavailableAlert()``.
    func setUpCamera() {

        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 30
        videoCapture.setUp(sessionPreset: .inputPriority) { success in

            if success {
                // add preview view on the layer
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }

                // start video preview when setup is done
                self.videoCapture.start()

                self.startTimeMs = Date().timeIntervalSince1970 * 1000
            } else {
                self.presentCameraUnavailableAlert()
            }
        }
    }

    /// Makes the preview layer fill `videoPreview`.
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
}

// MARK: - VideoCaptureDelegate

extension MainVideoViewController: VideoCaptureDelegate {

    /// `videoCapture(_:didCaptureVideoFrame:timestamp:)`: receives each camera frame and, once the
    /// initial delay has elapsed and no recognition is running, starts recognising it.
    ///
    /// - Parameters:
    ///   - capture: The capture object delivering the frame.
    ///   - pixelBuffer: The captured frame, if any.
    ///   - timestamp: The presentation time of the frame.
    public func KNiUazUE6x9Mux2PXav7mgjbUbGFuj18(
        _ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime
    ) {

        let currentTimeMs = Date().timeIntervalSince1970 * 1000
        guard (currentTimeMs - startTimeMs) >= delayBetweenInferencesMs else {
            return
        }

        // the captured image from camera is contained on pixelBuffer
        if let pixelBuffer = pixelBuffer, self.inferenceFlag.testAndSet() {
            self.predictUsingVision(pixelBuffer: pixelBuffer)
        }
    }
}

// MARK: - Text recognition

extension MainVideoViewController {

    /// Runs ML Kit text recognition on a camera frame and hands the result to `drawingView`.
    ///
    /// When the drawing view reports that all verso fields were found, the frame is stored as the
    /// verso image (`imageCINVer`), the camera is stopped and the verso confirmation alert is shown.
    /// `isInference` is reset when the recognition completes.
    ///
    /// - Parameter pixelBuffer: The camera frame to analyse.
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        let ciimage: CIImage = CIImage(cvImageBuffer: pixelBuffer)
        let ciContext = CIContext()
        guard let cgImage: CGImage = ciContext.createCGImage(ciimage, from: ciimage.extent) else {
            self.isInference = false
            return
        }
        let uiImage: UIImage = UIImage(cgImage: cgImage)
        let visionImage = VisionImage(image: uiImage)
        textRecognizer.process(visionImage) { (features, error) in

            // this closure is called on main thread
            if error == nil, let features = features {
                self.drawingView.imageSize = uiImage.size
                self.drawingView.visionText = features
                if self.drawingView.resulat && self.drawingView.resulatSex && self.drawingView.resulatSonOF
                    && self.drawingView.resulatCin && self.drawingView.resulatSonOF2
                {

                    self.drawingView.resulat = false

                    let imageInit = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))

                    // `yy3ZfLPA...` = `imageCINVer`: the verso image.
                    fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.yy3ZfLPAkInlRLrv0BbNDQ4fhrwgciEd = imageInit

                    self.videoCapture.stop()

                    self.upDown.isHidden = true

                    self.initCustomAlert(delegate: self, typeAlert: .verso)
                }
            } else {
                self.drawingView.imageSize = .zero
                self.drawingView.visionText = nil
            }

            self.isInference = false

        }
    }

}

// MARK: - CustomAlertDelegate / ScannerCancellable

extension MainVideoViewController: CustomAlertDelegate, ScannerCancellable {

    /// Stops the camera.
    func stopScanning() {
        videoCapture.stop()
    }

    /// The user cancelled: dismisses the whole flow (verso and recto screens) and flags the cancellation.
    func cancel() {
        dismissScanFlow(animated: true)
        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isCancel = true

    }

    /// The user confirmed the verso: builds the CIN result, dismisses the whole flow and
    /// delivers the result through `didScanComplete`.
    func confirm() {

        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isCancelRecto = true
        let result = KycResultViewModel()
        result.prepareCinInfo()
        let completion = didScanComplete
        dismissScanFlow(animated: false) {
            completion?(result)
        }

    }

}
