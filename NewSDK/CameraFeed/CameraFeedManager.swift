// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import AVFoundation

// MARK: - CameraFeedManagerDelegate

/// Receives camera frames and camera/session events from `CameraFeedManager`.
///
/// Original name: `CameraFeedManagerDelegate` (obfuscated by SwiftShield). The delegate methods are
/// invoked on different queues: the frame callback arrives on the video sample-buffer queue, the
/// error and permission callbacks are dispatched to the main queue, and the interruption callbacks
/// are forwarded from the `NotificationCenter` observers.
protocol ZSP58vZ71h0tlSCfgRnSJI3iOmpNO2qf: AnyObject {

    /// Delivers the pixel buffer of the frame currently seen by the device's camera.
    ///
    /// Original name: `didOutput`.
    ///
    /// - Parameter pixelBuffer: The BGRA pixel buffer of the latest video frame.
    func YSuZSMAQipUTTbB2I5iULuxr1BIACZfp(pixelBuffer: CVPixelBuffer)

    /// Signals that the user denied (or has previously denied) camera permission.
    ///
    /// Original name: `presentCameraPermissionsDeniedAlert`.
    func kZMcc83qv4P2CU8e8Dkq96aSr1AAfOqu()

    /// Signals that the capture session could not be configured (no usable input or output).
    ///
    /// Original name: `presentVideoConfigurationErrorAlert`.
    func wHnXp0M51N5LLTNe9YW7hnqifEcKwmWO()

    /// Signals that a capture session runtime error occurred.
    ///
    /// Original name: `sessionRunTimeErrorOccured`.
    func a5ccfNWAcEPeFtvp82hwA22Y6JLkyrsv()

    /// Signals that the capture session was interrupted.
    ///
    /// Original name: `sessionWasInterrupted`.
    ///
    /// - Parameter resumeManually: `true` when the interruption reason allows the user to resume the
    ///   session manually (the camera is in use by another client), `false` otherwise.
    func Elm5KJmsn1DFeuYmbW1OtrwrmH8AnuwW(canResumeManually resumeManually: Bool)

    /// Signals that a previous session interruption has ended.
    ///
    /// Original name: `sessionInterruptionEnded`.
    func JkiHfUKgZ896sjDkuK5AX3F2mV412zED()

}

// MARK: - Camera configuration state

/// The outcome of the camera permission check and capture session configuration.
///
/// Original name: `CameraConfiguration`.
enum l5et7Iy8OiSmrfEROfdGTv6nwErctYKm {

    /// The camera is authorized and the session was configured successfully (original name: `success`).
    case lxXEd7LnAK3tx6kQ1Uwvp34iy6W0dZfH

    /// The session could not be configured, or the authorization state is unusable (original name: `failed`).
    case fXQ5EIumjgUdCMBzRnWt2eDkq0HuUuEm

    /// The user denied camera access (original name: `permissionDenied`).
    case nEkKadIDQLeVntjq61ExDJry9B3GL597
}

// MARK: - CameraFeedManager

/// Manages the back-camera `AVCaptureSession`: permission handling, configuration, start/stop/resume,
/// interruption handling and delivery of video frames to its delegate.
///
/// Original name: `CameraFeedManager` (obfuscated by SwiftShield).
class D8bNFT95NbhlrfyWllDp68AZySXUHmXt: NSObject {

    // MARK: Camera related instance variables

    /// The capture session that connects the camera input to the video data output.
    private let session: AVCaptureSession = AVCaptureSession()

    /// The view whose layer displays the live camera preview (original name: `PreviewView`).
    private let previewView: bIvpRBRowRuX8QU2s0Lvnt0kuYdNTI9A

    /// Serial queue on which all session configuration and start/stop work is performed.
    private let sessionQueue = DispatchQueue(label: "sessionQueue")

    /// The result of the permission check and session configuration; read before the session starts.
    private var cameraConfiguration: l5et7Iy8OiSmrfEROfdGTv6nwErctYKm = .fXQ5EIumjgUdCMBzRnWt2eDkq0HuUuEm

    /// The output that delivers the raw video frames to the sample-buffer delegate.
    private lazy var videoDataOutput = AVCaptureVideoDataOutput()

    /// Whether the session was running the last time it was started or stopped through this manager.
    private var isSessionRunning = false

    // MARK: CameraFeedManagerDelegate

    /// The object that receives frames and session events.
    weak var delegate: ZSP58vZ71h0tlSCfgRnSJI3iOmpNO2qf?

    // MARK: Initializer

    /// Creates a manager, attaches its capture session to the preview view and requests camera access.
    ///
    /// The session uses the 1280x720 preset, a landscape-right preview orientation and an
    /// aspect-fill video gravity. The permission check and session configuration are started
    /// immediately (see `weqoqGGRsuj7bEbcLDoWP1x6SgV0tYd6()`).
    ///
    /// - Parameter previewView: The view that displays the camera preview.
    init(previewView: bIvpRBRowRuX8QU2s0Lvnt0kuYdNTI9A) {
        self.previewView = previewView
        super.init()

        // Initializes the session
        session.sessionPreset = .hd1280x720
        self.previewView.session = session
        self.previewView.previewLayer.connection?.videoOrientation = .landscapeRight
        self.previewView.previewLayer.videoGravity = .resizeAspectFill
        self.weqoqGGRsuj7bEbcLDoWP1x6SgV0tYd6()

    }

    // MARK: - Session start and end methods

    /// Starts the capture session if the camera configuration succeeded; otherwise reports the failure.
    ///
    /// Original name: `checkCameraConfigurationAndStartSession`. On success the notification observers
    /// are registered and the session is started on the session queue. On `.failed` the delegate gets
    /// the configuration-error callback and on `.permissionDenied` the permission-denied callback, both
    /// on the main queue.
    func yAGLUWQmhAyxCg2jfvamv7ioXvEjEDvn() {
        sessionQueue.async {
            switch self.cameraConfiguration {
            case .lxXEd7LnAK3tx6kQ1Uwvp34iy6W0dZfH:
                self.bgV1ki9LVSCbFfGyuPiZoJYtyO4GBXyg()
                self.dLy9tFf3yNa51AF22AajTOusCPpqD4aA()
            case .fXQ5EIumjgUdCMBzRnWt2eDkq0HuUuEm:
                DispatchQueue.main.async {
                    self.delegate?.wHnXp0M51N5LLTNe9YW7hnqifEcKwmWO()
                }
            case .nEkKadIDQLeVntjq61ExDJry9B3GL597:
                DispatchQueue.main.async {
                    self.delegate?.kZMcc83qv4P2CU8e8Dkq96aSr1AAfOqu()
                }
            }
        }
    }

    /// Stops the capture session if it is running and removes the notification observers.
    ///
    /// Original name: `stopSession`.
    func xdN0btp63XTVDRanlrXOLP1NfzJLVEE3() {
        self.nIdgb7raWYT7BDdvutG3302tLidGGJmO()
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }

    }

    /// Resumes an interrupted capture session.
    ///
    /// Original name: `resumeInterruptedSession`.
    ///
    /// - Parameter completion: Called on the main queue with `true` if the session is running again,
    ///   `false` otherwise.
    func Dvzo8SsdAEGIhYhZOa5lf87UIx6gwj3H(withCompletion completion: @escaping (Bool) -> Void) {

        sessionQueue.async {
            self.dLy9tFf3yNa51AF22AajTOusCPpqD4aA()

            DispatchQueue.main.async {
                completion(self.isSessionRunning)
            }
        }
    }

    /// Starts the capture session and records whether it is running.
    ///
    /// Original name: `startSession`. Must be called on the session queue.
    private func dLy9tFf3yNa51AF22AajTOusCPpqD4aA() {

        self.session.startRunning()
        self.isSessionRunning = self.session.isRunning

    }

    // MARK: - Session configuration methods

    /// Checks the camera authorization status, requests access when it is undetermined, and then
    /// configures the session on the session queue.
    ///
    /// Original name: `attemptToConfigureSession`. When the status is `.notDetermined` the session
    /// queue is suspended until the user answers the permission prompt, so the configuration step
    /// below only runs once the result is known. `.denied` and `.restricted` both end in the
    /// permission-denied state, so the user is told about the permission instead of a generic failure.
    private func weqoqGGRsuj7bEbcLDoWP1x6SgV0tYd6() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.cameraConfiguration = .lxXEd7LnAK3tx6kQ1Uwvp34iy6W0dZfH
        case .notDetermined:
            self.sessionQueue.suspend()
            self.MPFCGxPJGLISyIT5Q8nY9JCX1kqBZkce(completion: { _ in
                self.sessionQueue.resume()
            })
        case .denied, .restricted:
            self.cameraConfiguration = .nEkKadIDQLeVntjq61ExDJry9B3GL597
        @unknown default:
            break
        }

        self.sessionQueue.async {
            self.CpxRJYykmUOBOSJAqBwg7KbHNmJTLJUj()
        }
    }

    /// Requests camera permission from the user and stores the outcome in `cameraConfiguration`.
    ///
    /// Original name: `requestCameraAccess`.
    ///
    /// - Parameter completion: Called (on an arbitrary queue) with whether access was granted.
    private func MPFCGxPJGLISyIT5Q8nY9JCX1kqBZkce(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
            if !granted {
                self.cameraConfiguration = .nEkKadIDQLeVntjq61ExDJry9B3GL597
            } else {
                self.cameraConfiguration = .lxXEd7LnAK3tx6kQ1Uwvp34iy6W0dZfH
            }
            completion(granted)
        }
    }

    /// Configures the capture session: adds the camera input and the video data output.
    ///
    /// Original name: `configureSession`. Does nothing unless camera access has been granted. If
    /// either the input or the output cannot be added, the configuration is committed and
    /// `cameraConfiguration` becomes `.failed`; otherwise it stays `.success`.
    private func CpxRJYykmUOBOSJAqBwg7KbHNmJTLJUj() {

        guard cameraConfiguration == .lxXEd7LnAK3tx6kQ1Uwvp34iy6W0dZfH else {
            return
        }
        session.beginConfiguration()

        // Tries to add an AVCaptureDeviceInput.
        guard l35Z6FDTAJ6ZLJhyERw6gmkZnpGbjk2D() else {
            self.session.commitConfiguration()
            self.cameraConfiguration = .fXQ5EIumjgUdCMBzRnWt2eDkq0HuUuEm
            return
        }

        // Tries to add an AVCaptureVideoDataOutput.
        guard GS6V57XUvIdKeNJAsHmwtlzVZch9pHFe() else {
            self.session.commitConfiguration()
            self.cameraConfiguration = .fXQ5EIumjgUdCMBzRnWt2eDkq0HuUuEm
            return
        }

        session.commitConfiguration()
        self.cameraConfiguration = .lxXEd7LnAK3tx6kQ1Uwvp34iy6W0dZfH
    }

    /// Adds the back camera as the input of the capture session.
    ///
    /// Original name: `addVideoDeviceInput`. The preferred device is the triple camera, then the dual
    /// camera, then the wide-angle camera. Once the input is added, continuous auto focus, exposure and
    /// white balance are enabled via `configureCamera(_:)`.
    ///
    /// - Returns: `true` if the input was added; `false` if there is no back camera, the input cannot be
    ///   created, or the session refused it.
    private func l35Z6FDTAJ6ZLJhyERw6gmkZnpGbjk2D() -> Bool {

        // Prefer the multi-camera back devices and fall back to the plain wide-angle camera.
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInTripleCamera, .builtInDualCamera, .builtInWideAngleCamera,
        ]

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .back
        )

        // No back camera (for example on the simulator): report failure instead of crashing the host app.
        guard let camera = discoverySession.devices.first else {
            return false
        }

        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)

                // Configure the camera for continuous auto focus / exposure / white balance.
                configureCamera(camera)

                return true
            }
            return false
        } catch {
            return false
        }
    }

    /// Enables continuous auto focus, auto exposure and auto white balance on the camera when each
    /// mode is supported.
    ///
    /// - Parameter camera: The capture device to configure. If it cannot be locked for configuration
    ///   the error is logged and the device is left unchanged.
    private func configureCamera(_ camera: AVCaptureDevice) {
        do {
            try camera.lockForConfiguration()

            // Set focus mode to continuous auto focus
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }

            // Set exposure mode to continuous auto exposure
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
            }

            // Auto white balance
            if camera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                camera.whiteBalanceMode = .continuousAutoWhiteBalance
            }

            camera.unlockForConfiguration()
        } catch {
            print("Could not lock camera for configuration: \(error)")
        }
    }

    /// Adds the video data output to the capture session and makes `self` its sample-buffer delegate.
    ///
    /// Original name: `addVideoDataOutput`. Frames are requested as 32BGRA, late frames are
    /// discarded, mirroring is disabled and the connection orientation is landscape right.
    ///
    /// - Returns: `true` if the output was added; `false` if the session refused the output.
    private func GS6V57XUvIdKeNJAsHmwtlzVZch9pHFe() -> Bool {

        let sampleBufferQueue = DispatchQueue(label: "sampleBufferQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCMPixelFormat_32BGRA]
        videoDataOutput.connection(with: .video)?.automaticallyAdjustsVideoMirroring = false
        videoDataOutput.connection(with: .video)?.isVideoMirrored = false

        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            if let connection = videoDataOutput.connection(with: .video) {
                connection.videoOrientation = .landscapeRight
                connection.isVideoMirrored = false
            }
            return true
        }
        return false
    }

    // MARK: - Notification observer handling

    /// Registers for the session's runtime-error, interruption and interruption-ended notifications.
    ///
    /// Original name: `addObservers`.
    private func bgV1ki9LVSCbFfGyuPiZoJYtyO4GBXyg() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(D8bNFT95NbhlrfyWllDp68AZySXUHmXt.xSUcjtGpQm3uwt6h0SktPQQrUHJrzP0X(notification:)),
            name: NSNotification.Name.AVCaptureSessionRuntimeError, object: session)
        NotificationCenter.default.addObserver(
            self, selector: #selector(D8bNFT95NbhlrfyWllDp68AZySXUHmXt.Elm5KJmsn1DFeuYmbW1OtrwrmH8AnuwW(notification:)),
            name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: session)
        NotificationCenter.default.addObserver(
            self, selector: #selector(D8bNFT95NbhlrfyWllDp68AZySXUHmXt.JkiHfUKgZ896sjDkuK5AX3F2mV412zED),
            name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: session)
    }

    /// Removes the observers registered by `bgV1ki9LVSCbFfGyuPiZoJYtyO4GBXyg()`.
    ///
    /// Original name: `removeObservers`.
    private func nIdgb7raWYT7BDdvutG3302tLidGGJmO() {
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name.AVCaptureSessionRuntimeError, object: session)
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: session)
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: session)
    }

    // MARK: - Notification observers

    /// Handles `AVCaptureSessionWasInterrupted` and forwards it to the delegate.
    ///
    /// Original name: `sessionWasInterrupted`. The interruption reason is read from the notification;
    /// manual resume is only offered when the camera is in use by another client.
    ///
    /// - Parameter notification: The interruption notification carrying
    ///   `AVCaptureSessionInterruptionReasonKey` in its `userInfo`. Ignored if the reason is missing.
    @objc func Elm5KJmsn1DFeuYmbW1OtrwrmH8AnuwW(notification: Notification) {

        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue)
        {
            print("Capture session was interrupted with reason \(reason)")

            let canResumeManually = reason == .videoDeviceInUseByAnotherClient

            self.delegate?.Elm5KJmsn1DFeuYmbW1OtrwrmH8AnuwW(canResumeManually: canResumeManually)

        }
    }

    /// Handles `AVCaptureSessionInterruptionEnded` and forwards it to the delegate.
    ///
    /// Original name: `sessionInterruptionEnded`.
    ///
    /// - Parameter notification: The interruption-ended notification (unused).
    @objc func JkiHfUKgZ896sjDkuK5AX3F2mV412zED(notification: Notification) {

        self.delegate?.JkiHfUKgZ896sjDkuK5AX3F2mV412zED()
    }

    /// Handles `AVCaptureSessionRuntimeError`.
    ///
    /// Original name: `sessionRuntimeErrorOccured`. If the media services were reset and the session
    /// was running, the session is restarted on the session queue; in every other case the delegate is
    /// told that a runtime error occurred (on the main queue for the media-services-reset case).
    ///
    /// - Parameter notification: The runtime-error notification carrying an `AVError` under
    ///   `AVCaptureSessionErrorKey`. Ignored if the error is missing.
    @objc func xSUcjtGpQm3uwt6h0SktPQQrUHJrzP0X(notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else {
            return
        }

        print("Capture session runtime error: \(error)")

        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.dLy9tFf3yNa51AF22AajTOusCPpqD4aA()
                } else {
                    DispatchQueue.main.async {
                        self.delegate?.a5ccfNWAcEPeFtvp82hwA22Y6JLkyrsv()
                    }
                }
            }
        } else {
            self.delegate?.a5ccfNWAcEPeFtvp82hwA22Y6JLkyrsv()

        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

/// Forwards every captured video frame to the delegate.
extension D8bNFT95NbhlrfyWllDp68AZySXUHmXt: AVCaptureVideoDataOutputSampleBufferDelegate {

    /// Converts the captured sample buffer to a pixel buffer and hands it to the delegate.
    ///
    /// Original name of the delegate callback: `didOutput`. Frames without an image buffer are dropped.
    ///
    /// - Parameters:
    ///   - output: The video data output that produced the frame.
    ///   - sampleBuffer: The captured sample buffer.
    ///   - connection: The connection the frame arrived on.
    func captureOutput(
        _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection
    ) {

        // Converts the CMSampleBuffer to a CVPixelBuffer.
        let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)

        guard let imagePixelBuffer = pixelBuffer else {
            return
        }

        // Delegates the pixel buffer to the ViewController.
        delegate?.YSuZSMAQipUTTbB2I5iULuxr1BIACZfp(pixelBuffer: imagePixelBuffer)
    }

}
