// The voice pack catalog the package ships with, used when no newer catalog
// can be fetched.
//
// PROVISIONAL. The engines (#1502 on Android, #1517 on iOS) run on ONNX
// Runtime without a phonemizer, so the only model for now is Supertonic 3,
// which needs none. Models that need espeak-ng phonemes (Kitten, Piper,
// Kokoro) come back with #1518.
//
// The files are the originals on Hugging Face (Supertone/supertonic-3),
// pinned to revision 3cadd1ee6394adea1bd021217a0e650ede09a323.
// Hosting them ourselves is tracked in #1510; each file is a URL so the
// catalog can point anywhere without a format change. Sizes and checksums
// were computed by downloading every file.
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
      "id": "supertonic-3",
      "name": "Supertonic 3 (31 languages)",
      "version": 1,
      "model_type": "supertonic",
      "languages": [
        "en",
        "ko",
        "ja",
        "ar",
        "bg",
        "cs",
        "da",
        "de",
        "el",
        "es",
        "et",
        "fi",
        "fr",
        "hi",
        "hr",
        "hu",
        "id",
        "it",
        "lt",
        "lv",
        "nl",
        "pl",
        "pt",
        "ro",
        "ru",
        "sk",
        "sl",
        "sv",
        "tr",
        "uk",
        "vi"
      ],
      "speakers": [
        {"id": 0, "name": "F1", "gender": "female"},
        {"id": 1, "name": "F2", "gender": "female"},
        {"id": 2, "name": "F3", "gender": "female"},
        {"id": 3, "name": "F4", "gender": "female"},
        {"id": 4, "name": "F5", "gender": "female"},
        {"id": 5, "name": "M1", "gender": "male"},
        {"id": 6, "name": "M2", "gender": "male"},
        {"id": 7, "name": "M3", "gender": "male"},
        {"id": 8, "name": "M4", "gender": "male"},
        {"id": 9, "name": "M5", "gender": "male"}
      ],
      "files": [
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/onnx/duration_predictor.onnx",
          "size": 3700147,
          "sha256": "c3eb91414d5ff8a7a239b7fe9e34e7e2bf8a8140d8375ffb14718b1c639325db",
          "path": "onnx/duration_predictor.onnx"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/onnx/text_encoder.onnx",
          "size": 36416150,
          "sha256": "c7befd5ea8c3119769e8a6c1486c4edc6a3bc8365c67621c881bbb774b9902ff",
          "path": "onnx/text_encoder.onnx"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/onnx/vector_estimator.onnx",
          "size": 256534781,
          "sha256": "883ac868ea0275ef0e991524dc64f16b3c0376efd7c320af6b53f5b780d7c61c",
          "path": "onnx/vector_estimator.onnx"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/onnx/vocoder.onnx",
          "size": 101424195,
          "sha256": "085de76dd8e8d5836d6ca66826601f615939218f90e519f70ee8a36ed2a4c4ba",
          "path": "onnx/vocoder.onnx"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/onnx/tts.json",
          "size": 8253,
          "sha256": "42078d3aef1cd43ab43021f3c54f47d2d75ceb4e75f627f118890128b06a0d09",
          "path": "onnx/tts.json"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/onnx/unicode_indexer.json",
          "size": 277676,
          "sha256": "9bf7346e43883a81f8645c81224f786d43c5b57f3641f6e7671a7d6c493cb24f",
          "path": "onnx/unicode_indexer.json"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/voice_styles/F1.json",
          "size": 292046,
          "sha256": "bbdec6ee00231c2c742ad05483df5334cab3b52fda3ba38e6a07059c4563dbc2",
          "path": "voice_styles/F1.json"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/voice_styles/F2.json",
          "size": 292423,
          "sha256": "7c722c6a72707b1a77f035d67f0d1351ba187738e06f7683e8c72b1df3477fc6",
          "path": "voice_styles/F2.json"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/voice_styles/F3.json",
          "size": 290794,
          "sha256": "12f6ef2573baa2defa1128069cb59f203e3ab67c92af77b42df8a0e3a2f7c6ab",
          "path": "voice_styles/F3.json"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/voice_styles/F4.json",
          "size": 291808,
          "sha256": "c2fa764c1225a76dfc3e2c73e8aa4f70d9ee48793860eb34c295fff01c2e032b",
          "path": "voice_styles/F4.json"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/voice_styles/F5.json",
          "size": 291479,
          "sha256": "45966e73316415626cf41a7d1c6f3b4c70dbc1ba2bee5c1978ef0ce33244fc8d",
          "path": "voice_styles/F5.json"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/voice_styles/M1.json",
          "size": 291748,
          "sha256": "e35604687f5d23694b8e91593a93eec0e4eca6c0b02bb8ed69139ab2ea6b0a5b",
          "path": "voice_styles/M1.json"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/voice_styles/M2.json",
          "size": 292055,
          "sha256": "b76cbf62bac707c710cf0ae5aba5e31eea1a6339a9734bfae33ab98499534a50",
          "path": "voice_styles/M2.json"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/voice_styles/M3.json",
          "size": 290198,
          "sha256": "ea1ac35ccb91b0d7ecad533a2fbd0eec10c91513d8951e3b25fbba99954e159b",
          "path": "voice_styles/M3.json"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/voice_styles/M4.json",
          "size": 291522,
          "sha256": "ca8eefad4fcd989c9379032ff3e50738adc547eeb5e221b82593a6d7b3bac303",
          "path": "voice_styles/M4.json"
        },
        {
          "url": "https://huggingface.co/Supertone/supertonic-3/resolve/3cadd1ee6394adea1bd021217a0e650ede09a323/voice_styles/M5.json",
          "size": 291469,
          "sha256": "dd22b92740314321f8ae11c5e87f8dd60d060f15dd3a632b5adf77f471f77af2",
          "path": "voice_styles/M5.json"
        }
      ],
      "license": {
        "name": "LicenseRef-OpenRAIL-M",
        "url": "https://huggingface.co/Supertone/supertonic-3/blob/3cadd1ee6394adea1bd021217a0e650ede09a323/LICENSE",
        "attribution": "Supertonic 3 by Supertone Inc. BigScience OpenRAIL-M: its use restrictions apply and must be passed on to users. A maintainer license review is pending."
      },
      "config": {
        "duration_predictor": "onnx/duration_predictor.onnx",
        "text_encoder": "onnx/text_encoder.onnx",
        "vector_estimator": "onnx/vector_estimator.onnx",
        "vocoder": "onnx/vocoder.onnx",
        "tts_json": "onnx/tts.json",
        "unicode_indexer": "onnx/unicode_indexer.json",
        "voice_styles": [
          "voice_styles/F1.json",
          "voice_styles/F2.json",
          "voice_styles/F3.json",
          "voice_styles/F4.json",
          "voice_styles/F5.json",
          "voice_styles/M1.json",
          "voice_styles/M2.json",
          "voice_styles/M3.json",
          "voice_styles/M4.json",
          "voice_styles/M5.json"
        ]
      }
    }
  ]
}
''';
