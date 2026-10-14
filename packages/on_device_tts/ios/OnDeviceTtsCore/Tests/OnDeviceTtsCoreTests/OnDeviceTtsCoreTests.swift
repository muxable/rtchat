import XCTest

@testable import OnDeviceTtsCore

/// The reference fixture, made by `tool/make_parity_fixture.py` with the
/// official `supertonic` Python package.
struct ParityFixture: Decodable {
  struct Noise: Decodable {
    let u64: [String]
    let gaussian: [Double]
  }

  struct Preprocess: Decodable {
    let text: String
    let lang: String
    let processed: String
    let ids: [Int64]
  }

  struct Synthesis: Decodable {
    let text: String
    let lang: String
    let voice: String
    let seed: Int64
    let steps: Int
    let speed: Float
    let sampleRate: Int
    let duration: Double
    let numSamples: Int
    let rms: Double
    let stride: Int
    let samples: [Float]
  }

  let noise: [String: Noise]
  let preprocess: [Preprocess]
  let synthesis: [Synthesis]

  static let shared: ParityFixture = {
    let url = Bundle.module.url(
      forResource: "supertonic3_parity", withExtension: "json", subdirectory: "Fixtures")!
    let data = try! Data(contentsOf: url)
    return try! JSONDecoder().decode(ParityFixture.self, from: data)
  }()
}

/// Where the Supertonic 3 model is: `SUPERTONIC_MODEL_DIR` (pass it to
/// `xcodebuild test` as `TEST_RUNNER_SUPERTONIC_MODEL_DIR`). Tests that need
/// the model are skipped when it isn't set, and fail when it is set but
/// the model can't be loaded.
func modelDir() throws -> String {
  guard let dir = ProcessInfo.processInfo.environment["SUPERTONIC_MODEL_DIR"], !dir.isEmpty else {
    throw XCTSkip("SUPERTONIC_MODEL_DIR isn't set")
  }
  return dir
}

/// Compares strings by code point; `==` on `String` ignores normalization.
func scalars(_ text: String) -> [UInt32] {
  text.unicodeScalars.map(\.value)
}

func rms(_ pcm: [Float]) -> Double {
  guard !pcm.isEmpty else { return 0 }
  return (pcm.reduce(0.0) { $0 + Double($1) * Double($1) } / Double(pcm.count)).squareRoot()
}

class NoiseGeneratorTests: XCTestCase {
  // The same vectors as the contract (doc/native_contract.md) and the
  // Android tests.
  func testIsSplitMix64() {
    var noise = NoiseGenerator(seed: 0)
    XCTAssertEqual(noise.nextUInt64(), 0xE220_A839_7B1D_CDAF)
    XCTAssertEqual(noise.nextUInt64(), 0x6E78_9E6A_A1B9_65F4)
    XCTAssertEqual(noise.nextUInt64(), 0x06C4_5D18_8009_454F)
  }

  func testMatchesTheDocumentedSamples() {
    var noise = NoiseGenerator(seed: 42)
    XCTAssertEqual(
      noise.gaussians(6),
      [
        0.8822488784790039, -0.45084986090660095, 0.18835262954235077, 0.21958637237548828,
        -0.6703714728355408, -0.6765279769897461,
      ])
    noise = NoiseGenerator(seed: -1)
    XCTAssertEqual(noise.gaussians(3), [1.8068959712982178, -0.6297152638435364, 0.7070683836936951])
  }

  func testMatchesReferenceGenerator() {
    for (seed, expected) in ParityFixture.shared.noise {
      var noise = NoiseGenerator(seed: Int64(seed)!)
      for value in expected.u64 {
        XCTAssertEqual(noise.nextUInt64(), UInt64(value)!, "seed \(seed)")
      }
      noise = NoiseGenerator(seed: Int64(seed)!)
      XCTAssertEqual(noise.gaussians(expected.gaussian.count), expected.gaussian.map(Float.init))
    }
  }

  func testIsDeterministicPerSeed() {
    var a = NoiseGenerator(seed: 7)
    var b = NoiseGenerator(seed: 7)
    var c = NoiseGenerator(seed: 8)
    let first = a.gaussians(100)
    XCTAssertEqual(first, b.gaussians(100))
    XCTAssertNotEqual(first, c.gaussians(100))
  }

  func testIsStandardNormal() {
    var noise = NoiseGenerator(seed: 1234)
    let values = noise.gaussians(200_000).map(Double.init)
    let mean = values.reduce(0, +) / Double(values.count)
    let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
    XCTAssertEqual(mean, 0, accuracy: 0.01)
    XCTAssertEqual(variance.squareRoot(), 1, accuracy: 0.01)
    XCTAssertTrue(values.allSatisfy { $0.isFinite })
  }

  func testUniformsAreInTheUnitInterval() {
    var noise = NoiseGenerator(seed: 99)
    for _ in 0..<10_000 {
      let u = noise.nextDouble()
      XCTAssertTrue(u >= 0 && u < 1)
    }
  }
}

class TextProcessorTests: XCTestCase {
  func testPreprocessMatchesReference() {
    for item in ParityFixture.shared.preprocess {
      XCTAssertEqual(
        scalars(SupertonicTextProcessor.preprocess(item.text, language: item.lang)),
        scalars(item.processed), item.text)
    }
  }

  func testEncodeMatchesReference() throws {
    let dir = URL(fileURLWithPath: try modelDir())
    let processor = try SupertonicTextProcessor(
      indexerURL: dir.appendingPathComponent("onnx/unicode_indexer.json"))
    for item in ParityFixture.shared.preprocess {
      XCTAssertEqual(processor.encode(item.text, language: item.lang), item.ids, item.text)
    }
  }

  func testDropsCharactersTheModelDoesNotKnow() {
    // Like the real indexer: U+FE0F (the emoji variation selector) and
    // characters past the table are unknown.
    var indexer = (0..<0x10000).map { Int64($0) }
    indexer[0xFE0F] = -1
    let processor = SupertonicTextProcessor(indexer: indexer)
    func encode(_ text: String) -> [UInt32] {
      processor.encode(text, language: "en").map { UInt32($0) }
    }
    XCTAssertEqual(encode("pog so good ❤️"), scalars("<en>pog so good.</en>"))
    XCTAssertEqual(encode("a ️️ b"), scalars("<en>a b.</en>"))
    XCTAssertEqual(encode("math 𠀀 ok"), scalars("<en>math ok.</en>"))
    XCTAssertEqual(encode("️"), scalars("<en>.</en>"))
    // `@` becomes ` at ` before unknown characters are dropped.
    indexer[0x40] = -1
    XCTAssertEqual(
      SupertonicTextProcessor(indexer: indexer).encode("me@home", language: "en").map { UInt32($0) },
      scalars("<en>me at home.</en>"))
  }

  func testNormalization() {
    func pre(_ text: String, _ lang: String = "en") -> [UInt32] {
      scalars(SupertonicTextProcessor.preprocess(text, language: lang))
    }
    // NFKD splits accents, Hangul syllables and compatibility characters.
    XCTAssertEqual(pre("é"), scalars("<en>e\u{301}.</en>"))
    XCTAssertEqual(pre("한", "ko"), scalars("<ko>\u{1112}\u{1161}\u{11AB}.</ko>"))
    XCTAssertEqual(pre("wait…"), scalars("<en>wait...</en>"))
    XCTAssertEqual(pre("hi 👋🏽 there"), scalars("<en>hi there.</en>"))
    XCTAssertEqual(pre("a — b"), scalars("<en>a - b.</en>"))
    XCTAssertEqual(pre("a\u{3000}\u{2028} b\u{1F}"), scalars("<en>a b.</en>"))
    XCTAssertEqual(pre(""), scalars("<en>.</en>"))
  }

  func testStripsEmojiRanges() {
    XCTAssertEqual(pre(raw: "a😀☀➿🇦b"), scalars("<en>ab.</en>"))
    XCTAssertEqual(pre(raw: "◿⠀"), scalars("<en>◿⠀.</en>"))
  }

  private func pre(raw: String) -> [UInt32] {
    scalars(SupertonicTextProcessor.preprocess(raw, language: "en"))
  }

  func testResolveLanguage() {
    XCTAssertEqual(SupertonicTextProcessor.resolveLanguage("en"), "en")
    XCTAssertEqual(SupertonicTextProcessor.resolveLanguage("en-US"), "en")
    XCTAssertEqual(SupertonicTextProcessor.resolveLanguage("pt_BR"), "pt")
    XCTAssertEqual(SupertonicTextProcessor.resolveLanguage("RU"), "ru")
    XCTAssertEqual(SupertonicTextProcessor.resolveLanguage("zh-Hans"), "na")
    XCTAssertEqual(SupertonicTextProcessor.resolveLanguage(""), "na")
    XCTAssertEqual(SupertonicTextProcessor.resolveLanguage("na"), "na")
    XCTAssertEqual(SupertonicTextProcessor.languages.count, 32)
  }

  // The same cases as the Android TextChunkerTest.
  func testKeepsShortTextWhole() {
    XCTAssertEqual(
      SupertonicTextProcessor.chunk("  Hello chat. How are you?  "), ["Hello chat. How are you?"])
  }

  func testMakesNothingOfBlankText() {
    XCTAssertEqual(SupertonicTextProcessor.chunk(""), [])
    XCTAssertEqual(SupertonicTextProcessor.chunk(" \n\n "), [])
  }

  func testSplitsParagraphs() {
    XCTAssertEqual(SupertonicTextProcessor.chunk("One.\n\nTwo."), ["One.", "Two."])
    XCTAssertEqual(SupertonicTextProcessor.chunk("One.\n  \n\nTwo."), ["One.", "Two."])
    XCTAssertEqual(SupertonicTextProcessor.chunk("One.\nTwo."), ["One.\nTwo."])
  }

  func testPacksSentencesUpToTheLimit() {
    let sentence = "This sentence is exactly forty chars ok."
    XCTAssertEqual(sentence.utf16.count, 40)
    let text = Array(repeating: sentence, count: 5).joined(separator: " ")
    XCTAssertEqual(
      SupertonicTextProcessor.chunk(text, maxLength: 80), Array(repeating: sentence, count: 5))
    XCTAssertEqual(
      SupertonicTextProcessor.chunk(text, maxLength: 81),
      ["\(sentence) \(sentence)", "\(sentence) \(sentence)", sentence])
  }

  func testDoesNotSplitAfterAbbreviations() {
    XCTAssertEqual(
      SupertonicTextProcessor.chunk(
        "Dr. Smith and Mr. Jones met. They talked for a long while about everything.",
        maxLength: 50),
      ["Dr. Smith and Mr. Jones met.", "They talked for a long while about everything."])
  }

  func testSplitsLongSentencesOnCommasThenSpaces() {
    XCTAssertEqual(
      SupertonicTextProcessor.chunk("first part here, second part here, third part here", maxLength: 35),
      ["first part here, second part here", "third part here"])
    XCTAssertEqual(
      SupertonicTextProcessor.chunk("aaaa bbbb cccc dddd eeee", maxLength: 10),
      ["aaaa bbbb", "cccc dddd", "eeee"])
  }

  func testChunksStayWithinTheLimit() {
    let text = (0..<200).map { $0 % 7 == 6 ? "word\($0)." : "word\($0)," }.joined(separator: " ")
    let chunks = SupertonicTextProcessor.chunk(text, maxLength: 120)
    XCTAssertGreaterThan(chunks.count, 1)
    XCTAssertTrue(chunks.allSatisfy { $0.utf16.count <= 120 }, "\(chunks)")
    let rejoined = chunks.joined(separator: " ").replacingOccurrences(of: ",", with: "")
      .split(separator: " ")
    XCTAssertEqual(rejoined.count, 200)
  }

  func testUsesShorterChunksForKoreanAndJapanese() {
    XCTAssertEqual(SupertonicTextProcessor.maxChunkLength(language: "ko"), 120)
    XCTAssertEqual(SupertonicTextProcessor.maxChunkLength(language: "ja"), 120)
    XCTAssertEqual(SupertonicTextProcessor.maxChunkLength(language: "en"), 300)
    XCTAssertEqual(SupertonicTextProcessor.maxChunkLength(language: "na"), 300)
  }
}

/// A failed call, with the error code the plugin sends to Dart.
struct ChannelFailure: Error {
  let code: String
  let message: String
}

/// Drives `OnnxTtsEngine` with the channel contract's method names and
/// arguments, as `OnDeviceTtsPlugin` does for Dart.
class ChannelHarness {
  let engine = OnnxTtsEngine()
  var events = [[String: Any]]()
  var onEvent: (([String: Any]) -> Void)?
  let test: XCTestCase

  init(_ test: XCTestCase) {
    self.test = test
    engine.onEvent = { [weak self] event in
      guard let self = self else { return }
      self.events.append(event)
      self.onEvent?(event)
    }
  }

  private func dispatch(_ method: String, _ args: [String: Any], result: @escaping (Any?) -> Void) {
    func fail(_ error: OnnxTtsError) {
      result(ChannelFailure(code: error.code, message: error.message))
    }
    let handle = args["handle"] as? String ?? ""
    switch method {
    case "load":
      engine.load(
        modelType: args["modelType"] as? String ?? "supertonic",
        modelDir: args["modelDir"] as? String ?? "", numThreads: args["numThreads"] as? Int ?? 2,
        provider: args["provider"] as? String ?? "cpu"
      ) {
        switch $0 {
        case .success(let handle): result(handle)
        case .failure(let error): fail(error)
        }
      }
    case "voices":
      do {
        result(try engine.voices(handle: handle))
      } catch let error as OnnxTtsError {
        fail(error)
      } catch {
        XCTFail("\(error)")
      }
    case "speak":
      engine.speak(
        handle: handle, utteranceId: args["utteranceId"] as! String,
        segments: args["segments"] as? [String] ?? [], language: args["language"] as! String,
        voiceId: args["voiceId"] as! String, speed: Float(args["speed"] as? Double ?? 1.0),
        steps: args["steps"] as? Int ?? 5
      ) { error in
        if let error = error { fail(error) } else { result(nil) }
      }
    case "synthesize":
      engine.synthesize(
        handle: handle, text: args["text"] as! String, language: args["language"] as! String,
        voiceId: args["voiceId"] as! String, speed: Float(args["speed"] as? Double ?? 1.0),
        steps: args["steps"] as? Int ?? 5, noiseSeed: args["noiseSeed"] as? Int64
      ) {
        switch $0 {
        case .success(let audio): result(["sampleRate": audio.sampleRate, "pcm": audio.pcm])
        case .failure(let error): fail(error)
        }
      }
    case "stop":
      engine.stop()
      result(nil)
    case "unload":
      engine.unload(handle: handle) { result(nil) }
    default:
      XCTFail("unknown method \(method)")
    }
  }

  /// Calls `method` and waits for its result.
  func call(_ method: String, _ args: [String: Any] = [:], timeout: TimeInterval = 120) -> Any? {
    let done = test.expectation(description: method)
    var value: Any?
    dispatch(method, args) {
      value = $0
      done.fulfill()
    }
    test.wait(for: [done], timeout: timeout)
    return value
  }

  /// Calls `method` and returns an expectation for its result.
  func start(
    _ method: String, _ args: [String: Any], result: @escaping (Any?) -> Void = { _ in }
  ) -> XCTestExpectation {
    let done = test.expectation(description: method)
    dispatch(method, args) {
      result($0)
      done.fulfill()
    }
    return done
  }

  func load(provider: String = "cpu") throws -> String {
    let result = call(
      "load",
      ["modelType": "supertonic", "modelDir": try modelDir(), "numThreads": 2, "provider": provider])
    if let error = result as? ChannelFailure {
      XCTFail("load failed: \(error.code) \(error.message)")
      throw error
    }
    return try XCTUnwrap(result as? String)
  }

  func synthesize(_ handle: String, _ text: String, language: String, voice: String, seed: Int64?)
    throws -> (sampleRate: Int, pcm: [Float])
  {
    var args: [String: Any] = [
      "handle": handle, "text": text, "language": language, "voiceId": voice, "speed": 1.0,
      "steps": 5,
    ]
    if let seed = seed { args["noiseSeed"] = seed }
    let result = call("synthesize", args)
    if let error = result as? ChannelFailure {
      XCTFail("synthesize failed: \(error.code) \(error.message)")
      throw error
    }
    let map = try XCTUnwrap(result as? [String: Any])
    return (try XCTUnwrap(map["sampleRate"] as? Int), try XCTUnwrap(map["pcm"] as? [Float]))
  }
}

class SynthesisTests: XCTestCase {
  func testLoadFailsWithoutModelFiles() {
    let harness = ChannelHarness(self)
    let empty = NSTemporaryDirectory() + "/empty-\(UUID().uuidString)"
    try? FileManager.default.createDirectory(atPath: empty, withIntermediateDirectories: true)
    let result = harness.call("load", ["modelType": "supertonic", "modelDir": empty])
    XCTAssertEqual((result as? ChannelFailure)?.code, "load_failed")
  }

  func testLoadFailsWithBadModel() throws {
    let source = URL(fileURLWithPath: try modelDir())
    let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
      "bad-\(UUID().uuidString)")
    let fm = FileManager.default
    try fm.createDirectory(at: dir.appendingPathComponent("voice_styles"), withIntermediateDirectories: true)
    for name in ["tts.json", "unicode_indexer.json"] {
      try fm.copyItem(
        at: source.appendingPathComponent("onnx/\(name)"), to: dir.appendingPathComponent(name))
    }
    for name in ["duration_predictor", "text_encoder", "vector_estimator", "vocoder"] {
      try Data("not a model".utf8).write(to: dir.appendingPathComponent("\(name).onnx"))
    }
    try fm.copyItem(
      at: source.appendingPathComponent("voice_styles/F1.json"),
      to: dir.appendingPathComponent("voice_styles/F1.json"))
    let harness = ChannelHarness(self)
    let result = harness.call("load", ["modelType": "supertonic", "modelDir": dir.path])
    XCTAssertEqual((result as? ChannelFailure)?.code, "load_failed")
  }

  func testVoicesAndUnknownProviderFallsBackToCpu() throws {
    let harness = ChannelHarness(self)
    let handle = try harness.load(provider: "nnapi")
    XCTAssertEqual(harness.engine.model(handle)?.provider, "cpu")
    let voices = try XCTUnwrap(harness.call("voices", ["handle": handle]) as? [[String: Any]])
    XCTAssertEqual(voices.count, 10)
    XCTAssertEqual(voices.first?["id"] as? String, "F1")
    XCTAssertEqual(voices.first?["name"] as? String, "F1")
    XCTAssertNil(voices.first?["language"])
    XCTAssertTrue(handle.hasPrefix("supertonic-"))
    XCTAssertNil(harness.call("unload", ["handle": handle]))
    XCTAssertEqual((harness.call("voices", ["handle": handle]) as? ChannelFailure)?.code, "bad_args")
    // Unloading an unknown handle does nothing.
    XCTAssertNil(harness.call("unload", ["handle": handle]))
  }

  func testRejectsBadArguments() throws {
    let harness = ChannelHarness(self)
    let handle = try harness.load()
    func code(_ method: String, _ args: [String: Any]) -> String? {
      (harness.call(method, args) as? ChannelFailure)?.code
    }
    let synth: [String: Any] = ["handle": handle, "text": "Hi.", "language": "en", "voiceId": "F1"]
    XCTAssertEqual(code("synthesize", synth.merging(["voiceId": "X9"]) { $1 }), "bad_args")
    XCTAssertEqual(code("synthesize", synth.merging(["steps": 0]) { $1 }), "bad_args")
    XCTAssertEqual(code("synthesize", synth.merging(["steps": 101]) { $1 }), "bad_args")
    XCTAssertEqual(code("synthesize", synth.merging(["handle": "supertonic-999"]) { $1 }), "bad_args")
    XCTAssertEqual(
      code(
        "speak",
        ["handle": handle, "utteranceId": "x", "segments": ["Hi."], "language": "en", "voiceId": "X9"]),
      "bad_args")
    XCTAssertEqual(
      code("load", ["modelType": "supertonic", "modelDir": try modelDir(), "numThreads": 0]),
      "bad_args")
    XCTAssertEqual(code("load", ["modelType": "kokoro", "modelDir": try modelDir()]), "load_failed")
  }

  func testStopDoesNotAffectSynthesize() throws {
    let harness = ChannelHarness(self)
    let handle = try harness.load()
    var result: Any?
    let done = harness.start(
      "synthesize",
      ["handle": handle, "text": "This keeps going after stop.", "language": "en", "voiceId": "F1"]
    ) { result = $0 }
    XCTAssertNil(harness.call("stop"))
    wait(for: [done], timeout: 120)
    let map = try XCTUnwrap(result as? [String: Any], "\(String(describing: result))")
    XCTAssertGreaterThan((map["pcm"] as? [Float])?.count ?? 0, 44100)
  }

  func testSynthesizesSpeechInTwoLanguages() throws {
    let harness = ChannelHarness(self)
    let handle = try harness.load()
    let cases = [
      ("en", "M2", "Hello there! Thanks for the follow. That was a great play, well done."),
      ("es", "F3", "Hola a todos. Gracias por seguir el canal, nos vemos mañana."),
    ]
    for (language, voice, text) in cases {
      let start = Date()
      let audio = try harness.synthesize(handle, text, language: language, voice: voice, seed: 5)
      let elapsed = Date().timeIntervalSince(start)
      let seconds = Double(audio.pcm.count) / Double(audio.sampleRate)
      print("SYNTH \(language) \(voice): \(String(format: "%.2f", seconds)) s of audio in \(String(format: "%.2f", elapsed)) s, rms \(rms(audio.pcm))")
      XCTAssertEqual(audio.sampleRate, 44100)
      XCTAssertGreaterThan(seconds, 2, language)
      XCTAssertLessThan(seconds, 12, language)
      XCTAssertGreaterThan(rms(audio.pcm), 0.01, language)
      XCTAssertTrue(audio.pcm.allSatisfy { $0.isFinite && abs($0) <= 1.5 }, language)

      // The same seed gives the same audio; another seed doesn't.
      let again = try harness.synthesize(handle, text, language: language, voice: voice, seed: 5)
      XCTAssertEqual(again.pcm, audio.pcm, language)
      let other = try harness.synthesize(handle, text, language: language, voice: voice, seed: 6)
      XCTAssertNotEqual(other.pcm, audio.pcm, language)
    }
  }

  func testMatchesReferenceImplementation() throws {
    let harness = ChannelHarness(self)
    let handle = try harness.load()
    var report = [String]()
    for item in ParityFixture.shared.synthesis {
      let audio = try harness.synthesize(
        handle, item.text, language: item.lang, voice: item.voice, seed: item.seed)
      XCTAssertEqual(audio.sampleRate, item.sampleRate)
      XCTAssertLessThanOrEqual(abs(audio.pcm.count - item.numSamples), 64, item.text)
      let actual = stride(from: 0, to: audio.pcm.count, by: item.stride).map { audio.pcm[$0] }
      let n = min(actual.count, item.samples.count)
      XCTAssertGreaterThan(n, item.samples.count - 2)
      var maxDiff: Float = 0
      var dot = 0.0, aa = 0.0, bb = 0.0
      for i in 0..<n {
        let a = Double(actual[i]), b = Double(item.samples[i])
        maxDiff = max(maxDiff, abs(actual[i] - item.samples[i]))
        dot += a * b
        aa += a * a
        bb += b * b
      }
      let correlation = dot / (aa * bb).squareRoot()
      let rmsRatio = rms(audio.pcm) / item.rms
      let line = String(
        format: "PARITY %@ %@: samples %d vs %d, max abs diff %.6f, correlation %.6f, rms ratio %.4f",
        item.lang, item.voice, audio.pcm.count, item.numSamples, maxDiff, correlation, rmsRatio)
      print(line)
      report.append(line)
      XCTAssertLessThan(maxDiff, 0.05, item.text)
      XCTAssertGreaterThan(correlation, 0.99, item.text)
      XCTAssertEqual(rmsRatio, 1, accuracy: 0.02, item.text)
    }
    add(XCTAttachment(string: report.joined(separator: "\n")))
  }
}

class SpeakTests: XCTestCase {
  func testSpeaksSegmentsUntilDone() throws {
    let harness = ChannelHarness(self)
    let handle = try harness.load()
    let start = Date()
    var result: Any? = "unset"
    let done = harness.start(
      "speak",
      [
        "handle": handle, "utteranceId": "u1",
        "segments": ["Hello there,", "this is the second segment."], "language": "en",
        "voiceId": "F1", "speed": 1.2, "steps": 3,
      ]
    ) { result = $0 }
    // A second speak while the first one is playing is refused.
    let busy = harness.call(
      "speak", ["handle": handle, "utteranceId": "u2", "segments": ["No."], "language": "en", "voiceId": "F1"])
    XCTAssertEqual((busy as? ChannelFailure)?.code, "busy")
    wait(for: [done], timeout: 120)
    let elapsed = Date().timeIntervalSince(start)
    XCTAssertNil(result as? ChannelFailure)
    let types = harness.events.filter { $0["utteranceId"] as? String == "u1" }.map {
      $0["type"] as! String
    }
    XCTAssertEqual(types, ["firstAudio", "done"])
    let firstAudio = harness.events.first { $0["type"] as? String == "firstAudio" }!["elapsedMs"] as! Int
    let doneMs = harness.events.first { $0["type"] as? String == "done" }!["elapsedMs"] as! Int
    print("SPEAK firstAudio \(firstAudio) ms, done \(doneMs) ms")
    // Completion waits for playback: two segments last well over a second.
    XCTAssertGreaterThan(doneMs - firstAudio, 1000)
    XCTAssertGreaterThan(elapsed, 1.0)
  }

  func testStopEndsSpeakingQuickly() throws {
    let harness = ChannelHarness(self)
    let handle = try harness.load()
    let segments = (1...6).map { "This is sentence number \($0) of a long message that keeps going." }
    var result: Any? = "unset"
    let firstAudio = expectation(description: "firstAudio")
    harness.onEvent = { if $0["type"] as? String == "firstAudio" { firstAudio.fulfill() } }
    let done = harness.start(
      "speak",
      [
        "handle": handle, "utteranceId": "long", "segments": segments, "language": "en",
        "voiceId": "M1",
      ]
    ) { result = $0 }
    wait(for: [firstAudio], timeout: 120)
    harness.onEvent = nil
    let stopAt = Date()
    XCTAssertNil(harness.call("stop"))
    wait(for: [done], timeout: 5)
    let stopLatency = Date().timeIntervalSince(stopAt)
    print("STOP latency \(Int(stopLatency * 1000)) ms")
    XCTAssertLessThan(stopLatency, 0.5)
    XCTAssertNil(result as? ChannelFailure)
    let types = harness.events.map { $0["type"] as! String }
    XCTAssertEqual(types, ["firstAudio", "stopped"])

    // The engine is free again, and synthesis left over from the stopped
    // utterance doesn't leak into the next one.
    let next = harness.call(
      "speak",
      [
        "handle": handle, "utteranceId": "next", "segments": ["Okay."], "language": "en",
        "voiceId": "F2", "steps": 2,
      ])
    XCTAssertNil(next as? ChannelFailure)
    XCTAssertEqual(
      harness.events.filter { $0["utteranceId"] as? String == "next" }.map { $0["type"] as! String },
      ["firstAudio", "done"])
    XCTAssertFalse(harness.events.dropFirst(2).contains { $0["utteranceId"] as? String == "long" })
  }
}

/// Timing per execution provider, printed as `BENCH` lines. Only runs when
/// `SUPERTONIC_BENCHMARK` is set, since it takes a while. These are
/// simulator numbers: they say nothing about the Neural Engine.
class BenchmarkTests: XCTestCase {
  func testProviders() throws {
    guard let providers = ProcessInfo.processInfo.environment["SUPERTONIC_BENCHMARK"],
      !providers.isEmpty
    else {
      throw XCTSkip("SUPERTONIC_BENCHMARK isn't set")
    }
    let sentences = [
      "xXslayerXx said POGGERS that clutch was insane.",
      "Thanks for the raid, welcome everyone to the stream!",
      "Does anyone know when the next tournament starts? I want to watch it live.",
    ]
    for provider in providers.split(separator: ",").map(String.init) {
      let harness = ChannelHarness(self)
      let loadStart = Date()
      let handle = try harness.load(provider: provider)
      let loadSeconds = Date().timeIntervalSince(loadStart)
      let actual = harness.engine.model(handle)?.provider ?? "?"
      // Warm up: the first run includes graph setup (and CoreML compilation).
      let warmStart = Date()
      _ = try harness.synthesize(handle, "Warm up.", language: "en", voice: "F1", seed: 1)
      let warmSeconds = Date().timeIntervalSince(warmStart)
      var synthSeconds = 0.0
      var audioSeconds = 0.0
      for (i, sentence) in sentences.enumerated() {
        let start = Date()
        let audio = try harness.synthesize(handle, sentence, language: "en", voice: "M1", seed: Int64(i))
        synthSeconds += Date().timeIntervalSince(start)
        audioSeconds += Double(audio.pcm.count) / Double(audio.sampleRate)
      }
      print(
        String(
          format: "BENCH provider=%@ actual=%@ load=%.2fs first=%.2fs synth=%.2fs audio=%.2fs rtf=%.3f",
          provider, actual, loadSeconds, warmSeconds, synthSeconds, audioSeconds,
          synthSeconds / audioSeconds))
      _ = harness.call("unload", ["handle": handle])
    }
  }
}
