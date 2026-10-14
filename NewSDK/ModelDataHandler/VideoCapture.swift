import AVFoundation
import CoreVideo
import UIKit

/// Receives the camera frames captured by a `VideoCapture`.
public protocol VideoCaptureDelegate: AnyObject {
    /// Called for each frame delivered at the capture's frame rate.
    ///
    /// Original name: `videoCapture(_:didCaptureVideoFrame:timestamp:)`.
    ///
    /// This is called on the capture's background queue, not the main thread.
    ///
    /// - Parameters:
    ///   - capture: The capture object that produced the frame.
    ///   - didCaptureVideoFrame: The frame's pixel buffer (32-bit BGRA), or `nil` if the sample buffer had no image.
    ///   - timestamp: The presentation timestamp of the frame.
    func KNiUazUE6x9Mux2PXav7mgjbUbGFuj18(
        _ capture: VideoCapture, didCaptureVideoFrame: CVPixelBuffer?, timestamp: CMTime)
}

/// Captures live video from the back camera and forwards frames to a delegate at a limited frame rate.
///
/// Call `setUp(sessionPreset:completion:)`, add `previewLayer` to a view, then `start()` / `stop()` the session.
public class VideoCapture: NSObject {
    /// Layer that displays the camera preview; created by `setUp(sessionPreset:completion:)`.
    public var previewLayer: AVCaptureVideoPreviewLayer?
    /// Receives the captured frames.
    public weak var delegate: VideoCaptureDelegate?
    /// Maximum number of frames per second forwarded to the delegate (the camera itself keeps running at full speed).
    public var fps = 15

    /// The underlying capture session.
    let captureSession = AVCaptureSession()
    /// Delivers the raw video frames (32-bit BGRA, late frames discarded).
    let videoOutput = AVCaptureVideoDataOutput()
    /// Background queue on which sample buffers are delivered.
    let queue = DispatchQueue(label: "com.tucan9389.camera-queue")
    /// Serial queue for `startRunning` / `stopRunning`, which block and so must stay off the main thread.
    private let sessionQueue = DispatchQueue(label: "com.adria.newsdk.video-capture-session")

    /// Timestamp of the last frame forwarded to the delegate, used to enforce `fps`.
    var lastTimestamp = CMTime()

    /// Configures the capture session and creates the preview layer.
    ///
    /// - Parameters:
    ///   - sessionPreset: The quality preset for the session (`.vga640x480` by default).
    ///   - completion: Called with `true` once the session is configured, or `false` if no camera is available or
    ///     the input could not be added (for example when camera access is denied).
    public func setUp(
        sessionPreset: AVCaptureSession.Preset = .vga640x480,
        completion: @escaping (Bool) -> Void
    ) {
        rETUJKpbwcXAx1bKx5fY9RI6TWnYlV3j(sessionPreset: sessionPreset, completion: completion)
    }

    /// Does the work of `setUp(sessionPreset:completion:)` (original name: `setUpCamera(sessionPreset:completion:)`).
    ///
    /// Uses the ultra-wide back camera on devices that expose all three back cameras (wide, telephoto and
    /// ultra-wide) and the wide-angle back camera otherwise. Adds the camera input and the BGRA video output
    /// (oriented `.landscapeRight`) to the session and creates a portrait, aspect-fill preview layer.
    ///
    /// - Parameters:
    ///   - sessionPreset: The quality preset for the session.
    ///   - completion: Called with `true` on success and `false` on any configuration failure.
    func rETUJKpbwcXAx1bKx5fY9RI6TWnYlV3j(
        sessionPreset: AVCaptureSession.Preset, completion: @escaping (_ success: Bool) -> Void
    ) {

        captureSession.beginConfiguration()
        captureSession.sessionPreset = sessionPreset

        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: .back
        )
        let captureDevice: AVCaptureDevice?
        if deviceDiscoverySession.devices.count >= 3 {
            captureDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
        } else {
            captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }

        guard let captureDevice else {
            print("Error: No compatible video devices found")
            captureSession.commitConfiguration()
            completion(false)
            return
        }
        do {
            let videoInput = try AVCaptureDeviceInput(device: captureDevice)
            guard captureSession.canAddInput(videoInput) else {
                print("Error: Could not add the capture device input")
                captureSession.commitConfiguration()
                completion(false)
                return
            }
            captureSession.addInput(videoInput)
        } catch {
            // Typically camera permission denied / restricted.
            print("Error: Could not configure capture device - \(error)")
            captureSession.commitConfiguration()
            completion(false)
            return
        }
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        self.previewLayer = previewLayer

        let settings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]

        videoOutput.videoSettings = settings
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // We want the buffers to be in portrait orientation otherwise they are
        // rotated by 90 degrees. Need to set this _after_ addOutput()!
        videoOutput.connection(with: AVMediaType.video)?.videoOrientation = .landscapeRight

        captureSession.commitConfiguration()

        completion(true)
    }

    /// Starts the capture session on a background queue if it is not already running.
    public func start() {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    /// Stops the capture session on a background queue if it is running.
    public func stop() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {

    /// Forwards a frame to `delegate` when at least `1 / fps` seconds have passed since the last forwarded frame.
    ///
    /// - Parameters:
    ///   - output: The output that produced the frame.
    ///   - sampleBuffer: The captured sample buffer.
    ///   - connection: The connection the frame arrived on.
    public func captureOutput(
        _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection
    ) {

        // Because lowering the capture device's FPS looks ugly in the preview,
        // we capture at full speed but only call the delegate at its desired
        // framerate.
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let deltaTime = timestamp - lastTimestamp
        if deltaTime >= CMTimeMake(value: 1, timescale: Int32(fps)) {
            lastTimestamp = timestamp
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            delegate?.KNiUazUE6x9Mux2PXav7mgjbUbGFuj18(self, didCaptureVideoFrame: imageBuffer, timestamp: timestamp)
        }
    }
}
