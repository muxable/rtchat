// The voice packs the package offers.
//
// PROVISIONAL. The engines (#1502 on Android, #1517 on iOS) run on ONNX
// Runtime without a phonemizer, so the default model is Supertonic 3,
// which needs none. Supertonic 2 is also available as a smaller five-language
// alternative. Models requiring phonemes need a separate engine integration.
//
// The files are the originals on Hugging Face (Supertone/supertonic-3),
// pinned to revision 3cadd1ee6394adea1bd021217a0e650ede09a323. Hosting them
// ourselves is tracked in #1510; each file is a URL so the packs can point
// anywhere. Sizes and checksums were computed by downloading every file.
//
// Supertonic 3 is under the BigScience OpenRAIL-M license: its use
// restrictions apply and must be passed on to users (the app shows them with
// the pack). A maintainer license review is pending. `name` and
// `attribution` are shown to users, so keep notes like these out of them.

import 'voice_pack.dart';

const _revision = '3cadd1ee6394adea1bd021217a0e650ede09a323';
const _base =
    'https://huggingface.co/Supertone/supertonic-3/resolve/$_revision';

VoicePackFile _file(String path, int size, String sha256) => VoicePackFile(
  url: Uri.parse('$_base/$path'),
  size: size,
  sha256: sha256,
  path: path,
);

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
      'vi',
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
      _file(
        'onnx/duration_predictor.onnx',
        3700147,
        'c3eb91414d5ff8a7a239b7fe9e34e7e2bf8a8140d8375ffb14718b1c639325db',
      ),
      _file(
        'onnx/text_encoder.onnx',
        36416150,
        'c7befd5ea8c3119769e8a6c1486c4edc6a3bc8365c67621c881bbb774b9902ff',
      ),
      _file(
        'onnx/vector_estimator.onnx',
        256534781,
        '883ac868ea0275ef0e991524dc64f16b3c0376efd7c320af6b53f5b780d7c61c',
      ),
      _file(
        'onnx/vocoder.onnx',
        101424195,
        '085de76dd8e8d5836d6ca66826601f615939218f90e519f70ee8a36ed2a4c4ba',
      ),
      _file(
        'onnx/tts.json',
        8253,
        '42078d3aef1cd43ab43021f3c54f47d2d75ceb4e75f627f118890128b06a0d09',
      ),
      _file(
        'onnx/unicode_indexer.json',
        277676,
        '9bf7346e43883a81f8645c81224f786d43c5b57f3641f6e7671a7d6c493cb24f',
      ),
      _file(
        'voice_styles/F1.json',
        292046,
        'bbdec6ee00231c2c742ad05483df5334cab3b52fda3ba38e6a07059c4563dbc2',
      ),
      _file(
        'voice_styles/F2.json',
        292423,
        '7c722c6a72707b1a77f035d67f0d1351ba187738e06f7683e8c72b1df3477fc6',
      ),
      _file(
        'voice_styles/F3.json',
        290794,
        '12f6ef2573baa2defa1128069cb59f203e3ab67c92af77b42df8a0e3a2f7c6ab',
      ),
      _file(
        'voice_styles/F4.json',
        291808,
        'c2fa764c1225a76dfc3e2c73e8aa4f70d9ee48793860eb34c295fff01c2e032b',
      ),
      _file(
        'voice_styles/F5.json',
        291479,
        '45966e73316415626cf41a7d1c6f3b4c70dbc1ba2bee5c1978ef0ce33244fc8d',
      ),
      _file(
        'voice_styles/M1.json',
        291748,
        'e35604687f5d23694b8e91593a93eec0e4eca6c0b02bb8ed69139ab2ea6b0a5b',
      ),
      _file(
        'voice_styles/M2.json',
        292055,
        'b76cbf62bac707c710cf0ae5aba5e31eea1a6339a9734bfae33ab98499534a50',
      ),
      _file(
        'voice_styles/M3.json',
        290198,
        'ea1ac35ccb91b0d7ecad533a2fbd0eec10c91513d8951e3b25fbba99954e159b',
      ),
      _file(
        'voice_styles/M4.json',
        291522,
        'ca8eefad4fcd989c9379032ff3e50738adc547eeb5e221b82593a6d7b3bac303',
      ),
      _file(
        'voice_styles/M5.json',
        291469,
        'dd22b92740314321f8ae11c5e87f8dd60d060f15dd3a632b5adf77f471f77af2',
      ),
    ],
    license: VoicePackLicense(
      name: 'LicenseRef-OpenRAIL-M',
      url: Uri.parse(
        'https://huggingface.co/Supertone/supertonic-3/blob/$_revision/LICENSE',
      ),
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
        'voice_styles/M5.json',
      ],
    },
  ),

  VoicePack(
    id: 'supertonic-2',
    name: 'Supertonic 2',
    version: 1,
    modelType: VoicePackModelType.supertonic,
    languages: const ['en', 'ko', 'es', 'pt', 'fr'],
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
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/onnx/duration_predictor.onnx',
        ),
        size: 1521526,
        sha256:
            '6d556b3691165c364be91dc0bd894656b5949f5acd2750d8ec2f954010845011',
        path: 'onnx/duration_predictor.onnx',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/onnx/text_encoder.onnx',
        ),
        size: 27431318,
        sha256:
            'dd5f535ed629f7df86071043e15f541ce1b2ab7f1bdbce4c7892b307bca79fa3',
        path: 'onnx/text_encoder.onnx',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/onnx/tts.json',
        ),
        size: 8699,
        sha256:
            'ee531d9af9b80438a2ed703e22155ee6c83b12595ab22fd3bb6de94c7502fe96',
        path: 'onnx/tts.json',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/onnx/unicode_indexer.json',
        ),
        size: 262196,
        sha256:
            'b7662a73a0703f43b97c0f2e089f8e8325e26f5d841aca393b5a54c509c92df1',
        path: 'onnx/unicode_indexer.json',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/onnx/vector_estimator.onnx',
        ),
        size: 132471364,
        sha256:
            '105e9d66fd8756876b210a6b4aa03fc393b1eaca3a8dadcc8d9a3bc785c86a35',
        path: 'onnx/vector_estimator.onnx',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/onnx/vocoder.onnx',
        ),
        size: 101405066,
        sha256:
            '19bd51f47a186069c752403518a40f7ea4c647455056d2511f7249691ecddf7c',
        path: 'onnx/vocoder.onnx',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/voice_styles/F1.json',
        ),
        size: 420050,
        sha256:
            '6106950ebeb8a5da29ea22075f605db659cd07dbc288a68292543d9129aa250f',
        path: 'voice_styles/F1.json',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/voice_styles/F2.json',
        ),
        size: 420293,
        sha256:
            '8b97feb16d79ac0447136796708feac5f83dbabe92a5be1168212653c38729ae',
        path: 'voice_styles/F2.json',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/voice_styles/F3.json',
        ),
        size: 419887,
        sha256:
            '7eda5bccb4e6eb7f228fa182462d5fcf982d77628234603599027f0734d70c29',
        path: 'voice_styles/F3.json',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/voice_styles/F4.json',
        ),
        size: 419642,
        sha256:
            'e056fc2bee393edc8bff761eb28f33fb461e8dad828c3b05348a010ac1b7bb79',
        path: 'voice_styles/F4.json',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/voice_styles/F5.json',
        ),
        size: 419709,
        sha256:
            'ce7645ad7e3c13cca04e0d62bf890ef9ac401988005ba8f5e9c9b59257bc6931',
        path: 'voice_styles/F5.json',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/voice_styles/M1.json',
        ),
        size: 420510,
        sha256:
            'a04c823cbda6dd1c7de131ec68fea83bbb70d7f29d61623304eb871e3b83b5a1',
        path: 'voice_styles/M1.json',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/voice_styles/M2.json',
        ),
        size: 420285,
        sha256:
            '7ddd07bf873a3fd67d09ef4e8293b486beb658158b47e371166198e4c6926072',
        path: 'voice_styles/M2.json',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/voice_styles/M3.json',
        ),
        size: 420005,
        sha256:
            'e8e77a56459e4dc8cdfeb88e6f778dc9a0adf22e1184414f4b0e82a5d1edbe72',
        path: 'voice_styles/M3.json',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/voice_styles/M4.json',
        ),
        size: 419957,
        sha256:
            '95322725e4d25d9ed4e7dcccbf0f3726b0e9a2471d876b7942373218dbd30174',
        path: 'voice_styles/M4.json',
      ),
      VoicePackFile(
        url: Uri.parse(
          'https://huggingface.co/Supertone/supertonic-2/resolve/75e6727618a02f323c720cba9478152d4bc16ca4/voice_styles/M5.json',
        ),
        size: 419619,
        sha256:
            'be52f82327da63ff18481ce2dd8060c7df432e0168d748745ef3e21b92d706a5',
        path: 'voice_styles/M5.json',
      ),
    ],
    license: VoicePackLicense(
      name: 'LicenseRef-OpenRAIL-M',
      url: Uri.parse(
        'https://huggingface.co/Supertone/supertonic-2/blob/75e6727618a02f323c720cba9478152d4bc16ca4/LICENSE',
      ),
      attribution: 'Supertonic 2 by Supertone Inc.',
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
        'voice_styles/M5.json',
      ],
    },
  ),
]);
