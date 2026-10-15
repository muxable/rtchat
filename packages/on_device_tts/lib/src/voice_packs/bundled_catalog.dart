// The voice packs the package offers.
//
// PROVISIONAL. The engines (#1502 on Android, #1517 on iOS) run on ONNX
// Runtime without a phonemizer, so the only model for now is Supertonic 3,
// which needs none. Models that need espeak-ng phonemes (Kitten, Piper,
// Kokoro) come back with #1518.
//
// The files are the originals on Hugging Face (Supertone/supertonic-3),
// pinned to revision 3cadd1ee6394adea1bd021217a0e650ede09a323. Hosting them
// ourselves is tracked in #1510; each file is a URL so the packs can point
// anywhere. Sizes and checksums were computed by downloading every file.
//
// Supertonic 3 is under the BigScience OpenRAIL-M license: its use
// restrictions apply and must be passed on to users (the app shows them with
// the pack). A maintainer license review is pending. `name` and
// `attribution` are shown to users, so keep internal notes like these out of
// them; apps show the language count from `languages`.

import 'voice_pack.dart';

const _revision = '3cadd1ee6394adea1bd021217a0e650ede09a323';
const _base =
    'https://huggingface.co/Supertone/supertonic-3/resolve/$_revision';

VoicePackFile _file(String path, int size, String sha256) => VoicePackFile(
    url: Uri.parse('$_base/$path'), size: size, sha256: sha256, path: path);

/// The voice packs that can be downloaded.
final bundledVoicePacks = List<VoicePack>.unmodifiable([
  VoicePack(
    id: 'supertonic-3',
    name: 'Supertonic 3',
    version: 1,
    modelType: VoicePackModelType.supertonic,
    languages: const [
      'en',
      'ko',
      'ja',
      'ar',
      'bg',
      'cs',
      'da',
      'de',
      'el',
      'es',
      'et',
      'fi',
      'fr',
      'hi',
      'hr',
      'hu',
      'id',
      'it',
      'lt',
      'lv',
      'nl',
      'pl',
      'pt',
      'ro',
      'ru',
      'sk',
      'sl',
      'sv',
      'tr',
      'uk',
      'vi'
    ],
    speakers: const [
      VoicePackSpeaker(index: 0, name: 'F1', gender: 'female'),
      VoicePackSpeaker(index: 1, name: 'F2', gender: 'female'),
      VoicePackSpeaker(index: 2, name: 'F3', gender: 'female'),
      VoicePackSpeaker(index: 3, name: 'F4', gender: 'female'),
      VoicePackSpeaker(index: 4, name: 'F5', gender: 'female'),
      VoicePackSpeaker(index: 5, name: 'M1', gender: 'male'),
      VoicePackSpeaker(index: 6, name: 'M2', gender: 'male'),
      VoicePackSpeaker(index: 7, name: 'M3', gender: 'male'),
      VoicePackSpeaker(index: 8, name: 'M4', gender: 'male'),
      VoicePackSpeaker(index: 9, name: 'M5', gender: 'male'),
    ],
    files: [
      _file('onnx/duration_predictor.onnx', 3700147,
          'c3eb91414d5ff8a7a239b7fe9e34e7e2bf8a8140d8375ffb14718b1c639325db'),
      _file('onnx/text_encoder.onnx', 36416150,
          'c7befd5ea8c3119769e8a6c1486c4edc6a3bc8365c67621c881bbb774b9902ff'),
      _file('onnx/vector_estimator.onnx', 256534781,
          '883ac868ea0275ef0e991524dc64f16b3c0376efd7c320af6b53f5b780d7c61c'),
      _file('onnx/vocoder.onnx', 101424195,
          '085de76dd8e8d5836d6ca66826601f615939218f90e519f70ee8a36ed2a4c4ba'),
      _file('onnx/tts.json', 8253,
          '42078d3aef1cd43ab43021f3c54f47d2d75ceb4e75f627f118890128b06a0d09'),
      _file('onnx/unicode_indexer.json', 277676,
          '9bf7346e43883a81f8645c81224f786d43c5b57f3641f6e7671a7d6c493cb24f'),
      _file('voice_styles/F1.json', 292046,
          'bbdec6ee00231c2c742ad05483df5334cab3b52fda3ba38e6a07059c4563dbc2'),
      _file('voice_styles/F2.json', 292423,
          '7c722c6a72707b1a77f035d67f0d1351ba187738e06f7683e8c72b1df3477fc6'),
      _file('voice_styles/F3.json', 290794,
          '12f6ef2573baa2defa1128069cb59f203e3ab67c92af77b42df8a0e3a2f7c6ab'),
      _file('voice_styles/F4.json', 291808,
          'c2fa764c1225a76dfc3e2c73e8aa4f70d9ee48793860eb34c295fff01c2e032b'),
      _file('voice_styles/F5.json', 291479,
          '45966e73316415626cf41a7d1c6f3b4c70dbc1ba2bee5c1978ef0ce33244fc8d'),
      _file('voice_styles/M1.json', 291748,
          'e35604687f5d23694b8e91593a93eec0e4eca6c0b02bb8ed69139ab2ea6b0a5b'),
      _file('voice_styles/M2.json', 292055,
          'b76cbf62bac707c710cf0ae5aba5e31eea1a6339a9734bfae33ab98499534a50'),
      _file('voice_styles/M3.json', 290198,
          'ea1ac35ccb91b0d7ecad533a2fbd0eec10c91513d8951e3b25fbba99954e159b'),
      _file('voice_styles/M4.json', 291522,
          'ca8eefad4fcd989c9379032ff3e50738adc547eeb5e221b82593a6d7b3bac303'),
      _file('voice_styles/M5.json', 291469,
          'dd22b92740314321f8ae11c5e87f8dd60d060f15dd3a632b5adf77f471f77af2'),
    ],
    license: VoicePackLicense(
      name: 'LicenseRef-OpenRAIL-M',
      url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-3/blob/$_revision/LICENSE'),
      attribution: 'Supertonic 3 by Supertone Inc.',
    ),
    config: const {
      'duration_predictor': 'onnx/duration_predictor.onnx',
      'text_encoder': 'onnx/text_encoder.onnx',
      'vector_estimator': 'onnx/vector_estimator.onnx',
      'vocoder': 'onnx/vocoder.onnx',
      'tts_json': 'onnx/tts.json',
      'unicode_indexer': 'onnx/unicode_indexer.json',
      'voice_styles': [
        'voice_styles/F1.json',
        'voice_styles/F2.json',
        'voice_styles/F3.json',
        'voice_styles/F4.json',
        'voice_styles/F5.json',
        'voice_styles/M1.json',
        'voice_styles/M2.json',
        'voice_styles/M3.json',
        'voice_styles/M4.json',
        'voice_styles/M5.json'
      ],
    },
  ),
]);
