// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MGLFleetSDK",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(name: "MGLFleetSDK", targets: ["MGLFleetSDK"]),
    ],
    targets: [
        .target(
            name: "MGLFleetSDK",
            path: "Sources/MGLFleetSDK",
            resources: [],
            linkerSettings: []
        ),
        .testTarget(
            name: "MGLFleetSDKTests",
            dependencies: ["MGLFleetSDK"],
            path: "Tests/MGLFleetSDKTests"
        ),
    ]
)
