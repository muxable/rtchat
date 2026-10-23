// Adapted from flutter_tts 4.2.5 (MIT); see third_party/flutter_tts/LICENSE.
import AVFoundation

enum AudioCategory: String {
  case iosAudioCategoryAmbientSolo
  case iosAudioCategoryAmbient
  case iosAudioCategoryPlayback
  case iosAudioCategoryPlaybackAndRecord

  func toAVAudioSessionCategory() -> AVAudioSession.Category {
    switch self {
    case .iosAudioCategoryAmbientSolo:
      return .soloAmbient
    case .iosAudioCategoryAmbient:
      return .ambient
    case .iosAudioCategoryPlayback:
      return .playback
    case .iosAudioCategoryPlaybackAndRecord:
      return .playAndRecord
    }
  }
}
