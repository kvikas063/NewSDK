import Foundation
import UIKit

extension UIDevice {

    /// The model family of the current device, computed once from the `uname` hardware identifier.
    ///
    /// On the simulator the identifier is not an iPhone one, so this is `.unrecognized`.
    static let modelName: DeviceModel = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        return UIDevice.deviceModel(forIdentifier: identifier)
    }()

    /// Maps a hardware identifier (e.g. "iPhone15,2") to a `DeviceModel`.
    ///
    /// - Parameter identifier: The machine identifier reported by `uname`.
    /// - Returns: The matching model family, or `.unrecognized` for identifiers that are not listed.
    static func deviceModel(forIdentifier identifier: String) -> DeviceModel {
        switch identifier {
        case "iPhone3,1", "iPhone3,2", "iPhone3,3", "iPhone4,1": return .iphone4
        case "iPhone5,1", "iPhone5,2", "iPhone5,3", "iPhone5,4", "iPhone6,1", "iPhone6,2": return .iphone5
        case "iPhone7,2", "iPhone7,1", "iPhone8,1", "iPhone8,2": return .iphone6
        case "iPhone8,4": return .iphoneSE
        case "iPhone9,1", "iPhone9,3", "iPhone9,2", "iPhone9,4": return .iphone7
        case "iPhone10,1", "iPhone10,4", "iPhone10,2", "iPhone10,5": return .iphone8
        case "iPhone10,3", "iPhone10,6", "iPhone11,2", "iPhone11,4", "iPhone11,6": return .iphoneX
        case "iPhone11,8": return .iphoneXR
        case "iPhone12,1", "iPhone12,3", "iPhone12,5": return .iphone11
        case "iPhone12,8": return .iphoneSE2nd
        case "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone13,4": return .iphone12
        case "iPhone14,4", "iPhone14,5", "iPhone14,2", "iPhone14,3": return .iphone13
        case "iPhone14,6": return .iphoneSE3rd
        case "iPhone14,7", "iPhone14,8", "iPhone15,2", "iPhone15,3": return .iphone14
        case "iPhone15,4", "iPhone15,5", "iPhone16,1", "iPhone16,2": return .iphone15
        case "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4", "iPhone17,5": return .iphone16
        case "iPhone18,1", "iPhone18,2", "iPhone18,3", "iPhone18,4": return .iphone17
        default: return .unrecognized
        }
    }
}
