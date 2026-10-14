import UIKit

/// Namespace for the colors used by the face-detection screen.
struct Colors {

    /// Green used as the shadow color of the moving up/down scan bar.
    static var shadowColor: UIColor {
        UIColor(hex: "23FA00")
    }

    /// Cyan used as the background color of the moving up/down scan bar.
    static var upDownBarColor: UIColor {
        UIColor(hex: "00FFF5")
    }

    /// Teal used as the stroke color of the circular loading indicator around the face oval.
    static var frameColor: UIColor {
        UIColor(hex: "21C6A7")
    }
}
