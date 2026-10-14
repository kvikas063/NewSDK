import CoreImage
import CoreMedia
import MLKitTextRecognition
import MLKitVision
import UIKit

/// First screen of the new-CIN flow: scans the recto (front) of the card with ML Kit text recognition.
///
/// Camera frames are recognised on-device and analysed by `DrawingViewNewCin`; once the card number,
/// last name and first name have been found the recto image is stored in the session and a
/// ``CustomAlert`` lets the user continue with ``ViewControllerNewCinVerso``.
/// Two timers abort the scan: after 7 seconds if no valid new-CIN marker was seen, and at `timeOut`.
public class ViewControllerNewCin: BaseVC {

    // MARK: - UI Properties

    /// Container in which the camera preview layer is shown.
    @IBOutlet weak var videoPreview: UIView!

    /// "Recto" caption, rotated by 90° in `viewDidLoad()`.
    @IBOutlet weak var label: UILabel!

    /// View that analyses the recognised text and highlights the matched fields.
    @IBOutlet weak var drawingView: DrawingViewNewCin!

    /// Scan bar animated by ``BaseVC/startScanBarAnimation(_:)``.
    @IBOutlet weak var upDown: Shadow!

    /// One-second timer driving the scan timeouts.
    var timer: Timer?

    /// Number of seconds elapsed since the timer started.
    var countdown = 0

    /// Second at which the scan is aborted; longer on slow devices (iPhone 6/7).
    var timeOut = 27

    /// Time (ms) to wait after the camera started before the first frame is analysed.
    private let delayBetweenInferencesMs: Double = 2000

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

    /// Sets up the camera, the timeout timer and the cancel button and resets the session flags.
    public override func viewDidLoad() {
        super.viewDidLoad()

        setUpCamera()

        label?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        label?.text = "scan.recto".sdkLocalized

        switch UIDevice.modelName {
        case .iphone6, .iphone7:
            timeOut = 90
        default:
            timeOut = 27
        }

        setTimer()

        addScannerCancelButton()

        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isCancel = false

    }

    /// Marks the session as new CIN, starts the scan-bar animation and the camera.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.cinType = .newCin

        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isValidCin = false

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

    /// Stops the timeout timer once the screen is gone, so it can never fire for a dismissed screen.
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
    }

    /// Resizes the preview layer whenever the layout changes.
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }

    // MARK: - Timeout

    /// Tells the user the scan timed out (suggesting to avoid light reflections), flags the
    /// cancellation and closes the screen when "OK" is tapped.
    func presentVideoConfigurationErrorAlertFirst() {

        let alertController = UIAlertController(
            title: "alert.sessionTimeout".sdkLocalized,
            message: "alert.avoidReflections".sdkLocalized, preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: "common.ok".sdkLocalized, style: .cancel,
            handler: { _ in
                self.dismiss(animated: true, completion: nil)
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

extension ViewControllerNewCin: VideoCaptureDelegate {

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

extension ViewControllerNewCin {

    /// Runs ML Kit text recognition on a camera frame and hands the result to `drawingView`.
    ///
    /// When the drawing view reports that the card number, last name and first name were found,
    /// the frame is stored as the recto image (`imageCIN`), the camera and timer are stopped and the
    /// recto confirmation alert is shown. `isInference` is reset when the recognition completes.
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
                if self.drawingView.resulat && self.drawingView.resulatCin && self.drawingView.resulatNom
                    && self.drawingView.resulatPrenom
                {

                    self.drawingView.resulat = false

                    let imageInit = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))

                    // `ky1ePKYS...` = `imageCIN`: the recto image.
                    fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.ky1ePKYSfStWWtkoyn7UgCesivPB3BvT = imageInit

                    self.videoCapture.stop()

                    self.upDown.isHidden = true

                    self.timer?.invalidate()

                    self.initCustomAlert(delegate: self, typeAlert: .recto)

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

extension ViewControllerNewCin: CustomAlertDelegate, ScannerCancellable {

    /// Stops the timeout timer and the camera.
    func stopScanning() {
        timer?.invalidate()
        videoCapture.stop()
    }

    /// The user cancelled: dismisses the screen and flags the cancellation.
    func cancel() {
        self.dismiss(animated: true, completion: nil)
        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isCancel = true
    }

    /// The user confirmed the recto: presents the verso screen (`ViewControllerNewCinVerso`) full
    /// screen, passing the completion callback along.
    func confirm() {

        let viewController: BaseVC =
            UIStoryboard(name: "Main", bundle: .sdk).instantiateViewController(
                withIdentifier: "ViewControllerNewCinVerso") as! BaseVC
        viewController.didScanComplete = didScanComplete
        viewController.modalPresentationStyle = .fullScreen
        self.present(viewController, animated: true)

    }

}

// MARK: - Timeout timer

extension ViewControllerNewCin {

    /// Starts the one-second repeating timer.
    ///
    /// After 7 seconds without a valid new-CIN marker (`isValidCin`) it asks the user to use an
    /// original CIN card and closes the screen; at `timeOut` it shows the generic timeout alert.
    func setTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            switch self.countdown {
            case 7:
                if !fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isValidCin {
                    self.upDown.isHidden = true
                    self.videoCapture.stop()
                    timer.invalidate()
                    let alertController = UIAlertController(
                        title: "alert.useOriginalCin".sdkLocalized, message: "",
                        preferredStyle: .alert)
                    let okAction = UIAlertAction(
                        title: "common.ok".sdkLocalized, style: .cancel,
                        handler: { _ in
                            self.dismiss(animated: true, completion: nil)
                        })
                    alertController.addAction(okAction)
                    fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isCancel = true
                    self.present(alertController, animated: true, completion: nil)
                }
            case self.timeOut:
                self.presentVideoConfigurationErrorAlertFirst()
                timer.invalidate()

            default:
                break
            }
            self.countdown += 1
        }
    }
}
