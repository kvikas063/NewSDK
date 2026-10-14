import UIKit

/// Full-screen dimming overlay with a transparent oval "window" where the user's face should be.
///
/// The area outside the oval is filled with 60% black and the oval is outlined in white.
class FaceView: UIView {

    /// The layers added by the last `draw(_:)` call, removed before the next redraw.
    private var overlayLayers: [CALayer] = []

    /// The rectangle, in the view's coordinate space, that bounds the transparent oval.
    var overlayFrame: CGRect = .zero

    /// Creates the overlay covering the whole screen.
    ///
    /// - Parameter rect: The rectangle bounding the oval cut-out (empty by default; it can be set later through
    ///   `overlayFrame`).
    init(rect: CGRect = .zero) {
        super.init(frame: UIScreen.main.bounds)
        backgroundColor = UIColor.clear
        accessibilityIdentifier = "takeASelfieOvalOverlayView"
        overlayFrame = rect
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Adds two layers: a dimming fill with the oval cut out (even-odd fill rule) and the white oval outline.
    ///
    /// The layers added by a previous call are removed first, so repeated redraws do not stack layers.
    ///
    /// - Parameter rect: The portion of the view that needs updating (unused).
    override func draw(_ rect: CGRect) {

        let overlayPath = UIBezierPath(rect: bounds)
        let ovalPath = UIBezierPath(ovalIn: overlayFrame)
        overlayPath.append(ovalPath)
        overlayPath.usesEvenOddFillRule = true
        // draw oval layer
        let ovalLayer = CAShapeLayer()
        ovalLayer.path = ovalPath.cgPath
        ovalLayer.fillColor = UIColor.clear.cgColor
        ovalLayer.strokeColor = UIColor.white.cgColor
        ovalLayer.lineWidth = 2.0
        // draw layer that fills the view
        let fillLayer = CAShapeLayer()
        fillLayer.path = overlayPath.cgPath
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
        fillLayer.fillColor = UIColor.black.withAlphaComponent(0.6).cgColor
        // replace the layers of the previous redraw
        overlayLayers.forEach { $0.removeFromSuperlayer() }
        layer.addSublayer(fillLayer)
        layer.addSublayer(ovalLayer)
        overlayLayers = [fillLayer, ovalLayer]
    }

}
