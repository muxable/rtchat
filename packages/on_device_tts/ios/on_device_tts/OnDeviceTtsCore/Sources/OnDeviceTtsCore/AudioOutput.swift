import AVFoundation
import Foundation

/// Why `AudioOutput` cut the active audio off. `OnnxTtsEngine` turns these
/// into the utterance's terminal event.
enum AudioOutputEvent: Equatable {
  /// Another app interrupted the session (a call, Siri, an alarm).
  case interrupted
  /// The engine stopped itself because the hardware configuration changed
  /// (a route or format change, e.g. AirPods connecting), or the route
  /// changed and left the engine stopped.
  case configurationChanged
  /// The device that was playing went away (headphones unplugged, a
  /// Bluetooth device disconnected). Playback apps stop rather than carry
  /// on through the loudspeaker.
  case deviceRemoved
  /// The media server was reset; every audio object is invalid.
  case mediaServicesReset
}

/// `start` failed because another app holds the audio session (a call is
/// in progress). Transient: the next `start` after the interruption works.
struct AudioSessionInterrupted: Error, LocalizedError {
  let underlying: Error?
  var errorDescription: String? {
    "audio session interrupted" + (underlying.map { ": \($0.localizedDescription)" } ?? "")
  }
}

/// Plays mono float32 PCM through an `AVAudioPlayerNode` on an
/// `AVAudioEngine`, in an audio session that matches `SystemTtsEngine`'s
/// `flutter_tts` setup: the playback category, mixed with other audio, in
/// the voice prompt mode. With the app's `audio` background mode this keeps
/// playing in the background.
///
/// The session is shared with every other audio user in the app (audioplayers
/// switches it to `.ambient` or `.playback` and deactivates it after each
/// sound), so [start] asserts the category and activates the session before
/// every utterance. Like `flutter_tts` with `mixWithOthers`, it never
/// deactivates the session.
///
/// After a configuration change, an interruption or a media services reset
/// the engine and player node are thrown away and built again on the next
/// [start].
///
/// Call everything on the main thread. Completion handlers run on an
/// AVFoundation thread.
final class AudioOutput {
  private(set) var engine = AVAudioEngine()
  private(set) var player = AVAudioPlayerNode()
  private var format: AVAudioFormat?
  private var observers = [NSObjectProtocol]()
  /// Between [start] and [idle].
  private(set) var active = false
  /// The graph must be rebuilt before the next [start].
  private(set) var stale = false
  /// Between an interruption's `.began` and `.ended`.
  private(set) var interrupted = false
  /// Set by a media services reset: this output can't be used any more.
  private(set) var invalidated = false

  /// Called on the main thread when audio was cut off; see
  /// [AudioOutputEvent]. Only sent between [start] and [idle], except
  /// `mediaServicesReset`, which is always sent.
  var onEvent: ((AudioOutputEvent) -> Void)?

  /// The session setup, a hook for tests.
  var configureSession: () throws -> Void = AudioOutput.configureSharedSession

  init() {
    engine.attach(player)
    let center = NotificationCenter.default
    observers.append(
      center.addObserver(
        forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
      ) { [weak self] note in
        self?.handleInterruption(note)
      })
    // A route or format change stops the engine; the observer is for any
    // engine, since the graph is rebuilt with a new one.
    observers.append(
      center.addObserver(
        forName: .AVAudioEngineConfigurationChange, object: nil, queue: .main
      ) { [weak self] note in
        guard let self = self, let engine = note.object as? AVAudioEngine, engine === self.engine
        else { return }
        self.handleConfigurationChange()
      })
    observers.append(
      center.addObserver(
        forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main
      ) { [weak self] note in
        self?.handleRouteChange(note)
      })
    observers.append(
      center.addObserver(
        forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main
      ) { [weak self] _ in
        self?.handleMediaServicesReset()
      })
  }

  deinit {
    for observer in observers {
      NotificationCenter.default.removeObserver(observer)
    }
    // After a media services reset the audio objects are orphaned; leave
    // them alone.
    if !invalidated {
      player.stop()
      engine.stop()
    }
  }

  /// `.playback` + `.mixWithOthers` in `.voicePrompt`, then active. Set
  /// every time: audioplayers changes the category and deactivates the
  /// session behind our back.
  static func configureSharedSession() throws {
    let session = AVAudioSession.sharedInstance()
    if session.category != .playback || session.mode != .voicePrompt
      || session.categoryOptions != [.mixWithOthers]
    {
      try session.setCategory(.playback, mode: .voicePrompt, options: [.mixWithOthers])
    }
    try session.setActive(true)
  }

  /// Activates the audio session and starts the engine for audio at
  /// `sampleRate`. Throws [AudioSessionInterrupted] while another app holds
  /// the session.
  func start(sampleRate: Int) throws {
    if invalidated {
      throw NSError(
        domain: "on_device_tts", code: 3,
        userInfo: [NSLocalizedDescriptionKey: "media services were reset"])
    }
    do {
      try configureSession()
    } catch {
      if interrupted || AudioOutput.isInterruptionError(error) {
        throw AudioSessionInterrupted(underlying: error)
      }
      throw error
    }
    // The session is ours again, even if `.ended` never arrived (it isn't
    // always delivered, e.g. when the app was suspended during the call).
    if interrupted {
      interrupted = false
      stale = true
    }

    if stale {
      rebuild()
    }
    if format?.sampleRate != Double(sampleRate) {
      guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1)
      else {
        throw NSError(
          domain: "on_device_tts", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "unsupported sample rate \(sampleRate)"])
      }
      player.stop()
      engine.disconnectNodeOutput(player)
      engine.connect(player, to: engine.mainMixerNode, format: format)
      self.format = format
    }
    try startEngine()
    active = true
  }

  private func startEngine() throws {
    if !engine.isRunning {
      engine.prepare()
      try engine.start()
    }
  }

  /// Queues `pcm` after whatever is already queued. `completion` runs once
  /// it has been played, or dropped by [stop] (or a rebuild).
  func schedule(_ pcm: [Float], completion: @escaping () -> Void) {
    guard let format = format, !pcm.isEmpty,
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(pcm.count)),
      let channel = buffer.floatChannelData?[0]
    else {
      completion()
      return
    }
    buffer.frameLength = AVAudioFrameCount(pcm.count)
    pcm.withUnsafeBufferPointer { channel.update(from: $0.baseAddress!, count: pcm.count) }
    player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { _ in completion() }
  }

  /// Starts playing what is queued. `AVAudioPlayerNode.play()` raises an
  /// Objective-C exception (which Swift can't catch) when its engine isn't
  /// running, so the engine is started first; throws if it can't be.
  func play() throws {
    guard format != nil else {
      throw NSError(
        domain: "on_device_tts", code: 2,
        userInfo: [NSLocalizedDescriptionKey: "audio output not started"])
    }
    try startEngine()
    if !player.isPlaying { player.play() }
  }

  /// Drops everything queued and stops playing at once.
  func stop() {
    player.stop()
  }

  /// Stops the engine between utterances, so it doesn't render silence.
  /// The session stays active, as `flutter_tts` leaves it.
  func idle() {
    active = false
    player.stop()
    engine.pause()
  }

  /// A new engine and player node. Stopping the old player first runs the
  /// completions of whatever it still had queued.
  private func rebuild() {
    player.stop()
    engine.stop()
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    engine.attach(player)
    self.engine = engine
    self.player = player
    format = nil
    stale = false
  }

  // MARK: - Notifications

  private func handleInterruption(_ note: Notification) {
    guard let info = note.userInfo,
      let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
      let type = AVAudioSession.InterruptionType(rawValue: raw)
    else { return }
    switch type {
    case .began:
      // A stale interruption delivered when the app resumes from suspension:
      // the session was interrupted while the app wasn't running, and has
      // nothing to do with what is playing now.
      if AudioOutput.wasSuspended(info) { return }
      interrupted = true
      stale = true
      if active { onEvent?(.interrupted) }
    case .ended:
      // Not resumed: the interrupted utterance has already ended as
      // `stopped`. The next `start` reactivates the session.
      interrupted = false
    @unknown default:
      break
    }
  }

  static func wasSuspended(_ info: [AnyHashable: Any]) -> Bool {
    // iOS 14.5 and later (the plugin needs 15.1).
    if let raw = info[AVAudioSessionInterruptionReasonKey] as? UInt,
      AVAudioSession.InterruptionReason(rawValue: raw) == .appWasSuspended
    {
      return true
    }
    // The key it replaced, in case it is still sent.
    return (info["AVAudioSessionInterruptionWasSuspendedKey"] as? NSNumber)?.boolValue ?? false
  }

  /// Whether activating the session failed because another app holds it.
  static func isInterruptionError(_ error: Error) -> Bool {
    let code = (error as NSError).code
    return code == AVAudioSession.ErrorCode.cannotInterruptOthers.rawValue
      || code == AVAudioSession.ErrorCode.insufficientPriority.rawValue
  }

  private func handleConfigurationChange() {
    // The engine stops itself before posting this. If it is still running
    // (the change came from our own `start`), there is nothing to do.
    if engine.isRunning { return }
    stale = true
    if active { onEvent?(.configurationChanged) }
  }

  private func handleRouteChange(_ note: Notification) {
    guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
      let reason = AVAudioSession.RouteChangeReason(rawValue: raw)
    else { return }
    if reason == .oldDeviceUnavailable {
      stale = true
      if active { onEvent?(.deviceRemoved) }
      return
    }
    // Every other route change may or may not come with a configuration
    // change; if it left the engine stopped, treat it as one.
    if active, !engine.isRunning {
      stale = true
      onEvent?(.configurationChanged)
    }
  }

  private func handleMediaServicesReset() {
    invalidated = true
    onEvent?(.mediaServicesReset)
  }
}
