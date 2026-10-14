import UIKit

/// A button whose background is a two-colour linear gradient, with an optional border and corner radius.
///
/// Every property is `@IBInspectable`, so the gradient can also be configured from Interface Builder.
@IBDesignable
public class GradientBtn: UIButton {

    /// Colour at the start of the gradient.
    @IBInspectable var startColor: UIColor = .black { didSet { updateColors() } }

    /// Colour at the end of the gradient.
    @IBInspectable var endColor: UIColor = .white { didSet { updateColors() } }

    /// Position (0...1) where `startColor` begins.
    @IBInspectable var startLocation: Double = 0.05 { didSet { updateLocations() } }

    /// Position (0...1) where `endColor` is reached.
    @IBInspectable var endLocation: Double = 0.95 { didSet { updateLocations() } }

    /// When `true` the gradient runs left to right instead of top to bottom.
    @IBInspectable var horizontalMode: Bool = false { didSet { updatePoints() } }

    /// When `true` the gradient runs along a diagonal.
    @IBInspectable var diagonalMode: Bool = false { didSet { updatePoints() } }

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

    public override class var layerClass: AnyClass { CAGradientLayer.self }

    /// The backing layer, typed as a gradient layer.
    private var gradientLayer: CAGradientLayer {
        // swiftlint:disable:next force_cast
        layer as! CAGradientLayer
    }

    /// Updates the start/end points of the gradient from `horizontalMode` and `diagonalMode`.
    private func updatePoints() {
        if horizontalMode {
            gradientLayer.startPoint = diagonalMode ? .init(x: 1, y: 0) : .init(x: 0, y: 0.5)
            gradientLayer.endPoint = diagonalMode ? .init(x: 0, y: 1) : .init(x: 1, y: 0.5)
        } else {
            gradientLayer.startPoint = diagonalMode ? .init(x: 0, y: 0) : .init(x: 0.5, y: 0)
            gradientLayer.endPoint = diagonalMode ? .init(x: 1, y: 1) : .init(x: 0.5, y: 1)
        }
    }

    /// Applies `startLocation` and `endLocation` to the gradient layer.
    private func updateLocations() {
        gradientLayer.locations = [startLocation as NSNumber, endLocation as NSNumber]
    }

    /// Applies `startColor` and `endColor` to the gradient layer.
    private func updateColors() {
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updatePoints()
        updateLocations()
        updateColors()
    }
}
