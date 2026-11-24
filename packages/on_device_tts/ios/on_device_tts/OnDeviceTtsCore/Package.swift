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
    // Independent graph evaluator for standalone Swift tests.
    .package(url: "https://github.com/microsoft/onnxruntime-swift-package-manager", exact: "1.24.2")
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
