// swift-tools-version: 5.9

import PackageDescription

// The plugin for Flutter's Swift Package Manager integration. The engine is
// the OnDeviceTtsCore package next to this one; on_device_tts.podspec builds
// the same sources with CocoaPods.
let package = Package(
  name: "on_device_tts",
  platforms: [
    .iOS("15.1")
  ],
  products: [
    .library(name: "on-device-tts", targets: ["on_device_tts"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework"),
    .package(name: "OnDeviceTtsCore", path: "../OnDeviceTtsCore"),
  ],
  targets: [
    .target(
      name: "on_device_tts",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        .product(name: "OnDeviceTtsCore", package: "OnDeviceTtsCore"),
      ]
    )
  ]
)
