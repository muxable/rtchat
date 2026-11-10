// Adapted from flutter_tts 4.2.5 (MIT); see third_party/flutter_tts/LICENSE.
import AVFoundation

enum AudioCategoryOptions: String {
  case iosAudioCategoryOptionsMixWithOthers
  case iosAudioCategoryOptionsDuckOthers
  case iosAudioCategoryOptionsInterruptSpokenAudioAndMixWithOthers
  case iosAudioCategoryOptionsAllowBluetooth
  case iosAudioCategoryOptionsAllowBluetoothA2DP
  case iosAudioCategoryOptionsAllowAirPlay
  case iosAudioCategoryOptionsDefaultToSpeaker

  func toAVAudioSessionCategoryOptions() -> AVAudioSession.CategoryOptions? {
    switch self {
    case .iosAudioCategoryOptionsMixWithOthers:
      return .mixWithOthers
    case .iosAudioCategoryOptionsDuckOthers:
      return .duckOthers
    case .iosAudioCategoryOptionsInterruptSpokenAudioAndMixWithOthers:
      if #available(iOS 9.0, *) {
        return .interruptSpokenAudioAndMixWithOthers
      } else {
        return nil
      }
    case .iosAudioCategoryOptionsAllowBluetooth:
      return .allowBluetooth
    case .iosAudioCategoryOptionsAllowBluetoothA2DP:
      if #available(iOS 10.0, *) {
        return .allowBluetoothA2DP
      } else {
        return nil
      }
    case .iosAudioCategoryOptionsAllowAirPlay:
      if #available(iOS 10.0, *) {
        return .allowAirPlay
      } else {
        return nil
      }
    case .iosAudioCategoryOptionsDefaultToSpeaker:
      return .defaultToSpeaker
    }
  }
}
