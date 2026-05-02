// swift-tools-version: 5.9
// Root SPM manifest so hosts can depend on this repo by URL without subtree splits.
import PackageDescription

let package = Package(
    name: "MGLFleetSDKMonorepo",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(name: "MGLFleetSDK", targets: ["MGLFleetSDK"]),
    ],
    targets: [
        .target(
            name: "MGLFleetSDK",
            path: "native-ios/MGLFleetSDK/Sources/MGLFleetSDK",
            resources: [],
            linkerSettings: []
        ),
        .testTarget(
            name: "MGLFleetSDKTests",
            dependencies: ["MGLFleetSDK"],
            path: "native-ios/MGLFleetSDK/Tests/MGLFleetSDKTests"
        ),
    ]
)
