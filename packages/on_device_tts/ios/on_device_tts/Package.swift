// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "on_device_tts",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "on-device-tts", targets: ["on_device_tts"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "on_device_tts",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
