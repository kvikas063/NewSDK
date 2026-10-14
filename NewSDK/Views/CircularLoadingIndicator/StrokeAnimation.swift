import UIKit

/// A basic animation of a shape layer's `strokeStart` or `strokeEnd` with ease-in/ease-out timing.
class StrokeAnimation: CABasicAnimation {

    /// Which end of the stroke is animated.
    enum StrokeType {
        /// Animates `strokeStart`.
        case start
        /// Animates `strokeEnd`.
        case end
    }

    /// Required by Core Animation: it copies animations (for example when they are added to a layer) through
    /// `init()`. Without this override the copy traps with "unimplemented initializer 'init()'".
    override init() {
        super.init()
    }

    /// Creates the stroke animation.
    ///
    /// - Parameters:
    ///   - type: Whether to animate the start or the end of the stroke.
    ///   - beginTime: Delay before the animation starts within its group, in seconds.
    ///   - fromValue: The starting stroke position (0 to 1).
    ///   - toValue: The ending stroke position (0 to 1).
    ///   - duration: Duration in seconds.
    init(
        type: StrokeType,
        beginTime: Double = 0.0,
        fromValue: CGFloat,
        toValue: CGFloat,
        duration: Double
    ) {

        super.init()

        keyPath = type == .start ? "strokeStart" : "strokeEnd"

        self.beginTime = beginTime
        self.fromValue = fromValue
        self.toValue = toValue
        self.duration = duration
        timingFunction = .init(name: .easeInEaseOut)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
