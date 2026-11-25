// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "on_device_tts",
  platforms: [.iOS("15.1")],
  products: [
    .library(name: "on-device-tts", type: .static, targets: ["on_device_tts"])
  ],
  targets: [
    .target(
      name: "on_device_tts",
      path: ".",
      exclude: ["OnDeviceTtsCore/Package.swift", "OnDeviceTtsCore/Tests", "OnDeviceTtsCore/tool"],
      sources: ["Sources/on_device_tts", "OnDeviceTtsCore/Sources/OnDeviceTtsCore"]
    )
  ]
)
