// Ported from Supertone's Supertonic reference code: the Swift sample
// (swift/Sources/Helper.swift in https://github.com/supertone-oss-archive/supertonic)
// and the `supertonic` Python package 1.3.1 (supertonic/core.py, pipeline.py).
//
// MIT License
//
// Copyright (c) 2025 Supertone Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

// The Swift package gets ONNX Runtime's Objective-C API from Microsoft's
// Swift package; the CocoaPods build from the onnxruntime-objc pod.
#if canImport(OnnxRuntimeBindings)
  import OnnxRuntimeBindings
#else
  import onnxruntime_objc
#endif

public enum SupertonicError: Error, LocalizedError {
  case missingFile(String)
  case invalidModel(String)
  case unknownVoice(String)
  case invalidArgument(String)
  case cancelled
  case inference(String)

  public var errorDescription: String? {
    switch self {
    case .missingFile(let name): return "Missing model file: \(name)"
    case .invalidModel(let message): return "Invalid model: \(message)"
    case .unknownVoice(let id): return "Unknown voice: \(id)"
    case .invalidArgument(let message): return message
    case .cancelled: return "Cancelled"
    case .inference(let message): return "Inference failed: \(message)"
    }
  }
}

/// One of a model's voices: a voice style file's two style tensors.
public struct SupertonicVoice {
  public let id: String
  let ttl: ORTValue
  let dp: ORTValue
}

/// A loaded Supertonic 3 model: four ONNX Runtime sessions (duration
/// predictor, text encoder, vector estimator, vocoder), the text processor
/// and the voice styles.
///
/// Not thread-safe: run one synthesis at a time.
public final class SupertonicModel {
  public static let defaultSteps = 5
  public static let stepRange = 1...100
  public static let minSpeed: Float = 0.7
  public static let maxSpeed: Float = 2.0
  /// The silence the reference puts between the chunks of one text.
  public static let chunkSilenceSeconds: Float = 0.3

  public let sampleRate: Int
  /// The voices, sorted by id.
  public let voices: [SupertonicVoice]
  /// The execution provider each of the four models runs on, after any
  /// fallback, e.g. `["coreml", "coreml", "cpu", "cpu"]`.
  public let providers: [String]
  public let textProcessor: SupertonicTextProcessor

  /// The provider all four models run on, or `mixed` when some fell back.
  public var provider: String {
    Set(providers).count == 1 ? providers[0] : "mixed(\(providers.joined(separator: ",")))"
  }

  private let baseChunkSize: Int
  private let chunkCompressFactor: Int
  private let latentDim: Int
  private let durationPredictor: ORTSession
  private let textEncoder: ORTSession
  private let vectorEstimator: ORTSession
  private let vocoder: ORTSession

  private static let env: ORTEnv? = try? ORTEnv(loggingLevel: .warning)

  /// Loads the model in `modelDir`, laid out as the Hugging Face repository
  /// `Supertone/supertonic-3`: `onnx/` with `tts.json`,
  /// `unicode_indexer.json` and the four models (`<name>.onnx`, or
  /// `<name>.int8.onnx`), and `voice_styles/*.json`. Without `onnx/`, the
  /// files are looked up in `modelDir` itself.
  ///
  /// `provider` is `cpu`, `coreml` or `xnnpack`. Anything else, or a
  /// provider that fails to take one of the models, falls back to `cpu`
  /// (for that model and the ones after it), reported through `log`.
  public init(
    modelDir: String, numThreads: Int = 2, provider: String = "cpu",
    log: (String) -> Void = { NSLog("%@", $0) }
  ) throws {
    let root = URL(fileURLWithPath: modelDir, isDirectory: true)
    let fm = FileManager.default
    var isDirectory: ObjCBool = false
    guard fm.fileExists(atPath: root.path, isDirectory: &isDirectory), isDirectory.boolValue else {
      throw SupertonicError.missingFile(modelDir)
    }
    let onnxDir = root.appendingPathComponent("onnx", isDirectory: true)
    let filesDir = fm.fileExists(atPath: onnxDir.path) ? onnxDir : root
    func find(_ names: String...) throws -> URL {
      for name in names {
        let url = filesDir.appendingPathComponent(name)
        if fm.fileExists(atPath: url.path) { return url }
      }
      throw SupertonicError.missingFile(filesDir.appendingPathComponent(names[0]).path)
    }

    let configURL = try find("tts.json")
    let indexerURL = try find("unicode_indexer.json")
    let modelURLs = try ["duration_predictor", "text_encoder", "vector_estimator", "vocoder"].map {
      try find("\($0).onnx", "\($0).int8.onnx")
    }

    let config: [String: Any]
    do {
      let json = try JSONSerialization.jsonObject(with: Data(contentsOf: configURL))
      guard let dict = json as? [String: Any] else {
        throw SupertonicError.invalidModel("tts.json is not an object")
      }
      config = dict
    } catch let error as SupertonicError {
      throw error
    } catch {
      throw SupertonicError.invalidModel("tts.json: \(error.localizedDescription)")
    }
    guard let ae = config["ae"] as? [String: Any], let ttl = config["ttl"] as? [String: Any],
      let sampleRate = ae["sample_rate"] as? Int, let baseChunkSize = ae["base_chunk_size"] as? Int,
      let chunkCompressFactor = ttl["chunk_compress_factor"] as? Int,
      let latentDim = ttl["latent_dim"] as? Int
    else {
      throw SupertonicError.invalidModel("tts.json lacks ae/ttl settings")
    }
    self.sampleRate = sampleRate
    self.baseChunkSize = baseChunkSize
    self.chunkCompressFactor = chunkCompressFactor
    self.latentDim = latentDim

    do {
      textProcessor = try SupertonicTextProcessor(indexerURL: indexerURL)
    } catch let error as SupertonicError {
      throw error
    } catch {
      throw SupertonicError.invalidModel("unicode_indexer.json: \(error.localizedDescription)")
    }

    voices = try SupertonicModel.loadVoices(root.appendingPathComponent("voice_styles"))

    guard let env = SupertonicModel.env else {
      throw SupertonicError.invalidModel("ONNX Runtime failed to initialize")
    }

    // The providers to try, best first. CoreML tries the newer ML Program
    // format, then the older NeuralNetwork format. Once one fails for a
    // model, the models after it skip it too.
    var attempts: [(provider: String, variant: String?)] = []
    switch provider {
    case "coreml": attempts = [("coreml", "MLProgram"), ("coreml", "NeuralNetwork")]
    case "xnnpack": attempts = [("xnnpack", nil)]
    case "cpu": break
    default: log("provider \(provider) isn't available on iOS, using cpu")
    }
    attempts.append(("cpu", nil))
    var sessions = [ORTSession]()
    var providers = [String]()
    for url in modelURLs {
      while true {
        let attempt = attempts[0]
        do {
          let options = try SupertonicModel.sessionOptions(
            numThreads: numThreads, provider: attempt.provider, variant: attempt.variant)
          sessions.append(try ORTSession(env: env, modelPath: url.path, sessionOptions: options))
          providers.append(attempt.provider)
          break
        } catch {
          if attempts.count == 1 {
            throw SupertonicError.invalidModel("\(url.lastPathComponent): \(error.localizedDescription)")
          }
          let name = [attempt.provider, attempt.variant].compactMap { $0 }.joined(separator: " ")
          log("provider \(name) failed for \(url.lastPathComponent) (\(error.localizedDescription)), trying \(attempts[1].provider)")
          attempts.removeFirst()
        }
      }
    }
    self.providers = providers
    durationPredictor = sessions[0]
    textEncoder = sessions[1]
    vectorEstimator = sessions[2]
    vocoder = sessions[3]
  }

  /// Session config entries set for every provider. ONNX Runtime's
  /// intra-op threads busy-wait for work by default, after each parallel
  /// section and for a while after a run. Chat arrives a message at a time
  /// with idle gaps, so spinning only burns the battery; blocking costs
  /// little latency (see `doc/native_contract.md`). Sessions run
  /// sequentially, so there is no inter-op pool to configure.
  static let sessionConfig = ["session.intra_op.allow_spinning": "0"]

  /// The options for a session on `provider`. `configEntry` sees each
  /// config entry set (ONNX Runtime can't read them back), for tests.
  static func sessionOptions(
    numThreads: Int, provider: String, variant: String?,
    configEntry: ((String, String) -> Void)? = nil
  ) throws -> ORTSessionOptions {
    let options = try ORTSessionOptions()
    try options.setGraphOptimizationLevel(.all)
    for (key, value) in sessionConfig.sorted(by: { $0.key < $1.key }) {
      try options.addConfigEntry(withKey: key, value: value)
      configEntry?(key, value)
    }
    switch provider {
    case "cpu":
      try options.setIntraOpNumThreads(Int32(numThreads))
    case "coreml":
      guard ORTIsCoreMLExecutionProviderAvailable() else {
        throw SupertonicError.invalidModel("CoreML execution provider not built in")
      }
      try options.setIntraOpNumThreads(Int32(numThreads))
      try options.appendCoreMLExecutionProvider(withOptionsV2: [
        "ModelFormat": variant ?? "MLProgram",
        "MLComputeUnits": "ALL",
      ])
    case "xnnpack":
      // As ONNX Runtime recommends: XNNPACK gets the threads, the session's
      // own pool one thread.
      try options.setIntraOpNumThreads(1)
      let xnnpack = ORTXnnpackExecutionProviderOptions()
      xnnpack.intra_op_num_threads = Int32(numThreads)
      try options.appendXnnpackExecutionProvider(with: xnnpack)
    default:
      throw SupertonicError.invalidModel("unknown provider \(provider)")
    }
    return options
  }

  /// Every `*.json` file in `dir`, sorted by id (the file name without
  /// `.json`).
  private static func loadVoices(_ dir: URL) throws -> [SupertonicVoice] {
    let files =
      (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
    let voices = try files.filter { $0.pathExtension == "json" }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
      .map(loadVoice)
    if voices.isEmpty {
      throw SupertonicError.missingFile("\(dir.path)/*.json")
    }
    return voices
  }

  private static func loadVoice(_ url: URL) throws -> SupertonicVoice {
    let name = url.lastPathComponent
    let json: Any
    do {
      json = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
    } catch {
      throw SupertonicError.invalidModel("\(name): \(error.localizedDescription)")
    }
    guard let dict = json as? [String: Any] else {
      throw SupertonicError.invalidModel("\(name) is not an object")
    }
    func tensor(_ key: String) throws -> ORTValue {
      guard let component = dict[key] as? [String: Any], let dims = component["dims"] as? [Int],
        let data = component["data"]
      else {
        throw SupertonicError.invalidModel("\(name) lacks \(key)")
      }
      var values = [Float]()
      func flatten(_ value: Any) {
        if let array = value as? [Any] {
          array.forEach(flatten)
        } else if let number = value as? NSNumber {
          values.append(number.floatValue)
        }
      }
      flatten(data)
      guard dims.reduce(1, *) == values.count else {
        throw SupertonicError.invalidModel("\(name): \(key) has the wrong size")
      }
      return try floatTensor(values, shape: dims)
    }
    return SupertonicVoice(
      id: url.deletingPathExtension().lastPathComponent, ttl: try tensor("style_ttl"),
      dp: try tensor("style_dp"))
  }

  /// The voice with `id`.
  public func voice(_ id: String) throws -> SupertonicVoice {
    guard let voice = voices.first(where: { $0.id == id }) else {
      throw SupertonicError.unknownVoice(id)
    }
    return voice
  }

  // MARK: - Synthesis

  /// Synthesizes `text` chunk by chunk and hands each chunk's PCM (mono
  /// float32 at [sampleRate]) to `onAudio` as soon as it is ready. Chunks
  /// after the first are preceded by the reference's 0.3 s of silence.
  ///
  /// `language` is resolved with `SupertonicTextProcessor.resolveLanguage`.
  /// `speed` is clamped to the reference's range; `steps` must be in
  /// [stepRange]. `isCancelled` is checked before every model run; once it
  /// returns true this throws `SupertonicError.cancelled`.
  public func synthesize(
    _ text: String, language: String?, voice: SupertonicVoice, speed: Float = 1.0,
    steps: Int = defaultSteps, noise: inout NoiseGenerator,
    isCancelled: () -> Bool = { false }, onAudio: ([Float]) throws -> Void
  ) throws {
    let language = SupertonicTextProcessor.resolveLanguage(language)
    let style = (ttl: voice.ttl, dp: voice.dp)
    let speed = min(max(speed, SupertonicModel.minSpeed), SupertonicModel.maxSpeed)
    guard SupertonicModel.stepRange.contains(steps) else {
      throw SupertonicError.invalidArgument("steps must be in \(SupertonicModel.stepRange)")
    }
    let chunks = SupertonicTextProcessor.chunk(
      text, maxLength: SupertonicTextProcessor.maxChunkLength(language: language))
    for (i, chunk) in chunks.enumerated() {
      var wav = try infer(
        chunk, language: language, style: style, speed: speed, steps: steps, noise: &noise,
        isCancelled: isCancelled)
      if i > 0 {
        let silence = [Float](
          repeating: 0, count: Int(SupertonicModel.chunkSilenceSeconds * Float(sampleRate)))
        wav = silence + wav
      }
      try onAudio(wav)
    }
  }

  /// Synthesizes all of `text` into one buffer.
  public func synthesize(
    _ text: String, language: String?, voice: SupertonicVoice, speed: Float = 1.0,
    steps: Int = defaultSteps, noise: inout NoiseGenerator, isCancelled: () -> Bool = { false }
  ) throws -> [Float] {
    var pcm = [Float]()
    try synthesize(
      text, language: language, voice: voice, speed: speed, steps: steps, noise: &noise,
      isCancelled: isCancelled
    ) { pcm.append(contentsOf: $0) }
    return pcm
  }

  /// One chunk through the four models (supertonic/core.py
  /// `Supertonic.__call__`), trimmed to the predicted duration.
  func infer(
    _ text: String, language: String, style: (ttl: ORTValue, dp: ORTValue), speed: Float,
    steps: Int, noise: inout NoiseGenerator, isCancelled: () -> Bool
  ) throws -> [Float] {
    func check() throws {
      if isCancelled() { throw SupertonicError.cancelled }
    }
    let ids = textProcessor.encode(text, language: language)
    let textIds = try int64Tensor(ids, shape: [1, ids.count])
    let textMask = try floatTensor([Float](repeating: 1, count: ids.count), shape: [1, 1, ids.count])

    try check()
    let durationOut = try run(
      durationPredictor,
      ["text_ids": textIds, "style_dp": style.dp, "text_mask": textMask], output: "duration")
    guard let predicted = try floats(durationOut).first else {
      throw SupertonicError.inference("empty duration")
    }
    let duration = predicted / speed
    guard duration.isFinite, duration > 0 else { return [] }

    try check()
    let textEmb = try run(
      textEncoder, ["text_ids": textIds, "style_ttl": style.ttl, "text_mask": textMask],
      output: "text_emb")

    // Like numpy in the reference: float32 arithmetic, truncated.
    let wavLengthF = duration * Float(sampleRate)
    let wavLength = Int(wavLengthF)
    let chunkSize = baseChunkSize * chunkCompressFactor
    let latentLength = Int((wavLengthF + Float(chunkSize - 1)) / Float(chunkSize))
    let maskLength = (wavLength + chunkSize - 1) / chunkSize
    let channels = latentDim * chunkCompressFactor
    guard latentLength > 0 else { return [] }

    var latentMask = [Float](repeating: 0, count: latentLength)
    for t in 0..<min(maskLength, latentLength) { latentMask[t] = 1 }
    var latent = noise.gaussians(channels * latentLength)
    for c in 0..<channels {
      for t in 0..<latentLength { latent[c * latentLength + t] *= latentMask[t] }
    }

    var xt = try floatTensor(latent, shape: [1, channels, latentLength])
    let latentMaskValue = try floatTensor(latentMask, shape: [1, 1, latentLength])
    let totalStep = try floatTensor([Float(steps)], shape: [1])
    for step in 0..<steps {
      try check()
      let currentStep = try floatTensor([Float(step)], shape: [1])
      xt = try run(
        vectorEstimator,
        [
          "noisy_latent": xt, "text_emb": textEmb, "style_ttl": style.ttl, "text_mask": textMask,
          "latent_mask": latentMaskValue, "current_step": currentStep, "total_step": totalStep,
        ], output: "denoised_latent")
    }

    try check()
    let wav = try floats(run(vocoder, ["latent": xt], output: "wav_tts"))
    return Array(wav.prefix(wavLength))
  }

  private func run(_ session: ORTSession, _ inputs: [String: ORTValue], output: String) throws
    -> ORTValue
  {
    let outputs = try session.run(withInputs: inputs, outputNames: [output], runOptions: nil)
    guard let value = outputs[output] else {
      throw SupertonicError.inference("missing output \(output)")
    }
    return value
  }
}

func floatTensor(_ values: [Float], shape: [Int]) throws -> ORTValue {
  let data = values.withUnsafeBufferPointer { NSMutableData(bytes: $0.baseAddress, length: $0.count * 4) }
  return try ORTValue(tensorData: data, elementType: .float, shape: shape.map { NSNumber(value: $0) })
}

func int64Tensor(_ values: [Int64], shape: [Int]) throws -> ORTValue {
  let data = values.withUnsafeBufferPointer { NSMutableData(bytes: $0.baseAddress, length: $0.count * 8) }
  return try ORTValue(tensorData: data, elementType: .int64, shape: shape.map { NSNumber(value: $0) })
}

func floats(_ value: ORTValue) throws -> [Float] {
  let data = try value.tensorData()
  let count = data.length / MemoryLayout<Float>.size
  var result = [Float](repeating: 0, count: count)
  result.withUnsafeMutableBytes { $0.copyMemory(from: UnsafeRawBufferPointer(start: data.bytes, count: count * 4)) }
  return result
}
