import Flutter
import Foundation

// With Swift Package Manager the engine is the OnDeviceTtsCore package; with
// CocoaPods its sources are compiled into this module.
#if canImport(OnDeviceTtsCore)
  import OnDeviceTtsCore
#endif

/// The iOS side of `on_device_tts`'s ONNX Runtime engine: the
/// `on_device_tts/onnx` method channel and the `on_device_tts/onnx/events`
/// event channel. See `doc/native_contract.md`; the engine itself is
/// `OnnxTtsEngine` in `ios/OnDeviceTtsCore`.
public class OnDeviceTtsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  let engine = OnnxTtsEngine()
  private var eventSink: FlutterEventSink?

  public override init() {
    super.init()
    engine.onEvent = { [weak self] event in self?.eventSink?(event) }
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = OnDeviceTtsPlugin()
    let channel = FlutterMethodChannel(
      name: "on_device_tts/onnx", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)
    let events = FlutterEventChannel(
      name: "on_device_tts/onnx/events", binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    engine.shutdown()
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private struct BadArgs: Error {
    let message: String
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    func optional<T>(_ key: String, _ type: T.Type) throws -> T? {
      guard let value = args[key], !(value is NSNull) else { return nil }
      guard let typed = value as? T else { throw BadArgs(message: "\(key) has the wrong type") }
      return typed
    }
    func required<T>(_ key: String, _ type: T.Type) throws -> T {
      guard let value = try optional(key, type) else { throw BadArgs(message: "Missing \(key)") }
      return value
    }
    func fail(_ error: OnnxTtsError) {
      result(FlutterError(code: error.code, message: error.message, details: nil))
    }

    do {
      switch call.method {
      case "load":
        engine.load(
          modelType: try required("modelType", String.self),
          modelDir: try required("modelDir", String.self),
          numThreads: try optional("numThreads", NSNumber.self)?.intValue ?? 2,
          provider: try optional("provider", String.self) ?? "cpu"
        ) {
          switch $0 {
          case .success(let handle): result(handle)
          case .failure(let error): fail(error)
          }
        }
      case "voices":
        result(try engine.voices(handle: try required("handle", String.self)))
      case "speak":
        guard let segments = try required("segments", [Any].self) as? [String] else {
          throw BadArgs(message: "segments must be strings")
        }
        engine.speak(
          handle: try required("handle", String.self),
          utteranceId: try required("utteranceId", String.self), segments: segments,
          language: try required("language", String.self),
          voiceId: try required("voiceId", String.self),
          speed: try optional("speed", NSNumber.self)?.floatValue ?? 1,
          steps: try optional("steps", NSNumber.self)?.intValue ?? 5
        ) { error in
          if let error = error { fail(error) } else { result(nil) }
        }
      case "synthesize":
        engine.synthesize(
          handle: try required("handle", String.self), text: try required("text", String.self),
          language: try required("language", String.self),
          voiceId: try required("voiceId", String.self),
          speed: try optional("speed", NSNumber.self)?.floatValue ?? 1,
          steps: try optional("steps", NSNumber.self)?.intValue ?? 5,
          noiseSeed: try optional("noiseSeed", NSNumber.self)?.int64Value
        ) {
          switch $0 {
          case .success(let audio):
            let data = audio.pcm.withUnsafeBufferPointer { Data(buffer: $0) }
            result([
              "sampleRate": audio.sampleRate,
              "pcm": FlutterStandardTypedData(float32: data),
            ])
          case .failure(let error): fail(error)
          }
        }
      case "stop":
        engine.stop()
        result(nil)
      case "unload":
        engine.unload(handle: try required("handle", String.self)) { result(nil) }
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch let error as BadArgs {
      result(FlutterError(code: "bad_args", message: error.message, details: nil))
    } catch let error as OnnxTtsError {
      fail(error)
    } catch {
      result(FlutterError(code: "bad_args", message: "\(error)", details: nil))
    }
  }
}
