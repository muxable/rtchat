import 'voice_pack.dart';

/// Public weights are fetched once and verified by the existing pack installer.
VoicePack qwenVoicePack() {
  const original =
      'https://huggingface.co/Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice/resolve/85e237c12c027371202489a0ec509ded67b5e4b5';
  const quantized =
      'https://huggingface.co/onnx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice/resolve/18b0bf898d211718bc33082fadc36a448e0cbc0c/cpu_int4';
  VoicePackFile file(String name, int size, String hash) => VoicePackFile(
    url: Uri.parse('${name.endsWith(".onnx") ? quantized : original}/$name'),
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
        'talker_cache.onnx',
        288573853,
        '910e1d556cd74f11bbb55fff9d509a962bfc43f23608b62fb0a8215c7acc882f',
      ),
      file(
        'text_embed.onnx',
        203384915,
        'b2923edfce01344dea9bd719e2daf94bda0b45bfd05a307514e9dd5f793dcd09',
      ),
      file(
        'code_predictor.onnx',
        91668866,
        'f0b3a431b90a56d2784599948bcff678d5188e38481d3a991d80c550d0d0bfa2',
      ),
      file(
        'residual_embed.onnx',
        22179258,
        'eec76513b562f558e76eeeb9b0bfa982de512104cddac372ec368ab504b080a0',
      ),
      file(
        'tok_decoder.onnx',
        458268831,
        '8ec10051735029f6e08b04834128c9108428885c39384f443e49a6790ccb129f',
      ),
    ],
  );
}
