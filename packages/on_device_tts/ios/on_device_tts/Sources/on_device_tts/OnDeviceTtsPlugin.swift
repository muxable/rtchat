import Flutter
import UIKit

/// Placeholder until the iOS ONNX Runtime engine lands (#1517). It registers
/// the `on_device_tts/onnx` channel and answers every call with
/// `FlutterMethodNotImplemented`, so the plugin builds on iOS and Dart callers
/// can fall back to the system voices.
public class OnDeviceTtsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "on_device_tts/onnx", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(OnDeviceTtsPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }
}
