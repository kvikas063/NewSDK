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

import UIKit

/// First screen of the old-CIN flow: scans the recto (front) of the card.
///
/// Live camera frames are run through a TensorFlow Lite object-detection model
/// (`ModelDataHandler`); once all six expected fields have been recognised the recto is
/// confirmed with a ``CustomAlert`` and the flow continues with ``MainVideoViewController`` (verso).
/// A timer shows tips after 8 and 15 seconds and aborts the scan when `timeOut` is reached.
public class ViewController: BaseVC {

    // MARK: - Storyboard connections

    /// Camera preview view (`PreviewView`).
    @IBOutlet weak var previewView: bIvpRBRowRuX8QU2s0Lvnt0kuYdNTI9A!

    /// Overlay view (`OverlayView`) cleared at start-up.
    @IBOutlet weak var overlayView: yKw6WQbJGQFsKtF3V95mJ8DZM5OgHgjD!

    /// Button shown when the camera session can be resumed manually.
    @IBOutlet weak var resumeButton: UIButton!

    /// Label shown while the camera is unavailable (session interrupted).
    @IBOutlet weak var cameraUnavailableLabel: UILabel!

    /// Scan bar animated by ``BaseVC/startScanBarAnimation(_:)``.
    @IBOutlet weak var upDown: Shadow!

    /// "RECTO" caption, rotated by 90° in `viewDidLoad()`.
    @IBOutlet var label: UILabel? = UILabel()

    // MARK: - Timer

    /// One-second timer driving `countdown()`.
    var timer: Timer?

    /// Number of seconds elapsed since the timer started.
    var countdownValue = 0

    /// Second at which the scan is aborted; longer on slow devices (iPhone 6/7).
    var timeOut = 25

    // MARK: - Private state

    /// Time (ms) to wait after the view appears before the first frame is analysed.
    private let delayBeforeStarting: Double = 2000

    /// Timestamp (ms since 1970) at which the view last appeared.
    private var startTimeMs: Double!

    /// Minimum time (ms) between two model inferences.
    private let delayBetweenInferencesMs: Double = 200

    /// Latest model output; `myArray2` holds the six recognised fields (empty string = not found yet).
    private var result: Result?

    /// Timestamp (ms since 1970) of the last model inference.
    private var previousInferenceTimeMs: TimeInterval = Date.distantPast.timeIntervalSince1970 * 1000

    // MARK: - Controllers that manage functionality

    /// Camera manager (`CameraFeedManager`) delivering pixel buffers to this controller.
    private lazy var cameraFeedManager = D8bNFT95NbhlrfyWllDp68AZySXUHmXt(previewView: previewView)

    /// MobileNet-SSD based recogniser; `nil` if the model failed to load (fatal in `viewDidLoad()`).
    private let modelDataHandler: ModelDataHandler? =
        ModelDataHandler(modelFileInfo: MobileNetSSD.modelInfo, labelsFileInfo: MobileNetSSD.labelsInfo)

    // MARK: - View handling

    /// Configures the camera delegate, resets the session flags, adds the cancel button and starts the timeout timer.
    public override func viewDidLoad() {
        super.viewDidLoad()

        guard modelDataHandler != nil else {
            fatalError("Failed to load model")
        }
        cameraFeedManager.delegate = self
        overlayView.clearsContextBeforeDrawing = true

        self.view.bringSubviewToFront(resumeButton)

        label?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        label?.text = "scan.recto".sdkLocalized.uppercased()
        resumeButton.setTitle("camera.resumeSession".sdkLocalized, for: .normal)
        cameraUnavailableLabel.text = "camera.unavailableTitle".sdkLocalized

        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isCancel = false

        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isTimeOut = false

        addScannerCancelButton()

        switch UIDevice.modelName {
        case .iphone6, .iphone7:
            timeOut = 90
        default:
            timeOut = 27
        }

        startTimer()

    }

    /// Starts the camera session, resets the recognised fields and starts the scan-bar animation.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // `yAGLUWQm...` = `checkCameraConfigurationAndStartSession()`
        cameraFeedManager.yAGLUWQmhAyxCg2jfvamv7ioXvEjEDvn()

        self.startTimeMs = Date().timeIntervalSince1970 * 1000

        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.cinType = .oldCin

        // `Gv6iuNfQ...` = `tokenAccess`: the six recognised recto fields.
        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.Gv6iuNfQoFK2P4Pd3tdqXjDS25hJGyRR = ["", "", "", "", "", ""]

        startScanBarAnimation(upDown)

    }

    /// Stops the camera session.
    ///
    /// - Parameter animated: Whether the disappearance is animated.
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // `xdN0btp6...` = `stopSession()`
        cameraFeedManager.xdN0btp63XTVDRanlrXOLP1NfzJLVEE3()

    }

    /// Stops the timeout timer once the screen is gone (the timer retains this controller until invalidated).
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
    }

    /// Shows a single-line, rotated toast that fades out after about 4 seconds.
    ///
    /// - Parameters:
    ///   - message: The text to display.
    ///   - font: The font of the text.
    func showToast(message: String, font: UIFont) {

        let toastLabel = UILabel(
            frame: CGRect(
                x: self.view.frame.size.width / 2 - 275, y: self.view.frame.size.height / 2, width: 300, height: 40
            ))

        toastLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        self.view.addSubview(toastLabel)
        UIView.animate(
            withDuration: 4.0, delay: 0.1, options: .curveEaseOut,
            animations: {
                toastLabel.alpha = 0.0
            },
            completion: { (isCompleted) in
                toastLabel.removeFromSuperview()
            })
    }

    /// Same as ``showToast(message:font:)`` but allows the text to wrap over two lines.
    ///
    /// - Parameters:
    ///   - message: The text to display.
    ///   - font: The font of the text.
    func showToast2(message: String, font: UIFont) {

        let toastLabel = UILabel(
            frame: CGRect(
                x: self.view.frame.size.width / 2 - 275, y: self.view.frame.size.height / 2, width: 300, height: 40))

        toastLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        toastLabel.lineBreakMode = .byWordWrapping
        toastLabel.numberOfLines = 2
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        self.view.addSubview(toastLabel)
        UIView.animate(
            withDuration: 4.0, delay: 0.1, options: .curveEaseOut,
            animations: {
                toastLabel.alpha = 0.0
            },
            completion: { (isCompleted) in
                toastLabel.removeFromSuperview()
            })
    }

    /// Light status bar content, as the screen is dark.
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Button actions

    /// Tries to resume an interrupted camera session; hides the resume UI on success, otherwise alerts the user.
    ///
    /// - Parameter sender: The "resume" button.
    @IBAction func onClickResumeButton(_ sender: Any) {

        // `Dvzo8SsdA...` = `resumeInterruptedSession(completion:)`
        cameraFeedManager.Dvzo8SsdAEGIhYhZOa5lf87UIx6gwj3H { (complete) in

            if complete {
                self.resumeButton.isHidden = true
                self.cameraUnavailableLabel.isHidden = true
            } else {
                self.presentUnableToResumeSessionAlert()
            }
        }
    }

    /// Tells the user that the camera session could not be resumed.
    func presentUnableToResumeSessionAlert() {
        let alert = UIAlertController(
            title: "alert.resumeFailedTitle".sdkLocalized,
            message: "alert.resumeFailedMessage".sdkLocalized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "common.ok".sdkLocalized, style: .default, handler: nil))

        self.present(alert, animated: true)
    }

}

// MARK: - CameraFeedManagerDelegate

/// `ZSP58vZ7...` is the obfuscated `CameraFeedManagerDelegate`; the methods below keep their obfuscated names.
extension ViewController: ZSP58vZ71h0tlSCfgRnSJI3iOmpNO2qf {

    /// `didOutput(pixelBuffer:)`: receives each camera frame and runs the model on it while
    /// some field is still missing, once `delayBeforeStarting` has elapsed.
    ///
    /// - Parameter pixelBuffer: The camera frame.
    func YSuZSMAQipUTTbB2I5iULuxr1BIACZfp(pixelBuffer: CVPixelBuffer) {

        let currentTimeMs = Date().timeIntervalSince1970 * 1000
        guard (currentTimeMs - startTimeMs) >= delayBeforeStarting else {
            return
        }

        if fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.Gv6iuNfQoFK2P4Pd3tdqXjDS25hJGyRR.contains("") {
            runModel(onPixelBuffer: pixelBuffer)
        }
    }

    /// Handles the scan timeout: when none of the six fields was read, tells the user the card could
    /// not be scanned and closes the flow; otherwise shows the recto confirmation alert.
    func presentVideoConfigurationErrorAlertFirst() {

        let results = self.result?.myArray2.filter { $0 == "" }

        if results?.count == 6 {

            let alertController = UIAlertController(
                title: "alert.sessionTimeout".sdkLocalized, message: "alert.cardScanFailed".sdkLocalized,
                preferredStyle: .alert
            )
            let okAction = UIAlertAction(
                title: "common.ok".sdkLocalized, style: .cancel,
                handler: { alertAction in
                    self.dismiss(animated: true, completion: nil)

                    self.upDown.isHidden = true

                    fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isCancel = true
                })
            alertController.addAction(okAction)

            present(alertController, animated: true, completion: nil)

        } else {

            self.initCustomAlert(delegate: self, typeAlert: .recto)

        }

    }

    /// `presentCameraPermissionsDeniedAlert()`: offers to open the app's Settings page.
    func kZMcc83qv4P2CU8e8Dkq96aSr1AAfOqu() {

        let alertController = UIAlertController(
            title: "alert.cameraDeniedTitle".sdkLocalized,
            message: "alert.cameraDeniedMessage".sdkLocalized,
            preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "common.cancel".sdkLocalized, style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "common.settings".sdkLocalized, style: .default) { (action) in

            UIApplication.shared.open(
                URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)

        present(alertController, animated: true, completion: nil)
    }

    /// `presentVideoConfigurationErrorAlert()`: tells the user the camera configuration failed, then closes the
    /// scan (there is nothing to scan with) as a cancellation.
    func wHnXp0M51N5LLTNe9YW7hnqifEcKwmWO() {
        let alertController = UIAlertController(
            title: "alert.configFailedTitle".sdkLocalized, message: "alert.configFailedMessage".sdkLocalized,
            preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: "common.ok".sdkLocalized, style: .cancel,
            handler: { _ in
                self.stopScanning()
                self.cancel()
            })
        alertController.addAction(okAction)

        present(alertController, animated: true, completion: nil)
    }

    /// `sessionRunTimeErrorOccured()`: shows the resume button so the user can restart the session manually.
    func a5ccfNWAcEPeFtvp82hwA22Y6JLkyrsv() {
        self.resumeButton.isHidden = false
    }

    /// `sessionWasInterrupted(canResumeManually:)`: shows the resume button, or the
    /// "camera unavailable" label when the session cannot be resumed manually.
    ///
    /// - Parameter resumeManually: Whether the user can resume the session.
    func Elm5KJmsn1DFeuYmbW1OtrwrmH8AnuwW(canResumeManually resumeManually: Bool) {
        if resumeManually {
            self.resumeButton.isHidden = false
        } else {
            self.cameraUnavailableLabel.isHidden = false
        }
    }

    /// `sessionInterruptionEnded()`: hides the resume button and the "camera unavailable" label.
    func JkiHfUKgZ896sjDkuK5AX3F2mV412zED() {
        if !self.cameraUnavailableLabel.isHidden {
            self.cameraUnavailableLabel.isHidden = true
        }

        if !self.resumeButton.isHidden {
            self.resumeButton.isHidden = true
        }

    }

    /// Runs a live camera frame through the TensorFlow Lite model (at most every `delayBetweenInferencesMs`).
    ///
    /// When every field has been recognised, the fields are stored in the session, the timer and the
    /// camera are stopped and the recto confirmation alert is shown.
    ///
    /// - Parameter pixelBuffer: The camera frame to analyse.
    @objc func runModel(onPixelBuffer pixelBuffer: CVPixelBuffer) {

        let currentTimeMs = Date().timeIntervalSince1970 * 1000

        guard (currentTimeMs - previousInferenceTimeMs) >= delayBetweenInferencesMs else {
            return
        }

        previousInferenceTimeMs = currentTimeMs
        result = self.modelDataHandler?.runModel(onFrame: pixelBuffer)

        guard result != nil else {
            return
        }

        DispatchQueue.main.async {

            if !(self.result?.myArray2.contains(""))! {

                fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.Gv6iuNfQoFK2P4Pd3tdqXjDS25hJGyRR = self.result!.myArray2

                self.upDown.isHidden = true

                self.timer?.invalidate()

                self.cameraFeedManager.xdN0btp63XTVDRanlrXOLP1NfzJLVEE3()

                self.initCustomAlert(delegate: self, typeAlert: .recto)

            }
        }
    }

}

// MARK: - CustomAlertDelegate / ScannerCancellable

extension ViewController: CustomAlertDelegate, ScannerCancellable {

    /// Stops the timeout timer (the camera is stopped by `viewWillDisappear(_:)`).
    func stopScanning() {
        timer?.invalidate()
    }

    /// The user cancelled: dismisses the screen and flags the cancellation.
    func cancel() {
        self.dismiss(animated: true, completion: nil)
        fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isCancel = true
    }

    /// The user confirmed the recto: presents the verso screen (`MainVideoViewController`) full screen,
    /// passing the completion callback along.
    func confirm() {
        let viewController: BaseVC =
            UIStoryboard(name: "Main", bundle: .sdk).instantiateViewController(
                withIdentifier: "MainVideoViewController") as! BaseVC
        viewController.didScanComplete = didScanComplete
        viewController.modalPresentationStyle = .fullScreen
        self.present(viewController, animated: true)
    }

}

// MARK: - Timeout timer

extension ViewController {

    /// Timer tick (once per second): shows a tip at 8 s and 15 s and handles the timeout at `timeOut`.
    @objc func countdown() {

        switch self.countdownValue {

        case 8:
            self.showToast(
                message: "toast.avoidReflections".sdkLocalized,
                font: .systemFont(ofSize: 12.0))
        case 15:
            self.showToast2(
                message:
                    "toast.alignCard"
                    .sdkLocalized, font: .systemFont(ofSize: 11.0))

        case timeOut:

            presentVideoConfigurationErrorAlertFirst()

            fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.isTimeOut = true

            timer?.invalidate()

        default:
            break
        }
        self.countdownValue += 1

    }

    /// (Re)starts the one-second repeating timer that calls `countdown()`.
    private func startTimer() {

        if let timer = self.timer {
            timer.invalidate()
        }

        self.timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(self.countdown),
            userInfo: nil,
            repeats: true
        )
    }

}
