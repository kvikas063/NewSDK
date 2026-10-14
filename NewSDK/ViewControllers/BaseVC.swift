import UIKit

/// Implemented by scanner screens that own a camera and/or timers to release when the user cancels.
protocol ScannerCancellable {

    /// Stops the screen's own camera session and/or timers.
    func stopScanning()
}

/// Base class of every CIN scanner screen (recto / verso, old and new CIN).
///
/// It provides the pieces the screens share: the completion callback handed to the host app,
/// the "Annuler" button, the animated scan bar, the camera-unavailable alert and the
/// recto/verso confirmation alert (``CustomAlert``).
public class BaseVC: UIViewController {

    // MARK: - Properties

    /// The confirmation alert currently shown by ``initCustomAlert(delegate:typeAlert:)``, if any.
    var customAlert: CustomAlert?

    /// Called with the scan result once the whole flow has finished; it is forwarded from one
    /// screen to the next when the following screen is instantiated.
    public var didScanComplete: ((KycResultViewModel?) -> Void)?

    /// Optional container view used to size the confirmation alert horizontally.
    ///
    /// It is not connected in `Main.storyboard`, so it is `nil` and the alert uses the full view width.
    @IBOutlet weak var uv_body: UIView?

    /// Whether the scan-bar animation has already been started.
    private var scanBarAnimationStarted = false

    /// Whether the camera-unavailable alert has already been presented.
    private var cameraAlertShown = false

    // MARK: - Scan bar

    /// Sweeps the scan bar left/right. Runs once: `viewWillAppear` can fire several times and the
    /// original code shifted the bar again on every call, making it drift off its track.
    ///
    /// - Parameter bar: The scan bar view to animate.
    func startScanBarAnimation(_ bar: UIView) {
        guard !scanBarAnimationStarted else { return }
        scanBarAnimationStarted = true
        UIView.animate(
            withDuration: 0.1,
            animations: {
                bar.frame.origin.x -= 70
            }
        ) { _ in
            UIView.animateKeyframes(
                withDuration: 1.2, delay: 0.25, options: [.repeat, .autoreverse],
                animations: {
                    bar.frame.origin.x += 220
                })
        }
    }

    // MARK: - Camera unavailable

    /// Tells the user the camera could not be started (permission denied, no camera, ...)
    /// instead of leaving a black screen, then closes the flow as a cancellation.
    ///
    /// The alert is presented at most once per screen.
    func presentCameraUnavailableAlert() {
        guard !cameraAlertShown else { return }
        cameraAlertShown = true
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
                    (self as? ScannerCancellable)?.stopScanning()
                    (self as? CustomAlertDelegate)?.cancel()
                }))
        present(alert, animated: true)
    }

    // MARK: - Cancel button

    /// Adds a "Cancel" button at the top-left of a scanner screen.
    func addScannerCancelButton() {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "common.cancel".sdkLocalized
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        configuration.background.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        configuration.background.cornerRadius = 16
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .systemFont(ofSize: 15, weight: .semibold)
            return attributes
        }
        let button = UIButton(configuration: configuration)
        button.accessibilityIdentifier = "scannerCancelButton"
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(scannerCancelTapped), for: .touchUpInside)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
        ])
    }

    /// The host app's view controller that presented the first scanner screen of the flow.
    ///
    /// Walks up the chain of presenting scanner screens (`BaseVC`); `nil` when the flow was not presented.
    var scanFlowPresenter: UIViewController? {
        var first: UIViewController = self
        while let presenter = first.presentingViewController, presenter is BaseVC {
            first = presenter
        }
        return first.presentingViewController
    }

    /// Dismisses the whole scan flow, however many scanner screens are stacked.
    ///
    /// Everything is dismissed from the host's view controller (`scanFlowPresenter`). Unlike dismissing a
    /// fixed number of levels, this is correct whichever screen of the flow it is called from.
    ///
    /// - Parameters:
    ///   - animated: Whether the dismissal is animated.
    ///   - completion: Called once the flow has been dismissed.
    func dismissScanFlow(animated: Bool, completion: (() -> Void)? = nil) {
        (scanFlowPresenter ?? self).dismiss(animated: animated, completion: completion)
    }

    /// Stops the screen's own camera / timers, then reuses the screen's `cancel()` (CustomAlertDelegate),
    /// which flags the cancellation and dismisses the flow.
    @objc func scannerCancelTapped() {
        (self as? ScannerCancellable)?.stopScanning()
        (self as? CustomAlertDelegate)?.cancel()
    }

    // MARK: - Custom alert

    /// Shows the "recto/verso scanned" confirmation alert on top of the screen.
    ///
    /// The alert is rotated by 90° because the scanner screens are laid out in landscape while the
    /// view hierarchy stays in portrait.
    ///
    /// - Parameters:
    ///   - delegate: Receives `cancel()` / `confirm()` when the user taps a button.
    ///   - typeAlert: Which side of the card was scanned, which selects the alert texts.
    func initCustomAlert(delegate: CustomAlertDelegate? = nil, typeAlert: typeAlert) {
        let alert = CustomAlert()
        alert.transform = CGAffineTransform(rotationAngle: .pi / 2)
        alert.frame = CGRect(
            x: uv_body?.frame.origin.x ?? view.frame.origin.x,
            y: view.frame.origin.y,
            width: uv_body?.frame.width ?? view.frame.width,
            height: view.frame.height)
        alert.initAlert(typeOfAler: typeAlert, delegate: delegate)
        customAlert = alert

        view.addSubview(alert)
    }

}
