import AVFoundation
import NewSDK
import UIKit

/// Entry screen of the example app: starts a new-CIN or old-CIN scan with `NewSDKScanner` and shows the outcome.
final class HomeViewController: UIViewController {

    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "NewSDK Example"
        view.backgroundColor = .systemBackground

        let intro = UILabel()
        intro.text = "Scan a Moroccan national ID card (CIN) and read back the extracted data."
        intro.numberOfLines = 0
        intro.textAlignment = .center
        intro.font = .preferredFont(forTextStyle: .body)

        let newCinButton = makeButton(title: "Scan new CIN", action: #selector(scanNewCin))
        let oldCinButton = makeButton(title: "Scan old CIN", action: #selector(scanOldCin))

        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [intro, newCinButton, oldCinButton, statusLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -8),
        ])
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = title
        button.configuration = config
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - SDK entry points

    @objc private func scanNewCin() {
        startScan { NewSDKScanner.makeNewCinScanner(didScanComplete: $0) }
    }

    @objc private func scanOldCin() {
        startScan { NewSDKScanner.makeOldCinScanner(didScanComplete: $0) }
    }

    /// 1. Check the ML Kit resource bundles the host app must provide.
    /// 2. Make sure the camera is authorised.
    /// 3. Create the SDK's first screen with a factory; `didScanComplete` is forwarded through the whole
    ///    flow (recto → verso) and called once, with the final result.
    private func startScan(makeScanner: @escaping (@escaping (KycResultViewModel?) -> Void) -> UIViewController) {
        let missing = NewSDKScanner.missingMLKitResourceBundles()
        guard missing.isEmpty else {
            statusLabel.text =
                "Missing ML Kit resources: \(missing.joined(separator: ", ")). "
                + "Add them to Copy Bundle Resources (scripts/download_mlkit_bundles.sh)."
            return
        }
        ensureCameraAccess { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                self.statusLabel.text = "Camera access denied. Enable it in Settings > Privacy > Camera."
                return
            }
            let scanner = makeScanner { [weak self] result in
                self?.handle(result)
            }
            self.present(scanner, animated: true)
        }
    }

    private func handle(_ result: KycResultViewModel?) {
        guard let result = result else {
            statusLabel.text = "Scan returned no result."
            return
        }
        statusLabel.text = nil
        navigationController?.pushViewController(ResultViewController(result: result), animated: true)
    }

    private func ensureCameraAccess(_ completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            completion(false)
        }
    }

    // The SDK reports cancel / time-out through these flags instead of calling the callback.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if presentedViewController == nil, navigationController?.topViewController === self {
            if fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.getTimeOut() {
                statusLabel.text = "Scan timed out."
            } else if fKrUHvHJknyK3g7L2vSipDnasRUh8RKV.getIsCancel() {
                statusLabel.text = "Scan cancelled."
            }
        }
    }
}
