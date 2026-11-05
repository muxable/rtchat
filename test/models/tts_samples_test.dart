import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:flutter/widgets.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';
import 'package:rtchat/models/tts/samples.dart';

import '../fakes/fake_tts_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('speech locales also provide complete app UI translations', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('fi')));
    final finnish = lookupAppLocalizations(const Locale('fi'));
    expect(finnish.settings, 'Asetukset');
    expect(
      finnish.textToSpeechEnabled,
      'Tekstin puheeksi muuntaminen käytössä',
    );
    expect(
      lookupAppLocalizations(const Locale('fi')).saidMessage('Viewer', 'hello'),
      'Viewer sanoi: hello',
    );
  });

  test(
    'every selectable and bundled speech language has a localized sample',
    () {
      final english = ttsSampleMessage('en');
      final languages = {
        ...supportedLanguages,
        for (final pack in bundledVoicePacks) ...pack.languages,
      };
      for (final language in languages.where((code) => code != 'en')) {
        expect(ttsSampleMessage(language), isNot(english), reason: language);
      }
      expect(ttsSampleMessage('de-DE'), ttsSampleMessage('de'));
      expect(ttsSampleMessage('pt_BR'), ttsSampleMessage('pt'));
      expect(ttsSampleMessage('zh-Hant'), contains('這'));
      expect(ttsSampleMessage('zh-CN'), contains('这'));
      expect(ttsSampleMessage('unknown'), english);
    },
  );

  test(
    'main sample follows reading language using the chosen neural voice',
    () async {
      final system = FakeTtsEngine();
      final neural = FakeTtsEngine(availableVoices: packVoices(['de', 'en']));
      final model =
          TtsModel.fromJson({'language': 'de'}, engine: system)
            ..neuralEngine = neural
            ..setVoice('de', 'M3');
      addTearDown(model.dispose);
      await model.previewSample();
      expect(neural.utterances.single.text, ttsSampleMessage('de'));
      expect(neural.utterances.single.language, 'de');
      expect(neural.utterances.single.voice?.id, 'M3');
      expect(system.utterances, isEmpty);
    },
  );

  test(
    'per-voice preview uses that language and voice, independent of UI',
    () async {
      final neural = FakeTtsEngine(availableVoices: packVoices(['ja', 'en']));
      final model = TtsModel.fromJson({
        'language': 'en',
      }, engine: FakeTtsEngine())..neuralEngine = neural;
      addTearDown(model.dispose);
      await model.previewSample(language: 'ja-JP', voiceId: 'F4');
      expect(neural.utterances.single.text, ttsSampleMessage('ja'));
      expect(neural.utterances.single.language, 'ja');
      expect(neural.utterances.single.voice?.id, 'F4');
    },
  );

  test(
    'system sample receives matching text and language without a pack',
    () async {
      final system = FakeTtsEngine();
      final model = TtsModel.fromJson({'language': 'fi'}, engine: system);
      addTearDown(model.dispose);
      await model.previewSample();
      expect(system.utterances.single.text, ttsSampleMessage('fi'));
      expect(system.utterances.single.language, 'fi');
    },
  );
}
