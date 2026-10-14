import UIKit

/// A view with inspectable border, corner radius and shadow settings.
///
/// Used by the storyboard scenes (as `Shadow`) for the scan bar and the card frame. The inspectable
/// properties are set from Interface Builder's user-defined runtime attributes.
@IBDesignable
class Shadow: UIView {

    /// `true` when the top-right corner must be rounded in `layoutSubviews()`.
    private var isCardUI = false

    /// Border colour of the view.
    @IBInspectable var borderColor: UIColor = .clear {
        didSet { layer.borderColor = borderColor.cgColor }
    }

    /// Border width of the view.
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet { layer.borderWidth = borderWidth }
    }

    /// Corner radius of the view.
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet { layer.cornerRadius = cornerRadius }
    }

    /// Shadow colour.
    @IBInspectable var shadowColor: UIColor = .clear {
        didSet { layer.shadowColor = shadowColor.cgColor }
    }

    /// Shadow blur radius.
    @IBInspectable var shadowRadius: CGFloat = 0 {
        didSet { layer.shadowRadius = shadowRadius }
    }

    /// Shadow opacity (0...1).
    @IBInspectable var shadowOpacity: Float = 0 {
        didSet { layer.shadowOpacity = shadowOpacity }
    }

    /// Shadow offset.
    @IBInspectable var shadowOffset: CGSize = .zero {
        didSet { layer.shadowOffset = shadowOffset }
    }

    /// When `true` the top-right corner is rounded with a radius of 50 points (card style).
    @IBInspectable var isCard: Bool = false {
        didSet { isCardUI = isCard }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if isCardUI {
            roundCorners(corners: [.topRight], radius: 50)
        }
    }
}

extension UIView {

    /// Rounds only the given corners of the view by masking its layer.
    ///
    /// - Parameters:
    ///   - corners: The corners to round.
    ///   - radius: The corner radius, in points.
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

/// A button with inspectable border and corner radius settings.
@IBDesignable
class CornerBtn: UIButton {

    /// Border colour of the button.
    @IBInspectable var borderColor: UIColor = .clear {
        didSet { layer.borderColor = borderColor.cgColor }
    }

    /// Border width of the button.
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet { layer.borderWidth = borderWidth }
    }

    /// Corner radius of the button.
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet { layer.cornerRadius = cornerRadius }
    }
}
