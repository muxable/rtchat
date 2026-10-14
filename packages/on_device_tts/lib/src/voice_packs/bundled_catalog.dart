// The voice pack catalog the package ships with, used when no newer catalog
// can be fetched.
//
// PROVISIONAL: these packs are a starting point. The benchmark spike (#1500)
// picks the defaults we ship, and this list changes then.
//
// The files are the sherpa-onnx conversions published on GitHub
// (https://github.com/k2-fsa/sherpa-onnx/releases/tag/tts-models). Hosting
// them ourselves is tracked in #1510; each file is a URL so the catalog can
// point anywhere without a format change. Sizes and checksums were computed
// by downloading every file.
//
// Generated from JSON; keep it valid JSON so it can also be served as a
// remote catalog.

/// The JSON of the catalog bundled with the package.
const bundledVoicePackCatalogJson = r'''
{
  "schema": 1,
  "version": 1,
  "packs": [
    {
      "id": "kitten-nano-en-v0_8-int8",
      "name": "Kitten TTS nano 0.8 (English)",
      "version": 1,
      "model_type": "kitten",
      "languages": [
        "en-US"
      ],
      "speakers": [
        {
          "id": 0,
          "name": "Jasper",
          "gender": "male"
        },
        {
          "id": 1,
          "name": "Bella",
          "gender": "female"
        },
        {
          "id": 2,
          "name": "Bruno",
          "gender": "male"
        },
        {
          "id": 3,
          "name": "Luna",
          "gender": "female"
        },
        {
          "id": 4,
          "name": "Hugo",
          "gender": "male"
        },
        {
          "id": 5,
          "name": "Rosie",
          "gender": "female"
        },
        {
          "id": 6,
          "name": "Leo",
          "gender": "male"
        },
        {
          "id": 7,
          "name": "Kiki",
          "gender": "female"
        }
      ],
      "files": [
        {
          "url": "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kitten-nano-en-v0_8-int8.tar.bz2",
          "size": 31220690,
          "sha256": "6fa5be852612ce761094ba74ee6123b4fc4acfefa79bf64dc63acae4a83af2fd",
          "path": "",
          "archive": "tar.bz2",
          "strip_components": 1
        }
      ],
      "license": {
        "name": "Apache-2.0",
        "url": "https://github.com/KittenML/KittenTTS/blob/main/LICENSE",
        "attribution": "Kitten TTS by KittenML, converted by sherpa-onnx"
      },
      "config": {
        "model": "model.int8.onnx",
        "voices": "voices.bin",
        "tokens": "tokens.txt",
        "data_dir": "espeak-ng-data"
      }
    },
    {
      "id": "kokoro-int8-multi-lang-v1_0",
      "name": "Kokoro 1.0 (multilingual)",
      "version": 1,
      "model_type": "kokoro",
      "languages": [
        "en-US",
        "en-GB",
        "es",
        "fr",
        "hi",
        "it",
        "ja",
        "pt-BR",
        "zh"
      ],
      "speakers": [
        {
          "id": 0,
          "name": "af_alloy",
          "gender": "female",
          "language": "en-US"
        },
        {
          "id": 1,
          "name": "af_aoede",
          "gender": "female",
          "language": "en-US"
        },
        {
          "id": 2,
          "name": "af_bella",
          "gender": "female",
          "language": "en-US"
        },
        {
          "id": 3,
          "name": "af_heart",
          "gender": "female",
          "language": "en-US"
        },
        {
          "id": 4,
          "name": "af_jessica",
          "gender": "female",
          "language": "en-US"
        },
        {
          "id": 5,
          "name": "af_kore",
          "gender": "female",
          "language": "en-US"
        },
        {
          "id": 6,
          "name": "af_nicole",
          "gender": "female",
          "language": "en-US"
        },
        {
          "id": 7,
          "name": "af_nova",
          "gender": "female",
          "language": "en-US"
        },
        {
          "id": 8,
          "name": "af_river",
          "gender": "female",
          "language": "en-US"
        },
        {
          "id": 9,
          "name": "af_sarah",
          "gender": "female",
          "language": "en-US"
        },
        {
          "id": 10,
          "name": "af_sky",
          "gender": "female",
          "language": "en-US"
        },
        {
          "id": 11,
          "name": "am_adam",
          "gender": "male",
          "language": "en-US"
        },
        {
          "id": 12,
          "name": "am_echo",
          "gender": "male",
          "language": "en-US"
        },
        {
          "id": 13,
          "name": "am_eric",
          "gender": "male",
          "language": "en-US"
        },
        {
          "id": 14,
          "name": "am_fenrir",
          "gender": "male",
          "language": "en-US"
        },
        {
          "id": 15,
          "name": "am_liam",
          "gender": "male",
          "language": "en-US"
        },
        {
          "id": 16,
          "name": "am_michael",
          "gender": "male",
          "language": "en-US"
        },
        {
          "id": 17,
          "name": "am_onyx",
          "gender": "male",
          "language": "en-US"
        },
        {
          "id": 18,
          "name": "am_puck",
          "gender": "male",
          "language": "en-US"
        },
        {
          "id": 19,
          "name": "am_santa",
          "gender": "male",
          "language": "en-US"
        },
        {
          "id": 20,
          "name": "bf_alice",
          "gender": "female",
          "language": "en-GB"
        },
        {
          "id": 21,
          "name": "bf_emma",
          "gender": "female",
          "language": "en-GB"
        },
        {
          "id": 22,
          "name": "bf_isabella",
          "gender": "female",
          "language": "en-GB"
        },
        {
          "id": 23,
          "name": "bf_lily",
          "gender": "female",
          "language": "en-GB"
        },
        {
          "id": 24,
          "name": "bm_daniel",
          "gender": "male",
          "language": "en-GB"
        },
        {
          "id": 25,
          "name": "bm_fable",
          "gender": "male",
          "language": "en-GB"
        },
        {
          "id": 26,
          "name": "bm_george",
          "gender": "male",
          "language": "en-GB"
        },
        {
          "id": 27,
          "name": "bm_lewis",
          "gender": "male",
          "language": "en-GB"
        },
        {
          "id": 28,
          "name": "ef_dora",
          "gender": "female",
          "language": "es"
        },
        {
          "id": 29,
          "name": "em_alex",
          "gender": "male",
          "language": "es"
        },
        {
          "id": 30,
          "name": "ff_siwis",
          "gender": "female",
          "language": "fr"
        },
        {
          "id": 31,
          "name": "hf_alpha",
          "gender": "female",
          "language": "hi"
        },
        {
          "id": 32,
          "name": "hf_beta",
          "gender": "female",
          "language": "hi"
        },
        {
          "id": 33,
          "name": "hm_omega",
          "gender": "male",
          "language": "hi"
        },
        {
          "id": 34,
          "name": "hm_psi",
          "gender": "male",
          "language": "hi"
        },
        {
          "id": 35,
          "name": "if_sara",
          "gender": "female",
          "language": "it"
        },
        {
          "id": 36,
          "name": "im_nicola",
          "gender": "male",
          "language": "it"
        },
        {
          "id": 37,
          "name": "jf_alpha",
          "gender": "female",
          "language": "ja"
        },
        {
          "id": 38,
          "name": "jf_gongitsune",
          "gender": "female",
          "language": "ja"
        },
        {
          "id": 39,
          "name": "jf_nezumi",
          "gender": "female",
          "language": "ja"
        },
        {
          "id": 40,
          "name": "jf_tebukuro",
          "gender": "female",
          "language": "ja"
        },
        {
          "id": 41,
          "name": "jm_kumo",
          "gender": "male",
          "language": "ja"
        },
        {
          "id": 42,
          "name": "pf_dora",
          "gender": "female",
          "language": "pt-BR"
        },
        {
          "id": 43,
          "name": "pm_alex",
          "gender": "male",
          "language": "pt-BR"
        },
        {
          "id": 44,
          "name": "pm_santa",
          "gender": "male",
          "language": "pt-BR"
        },
        {
          "id": 45,
          "name": "zf_xiaobei",
          "gender": "female",
          "language": "zh"
        },
        {
          "id": 46,
          "name": "zf_xiaoni",
          "gender": "female",
          "language": "zh"
        },
        {
          "id": 47,
          "name": "zf_xiaoxiao",
          "gender": "female",
          "language": "zh"
        },
        {
          "id": 48,
          "name": "zf_xiaoyi",
          "gender": "female",
          "language": "zh"
        },
        {
          "id": 49,
          "name": "zm_yunjian",
          "gender": "male",
          "language": "zh"
        },
        {
          "id": 50,
          "name": "zm_yunxi",
          "gender": "male",
          "language": "zh"
        },
        {
          "id": 51,
          "name": "zm_yunxia",
          "gender": "male",
          "language": "zh"
        },
        {
          "id": 52,
          "name": "zm_yunyang",
          "gender": "male",
          "language": "zh"
        },
        {
          "id": 53,
          "name": "em_santa",
          "gender": "male",
          "language": "es"
        }
      ],
      "files": [
        {
          "url": "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-int8-multi-lang-v1_0.tar.bz2",
          "size": 132303094,
          "sha256": "4c3052abaa60943a341f193888cf6abd68787dae6ab8ae5c925a706caa247e4e",
          "path": "",
          "archive": "tar.bz2",
          "strip_components": 1
        }
      ],
      "license": {
        "name": "Apache-2.0",
        "url": "https://huggingface.co/hexgrad/Kokoro-82M",
        "attribution": "Kokoro-82M by hexgrad, converted by sherpa-onnx"
      },
      "config": {
        "model": "model.int8.onnx",
        "voices": "voices.bin",
        "tokens": "tokens.txt",
        "data_dir": "espeak-ng-data",
        "lexicon": "lexicon-us-en.txt,lexicon-zh.txt",
        "dict_dir": "dict",
        "rule_fsts": "date-zh.fst,phone-zh.fst,number-zh.fst"
      }
    },
    {
      "id": "vits-piper-en_us-ljspeech-medium",
      "name": "Piper ljspeech (English (US))",
      "version": 1,
      "model_type": "vits",
      "languages": [
        "en-US"
      ],
      "speakers": [
        {
          "id": 0,
          "name": "ljspeech",
          "gender": "female",
          "language": "en-US"
        }
      ],
      "files": [
        {
          "url": "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-ljspeech-medium.tar.bz2",
          "size": 67169893,
          "sha256": "3dfb4b759d8be032a4903a9538d128b0fda2a06ab1de6cbc2d93a97e2dd83dba",
          "path": "",
          "archive": "tar.bz2",
          "strip_components": 1
        }
      ],
      "license": {
        "name": "LicenseRef-public-domain",
        "url": "https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/ljspeech/medium/MODEL_CARD",
        "attribution": "Piper voice en_US-ljspeech-medium by the Piper project, trained on https://keithito.com/LJ-Speech-Dataset/, converted by sherpa-onnx"
      },
      "config": {
        "model": "en_US-ljspeech-medium.onnx",
        "tokens": "tokens.txt",
        "data_dir": "espeak-ng-data"
      }
    },
    {
      "id": "vits-piper-es_es-davefx-medium",
      "name": "Piper davefx (Spanish (Spain))",
      "version": 1,
      "model_type": "vits",
      "languages": [
        "es-ES"
      ],
      "speakers": [
        {
          "id": 0,
          "name": "davefx",
          "gender": "male",
          "language": "es-ES"
        }
      ],
      "files": [
        {
          "url": "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-es_ES-davefx-medium.tar.bz2",
          "size": 67184952,
          "sha256": "a3f6beb54a9cb893279f72978a22f807a4d9fc9c7848157b524d5cc7b7f58b22",
          "path": "",
          "archive": "tar.bz2",
          "strip_components": 1
        }
      ],
      "license": {
        "name": "CC0-1.0",
        "url": "https://huggingface.co/rhasspy/piper-voices/blob/main/es/es_ES/davefx/medium/MODEL_CARD",
        "attribution": "Piper voice es_ES-davefx-medium by the Piper project, trained on https://github.com/NabuCasa/voice-datasets, converted by sherpa-onnx"
      },
      "config": {
        "model": "es_ES-davefx-medium.onnx",
        "tokens": "tokens.txt",
        "data_dir": "espeak-ng-data"
      }
    },
    {
      "id": "vits-piper-de_de-thorsten-medium",
      "name": "Piper thorsten (German)",
      "version": 1,
      "model_type": "vits",
      "languages": [
        "de-DE"
      ],
      "speakers": [
        {
          "id": 0,
          "name": "thorsten",
          "gender": "male",
          "language": "de-DE"
        }
      ],
      "files": [
        {
          "url": "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-de_DE-thorsten-medium.tar.bz2",
          "size": 67214254,
          "sha256": "50487d9c95fdf2191f31d2588569381063ba1591dcd4c7d4bdd30f12b2191714",
          "path": "",
          "archive": "tar.bz2",
          "strip_components": 1
        }
      ],
      "license": {
        "name": "CC0-1.0",
        "url": "https://huggingface.co/rhasspy/piper-voices/blob/main/de/de_DE/thorsten/medium/MODEL_CARD",
        "attribution": "Piper voice de_DE-thorsten-medium by the Piper project, trained on https://github.com/thorstenMueller/Thorsten-Voice, converted by sherpa-onnx"
      },
      "config": {
        "model": "de_DE-thorsten-medium.onnx",
        "tokens": "tokens.txt",
        "data_dir": "espeak-ng-data"
      }
    },
    {
      "id": "vits-piper-fr_fr-siwis-medium",
      "name": "Piper siwis (French)",
      "version": 1,
      "model_type": "vits",
      "languages": [
        "fr-FR"
      ],
      "speakers": [
        {
          "id": 0,
          "name": "siwis",
          "gender": "female",
          "language": "fr-FR"
        }
      ],
      "files": [
        {
          "url": "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-fr_FR-siwis-medium.tar.bz2",
          "size": 67207459,
          "sha256": "375909aa30842b3a4efa10b1beb1d761af792960ae6873b4d53889f96c66195b",
          "path": "",
          "archive": "tar.bz2",
          "strip_components": 1
        }
      ],
      "license": {
        "name": "CC-BY-4.0",
        "url": "https://huggingface.co/rhasspy/piper-voices/blob/main/fr/fr_FR/siwis/medium/MODEL_CARD",
        "attribution": "Piper voice fr_FR-siwis-medium by the Piper project, trained on https://datashare.is.ed.ac.uk/handle/10283/2353, converted by sherpa-onnx"
      },
      "config": {
        "model": "fr_FR-siwis-medium.onnx",
        "tokens": "tokens.txt",
        "data_dir": "espeak-ng-data"
      }
    },
    {
      "id": "vits-piper-pt_br-faber-medium",
      "name": "Piper faber (Portuguese (Brazil))",
      "version": 1,
      "model_type": "vits",
      "languages": [
        "pt-BR"
      ],
      "speakers": [
        {
          "id": 0,
          "name": "faber",
          "gender": "male",
          "language": "pt-BR"
        }
      ],
      "files": [
        {
          "url": "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-pt_BR-faber-medium.tar.bz2",
          "size": 67183065,
          "sha256": "7add3f923ad6bc25ca8a192805fd1a64d1b3893e4611c4a9719545a825039a83",
          "path": "",
          "archive": "tar.bz2",
          "strip_components": 1
        }
      ],
      "license": {
        "name": "CC0-1.0",
        "url": "https://huggingface.co/rhasspy/piper-voices/blob/main/pt/pt_BR/faber/medium/MODEL_CARD",
        "attribution": "Piper voice pt_BR-faber-medium by the Piper project, trained on https://github.com/OHF-Voice/voice-datasets, converted by sherpa-onnx"
      },
      "config": {
        "model": "pt_BR-faber-medium.onnx",
        "tokens": "tokens.txt",
        "data_dir": "espeak-ng-data"
      }
    }
  ]
}
''';
