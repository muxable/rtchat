import AVFoundation
import Foundation

/// Plays mono float32 PCM through an `AVAudioPlayerNode` on an
/// `AVAudioEngine`, in an audio session that matches `SystemTtsEngine`'s
/// `flutter_tts` setup: the playback category, mixed with other audio, in
/// the voice prompt mode. With the app's `audio` background mode this keeps
/// playing in the background.
///
/// Call everything on the main thread. Completion handlers run on an
/// AVFoundation thread.
final class AudioOutput {
  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private var format: AVAudioFormat?
  private var observers = [NSObjectProtocol]()
  /// Between [start] and [idle].
  private var active = false

  /// Called on the main thread when another app interrupts the session
  /// (a call, Siri), or when the engine can't restart after its
  /// configuration changed (a route change it can't follow).
  var onInterrupted: ((String) -> Void)?

  init() {
    engine.attach(player)
    let center = NotificationCenter.default
    observers.append(
      center.addObserver(
        forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
      ) { [weak self] note in
        guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
          AVAudioSession.InterruptionType(rawValue: raw) == .began
        else { return }
        self?.onInterrupted?("audio session interrupted")
      })
    // A route change (headphones unplugged, a Bluetooth device connecting)
    // can change the hardware format; the engine then stops and has to be
    // started again.
    observers.append(
      center.addObserver(
        forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
      ) { [weak self] _ in
        self?.restartAfterConfigurationChange()
      })
  }

  deinit {
    for observer in observers {
      NotificationCenter.default.removeObserver(observer)
    }
    engine.stop()
  }

  /// Activates the audio session and starts the engine for audio at
  /// `sampleRate`.
  func start(sampleRate: Int) throws {
    let session = AVAudioSession.sharedInstance()
    if session.category != .playback || session.mode != .voicePrompt
      || session.categoryOptions != [.mixWithOthers]
    {
      try session.setCategory(.playback, mode: .voicePrompt, options: [.mixWithOthers])
    }
    try session.setActive(true)

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
    if !engine.isRunning {
      engine.prepare()
      try engine.start()
    }
    active = true
  }

  /// Queues `pcm` after whatever is already queued. `completion` runs once
  /// it has been played, or dropped by [stop].
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

  func play() {
    if !player.isPlaying { player.play() }
  }

  /// Drops everything queued and stops playing at once.
  func stop() {
    player.stop()
  }

  /// Stops the engine between utterances, so it doesn't render silence.
  func idle() {
    active = false
    player.stop()
    engine.pause()
  }

  private func restartAfterConfigurationChange() {
    guard active, !engine.isRunning else { return }
    do {
      engine.prepare()
      try engine.start()
      player.play()
    } catch {
      onInterrupted?("audio route changed: \(error.localizedDescription)")
    }
  }
}
