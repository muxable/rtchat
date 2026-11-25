import 'voice_pack.dart';

/// HTTPS directory containing the GPU pack produced by the Qwen packers.
const qwenPackBase = String.fromEnvironment('QWEN_TTS_PACK_URL');

VoicePack qwenVoicePack() {
  final base = Uri.parse(qwenPackBase);
  if (base.scheme != 'https' ||
      !base.hasAuthority ||
      !base.path.endsWith('/')) {
    throw FormatException('QWEN_TTS_PACK_URL must be an HTTPS directory URL');
  }
  VoicePackFile file(String name, int size, String hash) => VoicePackFile(
    url: base.resolve(name),
    path: name,
    size: size,
    sha256: hash,
  );
  return VoicePack(
    id: 'qwen3-tts-0.6b-customvoice',
    name: 'Qwen3-TTS 0.6B CustomVoice',
    modelType: VoicePackModelType.qwen3Tts,
    license: VoicePackLicense(
      name: 'Apache-2.0',
      attribution: 'Qwen Team',
      url: Uri.parse(
        'https://huggingface.co/Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice',
      ),
    ),
    languages: const [
      'en',
      'zh',
      'fr',
      'de',
      'it',
      'ja',
      'ko',
      'pt',
      'ru',
      'es',
    ],
    speakers: const [
      VoicePackSpeaker(index: 0, name: 'Ryan'),
      VoicePackSpeaker(index: 1, name: 'Serena'),
      VoicePackSpeaker(index: 2, name: 'Vivian'),
      VoicePackSpeaker(index: 3, name: 'Uncle_fu'),
      VoicePackSpeaker(index: 4, name: 'Aiden'),
      VoicePackSpeaker(index: 5, name: 'Ono_anna'),
      VoicePackSpeaker(index: 6, name: 'Sohee'),
      VoicePackSpeaker(index: 7, name: 'Eric'),
      VoicePackSpeaker(index: 8, name: 'Dylan'),
    ],
    files: [
      file(
        'config.json',
        4908,
        '81aca2b6fac304944d8acf345272d8a9a727d5fc2e2e66b222ab4729340c7455',
      ),
      file(
        'vocab.json',
        2776833,
        'ca10d7e9fb3ed18575dd1e277a2579c16d108e32f27439684afa0e10b1440910',
      ),
      file(
        'merges.txt',
        1671839,
        '599bab54075088774b1733fde865d5bd747cbcc7a547c5bc12610e874e26f5e3',
      ),
      file(
        'talker.bin',
        596979712,
        '66766178405ed97d0176b4a6a07440d10e0a101a60f12336cd1ce15d3712202f',
      ),
      file(
        'talker.json',
        8915,
        '63cf8d2cffc764ecbe946dd4f5161a58e90e352c85010f361ab8fd08ceafc364',
      ),
      file(
        'decoder.bin',
        456217916,
        '4163aa147ff7df3797eeebd3f6be9af9c39ad5181016465a2b382e1088c90ac1',
      ),
      file(
        'decoder.json',
        139859,
        '5f45fb57dd12479409c519ec2b9c2a29a23d61b6045bc6517b9b03699cdd1628',
      ),
      file(
        'layout.json',
        2380,
        '81f45adcc8d10a7f45a453ca2e8838d48c8e6dcec3dc2ca39620a7fc52aba115',
      ),
      file(
        'predictor.bin',
        107004928,
        '0e6588265c989906ecc05f13f1851a9154c10d470d39b1c93355a2de94cdc829',
      ),
    ],
  );
}
