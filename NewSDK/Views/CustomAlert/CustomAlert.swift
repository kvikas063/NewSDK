import UIKit

/// Receives the user's choice from a ``CustomAlert``.
protocol CustomAlertDelegate {

    /// Called after the user tapped "Annuler" and the alert was animated away.
    func cancel()

    /// Called after the user tapped "Continuer" and the alert was animated away.
    func confirm()
}

/// Default no-op implementations so conforming types only implement what they need.
extension CustomAlertDelegate {
    func cancel() {}
    func confirm() {}
}

/// The side of the identity card whose scan the alert reports on.
enum AlertOf {

    /// Front side: the alert says the recto was scanned and invites the user to scan the verso.
    case recto

    /// Back side: the alert says the whole identity document was scanned.
    case verso
}

/// Lower-camel alias of ``AlertOf`` used at the call sites (`typeAlert: .recto`).
typealias typeAlert = AlertOf

// MARK: - CustomAlert

/// Full-screen dimmed overlay hosting a card with a title, an optional subtitle and the
/// "Annuler" / "Continuer" buttons, shown once the recto or the verso has been scanned.
open class CustomAlert: UIView {

    // MARK: Properties

    /// Notified when one of the two buttons is tapped.
    var delegate: CustomAlertDelegate?

    // MARK: - UI Properties

    /// Rounded white card with a shadow that contains the title stack and the buttons.
    let uv_shadow: Shadow = {
        let uv = Shadow()
        uv.shadowColor = UIColor.black
        uv.shadowRadius = 5
        uv.shadowOpacity = 0.4
        uv.shadowOffset = CGSize(width: 0, height: 0)
        uv.borderColor = UIColor.lightGray
        uv.borderWidth = 4
        uv.cornerRadius = 30
        uv.backgroundColor = UIColor.white
        uv.translatesAutoresizingMaskIntoConstraints = false
        return uv
    }()

    /// Vertical stack holding the icon, the title and the subtitle.
    let titleStack: UIStackView = {
        let stack = UIStackView()
        stack.distribution = .fill
        stack.alignment = .fill
        stack.axis = .vertical
        stack.spacing = 22
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// Horizontal stack holding the cancel and confirm buttons.
    let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.axis = .horizontal
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// Cancel button ("Annuler"), tag `0`.
    let leftButton = CornerBtn()

    /// Confirm button ("Continuer"), tag `1`.
    let rightButton = GradientBtn()

    /// Main message, filled by ``rectoAlert()`` or ``versoAlert()``.
    let ul_title: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.text = ""
        label.numberOfLines = 0
        return label
    }()

    /// Secondary message below the title; hidden for the verso alert.
    let ul_subTitle: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.text = ""
        return label
    }()

    // MARK: - Initializers

    /// Fills the alert with the texts for the given card side and lays out its subviews.
    ///
    /// - Parameters:
    ///   - typeOfAler: Which card side was scanned (selects the title/subtitle).
    ///   - delegate: Receives `cancel()` / `confirm()` when a button is tapped.
    func initAlert(typeOfAler: typeAlert, delegate: CustomAlertDelegate? = nil) {
        self.delegate = delegate
        switch typeOfAler {
        case .recto:
            rectoAlert()
        case .verso:
            versoAlert()
        }
        configureUI()
    }
}
// MARK: - UI

extension CustomAlert {

    /// Builds the dimmed background, the icon, the two buttons and adds the card to the view.
    private func configureUI() {
        //view background color
        self.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        //icon
        let img_emoji = UIImageView()
        img_emoji.contentMode = .scaleAspectFit
        img_emoji.heightAnchor.constraint(equalToConstant: 55).isActive = true
        img_emoji.image = UIImage(named: "emosuccess", in: .sdk, compatibleWith: nil) as UIImage?

        //title
        titleStack.addArrangedSubview(img_emoji)
        titleStack.addArrangedSubview(ul_title)
        titleStack.addArrangedSubview(ul_subTitle)

        //left button
        leftButton.cornerRadius = 20
        leftButton.borderWidth = 2
        leftButton.borderColor = UIColor.lightGray
        leftButton.setTitle("common.cancel".sdkLocalized, for: .normal)
        leftButton.setTitleColor(UIColor.lightGray, for: .normal)
        leftButton.tag = 0
        leftButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        leftButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        leftButton.addTarget(self, action: #selector(action_clickOn(sender:)), for: .touchUpInside)

        //right button
        rightButton.cornerRadius = 20
        rightButton.startColor = UIColor.systemPink
        rightButton.endColor = UIColor.systemRed
        rightButton.startLocation = 0.3
        rightButton.endLocation = 0.7
        rightButton.horizontalMode = true
        rightButton.setTitle("common.continue".sdkLocalized, for: .normal)
        rightButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        rightButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        rightButton.addTarget(self, action: #selector(action_clickOn(sender:)), for: .touchUpInside)
        rightButton.tag = 1

        buttonStack.addArrangedSubview(leftButton)
        buttonStack.addArrangedSubview(rightButton)

        uv_shadow.addSubview(titleStack)
        uv_shadow.addSubview(buttonStack)

        self.addSubview(uv_shadow)

        setConstraints()
    }

    // MARK: - Constraints

    /// Centres the card (315-350pt wide) and stacks the title block above the buttons inside it.
    private func setConstraints() {

        NSLayoutConstraint.activate([

            uv_shadow.widthAnchor.constraint(lessThanOrEqualToConstant: 350),
            uv_shadow.widthAnchor.constraint(greaterThanOrEqualToConstant: 315),
            uv_shadow.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            uv_shadow.centerYAnchor.constraint(equalTo: self.centerYAnchor),

            titleStack.topAnchor.constraint(equalTo: uv_shadow.topAnchor, constant: 40),
            titleStack.leadingAnchor.constraint(equalTo: uv_shadow.leadingAnchor, constant: 30),
            titleStack.trailingAnchor.constraint(equalTo: uv_shadow.trailingAnchor, constant: -30),

            buttonStack.centerXAnchor.constraint(equalTo: uv_shadow.centerXAnchor),
            buttonStack.heightAnchor.constraint(equalToConstant: 40),
            buttonStack.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 30),
            buttonStack.bottomAnchor.constraint(equalTo: uv_shadow.bottomAnchor, constant: -40),

            leftButton.widthAnchor.constraint(equalTo: uv_shadow.widthAnchor, multiplier: 0.4),
            rightButton.widthAnchor.constraint(equalTo: uv_shadow.widthAnchor, multiplier: 0.4),

        ])
    }

    // MARK: - Actions

    /// Handles both buttons: animates the alert away, then forwards to the delegate based on the
    /// button tag (`0` cancel, `1` confirm).
    ///
    /// - Parameter sender: The tapped button.
    @objc
    private func action_clickOn(sender: UIButton) {
        dismissWithAnimation {
            switch sender.tag {
            case 0: self.delegate?.cancel()
            case 1: self.delegate?.confirm()
            default: break
            }
        }
    }

    /// Fades and shrinks the card, then runs `action` and removes the alert from its superview.
    ///
    /// - Parameter action: Executed once the animation has completed.
    private func dismissWithAnimation(_ action: @escaping () -> Void) {
        UIView.animate(
            withDuration: 0.2, delay: 0.0, options: .curveEaseIn,
            animations: {
                self.uv_shadow.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.uv_shadow.alpha = 0.0
                self.backgroundColor = .clear
            },
            completion: { _ in
                action()
                self.removeFromSuperview()
            })
    }

}

// MARK: - Custom Alert UI

extension CustomAlert {

    /// Texts shown after the recto has been scanned.
    func rectoAlert() {
        ul_title.text = "scan.rectoDone".sdkLocalized
        ul_subTitle.text = "scan.goVerso".sdkLocalized
    }

    /// Text shown after the verso has been scanned; the subtitle is hidden.
    func versoAlert() {
        ul_title.text = "scan.cardDone".sdkLocalized
        ul_subTitle.isHidden = true
    }

}
