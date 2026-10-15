import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';
import 'package:rtchat/models/tts/voice_packs.dart';

import '../../fakes/fake_tts_engine.dart';
import '../../fakes/fake_voice_pack_repository.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

/// The models behind the text to speech settings, with fakes for the voice
/// packs and engines, torn down after the test.
class TtsHarness {
  final repository = FakeVoicePackRepository();
  final systemEngine = FakeTtsEngine();
  late final VoicePacksModel packs;
  late final TtsModel tts;

  TtsHarness({String streamLanguage = 'en', TtsMode mode = TtsMode.disabled}) {
    packs = VoicePacksModel(repository, isSupported: true);
    tts = TtsModel.fromJson(const {},
        engine: systemEngine, reportError: (e, st) => throw e);
    tts.language = Language(streamLanguage);
    if (mode != TtsMode.disabled) tts.setMode(l10n, mode);
    addTearDown(() async {
      packs.dispose();
      tts.dispose();
      await repository.dispose();
    });
  }

  /// Lets the neural models' idle release run, so no timer outlives a test
  /// in which a neural engine spoke.
  Future<void> idle(WidgetTester tester) =>
      tester.pump(TtsModel.defaultNeuralIdleTimeout);

  /// Gives the model a neural engine with Supertonic's voices in
  /// [languages].
  FakeTtsEngine addEngine(List<String> languages) {
    final engine = FakeTtsEngine(availableVoices: packVoices(languages));
    tts.neuralEngines = [engine];
    return engine;
  }

  Widget app(Widget home) => MultiProvider(
        providers: [
          ChangeNotifierProvider<TtsModel>.value(value: tts),
          ChangeNotifierProvider<VoicePacksModel>.value(value: packs),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            LocaleNamesLocalizationsDelegate(),
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );
}
