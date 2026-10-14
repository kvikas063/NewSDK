import Foundation

/// The kind of guidance message shown to the user during the selfie (face video) step.
public enum SelfieAssistance {
    /// Asks the user to blink.
    case blink
    /// Asks the user to face the camera (shown once the blink has been detected).
    case facePositioning
}

/// Coarse iPhone model families, used to pick device-specific layout values.
///
/// Several hardware identifiers map to the same family; see `UIDevice.deviceModel(forIdentifier:)`.
public enum DeviceModel: String {
    /// iPhone 4 / 4s.
    case iphone4
    /// iPhone 5 / 5c / 5s.
    case iphone5
    /// iPhone 6 / 6 Plus / 6s / 6s Plus.
    case iphone6
    /// iPhone SE (1st generation).
    case iphoneSE
    /// iPhone 7 / 7 Plus.
    case iphone7
    /// iPhone 8 / 8 Plus.
    case iphone8
    /// iPhone X / XS / XS Max.
    case iphoneX
    /// iPhone XR.
    case iphoneXR
    /// iPhone 11 / 11 Pro / 11 Pro Max.
    case iphone11
    /// iPhone SE (2nd generation).
    case iphoneSE2nd
    /// iPhone 12 family.
    case iphone12
    /// iPhone 13 family.
    case iphone13
    /// iPhone SE (3rd generation).
    case iphoneSE3rd
    /// iPhone 14 family.
    case iphone14
    /// iPhone 15 family.
    case iphone15
    /// iPhone 16 family (including 16e).
    case iphone16
    /// iPhone 17 family (including Air).
    case iphone17
    /// The hardware identifier is not in the known list (simulator, iPad, newer models).
    case unrecognized
}

/// The generation of the national identity card (CIN) being scanned.
public enum CinType {
    /// The old CIN card.
    case oldCin
    /// The new CIN card.
    case newCin
}
