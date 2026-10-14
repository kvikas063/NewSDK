import ImageIO
import UIKit

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
/// Orders two optionals, treating `nil` as smaller than any value (used by `gcdForPair`, obfuscated below).
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// MARK: - Creating animated images from GIF data

extension UIImage {

    /// Creates an animated image from GIF data.
    ///
    /// - Parameter data: The raw bytes of a GIF file.
    /// - Returns: The animated image, or `nil` if the data cannot be read as an image source.
    class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("image doesn't exist")
            return nil
        }

        return UIImage.xZaMPDrwQaY1FFHRsRWWpO5JMukTNYZS(source)
    }

    /// Reads the display time of one GIF frame (original name: `delayForImageAtIndex(_:source:)`).
    ///
    /// Uses the unclamped delay time and falls back to the regular delay time when it is zero; values below
    /// 0.1 s are raised to 0.1 s. Frames without GIF properties are not handled and would trap.
    ///
    /// - Parameters:
    ///   - index: The index of the frame in the image source.
    ///   - source: The GIF image source.
    /// - Returns: The frame delay in seconds (at least 0.1).
    class func RlHvdh5Tl5FjD2su2PRHxw685JsCnzsB(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1

        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(
                cfProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self)

        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(
                gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(
                CFDictionaryGetValue(
                    gifProperties,
                    Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }

        delay = delayObject as! Double

        if delay < 0.1 {
            delay = 0.1
        }

        return delay
    }

    /// Greatest common divisor of two optional integers (original name: `gcdForPair(_:_:)`).
    ///
    /// - Parameters:
    ///   - a: The first value.
    ///   - b: The second value.
    /// - Returns: The GCD; if only one value is non-`nil` that value is returned, and `0` if both are `nil`.
    class func M2OfTfRCWrNE1i4p0681pP0LdNKL8j4B(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }

        if a < b {
            let c = a
            a = b
            b = c
        }

        var rest: Int
        while true {
            rest = a! % b!

            if rest == 0 {
                return b!
            } else {
                a = b
                b = rest
            }
        }
    }

    /// Greatest common divisor of all the integers of an array (original name: `gcdForArray(_:)`).
    ///
    /// - Parameter array: The values to reduce.
    /// - Returns: The GCD, or `1` for an empty array.
    class func FjdOZSR7z0WC9ujeQLSBvXSpCRLTk4Om(_ array: [Int]) -> Int {
        if array.isEmpty {
            return 1
        }

        var gcd = array[0]

        for val in array {
            gcd = UIImage.M2OfTfRCWrNE1i4p0681pP0LdNKL8j4B(val, gcd)
        }

        return gcd
    }

    /// Builds an animated image from a GIF image source (original name: `animatedImageWithSource(_:)`).
    ///
    /// Each frame is repeated `delay / gcd` times (delays in milliseconds) so that `UIImage.animatedImage`,
    /// which uses a uniform frame time, reproduces the per-frame GIF timing.
    ///
    /// - Parameter source: The GIF image source.
    /// - Returns: The animated image.
    class func xZaMPDrwQaY1FFHRsRWWpO5JMukTNYZS(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()

        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }

            let delaySeconds = UIImage.RlHvdh5Tl5FjD2su2PRHxw685JsCnzsB(i, source: source)
            delays.append(Int(delaySeconds * 1000.0))  // Seconds to ms
        }

        let duration = delays.reduce(0, +)

        let gcd = FjdOZSR7z0WC9ujeQLSBvXSpCRLTk4Om(delays)
        var frames = [UIImage]()

        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[i])
            frameCount = delays[i] / gcd

            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }

        return UIImage.animatedImage(
            with: frames,
            duration: Double(duration) / 1000.0)
    }

}

// MARK: - Data asset loading

extension UIImage {
    /// Creates an animated image from a GIF stored as a data asset in the SDK's asset catalog.
    ///
    /// - Parameter asset: The name of the data asset.
    /// - Returns: The animated image, or `nil` if the asset does not exist or cannot be decoded.
    class func gif(asset: String) -> UIImage? {
        if let asset = NSDataAsset(name: asset, bundle: Bundle.sdk) {
            return UIImage.gifImageWithData(asset.data)
        }
        return nil
    }
}
