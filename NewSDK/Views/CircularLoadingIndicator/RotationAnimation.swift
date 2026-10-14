import UIKit

/// A basic animation that rotates a layer around one axis (`transform.rotation.<axis>`).
class RotationAnimation: CABasicAnimation {

    /// The axis of the rotation; the raw value is the key-path suffix.
    enum Direction: String {
        case x, y, z
    }

    /// Required by Core Animation: it copies animations (for example when they are added to a layer) through
    /// `init()`. Without this override the copy traps with "unimplemented initializer 'init()'".
    override init() {
        super.init()
    }

    /// Creates the rotation animation.
    ///
    /// - Parameters:
    ///   - direction: The axis to rotate around.
    ///   - fromValue: The starting angle, in radians.
    ///   - toValue: The ending angle, in radians.
    ///   - duration: Duration of one rotation, in seconds.
    ///   - repeatCount: How many times the animation repeats.
    init(
        direction: Direction,
        fromValue: CGFloat,
        toValue: CGFloat,
        duration: Double,
        repeatCount: Float
    ) {

        super.init()

        keyPath = "transform.rotation.\(direction.rawValue)"

        self.fromValue = fromValue
        self.toValue = toValue

        self.duration = duration

        self.repeatCount = repeatCount
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
