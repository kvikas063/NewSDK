import CoreImage
import CoreMedia
import MLKitTextRecognition
import MLKitVision
import UIKit

/// Second screen of the new-CIN flow: scans the verso (back) of the card with ML Kit text recognition.
///
/// Camera frames are recognised on-device and analysed by `DrawingViewNewCinVerso`; once the
/// expected fields have been found the verso image is stored in the session and a ``CustomAlert``
/// lets the user finish. Confirming builds a ``KycResultViewModel`` and returns it through
/// `didScanComplete` after dismissing the whole flow.
public class ViewControllerNewCinVerso: BaseVC {

    // MARK: - UI Properties

    /// Container in which the camera preview layer is shown.
    @IBOutlet weak var videoPreview: UIView!

    /// "Verso" caption, rotated by 90° in `viewDidLoad()`.
    @IBOutlet weak var label: UILabel!

    /// View that analyses the recognised text and highlights the matched fields.
    @IBOutlet weak var drawingView: DrawingViewNewCinVerso!

    /// Scan bar animated by ``BaseVC/startScanBarAnimation(_:)``.
    @IBOutlet weak var upDown: Shadow!

    // MARK: - Timers

    /// One-second timer driving `onTimeOut()`; invalidated by `stopTimeoutTimer()`.
    var timer3: Timer?

    /// Seconds remaining before the scan times out; decremented by `onTimeOut()`.
    var timerOut = 27

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

    /// Set once the verso has been captured, so late frames / the timeout cannot trigger a second result.
    private let scanFinishedFlag = AtomicFlag()

    /// Whether the verso has already been captured.
    private var scanFinished: Bool { scanFinishedFlag.value }

    // MARK: - AV Property

    /// Camera capture wrapper delivering frames to `KNiUazUE6x9Mux2PXav7mgjbUbGFuj18(_:didCaptureVideoFrame:timestamp:)`.
    var videoCapture: VideoCapture!

    // MARK: - View lifecycle

    /// Sets up the camera, starts the timeout timer, adds the cancel button and resets the cancel flag.
    public override func viewDidLoad() {
        super.viewDidLoad()

        setUpCamera()

        timer3 = Timer.scheduledTimer(
            timeInterval: 1.0, target: self, selector: #selector(onTimeOut), userInfo: nil, repeats: true)

        label?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        label?.text = "scan.verso".sdkLocalized

        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isCancel = false

        addScannerCancelButton()
    }

    /// Starts the camera and the scan-bar animation.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.videoCapture.start()

        startScanBarAnimation(upDown)

    }

    /// Stops the camera.
    ///
    /// - Parameter animated: Whether the disappearance is animated.
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCapture.stop()
    }

    /// Releases the timeout timer so that it never outlives the screen.
    ///
    /// - Parameter animated: Whether the disappearance is animated.
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // The timeout timer retains `self`; make sure it never outlives the screen.
        stopTimeoutTimer()
    }

    /// Makes the preview layer follow the layout.
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }

    // MARK: - Timeout

    /// Invalidates and releases the timeout timer.
    private func stopTimeoutTimer() {
        timer3?.invalidate()
        timer3 = nil
    }

    /// Timer tick (once per second): when `timerOut` reaches zero the timer is stopped and, unless the
    /// scan already succeeded, the timeout alert is shown.
    @objc func onTimeOut() {

        timerOut -= 1

        if timerOut == 0 {

            stopTimeoutTimer()

            // A scan that already succeeded must not be turned into a timeout / cancel.
            guard !scanFinished else { return }

            presentVideoConfigurationErrorAlertFirst()
        }

    }

    /// Tells the user the scan timed out, flags the cancellation and, when "OK" is tapped,
    /// dismisses the whole flow (verso and recto screens).
    func presentVideoConfigurationErrorAlertFirst() {

        let alertController = UIAlertController(
            title: "alert.sessionTimeout".sdkLocalized,
            message: "alert.avoidReflections".sdkLocalized, preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: "common.ok".sdkLocalized, style: .cancel,
            handler: { _ in
                self.dismissScanFlow(animated: true)
            })
        alertController.addAction(okAction)

        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isCancel = true
        present(alertController, animated: true, completion: nil)

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

extension ViewControllerNewCinVerso: VideoCaptureDelegate {

    /// `videoCapture(_:didCaptureVideoFrame:timestamp:)`: receives each camera frame and, unless the
    /// scan has finished, once the initial delay has elapsed and no recognition is running,
    /// starts recognising it.
    ///
    /// - Parameters:
    ///   - capture: The capture object delivering the frame.
    ///   - pixelBuffer: The captured frame, if any.
    ///   - timestamp: The presentation time of the frame.
    public func KNiUazUE6x9Mux2PXav7mgjbUbGFuj18(
        _ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime
    ) {

        let currentTimeMs = Date().timeIntervalSince1970 * 1000
        guard !scanFinished, (currentTimeMs - startTimeMs) >= delayBetweenInferencesMs else {
            return
        }

        // the captured image from camera is contained on pixelBuffer
        if let pixelBuffer = pixelBuffer, self.inferenceFlag.testAndSet() {
            self.predictUsingVision(pixelBuffer: pixelBuffer)
        }
    }
}

// MARK: - Text recognition

extension ViewControllerNewCinVerso {

    /// Runs ML Kit text recognition on a camera frame and hands the result to `drawingView`.
    ///
    /// When the drawing view reports that all verso fields were found (and no other result was
    /// already produced), the frame is stored as the verso image (`imageCINVer`), the camera and
    /// timer are stopped and the verso confirmation alert is shown.
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
                if self.drawingView.resulatSonOF && self.drawingView.resulat && self.drawingView.resulatSonOF2
                    && self.scanFinishedFlag.testAndSet()
                {

                    self.stopTimeoutTimer()
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

extension ViewControllerNewCinVerso: CustomAlertDelegate, ScannerCancellable {

    /// Stops the camera.
    func stopScanning() {
        videoCapture.stop()
    }

    /// The user cancelled: stops the timer, flags the cancellation and dismisses the whole flow.
    func cancel() {
        stopTimeoutTimer()
        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isCancel = true
        // Close the whole flow (verso + recto), like the timeout path and the old-CIN verso do.
        // Dismissing only this screen would leave the user on the already-finished recto screen.
        dismissScanFlow(animated: true)
    }

    /// The user confirmed the verso: builds the CIN result, dismisses the whole flow and
    /// delivers the result through `didScanComplete`.
    func confirm() {
        stopTimeoutTimer()
        let result = KycResultViewModel()
        result.prepareCinInfo()
        let completion = didScanComplete
        dismissScanFlow(animated: false) {
            completion?(result)
        }
    }

}
