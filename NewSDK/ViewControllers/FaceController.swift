import AVFoundation
import MLKitFaceDetection
import MLKitVision
import PMAlertController
import UIKit
import Zip

/// Selfie / liveness screen. It is part of the package but is **not presented by the current scan flow**
/// (`NewSDKScanner` ends after the verso).
///
/// The front camera frames are analysed with ML Kit face detection: the user must blink (both eyes
/// closed), then look straight at the camera with both eyes open. Three such frames are collected,
/// saved to the Documents directory together with the CIN image and zipped; the user then validates
/// or cancels through a `PMAlertController`. The ``FaceDetectionView`` overlay shows the oval guide
/// and the hints.
class FaceController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    // MARK: - Properties

    /// Overlay with the oval guide, the hint label and the back button.
    var faceDetectionView: FaceDetectionView!

    /// Front-camera capture session.
    private let captureSession = AVCaptureSession()

    /// Layer showing the camera feed full screen.
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)

    /// Output delivering BGRA frames to `captureOutput(_:didOutput:from:)`.
    private let videoDataOutput = AVCaptureVideoDataOutput()

    /// Frames captured after the blink, with eyes open and looking forward; three are needed to finish.
    /// Written from the ML Kit callback and read from the camera queue, so every access goes through `framesLock`.
    private var listImage: [CIImage] = []

    /// Protects `listImage`.
    private let framesLock = NSLock()

    /// Set once the third frame has been handled, so the success alert and the zip are produced only once
    /// even though more frames keep arriving until the session has stopped.
    private let captureFinished = AtomicFlag()

    /// `true` when the front camera could not be set up (no camera, or permission denied).
    private var cameraUnavailable = false

    /// `true` once a blink (both eyes closed) has been detected; switches the hint to "face the camera".
    public var blink: Bool = false {
        didSet {
            if blink { faceDetectionView?.updateAssistanceMsg(.facePositioning) }
        }
    }

    /// Backing store of `isInference`; written from the camera queue and the main thread, hence atomic.
    private let inferenceFlag = AtomicFlag()

    /// `true` while a frame is being processed by ML Kit, so that frames arriving meanwhile are dropped.
    var isInference: Bool {
        get { inferenceFlag.value }
        set { inferenceFlag.value = newValue }
    }

    /// Maximum "eye open" probability for an eye to be considered closed; depends on the device model.
    var threshold: CGFloat = 0.25

    /// Serial queue for `startRunning`/`stopRunning`, which block and so must stay off the main thread.
    private let sessionQueue = DispatchQueue(label: "com.adria.newsdk.face-session")

    /// Not referenced anywhere in the SDK.
    public static var completion: (() -> Void)? = {}

    // MARK: - View lifecycle

    /// Configures the front camera, starts the session and picks the blink threshold for the device model.
    override func viewDidLoad() {
        super.viewDidLoad()
        guard addCameraInput() else {
            cameraUnavailable = true
            return
        }
        self.showCameraFeed()
        self.getCameraFrames()
        sessionQueue.async { self.captureSession.startRunning() }
        switch UIDevice.modelName {

        case .iphone4, .iphone5, .iphone6, .iphone7:

            threshold = 0.48

        case .iphone8, .iphoneSE, .iphoneSE2nd:

            threshold = 0.45

        case .iphoneX, .iphoneXR, .iphone11, .iphone12, .iphone13, .iphoneSE3rd, .iphone14, .iphone15, .iphone16,
            .iphone17, .unrecognized:

            threshold = 0.4

        }

    }

    /// Adds the ``FaceDetectionView`` overlay on top of the camera feed and starts its animation.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        faceDetectionView = FaceDetectionView(frame: self.view.bounds, delegate: self)
        view.addSubview(faceDetectionView)
        self.faceDetectionView.startAnimation()
    }

    /// Tells the user when the camera could not be set up, then leaves the screen.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard cameraUnavailable else { return }
        let alert = UIAlertController(
            title: "camera.unavailableTitle".sdkLocalized,
            message:
                "camera.unavailableMessage"
                .sdkLocalized,
            preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: "common.ok".sdkLocalized, style: .cancel,
                handler: { _ in
                    fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isCancel = true
                    self.dismiss(animated: true)
                }))
        present(alert, animated: true)
    }

    /// Keeps the preview layer sized to the view.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame

    }

    // MARK: - Frame processing

    /// Receives each camera frame.
    ///
    /// While fewer than three valid frames have been collected the frame is sent to ML Kit (one frame at
    /// a time). Once three frames are collected the session is stopped, the frames are stored in the
    /// session, the images are saved and zipped, and a success alert lets the user cancel or validate.
    ///
    /// - Parameters:
    ///   - output: The output that produced the frame.
    ///   - sampleBuffer: The captured frame.
    ///   - connection: The connection the frame came from.
    func captureOutput(
        _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection
    ) {

        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)

        if frameCount == 3 {

            // Frames keep arriving until the session has stopped: handle the third frame only once.
            guard captureFinished.testAndSet() else { return }

            DispatchQueue.main.async {

                self.sessionQueue.async { self.captureSession.stopRunning() }

                let frames = self.capturedFrames
                fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.fram0 = frames[0]

                fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.fram1 = frames[1]

                fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.fram2 = frames[2]

                self.saveImageInDocsDir()

                // Image by freepik.com, taken on flaticon.com
                let alertVC = PMAlertController(
                    title: "face.scanSuccess".sdkLocalized, description: "",
                    image: nil, style: .alert)

                alertVC.addAction(
                    PMAlertAction(
                        title: "common.cancel".sdkLocalized, style: .cancel,
                        action: { () -> Void in

                            fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isCancel = true

                            self.dismiss(animated: true, completion: nil)

                        }))

                alertVC.addAction(
                    PMAlertAction(
                        title: "common.confirm".sdkLocalized, style: .default,
                        action: { () in

                            fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.issValidFace = true
                            fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isZipFileFaceMatchingGenerated = true
                            self.dismiss(animated: true, completion: nil)

                        }))

                self.present(alertVC, animated: true, completion: nil)
            }
        } else {
            if !self.isInference, let pixelBuffer = pixelBuffer {
                self.isInference = true
                let ciImage = CIImage(cvImageBuffer: pixelBuffer)
                detectFace(on: ciImage)
            }

        }

    }

    // MARK: - Camera setup

    /// Adds the front camera (wide-angle, dual or TrueDepth) as input of the capture session.
    ///
    /// - Returns: `true` if the input was added; `false` if there is no front camera (for example on the
    ///   simulator) or the input cannot be created (for example because camera access was denied).
    private func addCameraInput() -> Bool {
        guard
            let device = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
                mediaType: .video,
                position: .front
            ).devices.first,
            let cameraInput = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(cameraInput)
        else {
            return false
        }
        self.captureSession.addInput(cameraInput)
        return true
    }

    /// Adds the preview layer (aspect-fill) to the view.
    private func showCameraFeed() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
    }

    /// Adds a BGRA video data output delivering frames to this controller on a background queue,
    /// discarding late frames, in portrait orientation when supported.
    private func getCameraFrames() {
        self.videoDataOutput.videoSettings =
            [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)]
            as [String: Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported
        else { return }
        connection.videoOrientation = .portrait
    }

    // MARK: - Face detection

    /// Runs ML Kit face detection (with eye-open probabilities) on a frame and drives the blink logic.
    ///
    /// Until a blink is seen, both eyes' open probability at or below `threshold` sets `blink`.
    /// Afterwards, a frame with both eyes at least 90% open and the face looking forward
    /// (see ``islookingForward(image:)``) is appended to `listImage`.
    /// `isInference` is reset when the detection completes or fails.
    ///
    /// - Parameter image: The camera frame to analyse.
    func detectFace(on image: CIImage) {

        let ciContext = CIContext()
        guard let cgImage: CGImage = ciContext.createCGImage(image, from: image.extent) else {
            self.isInference = false
            return
        }

        let img = UIImage(cgImage: cgImage)
        let options = FaceDetectorOptions()
        options.landmarkMode = .all
        options.classificationMode = .all
        options.performanceMode = .accurate
        let faceDetector = FaceDetector.faceDetector(options: options)

        let visionImage = VisionImage(image: img)
        visionImage.orientation = img.imageOrientation

        faceDetector.process(visionImage) { faces, error in
            guard error == nil, let faces = faces, !faces.isEmpty else {
                self.isInference = false
                return
            }

            // Faces detected
            for face in faces {
                if !self.blink && face.hasRightEyeOpenProbability && face.hasLeftEyeOpenProbability {
                    self.blink =
                        (face.rightEyeOpenProbability <= self.threshold
                            && face.leftEyeOpenProbability <= self.threshold)

                } else if (face.hasRightEyeOpenProbability && face.rightEyeOpenProbability >= 0.9)
                    && (face.hasLeftEyeOpenProbability && face.leftEyeOpenProbability >= 0.9)
                    && self.islookingForward(image: image)
                {
                    if self.blink { self.appendFrame(image) }
                }

            }
            self.isInference = false

        }

    }

    /// The number of frames collected so far.
    private var frameCount: Int {
        framesLock.lock()
        defer { framesLock.unlock() }
        return listImage.count
    }

    /// A snapshot of the frames collected so far.
    private var capturedFrames: [CIImage] {
        framesLock.lock()
        defer { framesLock.unlock() }
        return listImage
    }

    /// Adds a frame, ignoring it once three frames have been collected.
    ///
    /// - Parameter frame: The camera frame to keep.
    private func appendFrame(_ frame: CIImage) {
        framesLock.lock()
        defer { framesLock.unlock() }
        if listImage.count < 3 { listImage.append(frame) }
    }

    /// Tells whether the face in the frame is looking straight at the camera, using Core Image's face angle.
    ///
    /// - Parameter image: The camera frame to analyse.
    /// - Returns: `true` if the face angle of the last detected face is between -4 and 4 degrees;
    ///   `false` if no face is found.
    func islookingForward(image: CIImage) -> Bool {

        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces =
            faceDetector?.features(
                in: image, options: [CIDetectorSmile: true, CIDetectorEyeBlink: true, CIDetectorTracking: true])
            as? [CIFaceFeature] ?? []

        var islookingForward = false

        for face in faces {
            islookingForward = (-4...4 ~= face.faceAngle)
        }

        return islookingForward

    }

    // MARK: - Saving

    /// Converts a Core Image image into a `UIImage`.
    ///
    /// - Parameter cmage: The image to convert.
    /// - Returns: A bitmap-backed `UIImage`, or an empty image if the bitmap cannot be created.
    func convert(cmage: CIImage) -> UIImage {
        let context = CIContext()
        guard let cgImage = context.createCGImage(cmage, from: cmage.extent) else { return UIImage() }
        return UIImage(cgImage: cgImage)
    }

    /// Saves the CIN image and the three captured frames as JPEGs in `Documents/zipfile`, zips that
    /// folder to `archive.zip` and stores the zip URL in the session (`video`).
    ///
    /// Write and zip errors are only printed.
    func saveImageInDocsDir() {

        // `hdya2TCP...` = `getImageAccess()`: the CIN image held by the session.
        let image: UIImage? = fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.hdya2TCPu5RNn85L70JNyfpdQmfl253p()
        let frame0 = fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.getFrame0()
        let frame1 = fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.getFrame1()
        let frame2 = fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.getFrame2()

        // convert CImage to UImage
        let initFrame0 = convert(cmage: frame0)
        let initFrame1 = convert(cmage: frame1)
        let initFrame2 = convert(cmage: frame2)
        if let image = image {
            // get the documents directory url
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory = paths[0]
            let dataPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("zipfile").path
            // Create the folder if it does not exist yet
            if !FileManager.default.fileExists(atPath: dataPath) {
                try? FileManager.default.createDirectory(
                    atPath: dataPath, withIntermediateDirectories: true, attributes: nil)
            }

            // create the destination file urls to save the images
            let fileURL = URL(fileURLWithPath: dataPath).appendingPathComponent("image_cin.jpg")

            let fileURL2 = URL(fileURLWithPath: dataPath).appendingPathComponent("frame0.jpg")

            let fileURL3 = URL(fileURLWithPath: dataPath).appendingPathComponent("frame1.jpg")

            let fileURL4 = URL(fileURLWithPath: dataPath).appendingPathComponent("frame2.jpg")

            // get the JPEG data representations (compressionQuality 0.0 = lowest quality / smallest size)
            let data = image.jpegData(compressionQuality: 0.0)
            let dataFrame0 = initFrame0.jpegData(compressionQuality: 0.0)
            let dataFrame1 = initFrame1.jpegData(compressionQuality: 0.0)
            let dataFrame2 = initFrame2.jpegData(compressionQuality: 0.0)
            do {
                // writes the image data to disk
                try data?.write(to: fileURL, options: .atomic)
                try dataFrame0?.write(to: fileURL2, options: .atomic)
                try dataFrame1?.write(to: fileURL3, options: .atomic)
                try dataFrame2?.write(to: fileURL4, options: .atomic)

            } catch {
                print("error:", error)
            }

            let pathURL = URL(fileURLWithPath: dataPath)

            do {

                let zipFilePath = try Zip.compressFiles([pathURL], fileName: "archive")

                // `Y2tKeK7Q...` = `video`: the zip file URL held by the session.
                fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.Y2tKeK7Qj0fKVKJxcmXe2591quNLlCTF = zipFilePath
            } catch {
                print("Something went wrong")
            }

        }

    }

}

// MARK: - FaceDetectionDelegate

extension FaceController: FaceDetectionDelegate {

    /// Back button of the overlay: asks for confirmation, then stops the session and dismisses the screen.
    func closeCamera() {
        let alertVC = PMAlertController(
            title: "face.quitConfirm".sdkLocalized, description: "",
            image: nil, style: .alert)
        alertVC.addAction(
            PMAlertAction(
                title: "common.yes".sdkLocalized, style: .cancel,
                action: {
                    self.sessionQueue.async { self.captureSession.stopRunning() }
                    self.dismiss(animated: true)

                }))
        alertVC.addAction(PMAlertAction(title: "common.no".sdkLocalized, style: .default, action: {}))
        self.present(alertVC, animated: true, completion: nil)
    }

}
