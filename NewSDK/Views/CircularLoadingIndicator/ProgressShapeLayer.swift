import UIKit

/// A shape layer styled for the circular loading indicator: an unfilled path with rounded line caps.
class ProgressShapeLayer: CAShapeLayer {

    /// Creates the layer.
    ///
    /// - Parameters:
    ///   - strokeColor: The color of the stroke.
    ///   - lineWidth: The width of the stroke.
    init(strokeColor: UIColor, lineWidth: CGFloat) {
        super.init()

        self.strokeColor = strokeColor.cgColor
        self.lineWidth = lineWidth
        fillColor = UIColor.clear.cgColor
        lineCap = .round
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
