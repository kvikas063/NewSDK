import UIKit

/// A circular spinner: a round stroke whose arc grows and shrinks while the whole view rotates.
///
/// Call `animateStroke()` and `animateRotation()` to start the animations.
class CircularLoadingIndicator: UIView {
    /// The stroke colors; only the first one is used.
    let colors: [UIColor]
    /// Width of the circular stroke.
    let lineWidth: CGFloat

    /// The circle path layer, stroked with the first color; added to the view's layer by `animateStroke()`.
    private lazy var shapeLayer: ProgressShapeLayer = {
        ProgressShapeLayer(strokeColor: colors.first!, lineWidth: lineWidth)
    }()

    /// Creates an indicator with a frame.
    ///
    /// - Parameters:
    ///   - frame: The initial frame of the view.
    ///   - colors: The stroke colors; must contain at least one color (only the first is used).
    ///   - lineWidth: Width of the circular stroke.
    init(
        frame: CGRect,
        colors: [UIColor],
        lineWidth: CGFloat
    ) {
        self.colors = colors
        self.lineWidth = lineWidth

        super.init(frame: frame)

        backgroundColor = .clear
    }

    /// Creates an indicator with a zero frame, to be sized later by Auto Layout.
    ///
    /// - Parameters:
    ///   - colors: The stroke colors; must contain at least one color (only the first is used).
    ///   - lineWidth: Width of the circular stroke.
    convenience init(colors: [UIColor], lineWidth: CGFloat) {
        self.init(frame: .zero, colors: colors, lineWidth: lineWidth)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Rounds the view and updates the stroke path to an oval as wide as the view.
    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = frame.width / 2

        let path = UIBezierPath(
            ovalIn:
                CGRect(
                    x: 0,
                    y: 0,
                    width: bounds.width,
                    height: bounds.width
                )
        )

        shapeLayer.path = path.cgPath
    }

    // MARK: - Animations

    /// Adds the shape layer and starts the endless "growing and shrinking arc" stroke animation (1 s cycle).
    func animateStroke() {

        let startAnimation = StrokeAnimation(
            type: .start,
            beginTime: 0.25,
            fromValue: 0.0,
            toValue: 1.0,
            duration: 0.75
        )
        let endAnimation = StrokeAnimation(
            type: .end,
            fromValue: 0.0,
            toValue: 1.0,
            duration: 0.75
        )
        let strokeAnimationGroup = CAAnimationGroup()
        strokeAnimationGroup.duration = 1
        strokeAnimationGroup.repeatDuration = .infinity
        strokeAnimationGroup.animations = [startAnimation, endAnimation]
        shapeLayer.add(strokeAnimationGroup, forKey: nil)

        layer.addSublayer(shapeLayer)
    }

    /// Starts an endless rotation of the whole view around the Z axis (one turn every 2 s).
    func animateRotation() {
        let rotationAnimation = RotationAnimation(
            direction: .z,
            fromValue: 0,
            toValue: CGFloat.pi * 2,
            duration: 2,
            repeatCount: .greatestFiniteMagnitude
        )

        layer.add(rotationAnimation, forKey: nil)
    }
}
