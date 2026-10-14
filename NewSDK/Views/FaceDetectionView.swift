import UIKit

/// Receives the user's request to leave the selfie screen from a ``FaceDetectionView``.
protocol FaceDetectionDelegate: AnyObject {

    /// Called when the user taps the back button of the face detection overlay.
    func closeCamera()
}

// MARK: - FaceDetectionView

/// Overlay drawn on top of the selfie camera preview: a back button, an emoji and a hint
/// ("blink" / "face the camera"), an oval face guide with a sweeping scan bar and a loading indicator.
open class FaceDetectionView: UIView {

    /// Informed when the back button is tapped. Weak, because the owning controller also holds this view.
    weak var delegate: FaceDetectionDelegate?

    // MARK: - Properties

    /// Dimmed overlay with the oval cut-out showing where the face must be placed.
    private let ovalOverlayView = FaceView()

    /// Flexible placeholder in the main stack; its frame positions the oval cut-out.
    private let uiView = UIView()

    /// Circular spinner shown at the bottom of the screen.
    let loadingIndicator: CircularLoadingIndicator = {
        let progress = CircularLoadingIndicator(colors: [Colors.frameColor], lineWidth: 5)
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()

    /// Horizontal bar with the back button, the title stack and a spacer.
    let topBar: UIStackView = {
        let stack = UIStackView()
        stack.distribution = .fill
        stack.axis = .horizontal
        return stack
    }()

    /// Vertical stack laying out the top bar, the face placeholder and the loading indicator.
    let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.distribution = .fill
        stack.alignment = .center
        stack.axis = .vertical
        stack.spacing = 35
        return stack
    }()

    /// Vertical stack holding the emoji and the assistance label.
    let titleStack: UIStackView = {
        let stack = UIStackView()
        stack.distribution = .fill
        stack.alignment = .center
        stack.axis = .vertical
        stack.spacing = 10
        return stack
    }()

    /// Vertical scan bar swept left/right across the oval.
    let uv_Updown: Shadow = {
        let upDown = Shadow()
        upDown.backgroundColor = Colors.upDownBarColor
        upDown.shadowColor = Colors.shadowColor
        upDown.shadowRadius = 8
        upDown.shadowOpacity = 1
        upDown.cornerRadius = 2
        upDown.translatesAutoresizingMaskIntoConstraints = false

        return upDown
    }()

    /// Hint label telling the user what to do ("blink", then "face the camera").
    let lbl_assistance: UILabel = {
        let label = UILabel()
        label.text = "face.hintBlink".sdkLocalized
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = label.font.withSize(19)
        label.numberOfLines = 2
        return label
    }()

    /// Animated blinking emoji shown above the hint; hidden once the blink has been detected.
    let img_emoji = UIImageView()

    // MARK: - Initializers

    /// Builds the view from a nib/storyboard and sets up the UI and the loader animations.
    ///
    /// - Parameter coder: The unarchiver used to decode the view.
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        configureUI()
        setupUpdown()
        loadingIndicator.animateStroke()
        loadingIndicator.animateRotation()
    }

    /// Creates the overlay, adds the oval cut-out and sets up the UI and the loader animations.
    ///
    /// - Parameter frame: The frame of the view.
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(ovalOverlayView)
        configureUI()
        setupUpdown()
        loadingIndicator.animateStroke()
        loadingIndicator.animateRotation()
    }

    /// Creates the overlay and registers its delegate.
    ///
    /// - Parameters:
    ///   - frame: The frame of the view.
    ///   - delegate: Informed when the user taps the back button.
    convenience init(frame: CGRect, delegate: FaceDetectionDelegate) {
        self.init(frame: frame)
        self.delegate = delegate
    }

}

// MARK: - Layout

extension FaceDetectionView {

    /// Creates the back button, the emoji/hint block, assembles the stacks, activates the constraints
    /// and positions the oval cut-out inside the placeholder view.
    private func configureUI() {
        // MARK: back button
        let image = UIImage(named: "btprecedent", in: .sdk, compatibleWith: nil) as UIImage?
        let backButton = UIButton(type: UIButton.ButtonType.custom) as UIButton

        backButton.setImage(image, for: .normal)
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.addTarget(self, action: #selector(self.action_closeCamera(_:)), for: UIControl.Event.touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        backButton.heightAnchor.constraint(equalTo: backButton.widthAnchor).isActive = true
        let leftUiView = UIView()
        leftUiView.addSubview(backButton)
        backButton.topAnchor.constraint(equalTo: leftUiView.topAnchor, constant: 8).isActive = true
        backButton.leadingAnchor.constraint(equalTo: leftUiView.leadingAnchor, constant: 8).isActive = true

        // MARK: clignement title with gif
        let clignementGif = UIImage.gif(asset: "emoclignement")
        img_emoji.image = clignementGif
        img_emoji.contentMode = .scaleAspectFit
        img_emoji.translatesAutoresizingMaskIntoConstraints = false
        img_emoji.widthAnchor.constraint(equalToConstant: 40).isActive = true
        img_emoji.heightAnchor.constraint(equalTo: img_emoji.widthAnchor).isActive = true

        titleStack.addArrangedSubview(img_emoji)
        titleStack.addArrangedSubview(lbl_assistance)

        let rightUiView = UIView()
        rightUiView.translatesAutoresizingMaskIntoConstraints = false
        topBar.addArrangedSubview(leftUiView)
        topBar.addArrangedSubview(titleStack)
        topBar.addArrangedSubview(rightUiView)

        // MARK: main StackView
        uiView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubview(topBar)
        mainStackView.addArrangedSubview(uiView)
        mainStackView.addArrangedSubview(loadingIndicator)
        self.addSubview(mainStackView)

        // MARK: constraints
        NSLayoutConstraint.activate([

            loadingIndicator.widthAnchor.constraint(equalToConstant: 50),
            loadingIndicator.heightAnchor.constraint(equalToConstant: 50),

            mainStackView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 40),
            mainStackView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -25),
            mainStackView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -20),

            rightUiView.widthAnchor.constraint(equalTo: leftUiView.widthAnchor),

            topBar.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),

            topBar.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),

            uiView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor, constant: 8),
            uiView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor, constant: -8),

        ])

        self.layoutIfNeeded()
        let height = uiView.frame.height * 0.8
        let width = height * 0.69
        self.ovalOverlayView.overlayFrame = CGRect(
            x: (self.frame.width - width) / 2, y: mainStackView.frame.origin.y + uiView.frame.midY - height / 2,
            width: width, height: height)
        self.ovalOverlayView.layoutSubviews()
        self.layoutIfNeeded()

    }

    /// Adds the scan bar over the oval and starts its animation.
    func setupUpdown() {
        self.addSubview(uv_Updown)
        NSLayoutConstraint.activate([
            uv_Updown.widthAnchor.constraint(equalToConstant: 5),
            uv_Updown.heightAnchor.constraint(equalToConstant: self.ovalOverlayView.overlayFrame.height + 20),
            uv_Updown.leadingAnchor.constraint(
                equalTo: self.leadingAnchor, constant: self.ovalOverlayView.overlayFrame.origin.x + 20),
            uv_Updown.topAnchor.constraint(
                equalTo: self.topAnchor, constant: self.ovalOverlayView.overlayFrame.origin.y - 10),
        ])
        startAnimation()
    }

    /// (Re)starts the endless left/right sweep of the scan bar across the oval.
    func startAnimation() {
        self.uv_Updown.layer.removeAllAnimations()
        UIView.animate(
            withDuration: 0.1,
            animations: {
            }
        ) { _ in
            UIView.animateKeyframes(
                withDuration: 1.25, delay: 0.25, options: [.repeat, .autoreverse],
                animations: {
                    self.uv_Updown.frame.origin.x = self.ovalOverlayView.overlayFrame.maxX - 20

                })
        }

    }

    /// Back-button handler; forwards to the delegate.
    ///
    /// - Parameter sender: The tapped button.
    @objc func action_closeCamera(_ sender: UIButton) {
        delegate?.closeCamera()
    }

    /// Updates the hint label (and the emoji) to match the current liveness step.
    ///
    /// - Parameter message: `.blink` asks the user to blink; `.facePositioning` asks the user to face
    ///   the camera and hides the emoji.
    public func updateAssistanceMsg(_ message: SelfieAssistance) {
        switch message {
        case .blink:
            lbl_assistance.text = "face.hintBlink".sdkLocalized
        case .facePositioning:
            lbl_assistance.text = "face.hintFacing".sdkLocalized
            img_emoji.isHidden = true
        }
    }
}
