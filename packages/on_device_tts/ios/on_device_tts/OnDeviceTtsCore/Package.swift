// swift-tools-version: 5.9

// The plugin's Swift core: text processing, the noise generator, the
// Supertonic pipeline, and audio playback. The Flutter
// plugin (`../../on_device_tts.podspec`) compiles these same sources with
// CocoaPods; this package exists so they can be tested on their own:
//
//   xcodebuild test -scheme OnDeviceTtsCore \
//     -destination 'platform=iOS Simulator,name=iPhone 16'
//
// Tests that need the model read it from SUPERTONIC_MODEL_DIR (pass it as
// TEST_RUNNER_SUPERTONIC_MODEL_DIR to xcodebuild).

import PackageDescription

let package = Package(
  name: "OnDeviceTtsCore",
  platforms: [.iOS("15.1")],
  products: [
    .library(name: "OnDeviceTtsCore", targets: ["OnDeviceTtsCore"])
  ],
  dependencies: [
    // Test-only mirror of 1.24.2. This revision updates archive URLs and retains
    // the upstream SHA-256 checksums and Objective-C sources.
    .package(url: "https://github.com/thesagezm/onnxruntime-swift-package-manager", revision: "7dbd851c52a6e3889077f69dda8c9f8f438b60ab")
  ],
  targets: [
    .target(
      name: "OnDeviceTtsCore",
      dependencies: []
    ),
    .testTarget(
      name: "OnDeviceTtsCoreTests",
      dependencies: ["OnDeviceTtsCore", .product(name: "onnxruntime", package: "onnxruntime-swift-package-manager")],
      resources: [.copy("Fixtures")]
    ),
  ]
)
