import Foundation

/// Where `OnnxTtsEngine` plays audio. `AudioOutput` is the real one.
protocol PcmOutput: AnyObject {
  var onEvent: ((AudioOutputEvent) -> Void)? { get set }
  /// After a media services reset; the engine then makes a new output.
  var invalidated: Bool { get }
  func start(sampleRate: Int) throws
  func schedule(_ pcm: [Float], completion: @escaping () -> Void)
  func play() throws
  func stop()
  func idle()
}

extension AudioOutput: PcmOutput {}

/// An error with one of the platform contract's error codes.
public struct OnnxTtsError: Error, LocalizedError {
  public let code: String
  public let message: String

  public init(_ code: String, _ message: String) {
    self.code = code
    self.message = message
  }

  public var errorDescription: String? { message }
}

/// The platform side of the `on_device_tts/onnx` channel contract (see
/// `doc/native_contract.md`), independent of Flutter so it can be tested
/// directly.
///
/// Call every method on the main thread; completions and events are
/// delivered on the main thread too. Models load and synthesize on
/// background queues.
public final class OnnxTtsEngine {
  /// Receives `{utteranceId, type, elapsedMs, message?}` events.
  public var onEvent: (([String: Any]) -> Void)?

  private var models = [String: SupertonicModel]()
  private var nextHandle = 1
  private let loadQueue = DispatchQueue(
    label: "on_device_tts.load", qos: .userInitiated, attributes: .concurrent)
  /// Runs all synthesis, for `speak` and `synthesize`, in order.
  private let inferenceQueue = DispatchQueue(label: "on_device_tts.inference", qos: .userInitiated)
  /// Built on the first `speak`, and again after a media services reset.
  private(set) var output: PcmOutput?
  private let makeOutput: () -> PcmOutput
  private var current: SpeakJob?
  /// How long past the end of the audio scheduled so far the engine waits
  /// for the player to report it played, before it gives up on the
  /// utterance with an `error` (so a lost completion can't leave the engine
  /// `busy` for good).
  var watchdogMargin: TimeInterval = 5

  public convenience init() {
    self.init(makeOutput: { AudioOutput() })
  }

  init(makeOutput: @escaping () -> PcmOutput) {
    self.makeOutput = makeOutput
  }

  /// Logs through NSLog, so it shows in the device console.
  static func log(_ message: String) {
    NSLog("on_device_tts: %@", message)
  }

  static func badArgs(_ message: String) -> OnnxTtsError {
    OnnxTtsError("bad_args", message)
  }

  // MARK: - Models

  public func load(
    modelType: String, modelDir: String, numThreads: Int, provider: String,
    completion: @escaping (Result<String, OnnxTtsError>) -> Void
  ) {
    guard modelType == "supertonic" else {
      completion(.failure(OnnxTtsError("load_failed", "Unknown model type: \(modelType)")))
      return
    }
    guard numThreads >= 1 else {
      completion(.failure(OnnxTtsEngine.badArgs("numThreads must be at least 1")))
      return
    }
    loadQueue.async {
      let result: Result<SupertonicModel, OnnxTtsError>
      do {
        result = .success(
          try SupertonicModel(
            modelDir: modelDir, numThreads: numThreads, provider: provider,
            log: OnnxTtsEngine.log))
      } catch {
        result = .failure(OnnxTtsError("load_failed", error.localizedDescription))
      }
      DispatchQueue.main.async {
        completion(
          result.map { model in
            let handle = "supertonic-\(self.nextHandle)"
            self.nextHandle += 1
            self.models[handle] = model
            OnnxTtsEngine.log(
              "loaded \(modelDir) as \(handle) on \(model.provider) with \(numThreads) threads")
            return handle
          })
      }
    }
  }

  /// The model loaded as `handle`, if any. For tests and diagnostics.
  public func model(_ handle: String) -> SupertonicModel? {
    models[handle]
  }

  private func model(handle: String) throws -> SupertonicModel {
    guard let model = models[handle] else {
      throw OnnxTtsEngine.badArgs("Unknown handle: \(handle)")
    }
    return model
  }

  /// `{id, name}` for each voice, sorted by id. Every voice speaks all of
  /// the model's languages, so `language` is left out.
  public func voices(handle: String) throws -> [[String: Any]] {
    try model(handle: handle).voices.map { ["id": $0.id, "name": $0.id] }
  }

  /// Stops the active utterance (whatever its handle), waits for queued
  /// synthesis, then releases the model.
  public func unload(handle: String, completion: @escaping () -> Void) {
    stop()
    guard let model = models.removeValue(forKey: handle) else {
      completion()
      return
    }
    inferenceQueue.async {
      // Keep the model alive until the synthesis queued before has run.
      withExtendedLifetime(model) {}
      DispatchQueue.main.async(execute: completion)
    }
  }

  private func request(
    _ model: SupertonicModel, voiceId: String, steps: Int
  ) throws -> SupertonicVoice {
    guard SupertonicModel.stepRange.contains(steps) else {
      throw OnnxTtsEngine.badArgs("steps must be in \(SupertonicModel.stepRange)")
    }
    guard let voice = model.voices.first(where: { $0.id == voiceId }) else {
      throw OnnxTtsEngine.badArgs("Unknown voice: \(voiceId)")
    }
    return voice
  }

  // MARK: - Synthesis without playback

  /// Synthesizes `text` without playing it. Runs after any queued
  /// synthesis; [stop] doesn't affect it.
  public func synthesize(
    handle: String, text: String, language: String, voiceId: String, speed: Float, steps: Int,
    noiseSeed: Int64?,
    completion: @escaping (Result<(sampleRate: Int, pcm: [Float]), OnnxTtsError>) -> Void
  ) {
    let model: SupertonicModel
    let voice: SupertonicVoice
    do {
      model = try self.model(handle: handle)
      voice = try request(model, voiceId: voiceId, steps: steps)
    } catch {
      completion(.failure(error as! OnnxTtsError))
      return
    }
    inferenceQueue.async {
      var noise = noiseSeed.map { NoiseGenerator(seed: $0) } ?? .random()
      let result: Result<(sampleRate: Int, pcm: [Float]), OnnxTtsError>
      do {
        let pcm = try model.synthesize(
          text, language: language, voice: voice, speed: speed, steps: steps, noise: &noise)
        result = .success((model.sampleRate, pcm))
      } catch {
        result = .failure(OnnxTtsError("synthesis_failed", error.localizedDescription))
      }
      DispatchQueue.main.async { completion(result) }
    }
  }

  // MARK: - Speaking

  /// Speaks `segments` one after the other, synthesizing each while the
  /// previous one plays, and completes once the last one has played or
  /// [stop] cut it off.
  public func speak(
    handle: String, utteranceId: String, segments: [String], language: String,
    voiceId: String, speed: Float, steps: Int,
    completion: @escaping (OnnxTtsError?) -> Void
  ) {
    let received = DispatchTime.now()
    let model: SupertonicModel
    let voice: SupertonicVoice
    do {
      model = try self.model(handle: handle)
      voice = try request(model, voiceId: voiceId, steps: steps)
    } catch {
      completion((error as! OnnxTtsError))
      return
    }
    if let active = current {
      completion(OnnxTtsError("busy", "Already speaking \(active.utteranceId)"))
      return
    }
    let job = SpeakJob(
      utteranceId: utteranceId, start: received, sampleRate: model.sampleRate,
      completion: completion)
    current = job

    let output: PcmOutput
    do {
      output = try startOutput(sampleRate: model.sampleRate)
    } catch let error as AudioSessionInterrupted {
      // A call holds the session: nothing can play until it ends. Not a
      // failure of the engine, so the message is skipped quietly.
      OnnxTtsEngine.log("not speaking \(utteranceId): \(error.localizedDescription)")
      finish(job, type: "stopped", message: error.localizedDescription)
      return
    } catch {
      finish(job, type: "error", message: "audio output failed: \(error.localizedDescription)")
      return
    }

    inferenceQueue.async {
      var noise = NoiseGenerator.random()
      do {
        for segment in segments {
          if job.cancellation.isCancelled { break }
          try model.synthesize(
            segment, language: language, voice: voice, speed: speed, steps: steps,
            noise: &noise, isCancelled: { job.cancellation.isCancelled }
          ) { pcm in
            // Keep at most two buffers queued ahead of synthesis.
            if !job.ahead.acquire() { throw SupertonicError.cancelled }
            DispatchQueue.main.async { self.enqueue(pcm, for: job, on: output) }
          }
        }
        DispatchQueue.main.async {
          job.synthesisDone = true
          self.finishIfPlayed(job)
        }
      } catch SupertonicError.cancelled {
        // stop() has already completed the job.
      } catch {
        DispatchQueue.main.async {
          self.finish(job, type: "error", message: error.localizedDescription)
        }
      }
    }
  }

  private func startOutput(sampleRate: Int) throws -> PcmOutput {
    if let stale = output, stale.invalidated {
      output = nil
    }
    let output = self.output ?? makeOutput()
    if self.output == nil {
      output.onEvent = { [weak self, weak output] event in
        self?.handle(event, from: output)
      }
      self.output = output
    }
    try output.start(sampleRate: sampleRate)
    return output
  }

  /// Ends the active utterance when the audio output cut it off. The output
  /// rebuilds itself on the next `speak`; after a media services reset it is
  /// dropped and a new one is made.
  private func handle(_ event: AudioOutputEvent, from source: PcmOutput?) {
    if event == .mediaServicesReset, let source = source, source === output {
      // Its audio objects are invalid: don't touch them again.
      output = nil
    }
    guard let job = current else { return }
    let (type, message) = OnnxTtsEngine.outcome(of: event)
    OnnxTtsEngine.log("ending \(job.utteranceId) (\(type)): \(message)")
    cancel(job)
    finish(job, type: type, message: message)
  }

  /// The terminal event type and message for an utterance that `event`
  /// cut off.
  static func outcome(of event: AudioOutputEvent) -> (type: String, message: String) {
    switch event {
    case .interrupted: return ("stopped", "audio session interrupted")
    case .configurationChanged: return ("stopped", "audio configuration changed")
    case .deviceRemoved: return ("stopped", "audio device removed")
    case .mediaServicesReset: return ("error", "media services were reset")
    }
  }

  private func enqueue(_ pcm: [Float], for job: SpeakJob, on output: PcmOutput) {
    guard current === job, !job.cancellation.isCancelled else { return }
    // When this buffer should have finished playing: after what is still
    // queued, or from now if nothing is.
    let now = DispatchTime.now()
    let startsAt = job.pendingBuffers > 0 ? max(job.playedBy, now) : now
    job.playedBy = startsAt + Double(pcm.count) / Double(job.sampleRate)
    job.pendingBuffers += 1
    output.schedule(pcm) {
      DispatchQueue.main.async {
        job.pendingBuffers -= 1
        job.ahead.release()
        self.finishIfPlayed(job)
      }
    }
    // Every time, not just for the first buffer: if the engine stopped
    // since, this starts it again (or fails) instead of queueing audio that
    // never plays.
    do {
      try output.play()
    } catch {
      cancel(job)
      finish(job, type: "error", message: "audio output failed: \(error.localizedDescription)")
      return
    }
    armWatchdog(job)
    if !job.startedAudio {
      job.startedAudio = true
      emit(job, type: "firstAudio")
    }
  }

  /// Fails the utterance if the audio queued so far hasn't been reported as
  /// played `watchdogMargin` seconds after it should have.
  private func armWatchdog(_ job: SpeakJob) {
    job.watchdog?.cancel()
    let watchdog = DispatchWorkItem { [weak self, weak job] in
      guard let self = self, let job = job, self.current === job, job.pendingBuffers > 0 else {
        return
      }
      OnnxTtsEngine.log("\(job.utteranceId): playback stalled, giving up")
      self.cancel(job)
      self.finish(job, type: "error", message: "audio playback stalled")
    }
    job.watchdog = watchdog
    DispatchQueue.main.asyncAfter(deadline: job.playedBy + watchdogMargin, execute: watchdog)
  }

  private func finishIfPlayed(_ job: SpeakJob) {
    if current === job, job.synthesisDone, job.pendingBuffers == 0 {
      finish(job, type: "done")
    }
  }

  /// Stops the utterance being spoken, if any: playback stops at once, and
  /// its synthesis stops before the next model run. The pending `speak`
  /// completes normally. `synthesize` calls aren't affected.
  public func stop() {
    guard let job = current else { return }
    cancel(job)
    finish(job, type: "stopped")
  }

  private func cancel(_ job: SpeakJob) {
    job.cancellation.cancel()
    // Wake the synthesis loop if it's waiting for playback.
    job.ahead.close()
    output?.stop()
  }

  private func finish(_ job: SpeakJob, type: String, message: String? = nil) {
    guard current === job else { return }
    current = nil
    job.watchdog?.cancel()
    job.watchdog = nil
    if type != "done" {
      output?.stop()
    }
    output?.idle()
    emit(job, type: type, message: message)
    job.completion(type == "error" ? OnnxTtsError("speak_failed", message ?? "speak failed") : nil)
  }

  private func emit(_ job: SpeakJob, type: String, message: String? = nil) {
    var event: [String: Any] = [
      "utteranceId": job.utteranceId,
      "type": type,
      "elapsedMs": Int((DispatchTime.now().uptimeNanoseconds - job.start.uptimeNanoseconds) / 1_000_000),
    ]
    if let message = message { event["message"] = message }
    onEvent?(event)
  }

  /// Stops everything and releases every model.
  public func shutdown() {
    stop()
    models.removeAll()
    output?.idle()
    output = nil
  }
}

/// A thread-safe cancellation flag.
final class Cancellation {
  private let lock = NSLock()
  private var cancelled = false

  var isCancelled: Bool {
    lock.lock()
    defer { lock.unlock() }
    return cancelled
  }

  func cancel() {
    lock.lock()
    cancelled = true
    lock.unlock()
  }
}

/// Lets at most `limit` holders through until [close].
final class Gate {
  private let condition = NSCondition()
  private let limit: Int
  private var held = 0
  private var closed = false

  init(limit: Int) {
    self.limit = limit
  }

  /// Blocks until fewer than `limit` are held, then holds one. Returns
  /// false, without holding, once the gate is closed.
  func acquire() -> Bool {
    condition.lock()
    defer { condition.unlock() }
    while held >= limit && !closed {
      condition.wait()
    }
    if closed { return false }
    held += 1
    return true
  }

  func release() {
    condition.lock()
    held = max(0, held - 1)
    condition.signal()
    condition.unlock()
  }

  func close() {
    condition.lock()
    closed = true
    condition.broadcast()
    condition.unlock()
  }
}

/// One `speak` call. Only `cancellation` and `ahead` are used off the main
/// thread.
final class SpeakJob {
  let utteranceId: String
  let completion: (OnnxTtsError?) -> Void
  /// When the native side received the `speak` call.
  let start: DispatchTime
  let cancellation = Cancellation()
  let ahead = Gate(limit: 2)
  let sampleRate: Int
  var pendingBuffers = 0
  /// When the audio scheduled so far should have finished playing.
  var playedBy = DispatchTime.now()
  var watchdog: DispatchWorkItem?
  var synthesisDone = false
  var startedAudio = false

  init(
    utteranceId: String, start: DispatchTime, sampleRate: Int,
    completion: @escaping (OnnxTtsError?) -> Void
  ) {
    self.utteranceId = utteranceId
    self.start = start
    self.sampleRate = sampleRate
    self.completion = completion
  }
}
