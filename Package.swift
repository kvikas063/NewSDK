// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "NewSDK",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "NewSDK", targets: ["NewSDK"])
    ],
    dependencies: [
        // Google ML Kit is only published through CocoaPods; this community package rebuilds it as XCFrameworks.
        .package(url: "https://github.com/d-date/google-mlkit-swiftpm", .upToNextMinor(from: "9.0.2")),
        .package(url: "https://github.com/marmelroy/Zip", from: "2.1.2"),
    ],
    targets: [
        // TensorFlow Lite 2.17.0: Google's official iOS C library (downloaded from this repository's GitHub Release,
        // built by scripts/make_tflite_release_zip.sh) + the Swift wrapper from the same release in Vendor/.
        .binaryTarget(
            name: "TensorFlowLiteC",
            url: "https://github.com/kvikas063/NewSDK/releases/download/tflite-2.17.0/TensorFlowLiteC.xcframework.zip",
            checksum: "012d5c146d175d000bf3e4c2e521b75fd5ad0903c9f0e55f95cb9f6d7b191c54"),
        .target(
            name: "TensorFlowLite",
            dependencies: ["TensorFlowLiteC"],
            path: "Vendor/TensorFlowLite/Sources"),

        // PMAlertController 4.0.1 (MIT), vendored because its upstream repository is no longer available.
        .target(
            name: "PMAlertController",
            path: "Vendor/PMAlertController",
            exclude: ["LICENSE"],
            resources: [.process("PMAlertController.xib")]),

        .target(
            name: "NewSDK",
            dependencies: [
                "TensorFlowLite",
                "PMAlertController",
                .product(name: "Zip", package: "Zip"),
                .product(name: "MLKitFaceDetection", package: "google-mlkit-swiftpm"),
                .product(name: "MLKitTextRecognition", package: "google-mlkit-swiftpm"),
            ],
            path: "NewSDK",
            resources: [
                .process("ViewControllers/Main.storyboard"),
                .process("NewSDKAssets.xcassets"),
                .process("Resources"),
                .copy("Model/detect.tflite"),
                .copy("Model/labelmap.txt"),
            ]),

        .testTarget(
            name: "NewSDKTests",
            dependencies: ["NewSDK", .product(name: "Zip", package: "Zip")],
            path: "Tests/NewSDKTests"),
    ]
)
