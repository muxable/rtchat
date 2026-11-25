// The standalone Swift tests have no Flutter engine. Use ORT as their oracle
// for exercising the native pipeline, player, and lifecycle.
import Foundation
@testable import OnDeviceTtsCore
import OnnxRuntimeBindings

private final class ReferenceGraph: GraphSession {
  private static let env = try? ORTEnv(loggingLevel: .warning)
  let session: ORTSession
  init(_ url: URL) throws {
    guard let env = Self.env else { throw SupertonicError.invalidModel("ORT init failed") }
    let options = try ORTSessionOptions()
    try options.setIntraOpNumThreads(2)
    try options.addConfigEntry(withKey: "session.intra_op.allow_spinning", value: "0")
    session = try ORTSession(env: env, modelPath: url.path, sessionOptions: options)
  }
  func run(_ inputs: [String: GraphTensor], output: String) throws -> GraphTensor {
    let feeds = try inputs.mapValues { t in
      try ORTValue(tensorData: NSMutableData(data: t.data),
        elementType: t.element == .int64 ? .int64 : .float, shape: t.shape.map { NSNumber(value: $0) })
    }
    guard let out = try session.run(withInputs: feeds, outputNames: [output], runOptions: nil)[output]
    else { throw SupertonicError.inference(output) }
    return GraphTensor(data: try out.tensorData() as Data,
      shape: try out.tensorTypeAndShapeInfo().shape.map { $0.intValue }, element: .float32)
  }
}

extension OnnxTtsEngine {
  convenience init(makeOutput: @escaping () -> PcmOutput = { AudioOutput() }) {
    self.init(openGraph: { try ReferenceGraph($0) }, makeOutput: makeOutput)
  }
}
