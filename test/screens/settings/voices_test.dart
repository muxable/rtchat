import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';
import 'package:rtchat/screens/settings/tts/voices.dart';

import '../../fakes/fake_tts_engine.dart';

void main() {
  late TtsModel tts;
  late FakeTtsEngine engine;

  Future<void> open(WidgetTester tester) async {
    engine = FakeTtsEngine(availableVoices: packVoices(['en', 'de', 'fr']));
    tts =
        TtsModel.fromJson(
            const {},
            engine: FakeTtsEngine(),
            reportError: (e, st) => throw e,
          )
          ..language = Language('fr')
          ..neuralEngine = engine;
    addTearDown(tts.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: tts,
        child: const MaterialApp(
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            LocaleNamesLocalizationsDelegate(),
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: VoiceLanguagesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> titles(WidgetTester tester) => [
    for (final tile in tester.widgetList<ListTile>(find.byType(ListTile)))
      (tile.title as Text).data!,
  ];

  testWidgets('lists the languages, the stream language first', (tester) async {
    await open(tester);
    expect(titles(tester), ['Per-viewer voice', 'French', 'English', 'German']);
    expect(find.text('Stream language · F1'), findsOneWidget);
  });

  testWidgets('picking a voice is saved', (tester) async {
    await open(tester);
    await tester.tap(find.text('German'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('M2'));
    await tester.pumpAndSettle();
    expect((await tts.voiceFor('de'))?.id, 'M2');
    expect(tts.toJson()['neuralVoices'], {'de': 'M2'});
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      'M2',
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('M2'), findsOneWidget);
  });

  testWidgets('plays a sample with the voice through the engine', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('French'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(RadioListTile<String>, 'F3'),
        matching: find.byTooltip('Play sample message'),
      ),
    );
    await tester.pumpAndSettle();
    final utterance = engine.utterances.single;
    expect(
      utterance.text,
      lookupAppLocalizations(const Locale('fr')).sampleMessage,
    );
    expect(utterance.voice?.name, 'F3');
    expect(utterance.language, 'fr');
    // previewing doesn't pick the voice.
    expect((await tts.voiceFor('fr'))?.id, 'F1');

    // the model is released once idle.
    await tester.pump(TtsModel.defaultNeuralIdleTimeout);
    expect(engine.releaseCount, 1);
  });

  testWidgets('switches the per-viewer voice', (tester) async {
    await open(tester);
    expect(tts.isRandomVoiceEnabled, isTrue);
    await tester.tap(find.text('Per-viewer voice'));
    await tester.pumpAndSettle();
    expect(tts.isRandomVoiceEnabled, isFalse);
  });
}
