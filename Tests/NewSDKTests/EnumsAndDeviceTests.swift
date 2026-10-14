import UIKit
import XCTest

@testable import NewSDK

/// Tests for the public enums and for mapping hardware identifiers to `DeviceModel`.
final class EnumsAndDeviceTests: XCTestCase {

    func testDeviceModelRawValues() {
        XCTAssertEqual(DeviceModel.iphone6.rawValue, "iphone6")
        XCTAssertEqual(DeviceModel.iphoneSE2nd.rawValue, "iphoneSE2nd")
        XCTAssertEqual(DeviceModel(rawValue: "iphone13"), .iphone13)
        XCTAssertNil(DeviceModel(rawValue: "galaxy"))
    }

    func testModelNameOnSimulatorIsUnrecognized() {
        // Simulators report "arm64"/"x86_64" as machine identifier, never an "iPhoneX,Y" one.
        #if targetEnvironment(simulator)
        XCTAssertEqual(UIDevice.modelName, .unrecognized)
        #endif
    }

    func testIdentifierMapping() {
        let expected: [String: DeviceModel] = [
            "iPhone3,1": .iphone4, "iPhone6,2": .iphone5, "iPhone8,1": .iphone6, "iPhone8,4": .iphoneSE,
            "iPhone9,3": .iphone7, "iPhone10,4": .iphone8, "iPhone11,2": .iphoneX, "iPhone11,8": .iphoneXR,
            "iPhone12,1": .iphone11, "iPhone12,8": .iphoneSE2nd, "iPhone13,2": .iphone12,
            "iPhone14,5": .iphone13, "iPhone14,2": .iphone13,
            "iPhone14,6": .iphoneSE3rd,
            "iPhone14,7": .iphone14, "iPhone14,8": .iphone14, "iPhone15,2": .iphone14, "iPhone15,3": .iphone14,
            "iPhone15,4": .iphone15, "iPhone15,5": .iphone15, "iPhone16,1": .iphone15, "iPhone16,2": .iphone15,
            "iPhone17,1": .iphone16, "iPhone17,2": .iphone16, "iPhone17,3": .iphone16, "iPhone17,4": .iphone16,
            "iPhone17,5": .iphone16,
            "iPhone18,1": .iphone17, "iPhone18,2": .iphone17, "iPhone18,3": .iphone17, "iPhone18,4": .iphone17,
        ]
        for (identifier, model) in expected {
            XCTAssertEqual(UIDevice.deviceModel(forIdentifier: identifier), model, identifier)
        }
    }

    func testUnknownIdentifiersAreUnrecognized() {
        for identifier in ["", "arm64", "x86_64", "iPad13,1", "iPhone99,9"] {
            XCTAssertEqual(UIDevice.deviceModel(forIdentifier: identifier), .unrecognized, identifier)
        }
    }

    func testCinTypeCases() {
        XCTAssertNotEqual(CinType.oldCin, CinType.newCin)
    }
}
