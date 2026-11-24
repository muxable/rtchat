import Flutter
import Foundation

/// Graph execution runs on a Dart worker. The engine calls these synchronous
/// methods from its loader and inference queues, never from the main queue.
final class FlutterGraphs {
  let channel: FlutterMethodChannel
  private var pending = [UUID: (Any?) -> Void]()
  private var detached = false

  init(_ messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "on_device_tts/graphs", binaryMessenger: messenger)
  }

  func detach() {
    detached = true
    let replies = pending
    pending.removeAll()
    for reply in replies.values { reply(nil) }
  }

  private func call(_ method: String, _ arguments: Any) throws -> Any {
    dispatchPrecondition(condition: .notOnQueue(.main))
    let signal = DispatchSemaphore(value: 0)
    var result: Any?
    DispatchQueue.main.async {
      if self.detached { signal.signal(); return }
      let key = UUID()
      self.pending[key] = { result = $0; signal.signal() }
      self.channel.invokeMethod(method, arguments: arguments) { reply in
        self.pending.removeValue(forKey: key)?(reply)
      }
    }
    signal.wait()
    if let error = result as? FlutterError {
      throw SupertonicError.inference(error.message ?? error.code)
    }
    guard let result else { throw SupertonicError.inference("Flutter engine detached") }
    return result
  }

  func open(_ file: URL) throws -> GraphSession {
    guard let id = try call("open", file.path) as? NSNumber else {
      throw SupertonicError.invalidModel("Could not load \(file.lastPathComponent)")
    }
    return Session(id, self)
  }

  private final class Session: GraphSession {
    let id: NSNumber
    let graphs: FlutterGraphs

    init(_ id: NSNumber, _ graphs: FlutterGraphs) { self.id = id; self.graphs = graphs }

    deinit {
      let graphs = graphs, id = id
      DispatchQueue.main.async {
        if !graphs.detached { graphs.channel.invokeMethod("close", arguments: id) }
      }
    }

    func run(_ inputs: [String: GraphTensor], output: String) throws -> GraphTensor {
      let tensors = inputs.mapValues { t -> [String: Any] in
        let typed = t.element == .int64 ? FlutterStandardTypedData(int64: t.data)
          : FlutterStandardTypedData(float32: t.data)
        return ["shape": t.shape, "data": typed]
      }
      guard let out = try graphs.call("run", ["id": id, "inputs": tensors]) as? [String: Any],
        let data = out["data"] as? FlutterStandardTypedData, let shape = out["shape"] as? [Int]
      else { throw SupertonicError.inference("Invalid graph output \(output)") }
      return GraphTensor(data: data.data, shape: shape, element: .float32)
    }
  }
}
